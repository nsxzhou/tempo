import { createClient } from "https://esm.sh/@supabase/supabase-js@2.48.1";

type DatabaseTask = {
  id: string;
  user_id: string;
  title: string;
  due_date: string | null;
  is_all_day: boolean;
  is_completed: boolean;
  recurrence_rule: string | null;
  recurrence_end: string | null;
  recurrence_count: number | null;
};

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

type ReminderCandidate = {
  task: DatabaseTask;
  occurrenceDate: string | null;
  title: string;
  reminderAtUtc: Date;
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
        const inserted = await insertDelivery(supabase, device, candidate);
        if (!inserted) {
          skipped++;
          continue;
        }

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
      }
    }

    return json({ sent, skipped, failed, devices: devices?.length ?? 0 });
  } catch (error) {
    return json({
      error: error instanceof Error ? error.message : String(error),
    }, 500);
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

function minuteWindowForDevice(now: Date, timezone: string) {
  const local = localParts(now, timezone);
  const startUtc = localDateToUtc(
    local.year,
    local.month,
    local.day,
    local.hour,
    local.minute,
    0,
    timezone,
  );
  const endUtc = new Date(startUtc.getTime() + 60_000);
  const localDate = formatLocalDate(local.year, local.month, local.day);
  return { local, localDate, startUtc, endUtc, timezone };
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

  const taskIds = ((recurringTasks ?? []) as DatabaseTask[]).map((task) =>
    task.id
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
    ((completions ?? []) as Completion[]).map((c) =>
      `${c.task_id}:${c.occurrence_date}`
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
      exception,
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

function reminderAtForTask(task: DatabaseTask, timezone: string): Date {
  const due = new Date(task.due_date!);
  const local = localParts(due, timezone);
  if (task.is_all_day) {
    return localDateToUtc(local.year, local.month, local.day, 8, 0, 0, timezone);
  }
  return due;
}

function reminderAtForOccurrence(
  task: DatabaseTask,
  localDate: string,
  timezone: string,
  exception?: Exception,
): Date {
  if (exception?.override_due) return new Date(exception.override_due);

  const [year, month, day] = localDate.split("-").map(Number);
  if (task.is_all_day) {
    return localDateToUtc(year, month, day, 8, 0, 0, timezone);
  }

  const due = new Date(task.due_date!);
  const dueLocal = localParts(due, timezone);
  return localDateToUtc(
    year,
    month,
    day,
    dueLocal.hour,
    dueLocal.minute,
    dueLocal.second,
    timezone,
  );
}

function occurrenceForLocalDate(
  task: DatabaseTask,
  localDate: string,
  timezone: string,
): boolean {
  const due = new Date(task.due_date!);
  const dueLocal = localParts(due, timezone);
  const startDate = formatLocalDate(dueLocal.year, dueLocal.month, dueLocal.day);
  if (localDate < startDate) return false;
  if (task.recurrence_end && localDate > task.recurrence_end.slice(0, 10)) {
    return false;
  }

  const days = daysBetween(startDate, localDate);
  const rule = parseRrule(task.recurrence_rule ?? "");
  const interval = Number(rule.get("INTERVAL") ?? "1");
  if (!Number.isFinite(interval) || interval <= 0) return false;

  if (task.recurrence_count != null) {
    const occurrenceIndex = recurrenceIndex(
      startDate,
      localDate,
      rule,
      interval,
    );
    if (occurrenceIndex == null || occurrenceIndex >= task.recurrence_count) {
      return false;
    }
  }

  const freq = rule.get("FREQ");
  if (freq === "DAILY") {
    return days % interval === 0;
  }
  if (freq === "WEEKLY") {
    if (days < 0 || Math.floor(days / 7) % interval !== 0) return false;
    const byday = rule.get("BYDAY");
    const weekdays = byday
      ? byday.split(",")
      : [weekdayTokenForDate(startDate)];
    return weekdays.includes(weekdayTokenForDate(localDate));
  }
  if (freq === "MONTHLY") {
    const [sy, sm, sd] = startDate.split("-").map(Number);
    const [y, m, d] = localDate.split("-").map(Number);
    const monthDelta = (y - sy) * 12 + (m - sm);
    const bymonthday = rule.get("BYMONTHDAY");
    const monthDays = bymonthday
      ? bymonthday.split(",").map(Number)
      : [sd];
    return monthDelta >= 0 &&
      monthDelta % interval === 0 &&
      monthDays.includes(d);
  }
  return false;
}

function recurrenceIndex(
  startDate: string,
  localDate: string,
  rule: Map<string, string>,
  interval: number,
): number | null {
  const freq = rule.get("FREQ");
  if (freq === "DAILY") return Math.floor(daysBetween(startDate, localDate) / interval);
  if (freq === "WEEKLY") {
    return Math.floor(daysBetween(startDate, localDate) / 7 / interval);
  }
  if (freq === "MONTHLY") {
    const [sy, sm] = startDate.split("-").map(Number);
    const [y, m] = localDate.split("-").map(Number);
    return Math.floor(((y - sy) * 12 + (m - sm)) / interval);
  }
  return null;
}

function parseRrule(rrule: string): Map<string, string> {
  const map = new Map<string, string>();
  for (const part of rrule.split(";")) {
    const [key, value] = part.split("=");
    if (key && value) map.set(key, value);
  }
  return map;
}

async function insertDelivery(
  supabase: ReturnType<typeof createClient>,
  device: NotificationDevice,
  candidate: ReminderCandidate,
): Promise<boolean> {
  const { error } = await supabase.from("notification_deliveries").insert({
    device_id: device.id,
    task_id: candidate.task.id,
    occurrence_date: candidate.occurrenceDate,
    reminder_at: candidate.reminderAtUtc.toISOString(),
    status: "pending",
  });
  if (!error) return true;
  if (String(error.code) === "23505") return false;
  throw error;
}

async function markDeliveryFailed(
  supabase: ReturnType<typeof createClient>,
  device: NotificationDevice,
  candidate: ReminderCandidate,
  error: string,
) {
  await supabase
    .from("notification_deliveries")
    .update({ status: "failed", error })
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
    .update({ status: "sent", error: null })
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
        "authorization": `Bearer ${accessToken}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: device.fcm_token,
          notification: {
            title: "待办提醒",
            body: candidate.title,
          },
          data: {
            taskId: candidate.task.id,
            occurrenceDate: candidate.occurrenceDate ?? "",
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
  return status === 404 ||
    body.includes("UNREGISTERED") ||
    body.includes("INVALID_ARGUMENT");
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

  const response = await fetch(account.token_uri ?? "https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!response.ok) {
    throw new Error(`FCM token request failed: ${response.status} ${await response.text()}`);
  }
  const body = await response.json() as { access_token: string; expires_in: number };
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
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : new Uint8Array(input);
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function localParts(date: Date, timezone: string) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  }).formatToParts(date);
  const part = (type: string) => Number(parts.find((p) => p.type === type)?.value);
  return {
    year: part("year"),
    month: part("month"),
    day: part("day"),
    hour: part("hour"),
    minute: part("minute"),
    second: part("second"),
  };
}

function localDateToUtc(
  year: number,
  month: number,
  day: number,
  hour: number,
  minute: number,
  second: number,
  timezone: string,
): Date {
  const utcGuess = Date.UTC(year, month - 1, day, hour, minute, second);
  const offset = timezoneOffsetMillis(new Date(utcGuess), timezone);
  return new Date(utcGuess - offset);
}

function timezoneOffsetMillis(date: Date, timezone: string): number {
  const parts = localParts(date, timezone);
  const localAsUtc = Date.UTC(
    parts.year,
    parts.month - 1,
    parts.day,
    parts.hour,
    parts.minute,
    parts.second,
  );
  return localAsUtc - date.getTime();
}

function formatLocalDate(year: number, month: number, day: number): string {
  return `${year.toString().padStart(4, "0")}-${
    month.toString().padStart(2, "0")
  }-${day.toString().padStart(2, "0")}`;
}

function daysBetween(startDate: string, endDate: string): number {
  const [sy, sm, sd] = startDate.split("-").map(Number);
  const [ey, em, ed] = endDate.split("-").map(Number);
  return Math.floor(
    (Date.UTC(ey, em - 1, ed) - Date.UTC(sy, sm - 1, sd)) / 86_400_000,
  );
}

function weekdayTokenForDate(localDate: string): string {
  const [year, month, day] = localDate.split("-").map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  return ["SU", "MO", "TU", "WE", "TH", "FR", "SA"][date.getUTCDay()];
}

function isInWindow(date: Date, start: Date, end: Date): boolean {
  return date.getTime() >= start.getTime() && date.getTime() < end.getTime();
}
