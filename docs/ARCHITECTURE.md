# Architecture

This document defines the product and app structure that must stay stable
before shared backend work begins.

## Product Boundary

The MVP answers one question: will two people return regularly for a private
shared note and a short list of important dates?

Included in the MVP:

- Home summary
- Daily note or memory flow
- Timeline review
- Anniversary and countdown view

Explicitly excluded until later:

- Wishlist and gift ideas
- Home menu
- Shared photo albums
- Travel planning
- Conflict tools
- Broad profile customization

## Information Architecture

Primary navigation:

- `Home`: entry point, today-oriented summary, core CTA
- `Timeline`: lightweight shared note and memory stream
- `Dates`: anniversaries and countdowns

Secondary pages:

- `Ideas backlog`: holds non-MVP modules without promoting them to first-class navigation
- `Space settings`: holds static relationship settings, privacy notes, and later account controls

Rule:

- A screen may live in primary navigation only if it contributes directly to the MVP loop.

## App Layers

- `lib/app/`: app shell, theme, and top-level routing
- `lib/features/home/`: today summary and CTA
- `lib/features/timeline/`: daily note and memory review
- `lib/features/anniversaries/`: dates and countdown presentation
- `lib/features/profile/`: relationship settings and privacy policies
- `lib/features/wishlist/`: backlog ideas kept out of the MVP path
- `lib/shared/widgets/`: reusable display components

## Couple Space Lifecycle

The shared data model is based on exactly one private couple space with exactly
two active members.

Lifecycle rules:

1. One signed-in user creates the couple space.
2. That user generates an invite for the second user.
3. The second user joins the existing couple space through that invite.
4. Once two active members exist, no further members can join.
5. Either member can trigger an unlink request, but destructive deletion should
   require explicit confirmation.

## Privacy Rules

- Shared content is private by default and never public.
- Lock-screen notifications must stay generic until users opt into previews.
- Shared data access must always be scoped to the active couple space.
- Export should be available before destructive deletion.
- Unlinking a relationship should stop future shared access immediately, even if
  data retention is deferred by policy.

## Reliability Expectations

These expectations begin with the first shared alpha, not as late polish:

- Shared reads and writes need visible loading, empty, and error states.
- Failed sync should preserve local intent and explain next steps.
- Conflict-prone fields should prefer simple models such as append-only notes or
  last-write metadata with audit timestamps.

## Non-Goals

- Support for more than one couple space per user in the MVP
- Public discovery, content feeds, or analytics-first product loops
- Large module expansion before retention and privacy trust are validated
