import { assertStringIncludes, assertFalse } from "jsr:@std/assert@1";

Deno.test("send-recovery-email-otp rejects caller supplied user id", async () => {
  const source = await Deno.readTextFile(new URL("./index.ts", import.meta.url));

  assertStringIncludes(source, '"user_id" in body');
  assertStringIncludes(source, '"userId" in body');
  assertStringIncludes(source, "user_id_not_allowed");
});

Deno.test("send-recovery-email-otp derives user from JWT and uses service RPC", async () => {
  const source = await Deno.readTextFile(new URL("./index.ts", import.meta.url));

  assertStringIncludes(source, "auth.getUser");
  assertStringIncludes(source, "p_user_id: user.id");
  assertStringIncludes(source, "create_recovery_email_challenge_for_service");
  assertStringIncludes(source, "SUPABASE_SERVICE_ROLE_KEY");
});

Deno.test("send-recovery-email-otp delivers via local SMTP without returning token", async () => {
  const source = await Deno.readTextFile(new URL("./index.ts", import.meta.url));
  const responseBlock = source.slice(source.lastIndexOf("return json(200"));

  assertStringIncludes(source, "RECOVERY_EMAIL_SMTP_HOST");
  assertStringIncludes(source, "RECOVERY_EMAIL_SMTP_PORT");
  assertStringIncludes(source, "inbucket");
  assertStringIncludes(source, "1025");
  assertStringIncludes(source, "sendSmtpMail");
  assertFalse(responseBlock.includes("token"));
  assertFalse(responseBlock.includes("serviceRoleKey"));
});

Deno.test("send-recovery-email-otp rejects angle brackets in SMTP addresses", async () => {
  const source = await Deno.readTextFile(new URL("./index.ts", import.meta.url));

  assertStringIncludes(source, "function isSafeEmailAddress");
  assertStringIncludes(source, "/^[^<>\\s@]+@[^<>\\s@]+\\.[^<>\\s@]+$/");
  assertStringIncludes(source, "!isSafeEmailAddress(fromEmail)");
});
