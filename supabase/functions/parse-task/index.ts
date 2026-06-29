// ============================================================
// Tempo parse-task Edge Function
// 统一解析端点：JSON 文本路径(LLM) 为主；multipart 语音路径为降级 fallback
//
// 主路径（语音 + 文本）:
//   App POST JSON { text } → 豆包 LLM 结构化解析
//
// 降级路径（流式 ASR 不可用时）:
//   App multipart POST → Storage → 火山录音文件 ASR → LLM
//
// 环境变量:
//   DOUBAO_API_KEY             — 豆包 LLM API Key
//   DOUBAO_MODEL               — 豆包模型 ID（推荐 Seed-1.6-Flash 接入点 ep-xxxx）
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
  is_all_day: boolean;
  priority: number;
  confidence: number;
  raw_transcript: string;
  tag: string | null;
  recurrence_rule: string | null;
  recurrence_end: string | null;
  recurrence_count: number | null;
  duration_min: number | null;
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

    // 主路径：application/json → LLM 结构化解析（语音转写后、文本输入均走此路径）
    if (contentType.includes("application/json")) {
      const body = await request.json() as { text?: string };
      const text = body.text?.trim();
      if (!text) {
        return json({ error: "Missing 'text' field in JSON body" }, 400);
      }
      const t0 = performance.now();
      const parsed = await parseTaskWithDoubao(text);
      console.log(`[parse-task] llm_ms=${Math.round(performance.now() - t0)} text_len=${text.length}`);
      return json(parsed);
    }

    // 降级路径：multipart/form-data → Storage → 文件 ASR → LLM
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

    return json({ error: "Unsupported content type. Use application/json or multipart/form-data." }, 400);
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
  const signedPath = signData.signedURL;
  if (signedPath.startsWith("http")) {
    return signedPath;
  }
  // Storage API 返回相对路径 /object/sign/...，需拼上 /storage/v1 前缀。
  return `${baseUrl}/storage/v1${signedPath.startsWith("/") ? signedPath : `/${signedPath}`}`;
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

  const { currentDatetime, currentWeekday } = buildShanghaiTimeContext();
  const systemPrompt = buildSystemPrompt(currentDatetime, currentWeekday);

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

// ── LLM Prompt 模板 ──

function buildSystemPrompt(currentDatetime: string, currentWeekday: string): string {
  return `Parse Chinese task text into JSON only:
{"title":"string","description":string|null,"due_date":"ISO8601+08:00"|null,"is_all_day":true|false,"priority":0-4,"confidence":0-1,"raw_transcript":"input","tag":"work"|"life"|null,"recurrence_rule":"RRULE string"|null,"recurrence_end":"ISO date"|null,"recurrence_count":int|null,"duration_min":int|null}

Context: now=${currentDatetime}, weekday=${currentWeekday}（今天${currentWeekday}）
Rules:
- Relative dates from now; weekday = next occurrence if passed this week
- No explicit time on date → due_date at 00:00+08:00, is_all_day: true
- Explicit time (e.g. "下午3点") → due_date with that time, is_all_day: false
- No date → due_date: null, is_all_day: false
- 紧急→1, 高/重要→2, 中→3, 低→4, else 0
- Title: core action without time/priority/recurrence/duration words
- tag: 会议/文档/出差→work; 买菜/家务/餐饮/娱乐/外出→life; unsure→null
- recurrence_rule: RFC5545 RRULE without "RRULE:" prefix; null if not recurring. Examples: FREQ=DAILY;INTERVAL=1, FREQ=WEEKLY;BYDAY=MO,WE,FR
- recurrence_end: ISO date (YYYY-MM-DD) when recurrence ends by date; null otherwise
- recurrence_count: total occurrence count when user says "N次/持续N个月" etc.; null if open-ended or date-based end
- duration_min: event duration in minutes (e.g. 一小时→60, 半小时→30); null if not mentioned
- Set only one of recurrence_end or recurrence_count when both could apply; prefer recurrence_end for "持续三个月"
Example (today Monday): "周四去吃KFC" → due next Thu 00:00+08:00, is_all_day: true, tag: life, title "去吃KFC", recurrence fields null
Example: "明天下午三点开会" → title "开会", due_date tomorrow 15:00+08:00, is_all_day: false, priority: 0, confidence: 0.9, tag: work
Example: "每周一跑步" → title "跑步", due_date next Mon 00:00+08:00, recurrence_rule "FREQ=WEEKLY;BYDAY=MO", tag: life
Example: "每天八点锻炼一小时持续三个月" → title "锻炼", due_date next day 08:00+08:00, is_all_day: false, recurrence_rule "FREQ=DAILY;INTERVAL=1", recurrence_end ~3 months from now (YYYY-MM-DD), recurrence_count: null, duration_min: 60, tag: life
Example: "每周一三五跑步" → title "跑步", due_date next Mon 00:00+08:00 or today if Mon, recurrence_rule "FREQ=WEEKLY;BYDAY=MO,WE,FR", recurrence_end: null, recurrence_count: null, duration_min: null, tag: life`;
}

function buildShanghaiTimeContext(now = new Date()): {
  currentDatetime: string;
  currentWeekday: string;
} {
  const shanghai = new Date(now.getTime() + 8 * 60 * 60 * 1000);
  const weekdayLabels = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"];
  const pad = (value: number, width = 2) => value.toString().padStart(width, "0");
  const year = shanghai.getUTCFullYear();
  const month = pad(shanghai.getUTCMonth() + 1);
  const day = pad(shanghai.getUTCDate());
  const hour = pad(shanghai.getUTCHours());
  const minute = pad(shanghai.getUTCMinutes());
  const second = pad(shanghai.getUTCSeconds());
  const millis = pad(shanghai.getUTCMilliseconds(), 3);

  return {
    currentDatetime: `${year}-${month}-${day}T${hour}:${minute}:${second}.${millis}+08:00`,
    currentWeekday: weekdayLabels[shanghai.getUTCDay()],
  };
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
    is_all_day: normalizeIsAllDay(payload.is_all_day, payload.due_date),
    priority: normalizePriority(payload.priority),
    confidence: Math.max(0, Math.min(1, confidence)),
    raw_transcript: rawTranscript,
    tag: normalizeTag(payload.tag),
    recurrence_rule: normalizeRecurrenceRule(payload.recurrence_rule),
    recurrence_end: normalizeRecurrenceEnd(payload.recurrence_end),
    recurrence_count: nullableIntValue(payload.recurrence_count),
    duration_min: nullableIntValue(payload.duration_min),
  };
}

function normalizeRecurrenceRule(value: unknown): string | null {
  const rule = nullableStringValue(value);
  if (!rule) return null;
  const upper = rule.toUpperCase();
  if (!upper.includes("FREQ=")) return null;
  return upper;
}

function normalizeRecurrenceEnd(value: unknown): string | null {
  const end = nullableStringValue(value);
  if (!end) return null;
  const parsed = Date.parse(end);
  if (Number.isNaN(parsed)) return null;
  return end;
}

function normalizeIsAllDay(value: unknown, dueDate: unknown): boolean {
  if (typeof value === "boolean") return value;
  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    if (normalized === "true" || normalized === "1") return true;
    if (normalized === "false" || normalized === "0") return false;
  }
  // Legacy fallback: midnight due_date implies all-day
  if (typeof dueDate === "string") {
    return /T00:00(?::00)?(?:\.\d+)?\+08:00$/.test(dueDate.trim());
  }
  return false;
}

function normalizeTag(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim().toLowerCase();
  if (normalized === "work" || normalized === "工作") return "work";
  if (normalized === "life" || normalized === "生活") return "life";
  return null;
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

function nullableIntValue(value: unknown): number | null {
  if (value === null || value === undefined) return null;
  if (typeof value === "number" && Number.isFinite(value)) {
    const intValue = Math.trunc(value);
    return intValue > 0 ? intValue : null;
  }
  if (typeof value === "string") {
    const trimmed = value.trim();
    if (trimmed.length === 0) return null;
    const parsed = Number.parseInt(trimmed, 10);
    return Number.isFinite(parsed) && parsed > 0 ? parsed : null;
  }
  return null;
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
    is_all_day: false,
    priority: 2,
    confidence: 0.86,
    raw_transcript: "明天下午三点提交设计稿，优先级高",
    tag: "work",
    recurrence_rule: null,
    recurrence_end: null,
    recurrence_count: null,
    duration_min: null,
  };
}
