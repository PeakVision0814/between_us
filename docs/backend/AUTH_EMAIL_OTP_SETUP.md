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

This development stage only implements the Flutter product entry, pending state,
Supabase Auth API calls, and widget tests for Phone OTP. It does not add an SMS
provider SDK, does not commit provider credentials, does not implement a custom
verification-code backend, and does not generate verification codes in the
Flutter client.

Real SMS delivery depends on configuring Supabase Phone Auth for the target
hosted project before private Beta. Use either Supabase's supported SMS Provider
configuration or a Send SMS Hook. For domestic private testing in China, the
recommended follow-up is Send SMS Hook plus Aliyun SMS, Tencent Cloud SMS, or a
similar domestic provider.

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
