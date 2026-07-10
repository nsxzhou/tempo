import { createClient } from "https://esm.sh/@supabase/supabase-js@2.48.1";
import {
  type DatabaseTask,
  type ReminderCandidate,
  isInWindow,
  minuteWindowForDevice,
  occurrenceForLocalDate,
  reminderAtForOccurrence,
  reminderAtForTask,
  reminderKeyFor,
} from "./reminder_core.ts";

type NotificationDevice = {
  id: string;
  user_id: string;
  fcm_token: string;
  timezone: string;
  platform: string;
};

type Completion = {
  task_id: string;
  occurrence_date: string;
};

type Exception = {
  task_id: string;
  exception_date: string;
  override_due: string | null;
  override_title: string | null;
  is_cancelled: boolean;
};

type ServiceAccount = {
  client_email: string;
  private_key: string;
  project_id: string;
  token_uri?: string;
};

const jsonHeaders = {
  "content-type": "application/json; charset=utf-8",
};

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return json({ error: "method_not_allowed" }, 405);
    }

    const cronSecret = Deno.env.get("REMINDER_CRON_SECRET");
    if (cronSecret) {
      const auth = req.headers.get("authorization") ?? "";
      if (auth !== `Bearer ${cronSecret}`) {
        return json({ error: "unauthorized" }, 401);
      }
    }

    const supabaseUrl = requiredEnv("SUPABASE_URL");
    const serviceRoleKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const now = new Date();

    const { data: devices, error: deviceError } = await supabase
      .from("notification_devices")
      .select("id,user_id,fcm_token,timezone,platform")
      .eq("enabled", true);
    if (deviceError) throw deviceError;
    if ((devices ?? []).length === 0) {
      return json({ sent: 0, skipped: 0, failed: 0, devices: 0 });
    }
    if (!Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON")) {
      return json({
        sent: 0,
        skipped: 0,
        failed: 0,
        devices: devices.length,
        disabled: "missing_firebase_service_account",
      });
    }
    const accessToken = await getFcmAccessToken();

    let sent = 0;
    let skipped = 0;
    let failed = 0;

    for (const device of (devices ?? []) as NotificationDevice[]) {
      const window = minuteWindowForDevice(now, device.timezone);
      const candidates = await loadCandidatesForDevice(
        supabase,
        device,
        window,
      );

      for (const candidate of candidates) {
        const claimed = await claimDelivery(supabase, device, candidate, now);
        if (!claimed) {
          skipped++;
          continue;
        }

        try {
          const result = await sendFcm(accessToken, device, candidate);
          if (result.ok) {
            await markDeliverySent(supabase, device, candidate);
            sent++;
          } else {
            failed++;
            await markDeliveryFailed(supabase, device, candidate, result.error);
            if (isInvalidFcmToken(result.status, result.error)) {
              await supabase
                .from("notification_devices")
                .delete()
                .eq("id", device.id);
            }
          }
        } catch (error) {
          failed++;
          await markDeliveryFailed(
            supabase,
            device,
            candidate,
            error instanceof Error ? error.message : String(error),
          );
        }
      }
    }

    return json({ sent, skipped, failed, devices: devices?.length ?? 0 });
  } catch (error) {
    return json(
      {
        error: error instanceof Error ? error.message : String(error),
      },
      500,
    );
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing environment variable: ${name}`);
  return value;
}

async function loadCandidatesForDevice(
  supabase: ReturnType<typeof createClient>,
  device: NotificationDevice,
  window: ReturnType<typeof minuteWindowForDevice>,
): Promise<ReminderCandidate[]> {
  const { data: singleTasks, error: singleError } = await supabase
    .from("tasks")
    .select(
      "id,user_id,title,due_date,is_all_day,is_completed,recurrence_rule,recurrence_end,recurrence_count",
    )
    .eq("user_id", device.user_id)
    .eq("is_completed", false)
    .is("recurrence_rule", null)
    .not("due_date", "is", null);
  if (singleError) throw singleError;

  const candidates: ReminderCandidate[] = [];
  for (const task of (singleTasks ?? []) as DatabaseTask[]) {
    const reminderAtUtc = reminderAtForTask(task, window.timezone);
    if (!isInWindow(reminderAtUtc, window.startUtc, window.endUtc)) continue;
    candidates.push({
      task,
      occurrenceDate: null,
      title: task.title,
      reminderAtUtc,
    });
  }

  const { data: recurringTasks, error: recurringError } = await supabase
    .from("tasks")
    .select(
      "id,user_id,title,due_date,is_all_day,is_completed,recurrence_rule,recurrence_end,recurrence_count",
    )
    .eq("user_id", device.user_id)
    .eq("is_completed", false)
    .not("recurrence_rule", "is", null)
    .not("due_date", "is", null);
  if (recurringError) throw recurringError;

  if ((recurringTasks ?? []).length === 0) return candidates;

  const taskIds = ((recurringTasks ?? []) as DatabaseTask[]).map(
    (task) => task.id,
  );
  const { data: completions, error: completionError } = await supabase
    .from("task_completions")
    .select("task_id,occurrence_date")
    .in("task_id", taskIds);
  if (completionError) throw completionError;
  const { data: exceptions, error: exceptionError } = await supabase
    .from("task_recurrence_exceptions")
    .select("task_id,exception_date,override_due,override_title,is_cancelled")
    .in("task_id", taskIds);
  if (exceptionError) throw exceptionError;

  const completionSet = new Set(
    ((completions ?? []) as Completion[]).map(
      (c) => `${c.task_id}:${c.occurrence_date}`,
    ),
  );
  const exceptionMap = new Map(
    ((exceptions ?? []) as Exception[]).map((e) => [
      `${e.task_id}:${e.exception_date}`,
      e,
    ]),
  );

  for (const task of (recurringTasks ?? []) as DatabaseTask[]) {
    const occurrence = occurrenceForLocalDate(
      task,
      window.localDate,
      window.timezone,
    );
    if (!occurrence) continue;
    if (completionSet.has(`${task.id}:${window.localDate}`)) continue;

    const exception = exceptionMap.get(`${task.id}:${window.localDate}`);
    if (exception?.is_cancelled) continue;

    const reminderAtUtc = reminderAtForOccurrence(
      task,
      window.localDate,
      window.timezone,
      exception?.override_due,
    );
    if (!isInWindow(reminderAtUtc, window.startUtc, window.endUtc)) continue;

    candidates.push({
      task,
      occurrenceDate: window.localDate,
      title: exception?.override_title ?? task.title,
      reminderAtUtc,
    });
  }

  return candidates;
}

async function claimDelivery(
  supabase: ReturnType<typeof createClient>,
  device: NotificationDevice,
  candidate: ReminderCandidate,
  now: Date,
): Promise<boolean> {
  const { error } = await supabase.from("notification_deliveries").insert({
    device_id: device.id,
    task_id: candidate.task.id,
    occurrence_date: candidate.occurrenceDate,
    reminder_at: candidate.reminderAtUtc.toISOString(),
    status: "pending",
  });
  if (!error) return true;
  if (String(error.code) !== "23505") throw error;

  const { data, error: claimError } = await supabase.rpc(
    "claim_notification_delivery_retry",
    {
      p_device_id: device.id,
      p_task_id: candidate.task.id,
      p_occurrence_date: candidate.occurrenceDate,
      p_reminder_at: candidate.reminderAtUtc.toISOString(),
      p_now: now.toISOString(),
    },
  );
  if (claimError) throw claimError;
  return data === true;
}

async function markDeliveryFailed(
  supabase: ReturnType<typeof createClient>,
  device: NotificationDevice,
  candidate: ReminderCandidate,
  error: string,
) {
  await supabase
    .from("notification_deliveries")
    .update({
      status: "failed",
      error,
      last_attempt_at: new Date().toISOString(),
    })
    .eq("device_id", device.id)
    .eq("task_id", candidate.task.id)
    .eq("reminder_at", candidate.reminderAtUtc.toISOString());
}

async function markDeliverySent(
  supabase: ReturnType<typeof createClient>,
  device: NotificationDevice,
  candidate: ReminderCandidate,
) {
  await supabase
    .from("notification_deliveries")
    .update({
      status: "sent",
      error: null,
      last_attempt_at: new Date().toISOString(),
    })
    .eq("device_id", device.id)
    .eq("task_id", candidate.task.id)
    .eq("reminder_at", candidate.reminderAtUtc.toISOString());
}

async function sendFcm(
  accessToken: string,
  device: NotificationDevice,
  candidate: ReminderCandidate,
) {
  const projectId = serviceAccount().project_id;
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: device.fcm_token,
          notification: {
            title: "待办提醒",
            body: candidate.title,
          },
          android: {
            notification: { tag: reminderKeyFor(candidate) },
          },
          data: {
            reminderKey: reminderKeyFor(candidate),
            taskId: candidate.task.id,
            occurrenceDate: candidate.occurrenceDate ?? "",
            reminderAt: candidate.reminderAtUtc.toISOString(),
          },
        },
      }),
    },
  );
  if (response.ok) return { ok: true as const };
  return {
    ok: false as const,
    status: response.status,
    error: await response.text(),
  };
}

function isInvalidFcmToken(status: number, body: string): boolean {
  return (
    status === 404 ||
    body.includes("UNREGISTERED") ||
    body.includes("INVALID_ARGUMENT")
  );
}

let cachedAccessToken: { token: string; expiresAt: number } | null = null;

async function getFcmAccessToken(): Promise<string> {
  if (cachedAccessToken && cachedAccessToken.expiresAt > Date.now() + 60_000) {
    return cachedAccessToken.token;
  }

  const account = serviceAccount();
  const now = Math.floor(Date.now() / 1000);
  const jwt = await signJwt(
    {
      alg: "RS256",
      typ: "JWT",
    },
    {
      iss: account.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: account.token_uri ?? "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    },
    account.private_key,
  );

  const response = await fetch(
    account.token_uri ?? "https://oauth2.googleapis.com/token",
    {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: jwt,
      }),
    },
  );
  if (!response.ok) {
    throw new Error(
      `FCM token request failed: ${response.status} ${await response.text()}`,
    );
  }
  const body = (await response.json()) as {
    access_token: string;
    expires_in: number;
  };
  cachedAccessToken = {
    token: body.access_token,
    expiresAt: Date.now() + body.expires_in * 1000,
  };
  return body.access_token;
}

function serviceAccount(): ServiceAccount {
  const raw = requiredEnv("FIREBASE_SERVICE_ACCOUNT_JSON");
  return JSON.parse(raw) as ServiceAccount;
}

async function signJwt(
  header: Record<string, unknown>,
  payload: Record<string, unknown>,
  privateKeyPem: string,
): Promise<string> {
  const encodedHeader = base64Url(JSON.stringify(header));
  const encodedPayload = base64Url(JSON.stringify(payload));
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKeyPem),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );
  return `${signingInput}.${base64Url(signature)}`;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

function base64Url(input: string | ArrayBuffer): string {
  const bytes =
    typeof input === "string"
      ? new TextEncoder().encode(input)
      : new Uint8Array(input);
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}
