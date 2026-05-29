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

## Current scope boundary

This is intentionally a minimal cleanup strategy:

- no Flutter login-flow changes
- no delayed-profile-creation redesign
- no custom OTP service
- no full account lifecycle system

If the team later wants automatic cleanup, the same function can be called by a service-role maintenance job or a scheduled backend task without changing the app login flow.
