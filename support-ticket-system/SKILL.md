---
name: support-ticket-system
description: System zgłoszeń serwisowych — formularz, lista ticketów, email SMTP, integracja z Project Master
triggers:
  - "dodaj system zgłoszeń"
  - "support tickets"
  - "system ticketowy"
  - "zgłoszenia serwisowe"
  - "helpdesk"
---

# Support Ticket System

## Opis

Instaluje kompletny system zgłoszeń serwisowych w Next.js + Supabase SaaS:

- **Formularz zgłoszenia** — tytuł, opis, załączniki (drag & drop, do 3 plików, max 5 MB, tylko obrazy)
- **Lista "Moje zgłoszenia"** — karty z numerem, statusem, datą SLA, rozwinięciem szczegółów
- **Email SMTP** — potwierdzenie po przyjęciu + powiadomienie o rozwiązaniu
- **Replikacja do Project Master** — automatyczny handoff w `.ai/handoffs/` + POST do PM gateway
- **RLS** — każdy użytkownik widzi tylko własne zgłoszenia, serwis (service_role) może aktualizować statusy

Używaj, gdy SaaS potrzebuje kanału wsparcia bez zewnętrznych narzędzi (Zendesk, Freshdesk).

---

## Wymagania

- Next.js 16+ (App Router)
- Supabase (PostgreSQL + Auth + Storage)
- `nodemailer` (npm)
- Projekt zarejestrowany w `project_registry` Project Master (dla replikacji)
- HMAC secret skonfigurowany (skill: `cross-project-gateway`)

---

## Konfiguracja — zmienne środowiskowe

Dodaj do `.env.local` i na Vercel:

```env
# Prefiks numerów ticketów (np. TRN, CRM, MKT)
SUPPORT_TICKET_PREFIX=TRN

# SLA w dniach roboczych
SUPPORT_SLA_BUSINESS_DAYS=2

# SMTP — cyber-folks lub dowolny provider
SMTP_HOST=s170.cyber-folks.pl
SMTP_PORT=465
SMTP_USER=support@domena.pl
SMTP_PASS=haslo
SMTP_FROM=support@domena.pl

# Integracja z Project Master
CROSS_PROJECT_PM_URL=https://project-master-nine-omega.vercel.app
CROSS_PROJECT_HMAC_SECRET=twoj-sekret-hmac
```

---

## Migracja SQL

Uruchom w Supabase SQL Editor (lub przez `supabase db push`):

```sql
-- ===================================================
-- TABELA: support_tickets
-- ===================================================
CREATE TABLE IF NOT EXISTS public.support_tickets (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_number TEXT NOT NULL UNIQUE,
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_email   TEXT NOT NULL,
  title        TEXT NOT NULL,
  description  TEXT NOT NULL,
  status       TEXT NOT NULL DEFAULT 'new'
                 CHECK (status IN ('new', 'in_progress', 'waiting', 'resolved', 'closed')),
  priority     TEXT NOT NULL DEFAULT 'normal'
                 CHECK (priority IN ('low', 'normal', 'high', 'critical')),
  page_url     TEXT,
  sla_deadline TIMESTAMPTZ NOT NULL,
  resolution_note TEXT,
  attachments  JSONB DEFAULT '[]'::jsonb,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at  TIMESTAMPTZ
);

-- Indeks na user_id (filtrowanie RLS)
CREATE INDEX IF NOT EXISTS support_tickets_user_id_idx
  ON public.support_tickets(user_id);

-- Indeks na status (dashboardy admin)
CREATE INDEX IF NOT EXISTS support_tickets_status_idx
  ON public.support_tickets(status);

-- Auto-aktualizacja updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER support_tickets_updated_at
  BEFORE UPDATE ON public.support_tickets
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ===================================================
-- RLS POLICIES
-- ===================================================
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- Użytkownicy czytają tylko własne
CREATE POLICY "users_read_own" ON public.support_tickets
  FOR SELECT
  USING (user_id = auth.uid());

-- Użytkownicy tworzą (user_id musi być własne)
CREATE POLICY "users_create" ON public.support_tickets
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Serwis (service_role) może aktualizować statusy
CREATE POLICY "service_update" ON public.support_tickets
  FOR UPDATE
  USING (true);

-- ===================================================
-- STORAGE BUCKET: support-attachments
-- ===================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'support-attachments',
  'support-attachments',
  false,
  5242880,  -- 5 MB
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Policy: tylko właściciel może uploadować do własnego folderu
CREATE POLICY "owner_upload" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'support-attachments'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Policy: właściciel czyta własne pliki
CREATE POLICY "owner_read" ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'support-attachments'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Policy: serwis czyta wszystkie (do maili, handoffów)
CREATE POLICY "service_read_all" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'support-attachments');
```

---

## Pliki do utworzenia

### `src/lib/support/sla.ts`

```typescript
/**
 * Oblicza termin SLA w dniach roboczych (pn-pt, bez weekendów).
 * Weekendy są pomijane — termin przesuwa się na następny dzień roboczy.
 */
export function calculateSlaDeadline(
  fromDate: Date = new Date(),
  businessDays: number = parseInt(process.env.SUPPORT_SLA_BUSINESS_DAYS || "2")
): Date {
  const result = new Date(fromDate);
  let daysAdded = 0;

  while (daysAdded < businessDays) {
    result.setDate(result.getDate() + 1);
    const dayOfWeek = result.getDay();
    // 0 = niedziela, 6 = sobota
    if (dayOfWeek !== 0 && dayOfWeek !== 6) {
      daysAdded++;
    }
  }

  // Ustaw koniec dnia roboczego (17:00 czasu lokalnego serwera)
  result.setHours(17, 0, 0, 0);
  return result;
}

/**
 * Zwraca status SLA względem bieżącego czasu.
 */
export function getSlaStatus(
  slaDeadline: string | Date
): "on_time" | "at_risk" | "breached" {
  const deadline = new Date(slaDeadline);
  const now = new Date();
  const diffMs = deadline.getTime() - now.getTime();
  const diffHours = diffMs / (1000 * 60 * 60);

  if (diffMs < 0) return "breached";
  if (diffHours <= 4) return "at_risk";
  return "on_time";
}

/**
 * Generuje unikalny numer ticketu w formacie PREFIX-YYYYMMDD-XXXX.
 * Przykład: TRN-20260401-0042
 */
export function generateTicketNumber(
  prefix: string = process.env.SUPPORT_TICKET_PREFIX || "TKT",
  sequenceNumber: number = Math.floor(Math.random() * 9000) + 1000
): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  const seq = String(sequenceNumber).padStart(4, "0");
  return `${prefix}-${year}${month}${day}-${seq}`;
}

/**
 * Formatuje datę SLA do czytelnego opisu po polsku.
 */
export function formatSlaDeadline(slaDeadline: string | Date): string {
  return new Date(slaDeadline).toLocaleDateString("pl-PL", {
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}
```

---

### `src/lib/support/smtp.ts`

```typescript
import nodemailer from "nodemailer";

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT || "465"),
  secure: true,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

/**
 * Wysyła potwierdzenie przyjęcia zgłoszenia.
 */
export async function sendTicketConfirmation(
  to: string,
  ticketNumber: string,
  title: string,
  slaDeadline: string
): Promise<void> {
  const slaDate = new Date(slaDeadline).toLocaleDateString("pl-PL", {
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });

  await transporter.sendMail({
    from: process.env.SMTP_FROM,
    to,
    subject: `Zgłoszenie ${ticketNumber} zostało przyjęte`,
    html: `
      <!DOCTYPE html>
      <html lang="pl">
      <head><meta charset="UTF-8"></head>
      <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; color: #1a1a1a;">
        <h2 style="color: #2563eb; margin-bottom: 8px;">Zgłoszenie przyjęte ✓</h2>
        <p style="color: #6b7280; margin-top: 0;">Numer: <strong>${ticketNumber}</strong></p>
        <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 16px 0;">
        <p><strong>Temat:</strong> ${title}</p>
        <p>
          Twoje zgłoszenie zostało przyjęte i przekazane do zespołu wsparcia.
          Zobowiązujemy się odpowiedzieć w ciągu <strong>2 dni roboczych</strong>.
        </p>
        <div style="background: #eff6ff; border-left: 4px solid #2563eb; padding: 12px 16px; border-radius: 4px; margin: 16px 0;">
          <p style="margin: 0; font-size: 14px; color: #1d4ed8;">
            <strong>Termin odpowiedzi:</strong> ${slaDate}
          </p>
        </div>
        <p style="font-size: 14px; color: #6b7280;">
          Status zgłoszenia możesz sprawdzić w sekcji 
          <strong>Pomoc → Moje zgłoszenia</strong>.
        </p>
        <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 24px 0 16px;">
        <p style="font-size: 12px; color: #9ca3af; margin: 0;">
          Wiadomość wygenerowana automatycznie. Prosimy nie odpowiadać na ten email.
        </p>
      </body>
      </html>
    `,
  });
}

/**
 * Wysyła powiadomienie o rozwiązaniu zgłoszenia.
 */
export async function sendTicketResolved(
  to: string,
  ticketNumber: string,
  title: string,
  resolutionNote: string
): Promise<void> {
  await transporter.sendMail({
    from: process.env.SMTP_FROM,
    to,
    subject: `Zgłoszenie ${ticketNumber} zostało rozwiązane`,
    html: `
      <!DOCTYPE html>
      <html lang="pl">
      <head><meta charset="UTF-8"></head>
      <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; color: #1a1a1a;">
        <h2 style="color: #16a34a; margin-bottom: 8px;">Zgłoszenie rozwiązane ✓</h2>
        <p style="color: #6b7280; margin-top: 0;">Numer: <strong>${ticketNumber}</strong></p>
        <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 16px 0;">
        <p><strong>Temat:</strong> ${title}</p>
        <div style="background: #f0fdf4; border-left: 4px solid #16a34a; padding: 12px 16px; border-radius: 4px; margin: 16px 0;">
          <p style="margin: 0 0 8px 0; font-weight: bold; color: #15803d;">Rozwiązanie:</p>
          <p style="margin: 0; font-size: 14px; color: #1a1a1a;">${resolutionNote}</p>
        </div>
        <p style="font-size: 14px; color: #6b7280;">
          Jeśli problem nadal występuje lub masz pytania dotyczące rozwiązania, 
          utwórz nowe zgłoszenie w sekcji <strong>Pomoc → Zgłoś problem</strong>.
        </p>
        <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 24px 0 16px;">
        <p style="font-size: 12px; color: #9ca3af; margin: 0;">
          Wiadomość wygenerowana automatycznie. Prosimy nie odpowiadać na ten email.
        </p>
      </body>
      </html>
    `,
  });
}
```

---

### `src/lib/support/gateway.ts`

```typescript
import * as fs from "fs";
import * as path from "path";
import * as crypto from "crypto";

interface TicketPayload {
  ticketNumber: string;
  title: string;
  description: string;
  userEmail: string;
  userId: string;
  pageUrl?: string;
  slaDeadline: string;
  createdAt: string;
  attachments: Array<{ filename: string; storageUrl: string }>;
  sourceProject: string;
}

/**
 * Podpisuje żądanie HMAC-SHA256 (kompatybilne ze skill cross-project-gateway).
 */
function signRequest(body: string, secret: string): string {
  return crypto.createHmac("sha256", secret).update(body).digest("hex");
}

/**
 * Replikuje ticket do Project Master przez gateway API.
 * PM przechowuje kopię w tabeli support_tickets z kluczem source_project.
 */
export async function replicateTicketToPM(payload: TicketPayload): Promise<void> {
  const pmUrl = process.env.CROSS_PROJECT_PM_URL;
  const secret = process.env.CROSS_PROJECT_HMAC_SECRET;

  if (!pmUrl || !secret) {
    console.warn("[gateway] Brak CROSS_PROJECT_PM_URL lub CROSS_PROJECT_HMAC_SECRET — pomijam replikację");
    return;
  }

  const body = JSON.stringify({
    action: "support_ticket_created",
    payload,
  });

  const signature = signRequest(body, secret);

  try {
    const response = await fetch(`${pmUrl}/api/support/receive`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-HMAC-Signature": signature,
        "X-Source-Project": payload.sourceProject,
      },
      body,
    });

    if (!response.ok) {
      const text = await response.text();
      console.error(`[gateway] PM zwrócił błąd ${response.status}: ${text}`);
    }
  } catch (err) {
    console.error("[gateway] Błąd połączenia z PM:", err);
  }
}

/**
 * Tworzy plik handoff w .ai/handoffs/ w katalogu projektu.
 * Agent Claude Code odczyta go przy następnej sesji.
 */
export function createTicketHandoff(payload: TicketPayload): void {
  const handoffsDir = path.join(process.cwd(), ".ai", "handoffs");

  try {
    fs.mkdirSync(handoffsDir, { recursive: true });

    const attachmentsSection =
      payload.attachments.length > 0
        ? payload.attachments
            .map((a) => `- ${a.filename} (${a.storageUrl})`)
            .join("\n")
        : "Brak załączników";

    const content = `# Ticket ${payload.ticketNumber} — ${payload.title}

**Data:** ${new Date(payload.createdAt).toLocaleString("pl-PL")}
**Status:** Nowe
**SLA:** ${new Date(payload.slaDeadline).toLocaleString("pl-PL", {
      weekday: "long",
      day: "numeric",
      month: "long",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    })}
**Użytkownik:** ${payload.userEmail}
**Strona:** ${payload.pageUrl || "nie podano"}
**Projekt:** ${payload.sourceProject}

## Opis

${payload.description}

## Załączniki

${attachmentsSection}

## Instrukcja dla agenta

Zdiagnozuj problem opisany powyżej.
${payload.pageUrl ? `Sprawdź stronę ${payload.pageUrl} i powiązane komponenty/API routes.` : "Przeanalizuj opis i zidentyfikuj możliwą przyczynę."}
Po naprawie zmień status ticketu na "resolved" w Project Master (dashboard → Wsparcie).
Wypełnij pole "Notatka o rozwiązaniu" — zostanie wysłana do użytkownika emailem.
`;

    const filename = `ticket-${payload.ticketNumber}-${Date.now()}.md`;
    fs.writeFileSync(path.join(handoffsDir, filename), content, "utf-8");
    console.log(`[gateway] Handoff zapisany: .ai/handoffs/${filename}`);
  } catch (err) {
    console.error("[gateway] Błąd zapisu handoff:", err);
  }
}
```

---

### `src/components/support/TicketStatusBadge.tsx`

```typescript
"use client";

type TicketStatus = "new" | "in_progress" | "waiting" | "resolved" | "closed";

const STATUS_CONFIG: Record<
  TicketStatus,
  { label: string; className: string }
> = {
  new: {
    label: "Nowe",
    className: "bg-blue-100 text-blue-800 border-blue-200",
  },
  in_progress: {
    label: "W trakcie",
    className: "bg-yellow-100 text-yellow-800 border-yellow-200",
  },
  waiting: {
    label: "Oczekuje",
    className: "bg-orange-100 text-orange-800 border-orange-200",
  },
  resolved: {
    label: "Rozwiązane",
    className: "bg-green-100 text-green-800 border-green-200",
  },
  closed: {
    label: "Zamknięte",
    className: "bg-gray-100 text-gray-600 border-gray-200",
  },
};

interface TicketStatusBadgeProps {
  status: TicketStatus;
}

export function TicketStatusBadge({ status }: TicketStatusBadgeProps) {
  const config = STATUS_CONFIG[status] ?? STATUS_CONFIG.new;

  return (
    <span
      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${config.className}`}
    >
      {config.label}
    </span>
  );
}
```

---

### `src/components/support/SupportTicketForm.tsx`

```typescript
"use client";

import { useState, useRef, useCallback } from "react";
import { useRouter } from "next/navigation";

interface UploadedFile {
  file: File;
  preview: string;
}

interface SubmitResult {
  ticketNumber: string;
}

const MAX_FILES = 3;
const MAX_FILE_SIZE_MB = 5;
const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/gif", "image/webp"];

export function SupportTicketForm() {
  const router = useRouter();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [pageUrl, setPageUrl] = useState(
    typeof window !== "undefined" ? window.location.href : ""
  );
  const [files, setFiles] = useState<UploadedFile[]>([]);
  const [isDragging, setIsDragging] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successTicket, setSuccessTicket] = useState<string | null>(null);

  const addFiles = useCallback(
    (newFiles: FileList | File[]) => {
      const fileArray = Array.from(newFiles);
      const errors: string[] = [];
      const valid: UploadedFile[] = [];

      for (const file of fileArray) {
        if (!ALLOWED_TYPES.includes(file.type)) {
          errors.push(`${file.name}: niedozwolony format (tylko JPG, PNG, GIF, WebP)`);
          continue;
        }
        if (file.size > MAX_FILE_SIZE_MB * 1024 * 1024) {
          errors.push(`${file.name}: plik za duży (max ${MAX_FILE_SIZE_MB} MB)`);
          continue;
        }
        if (files.length + valid.length >= MAX_FILES) {
          errors.push(`Możesz dodać maksymalnie ${MAX_FILES} pliki`);
          break;
        }
        valid.push({ file, preview: URL.createObjectURL(file) });
      }

      if (errors.length > 0) {
        setError(errors.join("; "));
      } else {
        setError(null);
      }

      setFiles((prev) => [...prev, ...valid].slice(0, MAX_FILES));
    },
    [files.length]
  );

  const removeFile = (index: number) => {
    setFiles((prev) => {
      URL.revokeObjectURL(prev[index].preview);
      return prev.filter((_, i) => i !== index);
    });
  };

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      setIsDragging(false);
      addFiles(e.dataTransfer.files);
    },
    [addFiles]
  );

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!title.trim()) {
      setError("Podaj temat zgłoszenia.");
      return;
    }
    if (!description.trim() || description.length < 20) {
      setError("Opis musi zawierać co najmniej 20 znaków.");
      return;
    }

    setIsSubmitting(true);

    try {
      const formData = new FormData();
      formData.append("title", title.trim());
      formData.append("description", description.trim());
      formData.append("pageUrl", pageUrl);
      files.forEach((f) => formData.append("attachments", f.file));

      const response = await fetch("/api/support/tickets", {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        throw new Error(data.error || `Błąd serwera: ${response.status}`);
      }

      const result: SubmitResult = await response.json();
      setSuccessTicket(result.ticketNumber);
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : "Nie udało się wysłać zgłoszenia. Spróbuj ponownie."
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  if (successTicket) {
    return (
      <div className="rounded-lg border border-green-200 bg-green-50 p-6 text-center">
        <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
          <svg
            className="h-6 w-6 text-green-600"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M5 13l4 4L19 7"
            />
          </svg>
        </div>
        <h3 className="mb-1 text-lg font-semibold text-green-800">
          Zgłoszenie przyjęte!
        </h3>
        <p className="mb-1 font-mono text-sm font-medium text-green-700">
          {successTicket}
        </p>
        <p className="text-sm text-green-700">
          Odpowiemy w ciągu <strong>2 dni roboczych</strong>. Potwierdzenie
          zostało wysłane na Twój adres email.
        </p>
        <button
          onClick={() => router.push("/help/tickets")}
          className="mt-4 rounded-md bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700"
        >
          Zobacz moje zgłoszenia
        </button>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      {error && (
        <div className="rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* Temat */}
      <div>
        <label
          htmlFor="ticket-title"
          className="mb-1.5 block text-sm font-medium text-gray-700"
        >
          Temat zgłoszenia <span className="text-red-500">*</span>
        </label>
        <input
          id="ticket-title"
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Krótki opis problemu..."
          maxLength={200}
          className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
        />
        <p className="mt-1 text-xs text-gray-500">{title.length}/200 znaków</p>
      </div>

      {/* Opis */}
      <div>
        <label
          htmlFor="ticket-description"
          className="mb-1.5 block text-sm font-medium text-gray-700"
        >
          Szczegółowy opis <span className="text-red-500">*</span>
        </label>
        <textarea
          id="ticket-description"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Opisz problem jak najdokładniej: co robiłeś, co się stało, co oczekiwałeś..."
          rows={5}
          maxLength={5000}
          className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
        />
        <p className="mt-1 text-xs text-gray-500">
          {description.length}/5000 znaków (min. 20)
        </p>
      </div>

      {/* Strona */}
      <div>
        <label
          htmlFor="ticket-page"
          className="mb-1.5 block text-sm font-medium text-gray-700"
        >
          Adres strony z problemem
        </label>
        <input
          id="ticket-page"
          type="url"
          value={pageUrl}
          onChange={(e) => setPageUrl(e.target.value)}
          placeholder="https://..."
          className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
        />
        <p className="mt-1 text-xs text-gray-500">
          Uzupełniony automatycznie. Możesz zmienić jeśli problem dotyczy innej
          strony.
        </p>
      </div>

      {/* Załączniki */}
      <div>
        <label className="mb-1.5 block text-sm font-medium text-gray-700">
          Załączniki{" "}
          <span className="text-gray-400">(opcjonalne, max {MAX_FILES} pliki, {MAX_FILE_SIZE_MB} MB)</span>
        </label>

        {/* Drag & drop zone */}
        <div
          onDragOver={(e) => {
            e.preventDefault();
            setIsDragging(true);
          }}
          onDragLeave={() => setIsDragging(false)}
          onDrop={handleDrop}
          onClick={() => fileInputRef.current?.click()}
          className={`flex cursor-pointer flex-col items-center justify-center rounded-lg border-2 border-dashed p-6 transition-colors ${
            isDragging
              ? "border-blue-400 bg-blue-50"
              : "border-gray-300 bg-gray-50 hover:border-gray-400 hover:bg-gray-100"
          }`}
        >
          <svg
            className="mb-2 h-8 w-8 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={1.5}
              d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"
            />
          </svg>
          <p className="text-sm text-gray-600">
            <span className="font-medium text-blue-600">Kliknij</span> lub
            przeciągnij plik tutaj
          </p>
          <p className="mt-1 text-xs text-gray-400">
            JPG, PNG, GIF, WebP — maks. {MAX_FILE_SIZE_MB} MB każdy
          </p>
          <input
            ref={fileInputRef}
            type="file"
            accept={ALLOWED_TYPES.join(",")}
            multiple
            className="hidden"
            onChange={(e) => e.target.files && addFiles(e.target.files)}
          />
        </div>

        {/* Podgląd plików */}
        {files.length > 0 && (
          <ul className="mt-3 space-y-2">
            {files.map((f, i) => (
              <li
                key={i}
                className="flex items-center gap-3 rounded-md border border-gray-200 bg-white px-3 py-2"
              >
                <img
                  src={f.preview}
                  alt={f.file.name}
                  className="h-10 w-10 rounded object-cover"
                />
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium text-gray-700">
                    {f.file.name}
                  </p>
                  <p className="text-xs text-gray-400">
                    {(f.file.size / 1024 / 1024).toFixed(2)} MB
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => removeFile(i)}
                  className="ml-auto rounded p-1 text-gray-400 hover:bg-gray-100 hover:text-red-500"
                  aria-label="Usuń plik"
                >
                  <svg
                    className="h-4 w-4"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M6 18L18 6M6 6l12 12"
                    />
                  </svg>
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>

      {/* Submit */}
      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full rounded-md bg-blue-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-60"
      >
        {isSubmitting ? "Wysyłanie..." : "Wyślij zgłoszenie"}
      </button>
    </form>
  );
}
```

---

### `src/components/support/MyTickets.tsx`

```typescript
import { createClient } from "@/lib/supabase/server";
import { TicketStatusBadge } from "./TicketStatusBadge";
import { formatSlaDeadline, getSlaStatus } from "@/lib/support/sla";

interface Ticket {
  id: string;
  ticket_number: string;
  title: string;
  description: string;
  status: "new" | "in_progress" | "waiting" | "resolved" | "closed";
  priority: string;
  sla_deadline: string;
  resolution_note: string | null;
  attachments: Array<{ filename: string; storageUrl: string }>;
  created_at: string;
  resolved_at: string | null;
}

async function getMyTickets(): Promise<Ticket[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("support_tickets")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(50);

  if (error) {
    console.error("[MyTickets] Błąd pobierania:", error);
    return [];
  }

  return (data as Ticket[]) ?? [];
}

function SlaIndicator({ slaDeadline, status }: { slaDeadline: string; status: string }) {
  if (status === "resolved" || status === "closed") return null;

  const slaStatus = getSlaStatus(slaDeadline);
  const colorMap = {
    on_time: "text-green-600",
    at_risk: "text-yellow-600",
    breached: "text-red-600",
  };

  return (
    <p className={`text-xs ${colorMap[slaStatus]}`}>
      Termin: {formatSlaDeadline(slaDeadline)}
      {slaStatus === "breached" && " — PRZEKROCZONY"}
      {slaStatus === "at_risk" && " — wkrótce"}
    </p>
  );
}

function TicketCard({ ticket }: { ticket: Ticket }) {
  return (
    <details className="group rounded-lg border border-gray-200 bg-white shadow-sm">
      <summary className="flex cursor-pointer items-start gap-3 p-4 hover:bg-gray-50">
        <div className="min-w-0 flex-1">
          <div className="mb-1 flex flex-wrap items-center gap-2">
            <span className="font-mono text-xs text-gray-500">
              {ticket.ticket_number}
            </span>
            <TicketStatusBadge status={ticket.status} />
          </div>
          <p className="text-sm font-medium text-gray-900">{ticket.title}</p>
          <SlaIndicator slaDeadline={ticket.sla_deadline} status={ticket.status} />
        </div>
        <div className="flex-shrink-0 text-right">
          <p className="text-xs text-gray-400">
            {new Date(ticket.created_at).toLocaleDateString("pl-PL")}
          </p>
          <svg
            className="ml-auto mt-1 h-4 w-4 text-gray-400 transition-transform group-open:rotate-180"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M19 9l-7 7-7-7"
            />
          </svg>
        </div>
      </summary>

      <div className="border-t border-gray-100 px-4 pb-4 pt-3">
        <p className="mb-3 text-sm text-gray-700">{ticket.description}</p>

        {ticket.attachments && ticket.attachments.length > 0 && (
          <div className="mb-3">
            <p className="mb-1.5 text-xs font-medium text-gray-500">Załączniki:</p>
            <div className="flex flex-wrap gap-2">
              {ticket.attachments.map((att, i) => (
                <a
                  key={i}
                  href={att.storageUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-xs text-blue-600 hover:underline"
                >
                  {att.filename}
                </a>
              ))}
            </div>
          </div>
        )}

        {ticket.resolution_note && (
          <div className="rounded-md border border-green-200 bg-green-50 p-3">
            <p className="mb-1 text-xs font-medium text-green-800">
              Rozwiązanie:
            </p>
            <p className="text-sm text-green-700">{ticket.resolution_note}</p>
            {ticket.resolved_at && (
              <p className="mt-1 text-xs text-green-500">
                Rozwiązano:{" "}
                {new Date(ticket.resolved_at).toLocaleString("pl-PL")}
              </p>
            )}
          </div>
        )}
      </div>
    </details>
  );
}

export async function MyTickets() {
  const tickets = await getMyTickets();

  if (tickets.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-gray-200 py-12 text-center">
        <svg
          className="mb-3 h-10 w-10 text-gray-300"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={1.5}
            d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          />
        </svg>
        <p className="text-sm font-medium text-gray-500">Brak zgłoszeń</p>
        <p className="text-xs text-gray-400">
          Twoje zgłoszenia pojawią się tutaj
        </p>
      </div>
    );
  }

  const open = tickets.filter(
    (t) => t.status !== "resolved" && t.status !== "closed"
  );
  const closed = tickets.filter(
    (t) => t.status === "resolved" || t.status === "closed"
  );

  return (
    <div className="space-y-6">
      {open.length > 0 && (
        <section>
          <h3 className="mb-3 text-sm font-semibold text-gray-700">
            Aktywne ({open.length})
          </h3>
          <div className="space-y-3">
            {open.map((t) => (
              <TicketCard key={t.id} ticket={t} />
            ))}
          </div>
        </section>
      )}

      {closed.length > 0 && (
        <section>
          <h3 className="mb-3 text-sm font-semibold text-gray-500">
            Zakończone ({closed.length})
          </h3>
          <div className="space-y-3">
            {closed.map((t) => (
              <TicketCard key={t.id} ticket={t} />
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
```

---

### `src/app/api/support/tickets/route.ts`

```typescript
import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { createServiceClient } from "@/lib/supabase/service";
import { calculateSlaDeadline, generateTicketNumber } from "@/lib/support/sla";
import { sendTicketConfirmation } from "@/lib/support/smtp";
import { replicateTicketToPM, createTicketHandoff } from "@/lib/support/gateway";

// POST /api/support/tickets — utwórz zgłoszenie
export async function POST(req: NextRequest): Promise<NextResponse> {
  try {
    // Uwierzytelnienie
    const supabase = await createClient();
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json(
        { error: "Musisz być zalogowany" },
        { status: 401 }
      );
    }

    // Parsowanie FormData
    const formData = await req.formData();
    const title = (formData.get("title") as string)?.trim();
    const description = (formData.get("description") as string)?.trim();
    const pageUrl = (formData.get("pageUrl") as string)?.trim() || undefined;
    const attachmentFiles = formData.getAll("attachments") as File[];

    // Walidacja
    if (!title || title.length < 3) {
      return NextResponse.json(
        { error: "Temat jest wymagany (min. 3 znaki)" },
        { status: 400 }
      );
    }
    if (!description || description.length < 20) {
      return NextResponse.json(
        { error: "Opis jest wymagany (min. 20 znaków)" },
        { status: 400 }
      );
    }

    // Service client do operacji bez RLS
    const serviceClient = createServiceClient();

    // Generuj numer ticketu (z wykrywaniem kolizji)
    let ticketNumber: string;
    let attempts = 0;
    do {
      ticketNumber = generateTicketNumber();
      const { data: existing } = await serviceClient
        .from("support_tickets")
        .select("id")
        .eq("ticket_number", ticketNumber)
        .maybeSingle();
      if (!existing) break;
      attempts++;
    } while (attempts < 5);

    // Upload załączników do Storage
    const attachments: Array<{ filename: string; storageUrl: string }> = [];
    const allowedTypes = ["image/jpeg", "image/png", "image/gif", "image/webp"];
    const maxSizeBytes = 5 * 1024 * 1024;

    for (const file of attachmentFiles) {
      if (!file.size) continue;
      if (!allowedTypes.includes(file.type)) continue;
      if (file.size > maxSizeBytes) continue;

      const ext = file.name.split(".").pop() ?? "jpg";
      const storagePath = `${user.id}/${ticketNumber}/${Date.now()}.${ext}`;
      const buffer = await file.arrayBuffer();

      const { error: uploadError } = await serviceClient.storage
        .from("support-attachments")
        .upload(storagePath, buffer, {
          contentType: file.type,
          upsert: false,
        });

      if (!uploadError) {
        const { data: urlData } = serviceClient.storage
          .from("support-attachments")
          .getPublicUrl(storagePath);

        attachments.push({
          filename: file.name,
          storageUrl: urlData.publicUrl,
        });
      }
    }

    // Oblicz SLA
    const slaDeadline = calculateSlaDeadline();
    const createdAt = new Date().toISOString();

    // Zapisz do bazy
    const { error: insertError } = await serviceClient
      .from("support_tickets")
      .insert({
        ticket_number: ticketNumber,
        user_id: user.id,
        user_email: user.email ?? "",
        title,
        description,
        status: "new",
        priority: "normal",
        page_url: pageUrl,
        sla_deadline: slaDeadline.toISOString(),
        attachments,
        created_at: createdAt,
      });

    if (insertError) {
      console.error("[tickets/POST] Błąd zapisu:", insertError);
      return NextResponse.json(
        { error: "Błąd zapisu zgłoszenia" },
        { status: 500 }
      );
    }

    // Email potwierdzający (nie blokuj odpowiedzi)
    sendTicketConfirmation(
      user.email ?? "",
      ticketNumber,
      title,
      slaDeadline.toISOString()
    ).catch((err) =>
      console.error("[tickets/POST] Błąd email:", err)
    );

    // Replikacja do PM + handoff (nie blokuj odpowiedzi)
    const sourceProject =
      process.env.NEXT_PUBLIC_APP_NAME ??
      new URL(req.url).hostname.split(".")[0];

    replicateTicketToPM({
      ticketNumber,
      title,
      description,
      userEmail: user.email ?? "",
      userId: user.id,
      pageUrl,
      slaDeadline: slaDeadline.toISOString(),
      createdAt,
      attachments,
      sourceProject,
    }).catch((err) => console.error("[tickets/POST] Błąd replikacji PM:", err));

    createTicketHandoff({
      ticketNumber,
      title,
      description,
      userEmail: user.email ?? "",
      userId: user.id,
      pageUrl,
      slaDeadline: slaDeadline.toISOString(),
      createdAt,
      attachments,
      sourceProject,
    });

    return NextResponse.json({ ticketNumber }, { status: 201 });
  } catch (err) {
    console.error("[tickets/POST] Nieoczekiwany błąd:", err);
    return NextResponse.json(
      { error: "Wewnętrzny błąd serwera" },
      { status: 500 }
    );
  }
}

// GET /api/support/tickets — lista zgłoszeń (RLS filtruje do własnych)
export async function GET(): Promise<NextResponse> {
  try {
    const supabase = await createClient();
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json(
        { error: "Musisz być zalogowany" },
        { status: 401 }
      );
    }

    const { data, error } = await supabase
      .from("support_tickets")
      .select("*")
      .order("created_at", { ascending: false })
      .limit(50);

    if (error) {
      return NextResponse.json(
        { error: "Błąd pobierania zgłoszeń" },
        { status: 500 }
      );
    }

    return NextResponse.json({ tickets: data ?? [] });
  } catch (err) {
    console.error("[tickets/GET] Nieoczekiwany błąd:", err);
    return NextResponse.json(
      { error: "Wewnętrzny błąd serwera" },
      { status: 500 }
    );
  }
}
```

---

### `src/app/api/support/tickets/status/route.ts`

```typescript
import { NextRequest, NextResponse } from "next/server";
import * as crypto from "crypto";
import { createServiceClient } from "@/lib/supabase/service";
import { sendTicketResolved } from "@/lib/support/smtp";

/**
 * Weryfikuje podpis HMAC-SHA256 z nagłówka X-HMAC-Signature.
 */
function verifyHmac(body: string, signature: string, secret: string): boolean {
  const expected = crypto
    .createHmac("sha256", secret)
    .update(body)
    .digest("hex");
  try {
    return crypto.timingSafeEqual(
      Buffer.from(signature, "hex"),
      Buffer.from(expected, "hex")
    );
  } catch {
    return false;
  }
}

interface StatusUpdatePayload {
  ticketNumber: string;
  status: "new" | "in_progress" | "waiting" | "resolved" | "closed";
  resolutionNote?: string;
}

/**
 * POST /api/support/tickets/status
 * Webhook wywoływany przez Project Master po zmianie statusu ticketu.
 * Aktualizuje lokalną tabelę i wysyła email do użytkownika.
 */
export async function POST(req: NextRequest): Promise<NextResponse> {
  const secret = process.env.CROSS_PROJECT_HMAC_SECRET;
  if (!secret) {
    return NextResponse.json(
      { error: "Konfiguracja HMAC brak" },
      { status: 500 }
    );
  }

  // Odczyt ciała jako tekst (do weryfikacji HMAC)
  const rawBody = await req.text();
  const signature = req.headers.get("X-HMAC-Signature") ?? "";

  if (!verifyHmac(rawBody, signature, secret)) {
    return NextResponse.json(
      { error: "Nieprawidłowy podpis HMAC" },
      { status: 401 }
    );
  }

  let payload: StatusUpdatePayload;
  try {
    payload = JSON.parse(rawBody);
  } catch {
    return NextResponse.json(
      { error: "Nieprawidłowy JSON" },
      { status: 400 }
    );
  }

  const { ticketNumber, status, resolutionNote } = payload;

  if (!ticketNumber || !status) {
    return NextResponse.json(
      { error: "Brak wymaganych pól: ticketNumber, status" },
      { status: 400 }
    );
  }

  const serviceClient = createServiceClient();

  // Pobierz ticket (do emaila)
  const { data: ticket, error: fetchError } = await serviceClient
    .from("support_tickets")
    .select("user_email, title, status")
    .eq("ticket_number", ticketNumber)
    .maybeSingle();

  if (fetchError || !ticket) {
    return NextResponse.json(
      { error: "Ticket nie znaleziony" },
      { status: 404 }
    );
  }

  // Aktualizuj status
  const updateData: Record<string, unknown> = { status };
  if (resolutionNote) updateData.resolution_note = resolutionNote;
  if (status === "resolved") updateData.resolved_at = new Date().toISOString();

  const { error: updateError } = await serviceClient
    .from("support_tickets")
    .update(updateData)
    .eq("ticket_number", ticketNumber);

  if (updateError) {
    console.error("[status/POST] Błąd aktualizacji:", updateError);
    return NextResponse.json(
      { error: "Błąd aktualizacji statusu" },
      { status: 500 }
    );
  }

  // Wyślij email jeśli rozwiązano
  if (status === "resolved" && resolutionNote) {
    sendTicketResolved(
      ticket.user_email,
      ticketNumber,
      ticket.title,
      resolutionNote
    ).catch((err) =>
      console.error("[status/POST] Błąd email resolved:", err)
    );
  }

  return NextResponse.json({ ok: true, ticketNumber, status });
}
```

---

## Integracja z sekcją Pomocy

Dodaj linki do istniejącej strony pomocy (np. `src/app/(app)/help/page.tsx`):

```typescript
// Dodaj karty w sekcji pomocy:
import Link from "next/link";

// Karta 1 — Zgłoś problem
<Link href="/help/new-ticket">
  <div className="rounded-lg border border-gray-200 p-5 hover:border-blue-300 hover:shadow-sm transition-all cursor-pointer">
    <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-lg bg-red-100">
      {/* ikona np. ExclamationTriangleIcon z heroicons */}
    </div>
    <h3 className="font-semibold text-gray-900">Zgłoś problem</h3>
    <p className="mt-1 text-sm text-gray-500">
      Napotkałeś błąd lub masz pytanie? Opisz problem — odpiszemy w ciągu 2 dni roboczych.
    </p>
  </div>
</Link>

// Karta 2 — Moje zgłoszenia
<Link href="/help/tickets">
  <div className="rounded-lg border border-gray-200 p-5 hover:border-blue-300 hover:shadow-sm transition-all cursor-pointer">
    <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-lg bg-blue-100">
      {/* ikona np. ClipboardDocumentListIcon z heroicons */}
    </div>
    <h3 className="font-semibold text-gray-900">Moje zgłoszenia</h3>
    <p className="mt-1 text-sm text-gray-500">
      Sprawdź status swoich zgłoszeń i odpowiedzi zespołu wsparcia.
    </p>
  </div>
</Link>
```

### Strony do utworzenia

**`src/app/(app)/help/new-ticket/page.tsx`:**
```typescript
import { SupportTicketForm } from "@/components/support/SupportTicketForm";

export default function NewTicketPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-8">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Zgłoś problem</h1>
        <p className="mt-1 text-sm text-gray-500">
          Odpowiemy w ciągu 2 dni roboczych. Potwierdzenie otrzymasz emailem.
        </p>
      </div>
      <SupportTicketForm />
    </div>
  );
}
```

**`src/app/(app)/help/tickets/page.tsx`:**
```typescript
import { Suspense } from "react";
import { MyTickets } from "@/components/support/MyTickets";
import Link from "next/link";

export default function MyTicketsPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-8">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Moje zgłoszenia</h1>
          <p className="mt-1 text-sm text-gray-500">
            Historia Twoich zgłoszeń serwisowych
          </p>
        </div>
        <Link
          href="/help/new-ticket"
          className="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
        >
          Nowe zgłoszenie
        </Link>
      </div>
      <Suspense fallback={<p className="text-sm text-gray-400">Ładowanie...</p>}>
        <MyTickets />
      </Suspense>
    </div>
  );
}
```

---

## Handoff automatyczny — szablon

Plik tworzony przez `gateway.ts` w `.ai/handoffs/ticket-{NUMBER}-{timestamp}.md`:

```markdown
# Ticket TRN-20260401-0042 — Nie mogę wyeksportować raportu

**Data:** 1 kwiecień 2026, 14:23
**Status:** Nowe
**SLA:** wtorek, 3 kwiecień 2026 o 17:00
**Użytkownik:** jan.kowalski@firma.pl
**Strona:** https://app.example.com/reports/export
**Projekt:** trener-sprzedazy

## Opis

Klikam przycisk "Eksportuj do PDF" na stronie raportów, ale nic się nie dzieje.
Próbowałem w Chrome i Firefox — ten sam efekt. Konsola nie pokazuje błędów.

## Załączniki

- screenshot-export-button.png (https://supabase.co/storage/v1/...)

## Instrukcja dla agenta

Zdiagnozuj problem opisany powyżej.
Sprawdź stronę https://app.example.com/reports/export i powiązane komponenty/API routes.
Po naprawie zmień status ticketu na "resolved" w Project Master (dashboard → Wsparcie).
Wypełnij pole "Notatka o rozwiązaniu" — zostanie wysłana do użytkownika emailem.
```

---

## Checklist instalacji

1. **Zainstaluj zależności:**
   ```bash
   npm install nodemailer @types/nodemailer
   ```

2. **Ustaw zmienne środowiskowe** w `.env.local` i na Vercel (patrz sekcja Konfiguracja)

3. **Uruchom migrację SQL** w Supabase SQL Editor (sekcja Migracja SQL)

4. **Utwórz Storage bucket** `support-attachments` — jeśli SQL nie wykonał się dla Storage, zrób ręcznie w panelu Supabase → Storage

5. **Skopiuj pliki lib/support/**:
   - `src/lib/support/sla.ts`
   - `src/lib/support/smtp.ts`
   - `src/lib/support/gateway.ts`

6. **Skopiuj komponenty**:
   - `src/components/support/TicketStatusBadge.tsx`
   - `src/components/support/SupportTicketForm.tsx`
   - `src/components/support/MyTickets.tsx`

7. **Skopiuj API routes**:
   - `src/app/api/support/tickets/route.ts` (POST + GET)
   - `src/app/api/support/tickets/status/route.ts` (webhook z PM)

8. **Utwórz strony**:
   - `src/app/(app)/help/new-ticket/page.tsx`
   - `src/app/(app)/help/tickets/page.tsx`

9. **Dodaj linki w sekcji Pomocy** — karty "Zgłoś problem" i "Moje zgłoszenia"

10. **Test end-to-end**:
    - Zaloguj się jako użytkownik testowy
    - Wypełnij formularz i załącz obrazek
    - Sprawdź: rekord w tabeli `support_tickets`, plik w Storage, email na skrzynce
    - Sprawdź handoff w `.ai/handoffs/`
    - Sprawdź replikację w Project Master (dashboard → Wsparcie)
    - Wywołaj webhook statusu: `curl -X POST /api/support/tickets/status` z poprawnym HMAC i `status: "resolved"` — sprawdź email z rozwiązaniem

---

## Uwagi implementacyjne

### `createServiceClient`
Skill zakłada, że w projekcie istnieje `src/lib/supabase/service.ts` eksportujący `createServiceClient()` używający `SUPABASE_SERVICE_ROLE_KEY`. Jeśli nie istnieje, utwórz:

```typescript
// src/lib/supabase/service.ts
import { createClient } from "@supabase/supabase-js";

export function createServiceClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );
}
```

### Endpoint PM `/api/support/receive`
Jeśli Project Master nie ma tego endpointu, replikacja jest pomijana (tylko log). Skontaktuj się z administratorem PM w celu aktywacji.

### Publiczne URL w Storage
Bucket `support-attachments` jest prywatny — `getPublicUrl` zwraca URL wymagający odpowiednich cookies/tokena. Jeśli chcesz publiczne URLe (bez uwierzytelnienia), zmień `public: false` na `public: true` w SQL migracji (niezalecane dla danych użytkowników).
