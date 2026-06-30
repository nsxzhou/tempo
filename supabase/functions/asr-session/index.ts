// ============================================================
// Tempo asr-session Edge Function
// 为客户端流式 ASR 下发 relay 会话配置（密钥仅存 asr-relay）
//
// 环境变量:
//   VOLCENGINE_ASR_APP_KEY + VOLCENGINE_ASR_ACCESS_KEY — 旧版 App/Token
//   VOLCENGINE_ASR_API_KEY — 新版控制台单一 API Key
//   VOLCENGINE_ASR_RESOURCE_ID — 资源 ID，默认 volc.seedasr.sauc.duration
//   VOICE_TASK_MOCK — "true" 时返回 mock 配置
// ============================================================

import { corsHeaders, json } from "../_shared/http.ts";

const DEFAULT_RESOURCE_ID = "volc.seedasr.sauc.duration";

type AsrSessionResponse = {
  auth_mode: "relay";
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
