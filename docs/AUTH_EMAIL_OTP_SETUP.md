# Supabase Email OTP Setup

This note covers only the current Email OTP login path for Between Us.

## Repo state

- Flutter sends email OTP with `Supabase.instance.client.auth.signInWithOtp(email: ...)`.
- Flutter verifies the 6-digit code with `verifyOTP(email: ..., token: ..., type: OtpType.email)`.
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

## What this repo can and cannot prove today

Confirmed from code/config:

- The app is wired for Email OTP, not magic-link redirect login.
- The local Supabase template now renders a 6-digit token as the primary email content.

Not confirmed from this repo alone:

- Which hosted Supabase project URL and client key should be used for integration
- Whether the hosted project has custom SMTP enabled
- Whether the hosted template has already been changed to `{{ .Token }}`
- Whether the hosted project is still using the default test-email sender

## Verification steps for the product manager session

Use the target hosted Supabase project and verify these facts directly:

1. Send an Email OTP to a real inbox from the Dashboard-authenticated project.
2. Confirm the received email shows a 6-digit code rendered from `{{ .Token }}`.
3. Confirm the email is delivered by the configured SMTP provider, not the default test sender.
4. Launch Flutter with the hosted `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
5. Complete `signInWithOtp -> verifyOTP(type: email)` end-to-end inside the app.
