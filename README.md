# Between Us

[Chinese (Simplified)](README.zh-CN.md)

Between Us is a private-first mobile app for two people in a relationship.
The product focus is intentionally narrow: give a couple one calm place to
leave today's note or memory and keep important dates visible often enough to
become part of daily life.

## Product Focus

- Build a real mobile app, not a web wrapper.
- Keep the MVP centered on one daily loop: note, memory, and dates.
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

## Current Prototype

The repository currently contains an Android-first Flutter prototype with:

- Material 3 app shell
- Focused primary navigation for `Home`, `Timeline`, and `Dates`
- Local-only sample content for the first prototype
- Secondary placeholder pages for backlog ideas and relationship settings
- Supabase dependency prepared, but no auth or sync in the local prototype
- Widget tests for navigation and core entry points

Run locally:

```powershell
flutter pub get
flutter test
flutter run
```

## MVP Definition

The first prototype is complete only when it can demonstrate this local product
loop without backend complexity:

- Home shows the couple overview, today's note area, and the next important
  date.
- Timeline shows the lightweight daily record flow the app wants to encourage.
- Dates shows core anniversaries with clear countdown value.
- The app makes it obvious which pages belong to the MVP and which ideas are
  still backlog.

Authentication, invitations, shared sync, and Row Level Security are not part
of the local prototype. They belong to the backend foundation milestone.

## Backend Foundation After The Prototype

Before shared data work starts, the team must define:

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

## License

This project is licensed under the MIT License.
