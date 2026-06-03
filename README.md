# Between Us

[Chinese (Simplified)](README.zh-CN.md)

Between Us is a private-first mobile app for two people in a relationship.
The current product direction is a lightweight shared life space: one place for
the couple to check home status, manage a calendar, keep plans and casual
notes, and maintain shared "we" settings.

## Product Focus

- Build a real mobile app, not a web wrapper.
- Keep the MVP centered on four core surfaces: `Home`, `Calendar`,
  `Plans & Notes`, and `We`.
- Make the product feel like a calm shared life space instead of a heavy task
  tool or a pressure-driven diary.
- Default to Simplified Chinese for the real target users, while keeping
  English as an optional language setting.
- Support system, light, and dark themes as first-class product behavior.
- Validate retention before adding extra modules.
- Treat privacy, ownership, and deletion rules as product requirements.
- Defer lower-signal ideas until the shared foundation proves useful.

## Planned Tech Stack

- App: Flutter
- Backend: Supabase
- Database: PostgreSQL through Supabase
- Authentication: Supabase Auth
- Storage: Supabase Storage
- Target platform: Android first, iOS later

## Current Status

The repository currently contains an Android-first Flutter app with:

- Material 3 app shell
- Implemented primary navigation: `Home`, `Calendar`, `Plans & Notes`, and
  `We`
- Email OTP login with separated login and registration flows
- Post-registration profile setup for display name, gender, and optional
  birthday
- Shared Alpha on Supabase: calendar events, plans, notes, and invitations are
  wired to couple-space sync
- `AppController` as the single owner of profile state, auth state, and the
  current `spaceId`
- A unified visual system rolled out across the main app pages
- Widget tests for navigation, calendar behavior, couple-space guarding, and
  auth/session state

Run locally:

```powershell
flutter pub get
flutter test
flutter run
```

## Current MVP Definition

The current MVP centers on the logged-in shared life-space loop:

- Home shows real names, the couple overview, the latest activity preview, the
  next important date, and quick entry points.
- Calendar shows dated content such as anniversaries, date plans, and reminders.
- Plans & Notes shows undated plans and casual shared notes, backed by the
  shared couple space.
- We contains profile entry points, partner/invite entry points, shared-space
  information, and a secondary settings page.
- Solo mode can use the core content flow before pairing, then move into paired
  mode through invite codes.

Authentication, invitations, shared sync, and Row Level Security are now part of
the foundation. Future work should finish the phase 8 profile/identity closure
before moving into sensitive data or private beta work.

## Shared Foundation Rules

Shared data work must respect:

- Who creates a couple space and how the second person is invited.
- How couple membership is limited, revoked, or unlinked.
- What happens to shared data after unlinking or deletion requests.
- How export, retention, and permanent deletion are handled.
- How notifications and previews avoid leaking private content.

Those decisions now live in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and
[docs/DATABASE.md](docs/DATABASE.md).

## Backlog Modules

These are explicitly outside the focused MVP until the core loop proves useful:

- Gift ideas / wishlist
- Shared photo memories
- Reminder notifications
- Travel plans
- Home menu
- Conflict cooldown
- Personal preference notes

## Working Docs

- [docs/ROADMAP.md](docs/ROADMAP.md): phase plan and delivery checkpoints
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): product structure and rules
- [docs/DATABASE.md](docs/DATABASE.md): shared schema and access boundaries
- [docs/WORKFLOW.md](docs/WORKFLOW.md): development workflow for this repo

## License

This project is licensed under the MIT License.
