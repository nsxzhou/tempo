// ============================================================
// Tempo siyuan-pairing Edge Function
// 配对码验证 + 生成 session 返回 refresh_token
// 流程:
//   1. 查询 siyuan_pairing_codes 表验证 code
//   2. 检查 expires_at > now() 且 used_at IS NULL
//   3. 标记 used_at = now()
//   4. 使用 service role key 调用 admin.generateLink 生成 magiclink
//   5. 从 action_link 提取 hashed_token
//   6. 调用 GoTrue verify 端点交换 session
//   7. 返回 access_token + refresh_token + user 信息
// 环境变量:
//   SUPABASE_URL          — Supabase 项目 URL
//   SUPABASE_SERVICE_ROLE_KEY — Service Role Key (仅 Edge Function 持有)
// ============================================================

import { corsHeaders, json, requiredEnv } from "../_shared/http.ts";

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const body = await request.json() as { code?: string };
    const code = body.code?.trim();

    if (!code || !/^\d{6}$/.test(code)) {
      return json({ error: "配对码格式无效，请输入 6 位数字" }, 400);
    }

    const supabaseUrl = requiredEnv("SUPABASE_URL");
    const serviceRoleKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");

    // 1. 查询配对码
    const queryResp = await fetch(
      `${supabaseUrl}/rest/v1/siyuan_pairing_codes?code=eq.${code}&select=id,user_id,user_email,expires_at,used_at`,
      {
        headers: {
          "apikey": serviceRoleKey,
          "Authorization": `Bearer ${serviceRoleKey}`,
          "Content-Type": "application/json",
        },
      },
    );

    if (!queryResp.ok) {
      throw new Error(`查询配对码失败: ${queryResp.status}`);
    }

    const codes = await queryResp.json() as Array<{
      id: string;
      user_id: string;
      user_email: string;
      expires_at: string;
      used_at: string | null;
    }>;

    if (codes.length === 0) {
      return json({ error: "配对码无效" }, 400);
    }

    const pairingCode = codes[0];

    // 2. 检查过期
    if (new Date(pairingCode.expires_at) <= new Date()) {
      return json({ error: "配对码已过期，请重新生成" }, 400);
    }

    // 3. 检查已使用
    if (pairingCode.used_at !== null) {
      return json({ error: "配对码已使用" }, 409);
    }

    // 4. 标记已使用
    const updateResp = await fetch(
      `${supabaseUrl}/rest/v1/siyuan_pairing_codes?id=eq.${pairingCode.id}`,
      {
        method: "PATCH",
        headers: {
          "apikey": serviceRoleKey,
          "Authorization": `Bearer ${serviceRoleKey}`,
          "Content-Type": "application/json",
          "Prefer": "return=minimal",
        },
        body: JSON.stringify({ used_at: new Date().toISOString() }),
      },
    );

    if (!updateResp.ok) {
      throw new Error(`标记配对码已使用失败: ${updateResp.status}`);
    }

    // 5. 生成 Magic Link
    const linkResp = await fetch(`${supabaseUrl}/auth/v1/admin/generate_link`, {
      method: "POST",
      headers: {
        "apikey": serviceRoleKey,
        "Authorization": `Bearer ${serviceRoleKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        type: "magiclink",
        email: pairingCode.user_email,
      }),
    });

    if (!linkResp.ok) {
      const errText = await linkResp.text();
      throw new Error(`generateLink 失败: ${linkResp.status} ${errText}`);
    }

    const linkData = await linkResp.json() as Record<string, unknown>;

    const hashedToken = extractHashedToken(linkData);
    if (!hashedToken) {
      throw new Error("generateLink 响应中缺少 hashed_token");
    }

    // 6. 调用 verify 端点交换 session
    const session = await exchangeTokenForSession(
      supabaseUrl,
      serviceRoleKey,
      hashedToken,
    );

    // 7. 返回 session tokens
    return json({
      access_token: session.access_token,
      refresh_token: session.refresh_token,
      expires_in: session.expires_in,
      user_email: pairingCode.user_email,
      user_id: session.user?.id ?? pairingCode.user_id,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return json({ error: message }, 500);
  }
});

function extractHashedToken(linkData: Record<string, unknown>): string | null {
  const props = linkData.properties as Record<string, unknown> | undefined;

  const fromProps = props?.hashed_token;
  if (typeof fromProps === "string" && fromProps.length > 0) {
    return fromProps;
  }

  const flat = linkData.hashed_token;
  if (typeof flat === "string" && flat.length > 0) {
    return flat;
  }

  const actionLink =
    (typeof props?.action_link === "string" ? props.action_link : null) ??
    (typeof linkData.action_link === "string" ? linkData.action_link : null);

  if (actionLink) {
    try {
      const url = new URL(actionLink);
      return url.searchParams.get("token") ??
        url.searchParams.get("token_hash");
    } catch {
      // ignore malformed action_link
    }
  }

  return null;
}

async function exchangeTokenForSession(
  supabaseUrl: string,
  apiKey: string,
  tokenHash: string,
): Promise<{
  access_token: string;
  refresh_token: string;
  expires_in: number;
  user?: { id?: string; email?: string };
}> {
  const attempts: Array<Record<string, string>> = [
    { type: "magiclink", token: tokenHash },
    { type: "email", token_hash: tokenHash },
  ];

  let lastError = "";
  for (const body of attempts) {
    const verifyResp = await fetch(`${supabaseUrl}/auth/v1/verify`, {
      method: "POST",
      headers: {
        "apikey": apiKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });

    if (verifyResp.ok) {
      return await verifyResp.json();
    }

    lastError = await verifyResp.text();
  }

  throw new Error(`verify 失败: ${lastError}`);
}
