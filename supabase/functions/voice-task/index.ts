type VoiceTaskResponse = {
  title: string;
  description: string | null;
  due_date: string | null;
  priority: number;
  confidence: number;
  raw_transcript: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    if (Deno.env.get("VOICE_TASK_MOCK") === "true") {
      return json(mockVoiceTaskResponse());
    }

    const audio = await readAudioBytes(request);
    const transcript = await transcribeWithVolcengine(audio);
    const parsed = await parseTaskWithDoubao(transcript);
    return json(parsed);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return json({ error: message }, 500);
  }
});

async function readAudioBytes(request: Request): Promise<Uint8Array> {
  const contentType = request.headers.get("content-type") ?? "";

  if (contentType.includes("multipart/form-data")) {
    const form = await request.formData();
    const audio = form.get("audio");
    if (!(audio instanceof File)) {
      throw new Error("multipart/form-data must include an audio file");
    }
    return new Uint8Array(await audio.arrayBuffer());
  }

  if (contentType.includes("application/json")) {
    const body = await request.json() as { audio_base64?: string };
    if (!body.audio_base64) {
      throw new Error("JSON body must include audio_base64");
    }
    return decodeBase64(body.audio_base64);
  }

  throw new Error("Unsupported content type");
}

async function transcribeWithVolcengine(
  audio: Uint8Array,
): Promise<string> {
  const endpoint = requiredEnv("VOLCENGINE_ASR_ENDPOINT");
  const appKey = requiredEnv("VOLCENGINE_ASR_APP_KEY");
  const accessToken = requiredEnv("VOLCENGINE_ASR_ACCESS_TOKEN");

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "audio/mp4",
      "X-Api-App-Key": appKey,
    },
    body: audio,
  });

  if (!response.ok) {
    throw new Error(`Volcengine ASR failed: ${response.status}`);
  }

  const payload = await response.json();
  const transcript = extractTranscript(payload);
  if (!transcript) {
    throw new Error("Volcengine ASR response did not include transcript text");
  }
  return transcript;
}

async function parseTaskWithDoubao(
  transcript: string,
): Promise<VoiceTaskResponse> {
  const endpoint = Deno.env.get("DOUBAO_ENDPOINT") ??
    "https://ark.cn-beijing.volces.com/api/v3/chat/completions";
  const apiKey = requiredEnv("DOUBAO_API_KEY");
  const model = requiredEnv("DOUBAO_MODEL");

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      temperature: 0,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content:
            "Extract a task from Chinese speech. Return JSON only with title, description, due_date, priority, confidence, raw_transcript. priority is 0 none, 1 P0 urgent, 2 P1 high, 3 P2 medium, 4 P3 low. due_date must be ISO-8601 or null.",
        },
        {
          role: "user",
          content: transcript,
        },
      ],
    }),
  });

  if (!response.ok) {
    throw new Error(`Doubao parse failed: ${response.status}`);
  }

  const payload = await response.json();
  const content = extractDoubaoContent(payload);
  const parsed = JSON.parse(content) as Record<string, unknown>;
  return normalizeTaskResponse(parsed, transcript);
}

function normalizeTaskResponse(
  payload: Record<string, unknown>,
  transcript: string,
): VoiceTaskResponse {
  const title = stringValue(payload.title).trim();
  const rawTranscript = stringValue(payload.raw_transcript).trim() ||
    transcript.trim();
  const confidence = numberValue(payload.confidence, 0);

  return {
    title,
    description: nullableStringValue(payload.description),
    due_date: nullableStringValue(payload.due_date),
    priority: normalizePriority(payload.priority),
    confidence: Math.max(0, Math.min(1, confidence)),
    raw_transcript: rawTranscript,
  };
}

function extractTranscript(payload: unknown): string | null {
  const direct = findStringByKeys(payload, [
    "transcript",
    "text",
    "utterance",
    "result_text",
  ]);
  return direct?.trim() || null;
}

function extractDoubaoContent(payload: unknown): string {
  const record = asRecord(payload);
  const choices = record?.choices;
  if (!Array.isArray(choices) || choices.length === 0) {
    throw new Error("Doubao response missing choices");
  }

  const first = asRecord(choices[0]);
  const message = asRecord(first?.message);
  const content = message?.content;
  if (typeof content !== "string" || content.trim().length === 0) {
    throw new Error("Doubao response missing message content");
  }
  return content;
}

function findStringByKeys(
  value: unknown,
  keys: string[],
): string | null {
  if (typeof value === "string") {
    return null;
  }
  if (Array.isArray(value)) {
    for (const item of value) {
      const found = findStringByKeys(item, keys);
      if (found) {
        return found;
      }
    }
    return null;
  }

  const record = asRecord(value);
  if (!record) {
    return null;
  }

  for (const key of keys) {
    const candidate = record[key];
    if (typeof candidate === "string" && candidate.trim().length > 0) {
      return candidate;
    }
  }

  for (const nested of Object.values(record)) {
    const found = findStringByKeys(nested, keys);
    if (found) {
      return found;
    }
  }

  return null;
}

function normalizePriority(value: unknown): number {
  if (typeof value === "number") {
    return clampPriority(value);
  }

  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    const parsed = Number.parseInt(normalized, 10);
    if (Number.isFinite(parsed)) {
      return clampPriority(parsed);
    }
    if (normalized === "p0" || normalized === "urgent") {
      return 1;
    }
    if (normalized === "p1" || normalized === "high") {
      return 2;
    }
    if (normalized === "p2" || normalized === "medium") {
      return 3;
    }
    if (normalized === "p3" || normalized === "low") {
      return 4;
    }
  }

  return 0;
}

function clampPriority(value: number): number {
  if (value < 0 || value > 4) {
    return 0;
  }
  return Math.trunc(value);
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function decodeBase64(value: string): Uint8Array {
  const binary = atob(value);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

function stringValue(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function nullableStringValue(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

function numberValue(value: unknown, fallback: number): number {
  if (typeof value === "number") {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number.parseFloat(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }
  return fallback;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  return value as Record<string, unknown>;
}

function mockVoiceTaskResponse(): VoiceTaskResponse {
  return {
    title: "提交设计稿",
    description: "识别内容: 明天下午三点提交设计稿，优先级高",
    due_date: "2026-06-19T15:00:00.000+08:00",
    priority: 2,
    confidence: 0.86,
    raw_transcript: "明天下午三点提交设计稿，优先级高",
  };
}
