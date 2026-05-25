# Database

This document outlines the initial shared schema and the access rules required
before Supabase integration starts.

## Design Principles

- Every shared row belongs to exactly one `couple_space`.
- Every shared query must be filtered by couple-space membership.
- A couple space may have at most two active members.
- Destructive deletion must follow explicit product rules, not implicit cascade behavior.
- Export and unlink behavior must be documented before launch.

## Core Tables

### `profiles`

Purpose:

- Stores per-user display data tied to `auth.users`.

Suggested fields:

- `id uuid primary key` referencing `auth.users.id`
- `display_name text not null`
- `avatar_url text null`
- `timezone text not null`
- `created_at timestamptz not null`
- `updated_at timestamptz not null`

### `couple_spaces`

Purpose:

- Represents the single shared private space between two people.

Suggested fields:

- `id uuid primary key`
- `created_by uuid not null`
- `status text not null` with values such as `pending_partner`, `active`, `unlink_requested`, `closed`
- `created_at timestamptz not null`
- `updated_at timestamptz not null`
- `closed_at timestamptz null`

### `couple_memberships`

Purpose:

- Tracks who belongs to a couple space and with what status.

Suggested fields:

- `id uuid primary key`
- `couple_space_id uuid not null`
- `profile_id uuid not null`
- `role text not null` with values such as `owner`, `partner`
- `status text not null` with values such as `active`, `left`, `removed`
- `joined_at timestamptz not null`
- `left_at timestamptz null`

Constraints:

- A user can have at most one active membership at a time.
- A couple space can have at most two active memberships at a time.

### `couple_invites`

Purpose:

- Manages onboarding of the second member.

Suggested fields:

- `id uuid primary key`
- `couple_space_id uuid not null`
- `created_by uuid not null`
- `code_hash text not null`
- `expires_at timestamptz not null`
- `accepted_by uuid null`
- `accepted_at timestamptz null`
- `revoked_at timestamptz null`

Rules:

- Only an active member can create an invite.
- Invites become invalid after acceptance, revocation, expiry, or when the space already has two active members.

### `timeline_entries`

Purpose:

- Stores lightweight daily notes and memory entries.

Suggested fields:

- `id uuid primary key`
- `couple_space_id uuid not null`
- `author_profile_id uuid not null`
- `entry_date date not null`
- `title text null`
- `body text not null`
- `created_at timestamptz not null`
- `updated_at timestamptz not null`
- `deleted_at timestamptz null`

### `anniversaries`

Purpose:

- Stores important shared dates and countdown metadata.

Suggested fields:

- `id uuid primary key`
- `couple_space_id uuid not null`
- `created_by uuid not null`
- `title text not null`
- `event_date date not null`
- `recurrence text not null` with values such as `yearly`, `once`
- `reminder_days_before integer[] not null default '{}'`
- `created_at timestamptz not null`
- `updated_at timestamptz not null`
- `deleted_at timestamptz null`

## Row Level Security Direction

RLS rules should enforce these principles:

- A user can read their own `profiles` row only.
- A user can read a `couple_space` only if they have an active membership in it.
- A user can read or write `timeline_entries` and `anniversaries` only if they are an active member of the owning couple space.
- Invite creation, revocation, and acceptance must check membership status and two-member limits.
- Closed or unlinked spaces should deny new writes unless a dedicated recovery flow exists.

## Invite Flow Rules

1. User A signs in and creates a couple space.
2. User A becomes the `owner` active member.
3. User A creates an invite with expiry.
4. User B redeems the invite and becomes the `partner` active member.
5. The invite is marked used and the space becomes `active`.

Failure cases that must be handled:

- Invite expired
- Invite revoked
- User already belongs to another active couple space
- Target couple space already has two active members

## Unlink, Export, And Deletion Rules

- Unlink should immediately remove future shared access for the removed member.
- Data export should happen before permanent deletion is offered.
- Permanent deletion should be explicit and auditable, not an accidental side effect of unlink.
- Soft-delete fields such as `deleted_at` are preferred during early rollout so mistakes can be reviewed safely.

Open product decision:

- Whether unlink preserves a read-only export window for both members before final deletion.

## Notifications And Privacy Safety

- Notification payloads should avoid embedding sensitive message text by default.
- Lock-screen previews should remain generic unless both users explicitly opt in.
- Backend functions that generate reminders must respect couple-space membership at send time, not only at schedule time.
