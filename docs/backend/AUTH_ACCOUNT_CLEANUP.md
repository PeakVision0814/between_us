# Email OTP Empty-Account Cleanup

This document covers the minimal cleanup strategy for abandoned Email OTP sign-in attempts.

## Why stale auth users appear

The current app sends Email OTP with `signInWithOtp(email: ...)` and verifies it later with a 6-digit code inside the app.

In the current backend foundation:

- `public.handle_new_user()` runs `after insert on auth.users`
- The trigger immediately creates `public.profiles`
- `public.profiles.id` references `auth.users.id` with `on delete cascade`

That means an abandoned Email OTP attempt can leave behind:

1. an `auth.users` row
2. a matching `public.profiles` row

even if the person never finishes OTP verification and never really enters the product.

## What counts as a cleanup candidate

The cleanup function only targets accounts that satisfy all of the following:

- `auth.users.email` is present
- `email_confirmed_at is null`
- `phone_confirmed_at is null`
- `last_sign_in_at is null`
- `created_at` is older than the configured grace period
- there are no references from any current business tables:
  - `couple_spaces.created_by`
  - `couple_memberships.profile_id`
  - `couple_invites.created_by`
  - `couple_invites.accepted_by`
  - `calendar_events.created_by`
  - `plans.created_by`
  - `notes.author_profile_id`

This keeps the strategy focused on “unverified and never used” accounts only.

## Implemented cleanup entry point

Migration:

- `supabase/migrations/20260528184235_cleanup_stale_unverified_auth_users.sql`

Function:

- `private.cleanup_stale_unverified_email_otp_users(p_older_than interval default '24 hours', p_limit integer default 100, p_delete boolean default false)`

Behavior:

- `p_delete = false`: preview candidates only
- `p_delete = true`: delete matching `auth.users` rows

Because `public.profiles.id -> auth.users.id` is `on delete cascade`, deleting the auth user automatically deletes the matching profile row too. No separate profile cleanup job is needed.

## How to use it

Preview first:

```sql
select *
from private.cleanup_stale_unverified_email_otp_users(
  p_older_than => interval '24 hours',
  p_limit => 100,
  p_delete => false
);
```

Delete after review:

```sql
select *
from private.cleanup_stale_unverified_email_otp_users(
  p_older_than => interval '24 hours',
  p_limit => 100,
  p_delete => true
);
```

## Why this should not delete normal users

It will not touch:

- users who finished email verification
- users who have ever signed in
- users who already created or joined a `couple_space`
- users who already created invites, plans, notes, or calendar events
- any user younger than the configured grace period

## User-initiated account deletion

The in-app "delete account" entry now uses a server-side deletion flow. The
Flutter client still owns the product confirmations, but the destructive Auth
operation is performed only by Supabase Edge Function `delete-account`.

Execution flow:

1. Flutter keeps the existing client-side guard: if the current app state says
   the user is still in an active couple space, it blocks deletion and opens the
   Space status / leave flow.
2. In solo mode, Flutter shows two confirmations.
3. Flutter invokes `delete-account` through Supabase Functions with the current
   session access token.
4. The Edge Function reads `Authorization: Bearer <access_token>` and validates
   it with Supabase Auth `getUser()`.
5. The Edge Function never accepts a caller-supplied `user_id`; it only deletes
   the user represented by the verified access token.
6. A service-role Supabase client calls `public.prepare_account_deletion(user.id)`.
7. The database re-checks whether the user is still in an active couple space.
   If so, it rejects the request with `active_couple_space_required_exit`.
8. For a solo pending space, the database marks the user's active membership as
   `left`, closes the pending `couple_space`, and revokes still-open invites
   from that solo shell.
9. The database marks `profiles.deleted_at`, anonymizes the profile display
   name, and clears nonessential profile preferences. The profile row is
   retained because existing shared-history tables intentionally use restrictive
   foreign keys to `profiles`.
10. The Edge Function calls Auth Admin `deleteUser(user.id, true)`, using
    Supabase Auth soft delete so the Auth user can no longer sign in without
    triggering a cascade that would conflict with retained shared history.
11. Flutter clears the Supabase session/local app state and returns to the
    login page.

Why this must be server-side:

- Auth Admin `deleteUser` requires privileged credentials.
- Flutter is a public client and must never contain the service role key or any
  secret key.
- The server must re-check current database state because client state can be
  stale, tampered with, or offline.

Data handling in this first version:

- Auth user: soft-deleted by Auth Admin from the Edge Function. This keeps the
  operation server-side and invalidates the account without exposing privileged
  credentials to Flutter.
- Profile: retained with `deleted_at` set, display name anonymized, avatar
  cleared, and sensitive sharing preferences disabled. It is not hard-deleted in
  this version because shared-history tables use `on delete restrict`
  references to `profiles`.
- Session: Flutter calls sign-out/clears local authenticated state after a
  successful function response.
- Active couple space: deletion is refused; the user must leave the couple
  space first.
- Solo pending space: closed, and the user's membership is marked `left`.
- Historical shared data: not batch-deleted. `couple_spaces`, `calendar_events`,
  `plans`, `notes`, `anniversaries`, `cycle_records`, and other shared business
  records are not deleted or cleared by this flow.
- Audit: `account_deletion_requests` records a deletion request lifecycle
  without storing email, phone, or other credential plaintext.

First-version non-goals:

- No batch deletion of shared history.
- No data export.
- No account recovery.
- No deletion of the partner's data.
- No multi-space history management.
- No client-side "force delete shared data" action.

Local verification notes:

- Apply migrations locally with `supabase db reset` or the project's usual local
  migration workflow.
- Serve the function with `supabase functions serve delete-account --env-file <local-env-file>`.
- Required secrets are `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and
  `SUPABASE_SERVICE_ROLE_KEY`; on hosted Supabase they must be stored as
  Supabase function secrets, not in Flutter.
- SQL validation should confirm that `public.prepare_account_deletion` rejects
  active couple spaces, only closes the caller's own solo pending space, and
  marks only the caller's profile as deleted.

## Current scope boundary

This is intentionally a minimal cleanup strategy:

- no Flutter login-flow changes
- no delayed-profile-creation redesign
- no custom OTP service
- no full account lifecycle system beyond first-version user deletion
- no client-side Auth Admin deletion

If the team later wants automatic cleanup, the same function can be called by a service-role maintenance job or a scheduled backend task without changing the app login flow.
