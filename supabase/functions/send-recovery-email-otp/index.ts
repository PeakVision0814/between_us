import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type JsonBody = Record<string, unknown>;

type SmtpMessage = {
  host: string;
  port: number;
  fromEmail: string;
  fromName: string;
  toEmail: string;
  subject: string;
  text: string;
};

function json(status: number, body: JsonBody): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

async function parseBody(request: Request): Promise<JsonBody> {
  const contentType = request.headers.get("content-type") ?? "";
  if (!contentType.includes("application/json")) {
    return {};
  }

  try {
    const parsed = await request.json();
    return parsed && typeof parsed === "object" && !Array.isArray(parsed)
      ? parsed as JsonBody
      : {};
  } catch {
    return {};
  }
}

function isSafeEmailAddress(email: string): boolean {
  return /^[^<>\s@]+@[^<>\s@]+\.[^<>\s@]+$/.test(email);
}

function normalizeEmail(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const email = value.trim().toLowerCase();
  return isSafeEmailAddress(email) ? email : null;
}

function env(name: string, fallback?: string): string | null {
  const value = Deno.env.get(name)?.trim();
  return value && value.length > 0 ? value : fallback ?? null;
}

function recoveryEmailErrorCode(message: string): string {
  const normalized = message.toLowerCase();
  if (normalized.includes("invalid_email")) return "invalid_email";
  if (normalized.includes("same_recovery_email")) return "same_recovery_email";
  if (normalized.includes("recovery_email_in_use")) return "recovery_email_in_use";
  if (normalized.includes("account_deleted")) return "account_deleted";
  if (normalized.includes("not_authenticated")) return "not_authenticated";
  return "recovery_email_send_failed";
}

function recoveryEmailStatus(code: string): number {
  if (code === "invalid_email" || code === "same_recovery_email") return 400;
  if (code === "not_authenticated") return 401;
  if (code === "account_deleted") return 403;
  if (code === "recovery_email_in_use") return 409;
  return 500;
}

function dotStuff(message: string): string {
  return message
    .replace(/\r?\n/g, "\r\n")
    .split("\r\n")
    .map((line) => line.startsWith(".") ? `.${line}` : line)
    .join("\r\n");
}

async function sendSmtpMail(message: SmtpMessage): Promise<void> {
  const conn = await Deno.connect({
    hostname: message.host,
    port: message.port,
  });
  const reader = conn.readable.getReader();
  const writer = conn.writable.getWriter();
  const encoder = new TextEncoder();
  const decoder = new TextDecoder();
  let buffer = "";

  async function write(value: string): Promise<void> {
    await writer.write(encoder.encode(value));
  }

  async function readLine(): Promise<string> {
    while (true) {
      const newlineIndex = buffer.indexOf("\n");
      if (newlineIndex >= 0) {
        const line = buffer.slice(0, newlineIndex + 1);
        buffer = buffer.slice(newlineIndex + 1);
        return line.replace(/\r?\n$/, "");
      }

      const { value, done } = await reader.read();
      if (done) {
        throw new Error("smtp_connection_closed");
      }
      buffer += decoder.decode(value, { stream: true });
    }
  }

  async function readResponse(expectedPrefix: string): Promise<void> {
    let lastLine = "";
    while (true) {
      lastLine = await readLine();
      if (/^\d{3} /.test(lastLine)) {
        break;
      }
    }
    if (!lastLine.startsWith(expectedPrefix)) {
      throw new Error(`smtp_unexpected_response:${lastLine}`);
    }
  }

  async function command(value: string, expectedPrefix: string): Promise<void> {
    await write(`${value}\r\n`);
    await readResponse(expectedPrefix);
  }

  const safeFromName = message.fromName.replace(/[\r\n]/g, " ").trim();
  const safeSubject = message.subject.replace(/[\r\n]/g, " ").trim();
  const data = [
    `From: ${safeFromName} <${message.fromEmail}>`,
    `To: <${message.toEmail}>`,
    `Subject: ${safeSubject}`,
    "MIME-Version: 1.0",
    'Content-Type: text/plain; charset="UTF-8"',
    "Content-Transfer-Encoding: 8bit",
    "",
    message.text,
  ].join("\r\n");

  try {
    await readResponse("220");
    await command("EHLO between-us.local", "250");
    await command(`MAIL FROM:<${message.fromEmail}>`, "250");
    await command(`RCPT TO:<${message.toEmail}>`, "250");
    await command("DATA", "354");
    await write(`${dotStuff(data)}\r\n.\r\n`);
    await readResponse("250");
    await command("QUIT", "221");
  } finally {
    writer.releaseLock();
    reader.releaseLock();
    conn.close();
  }
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json(405, { code: "method_not_allowed" });
  }

  const body = await parseBody(request);
  if ("user_id" in body || "userId" in body) {
    return json(400, { code: "user_id_not_allowed" });
  }

  const email = normalizeEmail(body.email);
  if (!email) {
    return json(400, { code: "invalid_email" });
  }

  const supabaseUrl = env("SUPABASE_URL");
  const anonKey = env("SUPABASE_ANON_KEY");
  const serviceRoleKey = env("SUPABASE_SERVICE_ROLE_KEY");
  const smtpHost = env("RECOVERY_EMAIL_SMTP_HOST", "inbucket");
  const smtpPort = Number(env("RECOVERY_EMAIL_SMTP_PORT", "1025"));
  const fromEmail = env("RECOVERY_EMAIL_FROM", "no-reply@between-us.local");
  const fromName = env("RECOVERY_EMAIL_FROM_NAME", "Between Us");

  if (
    !supabaseUrl ||
    !anonKey ||
    !serviceRoleKey ||
    !smtpHost ||
    !fromEmail ||
    !isSafeEmailAddress(fromEmail) ||
    !fromName ||
    !Number.isInteger(smtpPort)
  ) {
    console.error("[send-recovery-email-otp] Missing environment");
    return json(500, { code: "server_not_configured" });
  }

  const authorization = request.headers.get("authorization") ?? "";
  const accessToken = authorization.replace(/^Bearer\s+/i, "").trim();
  if (!accessToken) {
    return json(401, { code: "missing_authorization" });
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
    auth: { persistSession: false },
  });

  const { data: userData, error: userError } = await userClient.auth.getUser(
    accessToken,
  );
  const user = userData.user;
  if (userError || !user) {
    return json(401, { code: "invalid_authorization" });
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data, error } = await adminClient.rpc(
    "create_recovery_email_challenge_for_service",
    {
      p_user_id: user.id,
      p_email: email,
    },
  );

  if (error) {
    const code = recoveryEmailErrorCode(error.message ?? "");
    return json(recoveryEmailStatus(code), { code });
  }

  const row = Array.isArray(data) ? data[0] : data;
  const recoveryEmailPending = row?.recovery_email_pending;
  const expiresAt = row?.expires_at;
  const token = row?.token;
  if (
    typeof recoveryEmailPending !== "string" ||
    typeof expiresAt !== "string" ||
    typeof token !== "string"
  ) {
    console.error("[send-recovery-email-otp] Invalid challenge response");
    return json(500, { code: "recovery_email_send_failed" });
  }

  try {
    await sendSmtpMail({
      host: smtpHost,
      port: smtpPort,
      fromEmail,
      fromName,
      toEmail: recoveryEmailPending,
      subject: "Between Us recovery email code",
      text: [
        `Your Between Us recovery email verification code is ${token}.`,
        "",
        "This code expires in 15 minutes.",
        "If you did not request this, you can ignore this message.",
      ].join("\n"),
    });
  } catch (error) {
    console.error("[send-recovery-email-otp] SMTP delivery failed", error);
    return json(502, { code: "recovery_email_send_failed" });
  }

  return json(200, {
    ok: true,
    recovery_email_pending: recoveryEmailPending,
    expires_at: expiresAt,
  });
});
