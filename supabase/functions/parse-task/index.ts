// ============================================================
// Tempo parse-task Edge Function
// 统一解析端点：multipart 语音路径(ASR+LLM) + json 文本路径(LLM only)
//
// 语音路径流程:
//   App multipart POST → 上传音频到 Supabase Storage → 生成 signed URL
//   → 提交火山引擎录音文件识别(submit) → 轮询结果(query) → 豆包 LLM 解析
//   → 清理 Storage 临时文件 → 返回结构化任务
//
// 环境变量:
//   DOUBAO_API_KEY             — 豆包 LLM API Key
//   DOUBAO_MODEL               — 豆包模型 ID (ep-xxxx 接入点)
//   DOUBAO_ENDPOINT            — 豆包 API 端点 (可选, 默认 ark.cn-beijing.volces.com)
//   VOLCENGINE_ASR_API_KEY     — 火山引擎语音 API Key (新版控制台 X-Api-Key)
//   VOICE_TASK_MOCK            — 设为 "true" 时返回 mock 响应
//
// Supabase Edge Function 自动注入:
//   SUPABASE_URL               — Supabase 项目 URL
//   SUPABASE_SERVICE_ROLE_KEY  — Service Role Key (Storage 操作)
// ============================================================

type ParseTaskResponse = {
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

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    // Mock 模式：无需真实密钥，返回固定响应
    if (Deno.env.get("VOICE_TASK_MOCK") === "true") {
      return json(mockResponse());
    }

    const contentType = request.headers.get("content-type") ?? "";

    // 语音路径：multipart/form-data → Storage 上传 → ASR(submit+poll) → LLM
    if (contentType.includes("multipart/form-data")) {
      const { audio, filename } = await readAudioFromMultipart(request);
      const storagePath = `voice-tasks/${crypto.randomUUID()}/${filename}`;

      try {
        // 1. 上传到 Supabase Storage，获取可访问 URL
        const audioUrl = await uploadToStorage(audio, storagePath);

        // 2. 提交 ASR 任务 + 轮询结果
        const transcript = await transcribeWithVolcengine(audioUrl);

        // 3. LLM 解析
        const parsed = await parseTaskWithDoubao(transcript);
        return json(parsed);
      } finally {
        // 4. 清理临时文件（静默，不影响主流程）
        await deleteFromStorage(storagePath).catch((err) => {
          console.error("Storage cleanup failed:", err);
        });
      }
    }

    // 文本路径：application/json → LLM 直接解析
    if (contentType.includes("application/json")) {
      const body = await request.json() as { text?: string };
      const text = body.text?.trim();
      if (!text) {
        return json({ error: "Missing 'text' field in JSON body" }, 400);
      }
      const parsed = await parseTaskWithDoubao(text);
      return json(parsed);
    }

    return json({ error: "Unsupported content type. Use multipart/form-data or application/json." }, 400);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return json({ error: message }, 500);
  }
});

// ── 音频读取 ──

async function readAudioFromMultipart(
  request: Request,
): Promise<{ audio: Uint8Array; filename: string }> {
  const form = await request.formData();
  const audio = form.get("audio");
  if (!(audio instanceof File)) {
    throw new Error("multipart/form-data must include an 'audio' file field");
  }
  return {
    audio: new Uint8Array(await audio.arrayBuffer()),
    filename: audio.name || "voice-task.m4a",
  };
}

// ── Supabase Storage 操作 ──

const STORAGE_BUCKET = "tempo-audio";
const SIGNED_URL_EXPIRY = 600; // 10 分钟

function storageBaseUrl(): string {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) {
    throw new Error("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required for Storage operations");
  }
  return url;
}

function storageAuthHeaders(): Record<string, string> {
  return {
    Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
    apikey: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  };
}

async function uploadToStorage(
  audio: Uint8Array,
  path: string,
): Promise<string> {
  const baseUrl = storageBaseUrl();
  const headers = storageAuthHeaders();

  // 上传文件到 Storage
  const uploadUrl = `${baseUrl}/storage/v1/object/${STORAGE_BUCKET}/${path}`;
  const uploadRes = await fetch(uploadUrl, {
    method: "POST",
    headers: {
      ...headers,
      "Content-Type": "audio/mp4",
      "x-upsert": "true",
    },
    body: audio,
  });

  if (!uploadRes.ok) {
    const errText = await uploadRes.text();
    throw new Error(`Storage upload failed (${uploadRes.status}): ${errText}`);
  }

  // 生成 signed URL 供火山引擎 ASR 访问
  const signUrl = `${baseUrl}/storage/v1/object/sign/${STORAGE_BUCKET}/${path}`;
  const signRes = await fetch(signUrl, {
    method: "POST",
    headers: {
      ...headers,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ expiresIn: SIGNED_URL_EXPIRY }),
  });

  if (!signRes.ok) {
    const errText = await signRes.text();
    throw new Error(`Storage sign URL failed (${signRes.status}): ${errText}`);
  }

  const signData = (await signRes.json()) as { signedURL: string };
  // signedURL 是相对路径，需要拼接 baseUrl
  const signedPath = signData.signedURL;
  return signedPath.startsWith("http")
    ? signedPath
    : `${baseUrl}${signedPath.startsWith("/") ? "" : "/"}${signedPath}`;
}

async function deleteFromStorage(path: string): Promise<void> {
  const baseUrl = storageBaseUrl();
  const headers = storageAuthHeaders();

  const deleteUrl = `${baseUrl}/storage/v1/object/${STORAGE_BUCKET}/${path}`;
  const res = await fetch(deleteUrl, {
    method: "DELETE",
    headers,
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Storage delete failed (${res.status}): ${errText}`);
  }
}

// ── 火山引擎 ASR（录音文件识别标准版） ──

const VOLCENGINE_ASR_SUBMIT =
  "https://openspeech.bytedance.com/api/v3/auc/bigmodel/submit";
const VOLCENGINE_ASR_QUERY =
  "https://openspeech.bytedance.com/api/v3/auc/bigmodel/query";
const VOLCENGINE_ASR_RESOURCE_ID = "volc.bigasr.auc";

// 轮询配置
const ASR_POLL_INTERVAL_MS = 1500;
const ASR_POLL_MAX_MS = 30_000;

async function transcribeWithVolcengine(audioUrl: string): Promise<string> {
  const apiKey = requiredEnv("VOLCENGINE_ASR_API_KEY");
  const requestId = crypto.randomUUID();

  // Step 1: 提交识别任务
  const submitHeaders: Record<string, string> = {
    "Content-Type": "application/json",
    "X-Api-Key": apiKey,
    "X-Api-Resource-Id": VOLCENGINE_ASR_RESOURCE_ID,
    "X-Api-Request-Id": requestId,
    "X-Api-Sequence": "-1",
  };

  const submitBody = {
    audio: {
      format: "m4a",
      url: audioUrl,
    },
    request: {
      model_name: "bigmodel",
      enable_itn: true,
      enable_punc: true,
    },
  };

  const submitRes = await fetch(VOLCENGINE_ASR_SUBMIT, {
    method: "POST",
    headers: submitHeaders,
    body: JSON.stringify(submitBody),
  });

  const submitStatus = submitRes.headers.get("X-Api-Status-Code");
  if (submitStatus !== "20000000") {
    const msg = submitRes.headers.get("X-Api-Message") ?? "unknown error";
    throw new Error(`ASR submit failed: code=${submitStatus}, msg=${msg}`);
  }

  // Step 2: 轮询查询结果
  return await pollAsrResult(apiKey, requestId);
}

async function pollAsrResult(
  apiKey: string,
  requestId: string,
): Promise<string> {
  const queryHeaders: Record<string, string> = {
    "Content-Type": "application/json",
    "X-Api-Key": apiKey,
    "X-Api-Resource-Id": VOLCENGINE_ASR_RESOURCE_ID,
    "X-Api-Request-Id": requestId,
  };

  const deadline = Date.now() + ASR_POLL_MAX_MS;

  while (Date.now() < deadline) {
    await sleep(ASR_POLL_INTERVAL_MS);

    const res = await fetch(VOLCENGINE_ASR_QUERY, {
      method: "POST",
      headers: queryHeaders,
      body: "{}",
    });

    const statusCode = res.headers.get("X-Api-Status-Code");

    // 20000001 = 处理中, 20000002 = 排队中 → 继续等待
    if (statusCode === "20000001" || statusCode === "20000002") {
      continue;
    }

    // 20000000 = 成功
    if (statusCode === "20000000") {
      const payload = await res.json();
      const transcript = extractAsrTranscript(payload);
      if (!transcript) {
        throw new Error("ASR completed but returned empty transcript");
      }
      return transcript;
    }

    // 其他状态码 = 错误
    const msg = res.headers.get("X-Api-Message") ?? "unknown error";
    throw new Error(`ASR query failed: code=${statusCode}, msg=${msg}`);
  }

  throw new Error("语音识别超时，请重试");
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function extractAsrTranscript(payload: unknown): string | null {
  const record = asRecord(payload);
  if (!record) return null;

  const result = asRecord(record.result);
  if (!result) return null;

  // 优先取 result.text（完整识别文本）
  const text = result.text;
  if (typeof text === "string" && text.trim().length > 0) {
    return text.trim();
  }

  // 降级：拼接 utterances
  const utterances = result.utterances;
  if (Array.isArray(utterances)) {
    const parts: string[] = [];
    for (const utt of utterances) {
      const u = asRecord(utt);
      if (u && typeof u.text === "string") {
        parts.push(u.text);
      }
    }
    const joined = parts.join("").trim();
    if (joined.length > 0) return joined;
  }

  return null;
}

// ── 豆包 LLM 解析 ──

async function parseTaskWithDoubao(inputText: string): Promise<ParseTaskResponse> {
  const endpoint = Deno.env.get("DOUBAO_ENDPOINT") ??
    "https://ark.cn-beijing.volces.com/api/v3/chat/completions";
  const apiKey = requiredEnv("DOUBAO_API_KEY");
  const model = requiredEnv("DOUBAO_MODEL");

  const currentDatetime = new Date().toISOString();
  const systemPrompt = buildSystemPrompt(currentDatetime);

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
        { role: "system", content: systemPrompt },
        { role: "user", content: inputText },
      ],
    }),
  });

  if (!response.ok) {
    throw new Error(`Doubao parse failed: ${response.status}`);
  }

  const payload = await response.json();
  const content = extractDoubaoContent(payload);
  const parsed = JSON.parse(content) as Record<string, unknown>;
  return normalizeTaskResponse(parsed, inputText);
}

// ── LLM Prompt 模板（设计文档 7.4 节）──

function buildSystemPrompt(currentDatetime: string): string {
  return `You are a task parser. Extract structured task information from Chinese text input.
Return JSON ONLY with these fields:
- title: string (task title, extract the core action without time/priority words)
- description: string | null (additional context, null if none)
- due_date: string | null (ISO 8601 with timezone, null if no date mentioned)
- priority: number (0=none, 1=P0 urgent, 2=P1 high, 3=P2 medium, 4=P3 low)
- confidence: number (0-1, how confident you are in the extraction)
- raw_transcript: string (the original input text)

Rules:
- Parse relative dates relative to the current time: ${currentDatetime}
- "明天" = tomorrow, "下周五" = next Friday, "月底" = end of month
- If no time is specified but date is, default to 09:00
- If no date is mentioned, due_date = null
- Extract priority from keywords: 紧急→P0, 高/重要→P1, 中→P2, 低→P3
- Title should be concise (remove date/priority words from title)`;
}

// ── 工具函数 ──

function normalizeTaskResponse(
  payload: Record<string, unknown>,
  inputText: string,
): ParseTaskResponse {
  const title = stringValue(payload.title).trim();
  const rawTranscript = stringValue(payload.raw_transcript).trim() || inputText.trim();
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

// ── LLM 响应提取 ──

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

// ── 优先级归一化 ──

function normalizePriority(value: unknown): number {
  if (typeof value === "number") return clampPriority(value);
  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    const parsed = Number.parseInt(normalized, 10);
    if (Number.isFinite(parsed)) return clampPriority(parsed);
    if (normalized === "p0" || normalized === "urgent") return 1;
    if (normalized === "p1" || normalized === "high") return 2;
    if (normalized === "p2" || normalized === "medium") return 3;
    if (normalized === "p3" || normalized === "low") return 4;
  }
  return 0;
}

function clampPriority(value: number): number {
  if (value < 0 || value > 4) return 0;
  return Math.trunc(value);
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function stringValue(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function nullableStringValue(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

function numberValue(value: unknown, fallback: number): number {
  if (typeof value === "number") return value;
  if (typeof value === "string") {
    const parsed = Number.parseFloat(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }
  return fallback;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value === null || typeof value !== "object" || Array.isArray(value)) return null;
  return value as Record<string, unknown>;
}

function mockResponse(): ParseTaskResponse {
  return {
    title: "提交设计稿",
    description: "识别内容: 明天下午三点提交设计稿，优先级高",
    due_date: "2026-07-21T15:00:00.000+08:00",
    priority: 2,
    confidence: 0.86,
    raw_transcript: "明天下午三点提交设计稿，优先级高",
  };
}
