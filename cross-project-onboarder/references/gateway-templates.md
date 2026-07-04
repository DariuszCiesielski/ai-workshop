# Gateway Templates — Cross-Project

Przeniesione z byłego skilla `cross-project-gateway`. Zawiera template'y kodu gateway (Supabase EF + Next.js API route) z HMAC auth.

## Template A: Supabase Edge Function (Deno)

```typescript
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { createHmac } from "node:crypto";

const MAX_TIMESTAMP_DRIFT_S = 300;

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405, false);
  }

  const bodyStr = await req.text();

  // === Auth: HMAC-SHA256 ===
  const secret = Deno.env.get("PM_HMAC_SECRET");
  if (!secret) return jsonError("Brak PM_HMAC_SECRET", 500);

  const signature = req.headers.get("x-signature");
  const timestamp = req.headers.get("x-timestamp");
  const nonce = req.headers.get("x-nonce");

  if (!signature || !timestamp || !nonce) {
    return jsonError("Brak nagłówków auth", 401, false);
  }

  const now = Math.floor(Date.now() / 1000);
  const ts = parseInt(timestamp, 10);
  if (isNaN(ts) || Math.abs(now - ts) > MAX_TIMESTAMP_DRIFT_S) {
    return jsonError("Timestamp poza zakresem", 401, false);
  }

  const message = `${timestamp}.${nonce}.${bodyStr}`;
  const expected = createHmac("sha256", secret).update(message).digest("hex");
  if (signature !== expected) {
    return jsonError("Nieprawidłowy podpis", 401, false);
  }

  // === Parse body ===
  let body: { action: string; job_id: string; correlation_id?: string; payload: Record<string, unknown> };
  try {
    body = JSON.parse(bodyStr);
  } catch {
    return jsonError("Invalid JSON", 400, false);
  }

  console.log(`[Gateway] ${body.action} (job: ${body.job_id?.slice(0, 8)})`);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  // === AKCJE — DOSTOSUJ DO PROJEKTU ===
  switch (body.action) {
    // ▼▼▼ TUTAJ WSTAW AKCJE PROJEKTU ▼▼▼

    case "get-task-status": {
      const { task_id } = body.payload as { task_id?: string };
      if (!task_id) return jsonError("Brak task_id", 400, false);

      const { data, error } = await supabase
        .from("TWOJA_TABELA_TASKOW")
        .select("status, result, error_message")
        .eq("id", task_id)
        .single();

      if (error) return jsonError(`Task ${task_id} nie znaleziony`, 404, false);

      return jsonSuccess({
        status: data.status === "completed" ? "completed" : data.status === "failed" ? "failed" : "processing",
        result: data.result,
        error: data.error_message,
      });
    }

    default:
      return jsonError(`Nieznana akcja: ${body.action}`, 400, false);
  }
});

function jsonSuccess(data: Record<string, unknown>) {
  return new Response(JSON.stringify({ success: true, data }), {
    headers: { "Content-Type": "application/json" },
  });
}

function jsonError(message: string, status: number, retryable = false) {
  return new Response(JSON.stringify({ success: false, error: message, retryable }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
```

## Template B: Next.js API Route

```typescript
import { NextRequest, NextResponse } from "next/server";
import { createHmac } from "node:crypto";

const MAX_TIMESTAMP_DRIFT_S = 300;

export async function POST(request: NextRequest) {
  const bodyStr = await request.text();

  const secret = process.env.PM_HMAC_SECRET;
  if (!secret) {
    return NextResponse.json({ success: false, error: "Brak PM_HMAC_SECRET" }, { status: 500 });
  }

  const signature = request.headers.get("x-signature");
  const timestamp = request.headers.get("x-timestamp");
  const nonce = request.headers.get("x-nonce");

  if (!signature || !timestamp || !nonce) {
    return NextResponse.json({ success: false, error: "Brak auth headers", retryable: false }, { status: 401 });
  }

  const now = Math.floor(Date.now() / 1000);
  const ts = parseInt(timestamp, 10);
  if (isNaN(ts) || Math.abs(now - ts) > MAX_TIMESTAMP_DRIFT_S) {
    return NextResponse.json({ success: false, error: "Timestamp expired", retryable: false }, { status: 401 });
  }

  const message = `${timestamp}.${nonce}.${bodyStr}`;
  const expected = createHmac("sha256", secret).update(message).digest("hex");
  if (signature !== expected) {
    return NextResponse.json({ success: false, error: "Bad signature", retryable: false }, { status: 401 });
  }

  const body = JSON.parse(bodyStr);
  const { action, job_id, payload } = body;

  console.log(`[Gateway] ${action} (job: ${job_id?.slice(0, 8)})`);

  // === AKCJE — DOSTOSUJ DO PROJEKTU ===
  switch (action) {
    // ▼▼▼ TUTAJ WSTAW AKCJE PROJEKTU ▼▼▼

    default:
      return NextResponse.json(
        { success: false, error: `Nieznana akcja: ${action}`, retryable: false },
        { status: 400 }
      );
  }
}
```

## Wzorce akcji

### Akcja sync (wynik od razu)
```typescript
case "NAZWA_AKCJI": {
  const { param1, param2 } = body.payload as { param1?: string; param2?: string };
  if (!param1) return jsonError("Brak param1", 400, false);

  const { data, error } = await supabase
    .from("tabela")
    .select("*")
    .eq("kolumna", param1);

  if (error) return jsonError(error.message, 500, true);
  return jsonSuccess({ wynik: data });
}
```

### Akcja async (długotrwała — zwróć task_id)
```typescript
case "NAZWA_AKCJI": {
  const { param1 } = body.payload as { param1?: string };
  if (!param1) return jsonError("Brak param1", 400, false);

  const { data: task, error } = await supabase
    .from("TABELA_TASKOW")
    .insert({
      type: "NAZWA_AKCJI",
      params: body.payload,
      status: "pending",
      source_project: "project-master",
      source_job_id: body.job_id,
    })
    .select("id")
    .single();

  if (error) return jsonError(error.message, 500, true);

  return new Response(JSON.stringify({
    success: true,
    async_task_id: task.id,
    estimated_seconds: 60,
  }), { headers: { "Content-Type": "application/json" } });
}
```

## Pipeline Templates

Pipeline'y definiowane w `scripts/orchestrator/pipelines/`:

```typescript
import type { PipelineTemplate } from '../../../src/types/cross-project';

const myPipeline: PipelineTemplate = {
  name: 'nazwa-pipeline',
  description: 'Opis co robi pipeline',
  steps: [
    { step: 1, target_project: 'projekt-a', target_action: 'akcja-1',
      buildPayload: (params) => ({ url: params.url }) },
    { step: 2, target_project: 'projekt-b', target_action: 'akcja-2',
      buildPayload: (params, prevResult) => ({ data: prevResult }) },
  ],
};

export default myPipeline;
```
