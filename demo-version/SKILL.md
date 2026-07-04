---
name: demo-version
description: Tworzenie wersji demo/prezentacyjnej aplikacji — ten sam Supabase, anonimizowane dane, jeden użytkownik demo, seed script, scenariusze prezentacyjne, oznaczenie "DEMO". Aliasy głosowe: "wersja demo", "wersja prezentacyjna", "przygotuj demo". Używaj gdy trzeba przygotować wersję demonstracyjną aplikacji do pokazania klientom, na filmach lub prezentacjach.
triggers:
  - "wersja demo"
  - "wersja prezentacyjna"
  - "przygotuj demo"
  - "zrób demo"
  - "demo dla klienta"
  - "prezentacja aplikacji"
  - "mockowe dane"
  - "dane demonstracyjne"
  - "anonimizacja danych"
---

# Wersja demo — Przewodnik tworzenia

Skill do tworzenia wersji demo/prezentacyjnej istniejących aplikacji. Ten sam projekt Supabase, anonimizowane dane, jeden użytkownik demo, gotowe scenariusze prezentacyjne.

## Spis treści

1. [Architektura demo](#1-architektura)
2. [Użytkownik demo](#2-użytkownik-demo)
3. [Izolacja danych](#3-izolacja-danych)
4. [Audyt danych wrażliwych](#4-audyt-danych-wrażliwych)
5. [Generator danych demo](#5-generator-danych-demo)
6. [Seed script](#6-seed-script)
7. [Oznaczenie wersji demo w UI](#7-oznaczenie-demo-w-ui)
8. [Ochrona produkcji](#8-ochrona-produkcji)
9. [Scenariusze prezentacyjne](#9-scenariusze-prezentacyjne)
10. [Konfiguracja środowiska](#10-konfiguracja-środowiska)
11. [Checklist](#11-checklist)

---

## 1. Architektura

### Zasada: ten sam Supabase, izolacja po organization_id

```
┌─────────────────────────────────────────────────┐
│                  Supabase (ten sam projekt)       │
│                                                   │
│  ┌──────────────────┐  ┌──────────────────────┐ │
│  │ Dane produkcyjne  │  │ Dane demo            │ │
│  │ org: klient-abc   │  │ org: demo-org-xxx    │ │
│  │ org: klient-def   │  │                      │ │
│  │ ...               │  │ 1 użytkownik demo    │ │
│  │                    │  │ mockowane dane       │ │
│  └──────────────────┘  └──────────────────────┘ │
└─────────────────────────────────────────────────┘
         ↑                          ↑
    Produkcja                  Wersja demo
    (pełna aplikacja)          (ta sama aplikacja,
                                .env.demo)
```

### Dlaczego ten sam Supabase?
- Zero duplikacji infrastruktury i kosztów
- Struktury DB już przetestowane na produkcji
- RLS automatycznie izoluje dane demo od produkcji (po `organization_id`)
- Migracje działają raz — obie wersje mają ten sam schemat

---

## 2. Użytkownik demo

### Jeden standardowy użytkownik dla WSZYSTKICH wersji demo

```typescript
// Stałe użytkownika demo — te same we wszystkich projektach
const DEMO_USER = {
  email: "demo@aiwbiznesie.dev",    // Lub prawdziwy email właściciela
  password: "demo-password-2026",     // Zmień na bezpieczne hasło
  name: "Dariusz Ciesielski",         // Imię i nazwisko właściciela
  role: "owner",                       // Pełny dostęp w demo
};
```

### Konwencja: prefix `demo-` w identyfikatorach

| Element | Konwencja | Przykład |
|---------|-----------|---------|
| Organizacja demo | `demo-{slug-projektu}` | `demo-smm`, `demo-hotel-demo` |
| Nazwa organizacji | `[DEMO] {Nazwa projektu}` | `[DEMO] Social Media Manager` |
| API key demo | `demo_{slug}_` prefix | `demo_smm_a1b2c3d4...` |

### Dlaczego jeden użytkownik?
- Upraszcza zarządzanie — jeden login do wszystkich demo
- Nie trzeba pamiętać różnych haseł per projekt
- Ten sam użytkownik w Supabase Auth, różne organizacje per projekt
- Na prezentacji nie musisz szukać loginu — zawsze ten sam

---

## 3. Izolacja danych

### RLS robi robotę

Jeśli projekt używa `organization_id` w tabelach (a powinien — patrz skill `supabase-auth-rls`), izolacja jest automatyczna:

```sql
-- Użytkownik demo widzi TYLKO dane z organizacji demo
-- Użytkownicy produkcyjni NIGDY nie widzą danych demo
-- To samo RLS policy co już masz — nie trzeba nic zmieniać
```

### Organizacja demo — tworzenie

```typescript
// scripts/create-demo-org.ts
import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  { auth: { persistSession: false } }
);

async function createDemoOrganization(projectSlug: string, projectName: string) {
  // 1. Znajdź lub utwórz użytkownika demo
  const { data: existingUser } = await supabase
    .from("profiles")
    .select("id")
    .eq("email", "demo@aiwbiznesie.dev")
    .single();

  let userId = existingUser?.id;

  if (!userId) {
    // Utwórz użytkownika w Supabase Auth
    const { data: authUser } = await supabase.auth.admin.createUser({
      email: "demo@aiwbiznesie.dev",
      password: "demo-password-2026",
      email_confirm: true,
      user_metadata: { full_name: "Dariusz Ciesielski" },
    });
    userId = authUser?.user?.id;
  }

  // 2. Utwórz organizację demo
  const { data: org } = await supabase
    .from("organizations")
    .insert({
      name: `[DEMO] ${projectName}`,
      slug: `demo-${projectSlug}`,
      is_demo: true,  // Flaga demo — dodaj kolumnę jeśli nie istnieje
    })
    .select("id")
    .single();

  // 3. Przypisz użytkownika jako owner
  await supabase.from("organization_members").insert({
    organization_id: org!.id,
    user_id: userId,
    role: "owner",
  });

  return { organizationId: org!.id, userId };
}
```

### Kolumna `is_demo` w tabeli organizations

```sql
-- Dodaj raz do migracji (jeśli nie istnieje)
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS is_demo BOOLEAN DEFAULT false;
```

Dzięki niej możesz:
- Filtrować dane demo w dashboardach analitycznych
- Pomijać organizacje demo w statystykach
- Szybko wyczyścić dane demo: `DELETE FROM ... WHERE organization_id IN (SELECT id FROM organizations WHERE is_demo = true)`

---

## 4. Audyt danych wrażliwych

### Przed seedowaniem — przeskanuj projekt

Szukaj tych wzorców w kodzie i bazie:

| Typ danych | Gdzie szukać | Co zamockować |
|------------|-------------|---------------|
| **Emaile** | Tabele: profiles, users, invitations | faker: `jan.kowalski@przyklad.pl` |
| **Imiona/nazwiska** | Tabele: profiles, contacts, customers | faker: polskie imiona |
| **Nazwy firm** | Tabele: organizations, customers | faker: `Przykładowa Firma Sp. z o.o.` |
| **Adresy** | Tabele: addresses, locations | faker: polskie adresy |
| **Telefony** | Tabele: profiles, contacts | faker: `+48 600 XXX XXX` |
| **Tokeny API** | Tabele: api_keys, integrations | placeholder: `demo_token_xxx` |
| **URL-e produkcyjne** | Tabele: channels, webhooks | placeholder: `https://demo.przyklad.pl` |
| **Dane finansowe** | Tabele: invoices, payments | faker: realistyczne kwoty PLN |
| **Treści prywatne** | Tabele: messages, posts, notes | faker: lorem ipsum po polsku |

### Automatyczny skan

```bash
# Szukaj prawdziwych emaili w seedach i migracjach
grep -r "@gmail\|@wp\|@onet\|@interia\|@aiwbiznesie" scripts/ src/ supabase/

# Szukaj hardcoded nazw firm
grep -r "Sp\. z o\.o\.\|S\.A\.\|Sp\.j\." scripts/ src/

# Szukaj tokenów
grep -r "sk_\|pk_\|Bearer \|api_key\|secret" scripts/ src/ --include="*.ts"
```

---

## 5. Generator danych demo

### Polskie dane faker — utility

```typescript
// scripts/demo/fake-data.ts

/** Polskie imiona i nazwiska do danych demo */
const FIRST_NAMES = [
  "Anna", "Katarzyna", "Maria", "Magdalena", "Agnieszka",
  "Piotr", "Krzysztof", "Tomasz", "Andrzej", "Marcin",
  "Ewa", "Joanna", "Dorota", "Monika", "Aleksandra",
  "Paweł", "Michał", "Łukasz", "Adam", "Grzegorz",
];

const LAST_NAMES = [
  "Nowak", "Kowalski", "Wiśniewski", "Wójcik", "Kowalczyk",
  "Kamiński", "Lewandowski", "Zieliński", "Szymański", "Woźniak",
  "Dąbrowski", "Kozłowski", "Jankowski", "Mazur", "Krawczyk",
  "Piotrowska", "Grabowska", "Pawlak", "Michalska", "Zając",
];

const COMPANY_NAMES = [
  "Innowacje Cyfrowe", "TechPol Solutions", "Marketing Pro",
  "Studio Kreatywne Pixel", "Agencja Wzrost", "DataDrive",
  "Firma Przykładowa", "WebExperts", "ContentFlow",
  "Strategia Online", "BrandMaster", "SocialBuzz",
];

const DOMAINS = [
  "przyklad.pl", "testowa-firma.pl", "demo-company.pl",
  "firma-demo.pl", "test.przyklad.pl",
];

export function fakeName(): { firstName: string; lastName: string; fullName: string } {
  const firstName = FIRST_NAMES[Math.floor(Math.random() * FIRST_NAMES.length)];
  const lastName = LAST_NAMES[Math.floor(Math.random() * LAST_NAMES.length)];
  return { firstName, lastName, fullName: `${firstName} ${lastName}` };
}

export function fakeEmail(firstName?: string, lastName?: string): string {
  const name = firstName || fakeName().firstName;
  const surname = lastName || fakeName().lastName;
  const domain = DOMAINS[Math.floor(Math.random() * DOMAINS.length)];
  return `${name.toLowerCase()}.${surname.toLowerCase()}@${domain}`;
}

export function fakeCompany(): string {
  return COMPANY_NAMES[Math.floor(Math.random() * COMPANY_NAMES.length)];
}

export function fakePhone(): string {
  const prefix = ["600", "601", "602", "660", "661", "690", "691", "500", "501", "510"];
  const p = prefix[Math.floor(Math.random() * prefix.length)];
  const rest = String(Math.floor(Math.random() * 1000000)).padStart(6, "0");
  return `+48 ${p} ${rest.slice(0, 3)} ${rest.slice(3)}`;
}

export function fakeAmount(min = 100, max = 50000): number {
  return Math.round((Math.random() * (max - min) + min) * 100) / 100;
}

export function fakeDate(daysBack = 90): string {
  const date = new Date();
  date.setDate(date.getDate() - Math.floor(Math.random() * daysBack));
  return date.toISOString();
}
```

---

## 6. Seed script

### Struktura

```
scripts/
├── demo/
│   ├── fake-data.ts        # Generator polskich danych (powyżej)
│   ├── seed-demo.ts        # Główny seed script
│   ├── cleanup-demo.ts     # Czyszczenie danych demo
│   └── scenarios/          # Dane per scenariusz prezentacyjny
│       ├── basic.ts        # Podstawowe dane (użytkownicy, org)
│       └── rich.ts         # Bogate dane (posty, kampanie, analytics)
```

### Główny seed script

```typescript
// scripts/demo/seed-demo.ts
import { createClient } from "@supabase/supabase-js";
import { fakeName, fakeEmail, fakeCompany, fakeAmount, fakeDate } from "./fake-data";

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  { auth: { persistSession: false } }
);

const DEMO_ORG_SLUG = `demo-${process.env.PROJECT_SLUG || "app"}`;

async function seedDemo() {
  console.log("🎬 Seedowanie danych demo...");

  // 1. Znajdź organizację demo
  const { data: org } = await supabase
    .from("organizations")
    .select("id")
    .eq("slug", DEMO_ORG_SLUG)
    .single();

  if (!org) {
    console.error(`Organizacja ${DEMO_ORG_SLUG} nie istnieje. Uruchom najpierw create-demo-org.ts`);
    process.exit(1);
  }

  const orgId = org.id;

  // 2. Seeduj dane specyficzne dla projektu
  // TU DOSTOSUJ DO SWOJEGO PROJEKTU — poniżej przykład dla SMM

  // Przykład: kanały social media
  const channels = Array.from({ length: 5 }, () => ({
    organization_id: orgId,
    name: `${fakeCompany()} — Facebook`,
    platform: ["facebook", "linkedin", "instagram", "twitter"][Math.floor(Math.random() * 4)],
    token_status: "active",
    followers_count: Math.floor(Math.random() * 10000),
    created_at: fakeDate(180),
  }));

  await supabase.from("channels").insert(channels);
  console.log(`  ✓ ${channels.length} kanałów`);

  // Przykład: posty
  const posts = Array.from({ length: 50 }, (_, i) => ({
    organization_id: orgId,
    title: `Przykładowy post #${i + 1}`,
    content: `Treść demonstracyjna posta. ${fakeCompany()} przedstawia nową ofertę.`,
    status: ["draft", "scheduled", "published", "published", "published"][Math.floor(Math.random() * 5)],
    scheduled_at: fakeDate(30),
    created_at: fakeDate(60),
  }));

  await supabase.from("posts").insert(posts);
  console.log(`  ✓ ${posts.length} postów`);

  console.log("✅ Seedowanie demo zakończone!");
}

seedDemo().catch(console.error);
```

### package.json scripts

```json
{
  "scripts": {
    "demo:create-org": "npx tsx scripts/demo/create-demo-org.ts",
    "demo:seed": "npx tsx scripts/demo/seed-demo.ts",
    "demo:cleanup": "npx tsx scripts/demo/cleanup-demo.ts",
    "demo:reset": "npm run demo:cleanup && npm run demo:seed"
  }
}
```

---

## 7. Oznaczenie wersji demo w UI

### Zasada: ten sam deploy, dynamiczny banner

Banner pojawia się na podstawie **danych z bazy** (flaga `is_demo` na organizacji), nie z env var. Dzięki temu:
- Jeden deploy na Vercel obsługuje i produkcję, i demo
- Zaloguj się jako użytkownik demo → widzisz banner
- Zaloguj się jako prawdziwy użytkownik → brak bannera

### Banner demo — komponent

```typescript
// src/components/demo-banner.tsx
"use client";

import { useOrganization } from "@/hooks/use-organization"; // Twój hook do aktualnej organizacji

export function DemoBanner() {
  const { organization } = useOrganization();

  if (!organization?.is_demo) return null;

  return (
    <div className="fixed top-0 left-0 right-0 z-[100] bg-amber-500 text-amber-950 text-center text-sm font-medium py-1 px-4">
      Wersja demo — dane prezentacyjne
    </div>
  );
}
```

### Dodaj do layoutu (wewnątrz auth providera)

```typescript
// src/app/(hub)/layout.tsx — layout chronionych stron
import { DemoBanner } from "@/components/demo-banner";

export default function HubLayout({ children }) {
  return (
    <>
      <DemoBanner />
      {children}
    </>
  );
}
```

### Helper: isDemoOrg

```typescript
// src/lib/demo-guard.ts

/** Sprawdza czy bieżąca organizacja jest demo (po danych z DB) */
export function isDemoOrg(organization: { is_demo?: boolean } | null): boolean {
  return organization?.is_demo === true;
}
```

---

## 8. Ochrona produkcji

### Zasada: guardy bazują na fladze `is_demo` z organizacji

Ten sam deploy obsługuje i produkcję, i demo. Guardy sprawdzają **organizację** bieżącego użytkownika — nie env var.

### Blokada wysyłki prawdziwych emaili/SMS w demo

```typescript
// src/lib/email.ts
import { isDemoOrg } from "@/lib/demo-guard";

export async function sendEmail(
  to: string, subject: string, body: string,
  org: { is_demo?: boolean }
) {
  if (isDemoOrg(org)) {
    console.log(`[DEMO] Email zablokowany: ${to} — ${subject}`);
    return { success: true, demo: true };
  }
  // ... prawdziwa wysyłka
}
```

### Blokada integracji zewnętrznych

```typescript
// src/lib/integrations/facebook.ts
import { isDemoOrg } from "@/lib/demo-guard";

export async function publishToFacebook(
  post: Post,
  org: { is_demo?: boolean }
) {
  if (isDemoOrg(org)) {
    console.log(`[DEMO] Publikacja FB zablokowana: ${post.title}`);
    return { id: "demo-post-id", status: "simulated" };
  }
  // ... prawdziwa publikacja
}
```

### Wzorzec: przekazuj `org` do funkcji z efektami ubocznymi

Każda funkcja, która wysyła emaile, publikuje posty, wywołuje płatności — powinna przyjmować obiekt organizacji i sprawdzać `isDemoOrg()` na początku. Dane demo nigdy nie trafiają do zewnętrznych serwisów.

---

## 9. Scenariusze prezentacyjne

### Dokumentuj gotowe ścieżki demo

Utwórz plik `docs/DEMO_SCENARIOS.md` w projekcie:

```markdown
# Scenariusze demo — {Nazwa Projektu}

## Logowanie
- Email: demo@aiwbiznesie.dev
- Hasło: [w credentials.env]

## Scenariusz 1: Przegląd dashboardu (2 min)
1. Zaloguj się → Dashboard z podsumowaniem
2. Pokaż: statystyki, wykresy, ostatnie aktywności
3. Kluczowe punkty: "widzimy X postów, Y kanałów, Z interakcji"

## Scenariusz 2: Tworzenie kampanii (3 min)
1. Kliknij "Nowa kampania" → formularz
2. Wypełnij: nazwa "Kampania demonstracyjna", cel "Zasięg"
3. Wybierz kanały → pokaż multi-select
4. Zapisz → pokaż na liście kampanii
5. Kluczowe punkty: "prosta konfiguracja, wybieram kanały, gotowe"

## Scenariusz 3: Raport analityczny (2 min)
1. Przejdź do Analityka → Raporty
2. Wybierz okres: ostatnie 30 dni
3. Pokaż: wykres zaangażowania, tabela top postów
4. Eksportuj do PDF / Excel
```

---

## 10. Konfiguracja środowiska

### Zasada: jeden deploy, zero osobnych konfiguracji

Nie ma `.env.demo` ani osobnego deployu. Wersja demo to **ten sam deploy co produkcja** — różnica jest tylko w tym, na jakie konto się logujesz.

### Jak używać wersji demo

```
1. Otwórz aplikację (ten sam URL co produkcja)
2. Zaloguj się jako: demo@aiwbiznesie.dev
3. Wybierz organizację demo (np. "[DEMO] Social Media Manager")
4. Banner "Wersja demo" pojawia się automatycznie
5. Guardy blokują emaile i integracje zewnętrzne
```

### Dane logowania demo — credentials-vault

Zapisz dane użytkownika demo w `credentials.env` projektu (patrz skill `credentials-vault`):

```bash
# credentials.env
DEMO_USER_EMAIL=demo@aiwbiznesie.dev
DEMO_USER_PASSWORD=demo-password-2026
```

### Resetowanie danych przed prezentacją

```bash
# Wyczyść i zaseeduj od nowa — zajmuje ~10 sekund
npm run demo:reset
```

---

## 11. Checklist

### Przygotowanie wersji demo od zera

- [ ] Dodaj kolumnę `is_demo` do tabeli `organizations` (migracja)
- [ ] Stwórz użytkownika demo w Supabase Auth (jednorazowo, globalnie)
- [ ] Stwórz skrypt `scripts/demo/create-demo-org.ts`
- [ ] Stwórz skrypt `scripts/demo/seed-demo.ts` z danymi specyficznymi dla projektu
- [ ] Stwórz skrypt `scripts/demo/cleanup-demo.ts`
- [ ] Skopiuj `scripts/demo/fake-data.ts` (polskie dane)
- [ ] Dodaj `DemoBanner` komponent do layoutu
- [ ] Dodaj `isDemoMode()` guard do zewnętrznych integracji (email, SMS, API)
- [ ] Dodaj scripts do `package.json` (`demo:seed`, `demo:cleanup`, `demo:reset`)
- [ ] Uruchom `demo:create-org` → `demo:seed`
- [ ] Przetestuj logowanie na `demo@aiwbiznesie.dev` i scenariusze
- [ ] Napisz `docs/DEMO_SCENARIOS.md` z gotowymi ścieżkami prezentacyjnymi

### Resetowanie danych demo (przed prezentacją)

```bash
npm run demo:reset
# Czyści dane demo → seeduje od nowa → gotowe na prezentację
```

---

## Antywzorce — czego NIE robić

| Antywzorzec | Dlaczego | Co zamiast |
|-------------|----------|------------|
| Osobny projekt Supabase na demo | Duplikacja kosztów, migracji, testów | Ten sam projekt + `is_demo` flag |
| Osobny deploy Vercel na demo | Dodatkowe koszty, duplikacja konfiguracji | Ten sam deploy — demo = inna organizacja |
| `NEXT_PUBLIC_DEMO_MODE` env var | Wymaga osobnej konfiguracji env | Dynamiczny banner z `organization.is_demo` |
| Prawdziwe emaile/imiona w danych demo | Wyciek danych osobowych | Generator z `fake-data.ts` |
| Brak `isDemoMode()` w integracji z FB/Stripe | Przypadkowy post na prawdziwym koncie | Guard na początku każdej integracji |
| Hardcoded dane demo w kodzie | Trudne do aktualizacji | Seed script + `demo:reset` |
| Demo bez scenariuszy | Chaotyczna prezentacja | `docs/DEMO_SCENARIOS.md` |
| Commitowanie `.env.demo` do git | Wyciek sekretów | `.gitignore` + `credentials-vault` |

---

## Pułapki

Typowe błędy popełniane przez AI (i ludzi) przy budowaniu wersji demo. Sprawdź każdy punkt przed oznaczeniem zadania jako ukończone.

### 1. Hardcoded credentials demo usera w kodzie źródłowym

Hasło i email demo usera trafiają bezpośrednio do komponentów lub seed scriptów zamiast do `credentials.env`.

❌ `const password = "demo-password-2026"` w `seed-demo.ts`
✅ `const password = process.env.DEMO_USER_PASSWORD!` + wartość w `credentials.env`

Dotyczy też komentarzy w kodzie i `DEMO_SCENARIOS.md` — nie wpisuj tam haseł, odwołuj się do credentials-vault.

### 2. Seed script, który nie jest idempotentny

Uruchomiony dwukrotnie tworzy duplikaty danych (podwójne kanały, posty, kontakty). Prezentacja z 100 duplikatami wygląda nieprofesjonalnie.

❌ `INSERT INTO channels (...)` bez sprawdzenia czy dane demo już istnieją
✅ Na początku seed scriptu: `DELETE FROM ... WHERE organization_id = demoOrgId` (cleanup-first), albo `UPSERT` z unikalnym kluczem. Najlepiej: osobny `cleanup-demo.ts` wywoływany przez `demo:reset`.

### 3. Anonimizacja, która zostawia PII w edge case'ach

Faker generuje nowe imiona/emaile do głównych tabel, ale prawdziwe dane wyciekają przez:
- **Logi audytu** (`audit_log`, `activity_feed`) — zawierają `"Jan Kowalski zmienił status"`
- **Komentarze/notatki** — treść wpisana przez prawdziwych użytkowników, skopiowana do demo
- **Metadane plików** — nazwy uploadowanych plików zawierają imiona klientów
- **Tabele junction** — `organization_members` z prawdziwymi `user_id`

Przed seedowaniem przeskanuj WSZYSTKIE tabele z `organization_id`, nie tylko główne encje.

### 4. Brak bannera "DEMO" lub banner widoczny tylko na dashboardzie

Banner demo pojawia się na stronie głównej, ale znika w pod-stronach (bo `DemoBanner` dodany do jednego layoutu, a nie do głównego `HubLayout`).

❌ `DemoBanner` w `page.tsx` dashboardu
✅ `DemoBanner` w `(hub)/layout.tsx` — widoczny na KAŻDEJ stronie za auth-wallem

Dodatkowa pułapka: banner bez `z-[100]` chowa się pod sidebar lub modalami.

### 5. Guard `isDemoOrg()` dodany do UI, ale nie do server actions / API routes

Przycisk "Wyślij email" jest ukryty w UI demo, ale endpoint `POST /api/send-email` nadal działa. Ktoś (lub test) może wywołać API bezpośrednio.

❌ `{!isDemoOrg(org) && <Button>Wyślij</Button>}` — guard tylko w komponencie
✅ Guard w **server action / API route** — `if (isDemoOrg(org)) return { success: true, demo: true }` — zabezpieczenie na poziomie backendu, niezależnie od UI.

### 6. Seed generuje dane z przyszłymi datami lub nierealistycznymi zakresami

Faker generuje daty z `fakeDate(365)`, co daje posty "opublikowane" rok temu — zanim aplikacja istniała. Albo kwoty `fakeAmount()` zwracają 47 123,87 PLN za pojedynczy post na Facebooku.

❌ Losowe daty i kwoty bez kontekstu biznesowego
✅ Daty z ostatnich 30-60 dni, kwoty realistyczne dla branży (np. kampania FB: 500-5000 PLN, nie 50 000 PLN). Dane demo muszą wyglądać wiarygodnie na prezentacji.

### 7. Cleanup script usuwa dane demo, ale nie resetuje sekwencji / relacji

`cleanup-demo.ts` kasuje rekordy z głównych tabel, ale zapomina o:
- **Tabelach powiązanych** (foreign keys bez `ON DELETE CASCADE`) — osierocone rekordy
- **Storage buckets** — pliki uploadowane w demo zostają w Supabase Storage
- **Supabase Auth metadata** — `user_metadata` demo usera nie wraca do stanu początkowego

❌ `DELETE FROM posts WHERE organization_id = demoOrgId` (i nic więcej)
✅ Kasuj w kolejności odwrotnej do tworzenia (najpierw dzieci, potem rodzice), wyczyść storage: `supabase.storage.from('bucket').list()` + `remove()`, zresetuj profil demo usera.

### 8. Organizacja demo widoczna w dropdownie obok produkcyjnych

Użytkownik produkcyjny (np. Ty sam) widzi "[DEMO] Social Media Manager" obok prawdziwych organizacji w przełączniku. Na prezentacji ekranowej to nie problem, ale na screenshotach lub filmach — wyciek nazw prawdziwych organizacji.

❌ Demo i produkcja w jednym widoku przełącznika organizacji
✅ Podczas nagrywania/prezentacji: demo user ma dostęp TYLKO do organizacji demo. Nie przypisuj demo usera do produkcyjnych organizacji. Jeśli musisz — filtruj dropdown: `organizations.filter(o => isDemoOrg(o))` w kontekście demo.
