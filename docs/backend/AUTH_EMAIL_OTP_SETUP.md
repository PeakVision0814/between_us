# Supabase OTP Auth Setup

This note covers the current Email OTP path and the reserved Phone OTP code
path for Between Us.

## Repo state

- Flutter sends email OTP with `Supabase.instance.client.auth.signInWithOtp(email: ...)`.
- Flutter verifies the 6-digit code with `verifyOTP(email: ..., token: ..., type: OtpType.email)`.
- Flutter now also reserves Phone OTP calls:
  - Sign in: `signInWithOtp(phone: ..., shouldCreateUser: false)`
  - Sign up: `signInWithOtp(phone: ..., shouldCreateUser: true)`
  - Verify: `verifyOTP(phone: ..., token: ..., type: OtpType.sms)`
- Logged-in credential binding is reserved through Supabase Auth native user
  update flows:
  - Bind / change phone: `updateUser(UserAttributes(phone: ...))`
  - Verify phone change: `verifyOTP(phone: ..., token: ..., type: OtpType.phoneChange)`
  - Bind / change email: `updateUser(UserAttributes(email: ...))`
  - Verify email change when the project uses in-app OTP confirmation:
    `verifyOTP(email: ..., token: ..., type: OtpType.emailChange)`
- Recovery email is intentionally separate from Supabase Auth login email:
  - Request from Flutter: `functions.invoke('send-recovery-email-otp', body: { email })`
  - Verify: `rpc('verify_recovery_email_change', p_token)`
  - Storage: visible state in `profiles.recovery_email*`, OTP challenge state
    in `private.account_recovery_email_challenges`
  - Local delivery: the Edge Function sends the OTP to Supabase local Inbucket.
  - It does not call `updateUser(UserAttributes(email: ...))` and does not
    write `auth.users.email`.
- Phone numbers are lightly validated as E.164 strings, for example `+8613812345678`.
- Local Supabase CLI config now pins the `magic_link` email template to `supabase/templates/magic_link.html`, and that template renders `{{ .Token }}` as the primary content.
- The checked-in Flutter defaults still point to the local emulator:
  - `SUPABASE_URL` default: `http://10.0.2.2:54321`
  - `SUPABASE_ANON_KEY` default: local publishable key in `lib/app/supabase_config.dart`

## Real environment checklist

Hosted Supabase Auth email settings are not versioned in this repo. They must be checked in the Supabase Dashboard or via the Management API for the target project.

Required hosted settings:

1. Auth -> Providers -> Email
   - Email provider enabled
   - Passwordless / OTP email sign-in enabled for the project
2. Auth -> Email Templates -> Magic Link
   - The template must render `{{ .Token }}`
   - Do not leave the template as only `{{ .ConfirmationURL }}`
   - The current product login flow expects users to type a 6-digit code inside the app, not click a magic link
3. Auth -> SMTP Settings
   - Custom SMTP enabled
   - Valid SMTP host, port, username, password or API key, sender email, and sender name configured
   - A sender domain/provider that can deliver to real inboxes is configured
4. Auth -> Providers -> Phone
   - Phone provider enabled before private Beta phone testing
   - A Supabase SMS Provider configured, or a Send SMS Hook configured
   - For mainland China private testing, prefer Send SMS Hook connected to a
     domestic SMS provider such as Aliyun SMS or Tencent Cloud SMS

## Default test-email limitation

If the hosted project is still using Supabase's default built-in mailer instead of custom SMTP, it is still under the default test-email restriction and is not ready for real user email delivery. Treat that state as not production-ready for Email OTP login.

## Frontend integration parameters

For real environment testing, Flutter must be launched with the hosted project values instead of the local emulator defaults.

Example:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<publishable-or-anon-client-key>
```

Notes:

- `lib/app/supabase_config.dart` reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from Dart defines.
- The variable name is `SUPABASE_ANON_KEY`, but the current checked-in default value is a publishable-style key. For hosted testing, pass the project's client-safe key through that same define.
- If these defines are omitted, the app talks to the local Supabase emulator and cannot verify hosted SMTP delivery.

## Phone OTP delivery boundary

The current development stage does not connect a real SMS Provider. Real SMS
testing creates provider cost and operational work, so phone delivery is
intentionally deferred until before private Beta.

This repo keeps the Supabase Phone OTP call chain reserved:

- Sign-in still calls `signInWithOtp(phone: ..., shouldCreateUser: false)`.
- Sign-up still calls `signInWithOtp(phone: ..., shouldCreateUser: true)`.
- Phone-code verification still uses `verifyOTP(phone: ..., type: OtpType.sms)`.
- Bind / change phone still uses `updateUser(UserAttributes(phone: ...))` and
  `verifyOTP(phone: ..., type: OtpType.phoneChange)`.

During development and QA, Phone OTP can verify:

- 11-digit mainland China phone input validation.
- Conversion from `13812345678` to `+8613812345678` before Supabase calls.
- Sign-in, registration, bind, and change-phone UI/state flows.
- The boundary where Flutter asks Supabase Auth to send or verify a phone OTP.
- User-facing error copy when sending fails.

During development and QA, Phone OTP cannot verify:

- Real SMS delivery to a handset.
- Domestic SMS signature and template approval.
- SMS cost.
- Provider rate limiting and failure callbacks.
- Private Beta success rate for real phone-code receipt.

Before private Beta, the team must add and validate:

- Supabase Phone Auth delivery through either an SMS Provider or Send SMS Hook.
- A domestic SMS provider choice for mainland China testing.
- Approved SMS signature and message templates.
- Real-phone E2E acceptance for sign-in, registration, bind, and change-phone.
- Cost, quota, rate-limit, retry, and failure-handling policy.

The Flutter client must not hold Aliyun SMS, Tencent Cloud SMS, Twilio, or other
SMS provider secrets. It must not add provider SDKs for direct client-side SMS
delivery. It must not build a custom client verification-code system or bypass
Supabase Auth with locally generated codes.

When phone sending fails in this stage, the product copy should avoid promising
that a code was delivered. The Chinese fallback is:
`手机号验证码暂时无法发送。当前环境可能尚未配置短信服务，请稍后重试或改用邮箱。`

The English fallback is:
`Phone code could not be sent. SMS delivery may not be configured for this environment. Try again later or use email.`

Real SMS delivery depends on configuring Supabase Phone Auth for the target
hosted project before private Beta. Use either Supabase's supported SMS Provider
configuration or a Send SMS Hook. For domestic private testing in China, the
recommended follow-up is Send SMS Hook plus Aliyun SMS, Tencent Cloud SMS, or a
similar domestic provider configured outside the Flutter client.

## Registration, sign-in, and binding boundaries

- Registration creates a new Supabase `auth.users.id`.
- Sign-in uses an existing email or phone credential already attached to one
  `auth.users.id`.
- Binding runs only after the user is signed in and adds another credential to
  that same current `auth.users.id`.
- Binding does not merge two existing accounts. If the target email or phone is
  already owned by another Supabase user, the app must stop and show a conflict
  message.
- Login credentials are account security information. They are not shared with
  the partner profile and should not be exposed through couple-space profile
  reads.
- Recovery email is account security information, not a login credential in
  this version. It is verified before becoming effective and is not shared with
  the partner profile by default.

## Recovery email delivery boundary

Recovery email OTP is a server-side request / verify flow. It is separate from
Supabase Auth's login email OTP:

- Login email OTP uses Supabase Auth (`signInWithOtp` / `verifyOTP`) and can
  sign the user in.
- Recovery email OTP verifies `profiles.recovery_email` only. It never becomes
  `auth.users.email`, never signs the user in, and never changes login
  credentials.

Current behavior:

- Flutter calls `send-recovery-email-otp` instead of directly calling
  `request_recovery_email_change`.
- The Edge Function verifies the current JWT with `auth.getUser`; it rejects
  caller-supplied `user_id` / `userId`.
- The Edge Function uses the service role key server-side to call
  `create_recovery_email_challenge_for_service(p_user_id, p_email)`.
- PostgreSQL generates a short-lived 6-digit token.
- `private.account_recovery_email_challenges.otp_hash` stores only a SHA-256
  hash.
- `private.account_recovery_email_challenges.expires_at` expires the token
  after 15 minutes.
- The private challenge table is revoked from `anon` and `authenticated`;
  Flutter cannot read token hashes through the Supabase Data API.
- `get_my_profile()` returns recovery email state and pending email. It does
  not return token hash, plaintext token, or challenge expiration.
- The public `request_recovery_email_change(p_email)` RPC still does not return
  plaintext token. It exists as a no-token compatibility path, but Flutter's
  product flow uses the Edge Function so the token can be mailed.
- The Edge Function response to Flutter returns only `{ ok,
  recovery_email_pending, expires_at }`; it never returns `token`.
- The RPC does not write plaintext tokens to database logs.

Local development delivery:

- Supabase local Inbucket Web UI: `http://127.0.0.1:54324/`
- The local Supabase mail container currently runs Mailpit. Its Web UI is
  exposed on host port `54324`, while its SMTP listener is reachable from Edge
  Runtime on the Docker network as `inbucket:1025`.
- `supabase/config.toml` also enables `smtp_port = 54325` under `[inbucket]`
  for host-side local tools after a full local stack restart, but the Edge
  Function itself does not depend on that host port.
- `send-recovery-email-otp` sends SMTP to
  `RECOVERY_EMAIL_SMTP_HOST` / `RECOVERY_EMAIL_SMTP_PORT`.
- Defaults are `inbucket:1025`, matching the current Supabase Docker network
  service discovered from the local container config.
- The Edge Function is covered by the repo-level `deno.json`. In an environment
  with Deno installed, run `deno task check:functions` and
  `deno task test:functions`; VS Code is scoped to enable Deno only for
  `supabase/functions`.
- To complete the flow locally: request the auxiliary email code in Flutter,
  open `http://127.0.0.1:54324/`, read the 6-digit code, and type it into the
  app's auxiliary email verification step.

Before private Beta:

- Replace local Inbucket SMTP with a real server-side delivery provider, such
  as hosted SMTP, Resend, SendGrid, or another approved mail service.
- Store SMTP / Resend / SendGrid / other mail-provider secrets only in
  Supabase Edge Function secrets or the server environment.
- Do not put mail-provider credentials or real token generation in Flutter.
- Do not reintroduce permanent plaintext token logging for private Beta or
  production.
- Future account recovery should start from verified `profiles.recovery_email`;
  this field still must not become the Auth login email implicitly.

## Account deletion boundary

The current Flutter client only exposes the account-deletion product entry and
state rules inside Account & security. It does not delete Supabase Auth users.

- If the current user still has an active couple space, the app blocks deletion
  and guides them to the existing Space status / exit couple space flow.
- If the current user is in single mode, the app shows two confirmations and
  then explains that deletion will be completed after server-side deletion
  capability is added.
- The Flutter client must not hold a service role key or secret key.
- The Flutter client must not call Auth Admin `deleteUser`.
- Historical shared data is not batch-deleted by the client.

Real account deletion must be implemented server-side with an explicit Auth
Admin capability, session handling, audit/confirmation rules, and a clear shared
data retention policy.

## What this repo can and cannot prove today

Confirmed from code/config:

- The app is wired for Email OTP, not magic-link redirect login.
- The app has a reserved Phone OTP frontend path using Supabase Auth's phone
  OTP methods.
- The app has a reserved account security path for binding email and phone to
  the current Supabase Auth user through native update-user flows.
- The app has a recovery email request / verify path backed by an Edge Function,
  `profiles` visible state, a private OTP challenge table, and RPCs. Recovery
  email is not a login method in this version.
- The app has a deletion entry and confirmation rules, but does not perform
  real Supabase Auth user deletion.
- The local Supabase template now renders a 6-digit token as the primary email content.

Not confirmed from this repo alone:

- Which hosted Supabase project URL and client key should be used for integration
- Whether the hosted project has custom SMTP enabled
- Whether the hosted template has already been changed to `{{ .Token }}`
- Whether the hosted project is still using the default test-email sender
- Whether the hosted project has Phone Auth enabled
- Which SMS Provider or Send SMS Hook will deliver real phone codes
- Whether hosted email-change confirmation is configured for OTP input inside
  the app, or for email-link confirmation in the mailbox
- Whether recovery email delivery has been connected to a production mail sender
  before private Beta. Local development uses Inbucket only.

## Verification steps for the product manager session

Use the target hosted Supabase project and verify these facts directly:

1. Send an Email OTP to a real inbox from the Dashboard-authenticated project.
2. Confirm the received email shows a 6-digit code rendered from `{{ .Token }}`.
3. Confirm the email is delivered by the configured SMTP provider, not the default test sender.
4. Launch Flutter with the hosted `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
5. Complete `signInWithOtp -> verifyOTP(type: email)` end-to-end inside the app.
6. Before private Beta, enable Phone Auth, configure SMS delivery, then complete
   `signInWithOtp(phone: ...) -> verifyOTP(type: sms)` end-to-end inside the app.
7. While signed in with an email-only account, bind a phone number and confirm
   it remains the same `auth.users.id`.
8. While signed in with a phone-only account, bind an email address and confirm
   it remains the same `auth.users.id`.
9. Try binding an email or phone already owned by another account and confirm
   the app blocks the operation without merging accounts.
10. Request a recovery email change in Flutter, open
    `http://127.0.0.1:54324/`, copy the Inbucket code, verify it in the app,
    and confirm the email becomes verified without changing the Supabase Auth
    login email.
