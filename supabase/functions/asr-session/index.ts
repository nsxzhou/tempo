// ============================================================
// Tempo asr-session Edge Function
// 为客户端流式 ASR 下发短期会话配置（密钥仅存服务端）
//
// 环境变量（二选一鉴权）:
//   A) VOLCENGINE_ASR_APP_KEY + VOLCENGINE_ASR_ACCESS_KEY — 旧版 App/Token
//   B) VOLCENGINE_ASR_API_KEY — 新版控制台单一 API Key (X-Api-Key)
//   VOLCENGINE_ASR_RESOURCE_ID  — 资源 ID，默认 volc.seedasr.sauc.duration
//   VOLCENGINE_ASR_WS_ENDPOINT  — WebSocket 端点，默认 bigmodel_async
//   VOICE_TASK_MOCK             — "true" 时返回 mock 配置
// ============================================================

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const DEFAULT_RESOURCE_ID = "volc.seedasr.sauc.duration";

type AsrSessionResponse = {
  auth_mode: "relay" | "app_access" | "api_key";
  app_key: string;
  access_key: string;
  api_key: string;
  resource_id: string;
  ws_endpoint: string;
  connect_id: string;
  mock: boolean;
};

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    if (Deno.env.get("VOICE_TASK_MOCK") === "true") {
      return json(mockSession());
    }

    const resourceId = Deno.env.get("VOLCENGINE_ASR_RESOURCE_ID") ??
      DEFAULT_RESOURCE_ID;
    const connectId = crypto.randomUUID();
    const relayEndpoint = buildRelayEndpoint();

    const appKey = Deno.env.get("VOLCENGINE_ASR_APP_KEY")?.trim() ?? "";
    const accessKey = Deno.env.get("VOLCENGINE_ASR_ACCESS_KEY")?.trim() ?? "";
    const apiKey = Deno.env.get("VOLCENGINE_ASR_API_KEY")?.trim() ?? "";

    if (!appKey && !accessKey && !apiKey) {
      throw new Error(
        "Missing ASR credentials: set VOLCENGINE_ASR_APP_KEY + VOLCENGINE_ASR_ACCESS_KEY, or VOLCENGINE_ASR_API_KEY",
      );
    }

    return json({
      auth_mode: "relay",
      app_key: "",
      access_key: "",
      api_key: "",
      resource_id: resourceId,
      ws_endpoint: relayEndpoint,
      connect_id: connectId,
      mock: false,
    } satisfies AsrSessionResponse);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return json({ error: message }, 500);
  }
});

function mockSession(): AsrSessionResponse {
  return {
    auth_mode: "relay",
    app_key: "",
    access_key: "",
    api_key: "",
    resource_id: DEFAULT_RESOURCE_ID,
    ws_endpoint: buildRelayEndpoint(),
    connect_id: crypto.randomUUID(),
    mock: true,
  };
}

function buildRelayEndpoint(): string {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  if (!supabaseUrl) {
    throw new Error("Missing SUPABASE_URL for asr-relay endpoint");
  }
  const wsBase = supabaseUrl.replace(/^http/i, "ws");
  return `${wsBase}/functions/v1/asr-relay`;
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
