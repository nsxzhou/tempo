// ============================================================
// Tempo asr-relay Edge Function
// 客户端 WebSocket ↔ 火山 Seed 流式 ASR 双向中继（密钥仅存服务端）
// ============================================================

import WS from "ws";

const DEFAULT_RESOURCE_ID = "volc.seedasr.sauc.duration";
const DEFAULT_WS_ENDPOINT =
  "wss://openspeech.bytedance.com/api/v3/sauc/bigmodel_async";

type UpstreamAuth =
  | { mode: "app_access"; headers: Record<string, string> }
  | { mode: "api_key"; headers: Record<string, string> };

Deno.serve(async (request: Request): Promise<Response> => {
  const upgrade = request.headers.get("upgrade") ?? "";
  if (upgrade.toLowerCase() !== "websocket") {
    return new Response("Expected WebSocket upgrade", { status: 400 });
  }

  if (Deno.env.get("VOICE_TASK_MOCK") === "true") {
    const { socket, response } = Deno.upgradeWebSocket(request);
    socket.onopen = () => {
      socket.send(
        JSON.stringify({
          __tempo_mock: true,
          message: "relay mock connected",
        }),
      );
    };
    keepSocketAlive(socket);
    return response;
  }

  let auth: UpstreamAuth;
  try {
    auth = buildUpstreamAuth();
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return new Response(message, { status: 500 });
  }

  const wsEndpoint = Deno.env.get("VOLCENGINE_ASR_WS_ENDPOINT") ??
    DEFAULT_WS_ENDPOINT;
  const { socket: clientSocket, response } = Deno.upgradeWebSocket(request);
  let upstream: WS | null = null;
  let cleaned = false;
  const pendingMessages: Uint8Array[] = [];
  let clientMessages = 0;
  let upstreamMessages = 0;
  let upstreamOpened = false;

  const sendRelayStatus = (payload: Record<string, unknown>) => {
    if (clientSocket.readyState !== WebSocket.OPEN) return;
    try {
      clientSocket.send(JSON.stringify({ __relay: payload }));
    } catch {
      // ignore
    }
  };

  const cleanup = (reason?: string) => {
    if (cleaned) return;
    cleaned = true;
    console.log(
      `asr-relay summary (${auth.mode}): upstreamOpened=${upstreamOpened} ` +
        `clientMessages=${clientMessages} upstreamMessages=${upstreamMessages} ` +
        `pendingDropped=${pendingMessages.length} reason=${reason ?? "unknown"}`,
    );
    pendingMessages.length = 0;
    try {
      upstream?.close();
    } catch {
      // ignore
    }
    try {
      clientSocket.close(1011, reason);
    } catch {
      // ignore
    }
  };

  const toUint8Array = (data: unknown): Uint8Array => {
    if (data instanceof ArrayBuffer) {
      return new Uint8Array(data);
    }
    if (ArrayBuffer.isView(data)) {
      return new Uint8Array(data.buffer, data.byteOffset, data.byteLength);
    }
    if (typeof data === "string") {
      return new TextEncoder().encode(data);
    }
    throw new Error("Unsupported WebSocket payload type");
  };

  const forwardToClient = (data: WS.RawData) => {
    if (clientSocket.readyState !== WebSocket.OPEN) return;
    if (data instanceof ArrayBuffer) {
      clientSocket.send(new Uint8Array(data));
      return;
    }
    if (ArrayBuffer.isView(data)) {
      clientSocket.send(
        new Uint8Array(data.buffer, data.byteOffset, data.byteLength),
      );
      return;
    }
    clientSocket.send(data as string);
  };

  const flushPendingMessages = () => {
    if (!upstream || upstream.readyState !== WS.OPEN) return;
    const flushed = pendingMessages.length;
    while (pendingMessages.length > 0) {
      const payload = pendingMessages.shift();
      if (payload) upstream.send(payload);
    }
    if (flushed > 0) {
      console.log(`asr-relay flushed ${flushed} pending client messages`);
    }
  };

  clientSocket.onopen = () => {
    console.log(`asr-relay client open, connecting upstream (${auth.mode})`);
    upstream = new WS(wsEndpoint, { headers: auth.headers });

    upstream.on("open", () => {
      upstreamOpened = true;
      console.log(`asr-relay upstream open (${auth.mode})`);
      sendRelayStatus({
        phase: "upstream_open",
        pending: pendingMessages.length,
      });
      flushPendingMessages();
    });

    upstream.on("message", (data: WS.RawData) => {
      upstreamMessages++;
      forwardToClient(data);
    });

    upstream.on("error", (error: Error) => {
      console.error(`asr-relay upstream error (${auth.mode}):`, error.message);
      sendRelayStatus({
        phase: "upstream_error",
        message: error.message,
      });
      cleanup(`upstream error: ${error.message}`);
    });

    upstream.on("close", () => cleanup("upstream closed"));
  };

  clientSocket.onmessage = (event) => {
    if (cleaned) return;
    clientMessages++;

    let payload: Uint8Array;
    try {
      payload = toUint8Array(event.data);
    } catch (error) {
      console.error("asr-relay client payload error:", error);
      cleanup("invalid client payload");
      return;
    }

    if (!upstream || upstream.readyState !== WS.OPEN) {
      pendingMessages.push(payload);
      return;
    }

    upstream.send(payload);
  };

  clientSocket.onerror = (event) => {
    console.error("asr-relay client error:", event.message ?? "unknown");
    cleanup("client error");
  };

  clientSocket.onclose = () => cleanup("client closed");
  keepSocketAlive(clientSocket);

  return response;
});

function buildUpstreamAuth(): UpstreamAuth {
  const resourceId = Deno.env.get("VOLCENGINE_ASR_RESOURCE_ID") ??
    DEFAULT_RESOURCE_ID;
  const connectId = crypto.randomUUID();
  const sharedHeaders = {
    "X-Api-Resource-Id": resourceId,
    "X-Api-Connect-Id": connectId,
    "X-Api-Request-Id": connectId,
    "X-Api-Sequence": "-1",
  };

  const appKey = Deno.env.get("VOLCENGINE_ASR_APP_KEY")?.trim() ?? "";
  const accessKey = Deno.env.get("VOLCENGINE_ASR_ACCESS_KEY")?.trim() ?? "";
  const apiKey = Deno.env.get("VOLCENGINE_ASR_API_KEY")?.trim() ?? "";

  // 流式 ASR 应用凭证（豆包语音控制台 App ID + Access Token）优先于通用 API Key。
  if (appKey && accessKey) {
    return {
      mode: "app_access",
      headers: {
        "X-Api-App-Key": appKey,
        "X-Api-Access-Key": accessKey,
        ...sharedHeaders,
      },
    };
  }

  if (apiKey) {
    return {
      mode: "api_key",
      headers: {
        "X-Api-Key": apiKey,
        ...sharedHeaders,
      },
    };
  }

  throw new Error(
    "Missing ASR credentials: set VOLCENGINE_ASR_APP_KEY + VOLCENGINE_ASR_ACCESS_KEY, or VOLCENGINE_ASR_API_KEY",
  );
}

function keepSocketAlive(socket: WebSocket) {
  const done = new Promise<void>((resolve) => {
    socket.addEventListener("close", () => resolve(), { once: true });
  });
  // @ts-ignore Supabase Edge Runtime
  EdgeRuntime.waitUntil(done);
}
