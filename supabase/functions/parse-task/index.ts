// ============================================================
// Tempo parse-task Edge Function
// POST JSON { text } → 豆包 LLM 结构化解析
//
// 环境变量:
//   DOUBAO_API_KEY             — 豆包 LLM API Key
//   DOUBAO_MODEL               — 豆包模型 ID（推荐 Seed-1.6-Flash 接入点 ep-xxxx）
//   DOUBAO_ENDPOINT            — 豆包 API 端点 (可选, 默认 ark.cn-beijing.volces.com)
//   VOICE_TASK_MOCK            — 设为 "true" 时返回 mock 响应
// ============================================================

import "../_shared/http.ts";

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

    if (!contentType.includes("application/json")) {
      return json({ error: "Unsupported content type. Use application/json." }, 400);
    }

    const body = await request.json() as { text?: string };
    const text = body.text?.trim();
    if (!text) {
      return json({ error: "Missing 'text' field in JSON body" }, 400);
    }
    const t0 = performance.now();
    const parsed = await parseTaskWithDoubao(text);
    console.log(`[parse-task] llm_ms=${Math.round(performance.now() - t0)} text_len=${text.length}`);
    return json(parsed);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return json({ error: message }, 500);
  }
});

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
  return `你是一个专业的高性能中文待办任务（To-Do）解析器。请将用户的输入文本（可能包含口语化表达或语音识别错别字）精准解析为指定的 JSON 格式。

# 任务上下文
- 当前时间 (now): ${currentDatetime}
- 当前星期 (weekday): ${currentWeekday}

# 输出格式
请直接输出 JSON 对象，不要包含任何 Markdown 标记（如 \`\`\`json）、解释或额外字符。格式定义如下：
{
  "title": "string", // 核心任务动作。须剔除时间、频次、周期、优先级等修饰词。
  "description": "string" | null, // 补充备注信息，无则为 null。
  "due_date": "ISO8601+08:00" | null, // 任务截止或发生时间。
  "is_all_day": boolean, // 是否全天任务。
  "priority": 0 | 1 | 2 | 3 | 4, // 优先级：1-紧急, 2-高/重要, 3-中, 4-低, 0-无提及/普通。
  "confidence": number, // 置信度 (0.0 - 1.0)。存在模糊语义或严重错别字导致推测时降低此值。
  "raw_transcript": "string", // 原始输入文本。
  "tag": "work" | "life" | null, // 分类：工作相关（会议、文档、出差、客签等）为 "work"；个人生活（买菜、家务、健身、餐饮、娱乐等）为 "life"；无法确定为 null。
  "recurrence_rule": "string" | null, // RFC5545 RRULE 规则（不含 "RRULE:" 前缀），如 FREQ=DAILY;INTERVAL=1。非周期任务为 null。
  "recurrence_end": "YYYY-MM-DD" | null, // 重复截止日期。与 recurrence_count 二选一，优先使用此字段。
  "recurrence_count": number | null, // 重复次数（如"完成5次后停止"）。与 recurrence_end 二选一。
  "duration_min": number | null // 任务持续时长（分钟），如"开会一小时"对应 60。无提及为 null。
}

# 解析与容错规则

1. **错别字与同音字容错 (ASR 纠错)**：
   - 识别并纠正因拼音或语音输入导致的错别字。例如："开会"误写为"开回/开毁"、"报销"误写为"包销/报消"、"跑步"误写为"泡布"。
   - 根据上下文语义还原真实意图，并在 \`title\` 中使用纠正后的词汇，同时可适当降低 \`confidence\`。

2. **时间解析逻辑**：
   - **相对时间**：基于当前时间 (${currentDatetime}) 计算。
   - **星期/周**：若提到的星期已过（如周一说"周日"），指下一个周日。若提到"这周/本周"，指当前周的对应天。
   - **无具体时间点**：如"明天"、"周五"，\`due_date\` 设为当日 00:00:00+08:00，且 \`is_all_day\` 为 true。
   - **有具体时间点**：如"下午3点"、"晚上8点"，\`due_date\` 设为对应具体时间，且 \`is_all_day\` 为 false。
   - **无任何时间提及**：\`due_date\` 为 null，\`is_all_day\` 为 false。

3. **周期性任务 (Recurrence)**：
   - 支持标准 RFC5545 规则。
   - "每周一三五" -> \`FREQ=WEEKLY;BYDAY=MO,WE,FR\`
   - "每隔一天" -> \`FREQ=DAILY;INTERVAL=2\`
   - 若用户提到"持续三个月"等模糊结束条件，计算出对应的 \`recurrence_end\`（格式 YYYY-MM-DD），此时 \`recurrence_count\` 保持为 null。

4. **标题提炼 (Title Cleaning)**：
   - 提取不含时间、频率、修饰词的纯粹行为。例如："明天下午三点去健身房健身一小时" -> \`title\` 应为 "去健身房健身"。

# 解析示例

示例 1（常规）：
输入："下周一开回" (注：错别字"开回"应为"开会")
输出：{"title":"开会","description":null,"due_date":"[计算得到的下周一日期]T00:00:00+08:00","is_all_day":true,"priority":0,"confidence":0.8,"raw_transcript":"下周一开回","tag":"work","recurrence_rule":null,"recurrence_end":null,"recurrence_count":null,"duration_min":null}

示例 2（复杂周期）：
输入："每天早上八点半提醒我吃药持续两周"
输出：{"title":"吃药","description":null,"due_date":"[计算得到的明天日期]T08:30:00+08:00","is_all_day":false,"priority":0,"confidence":1.0,"raw_transcript":"每天早上八点半提醒我吃药持续两周","tag":"life","recurrence_rule":"FREQ=DAILY;INTERVAL=1","recurrence_end":"[当前日期+14天]","recurrence_count":null,"duration_min":null}`;
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
