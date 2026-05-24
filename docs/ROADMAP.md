# Roadmap

This roadmap describes the planned development path for Between Us. It is meant
to guide implementation decisions, keep the first version focused, and leave
room for personal features later.

## Guiding Principles

- Build the app as a real mobile app from the beginning.
- Keep the first version small enough to finish and use.
- Prefer stable foundations over many unfinished features.
- Treat privacy and data ownership as product requirements.
- Add new modules only after the couple-space foundation works.

## Phase 0: Project Foundation

Goal: prepare the repository and development environment.

Scope:

- Create public GitHub repository.
- Add MIT License.
- Add English and Chinese README files.
- Add this roadmap.
- Install and verify Flutter locally.
- Generate the initial Flutter project structure.
- Add a Flutter-oriented `.gitignore`.

Done when:

- The repository has documentation, license, and roadmap.
- `flutter doctor` can run locally.
- The initial Flutter app can build or run on an Android device.
- The first Flutter project commit is pushed to GitHub.

## Phase 1: App Skeleton

Goal: create a clean mobile app base that future modules can build on.

Scope:

- Define app name, package name, and basic metadata.
- Create the top-level Flutter app structure.
- Add app theme, colors, typography, and reusable UI tokens.
- Add navigation and route structure.
- Create placeholder screens for the initial modules.
- Keep all data local and static in this phase.

Initial screens:

- Home
- Timeline
- Anniversaries
- Wishlist
- Profile

Done when:

- The app opens on a real Android device.
- Bottom navigation or equivalent primary navigation works.
- Each initial screen has a placeholder view.
- The structure is clear enough to add feature code without reorganizing.

## Phase 2: Local Prototype

Goal: prove the core couple-app experience without backend complexity.

Scope:

- Home screen shows basic couple information.
- Timeline supports local sample entries.
- Anniversaries support local sample items and countdown display.
- Daily note or message area exists in the home experience.
- Profile screen shows two-person relationship settings as static data.

Done when:

- The app feels like a minimal couple app, not only a technical shell.
- A user can move between the main sections naturally.
- The first prototype can be demonstrated without Supabase.

## Phase 3: Supabase Integration

Goal: connect the app to real shared data.

Scope:

- Create Supabase project.
- Add Supabase client configuration.
- Add authentication.
- Add profile model.
- Add couple-space model.
- Add database access rules.
- Add environment/config handling without committing secrets.

Initial tables:

- profiles
- couples
- timeline_entries
- anniversaries
- notes

Done when:

- Two users can sign in.
- Both users can belong to the same couple space.
- Data is scoped by couple space.
- No private Supabase keys or local secrets are committed.

## Phase 4: Shared Core Features

Goal: make the app useful for daily two-person use.

Scope:

- Create and read timeline entries.
- Create and read anniversaries.
- Create and read daily notes.
- Show recent activity on the home screen.
- Add basic loading, empty, and error states.

Done when:

- Both users can see shared timeline data.
- Both users can see shared anniversaries and notes.
- The app remains usable when the network is slow or data is empty.

## Phase 5: Home Menu Module

Goal: add the first practical life module after the base app is stable.

Scope:

- Add menu item model.
- Add order/request model.
- Add menu list screen.
- Add request flow for "I want this".
- Add kitchen/task view for pending requests.
- Add status changes such as pending, in progress, and done.

Initial tables:

- menu_items
- menu_requests

Done when:

- Either person can request a dish.
- The other person can see and update the request status.
- Menu data belongs to the same couple space.

## Phase 6: Polish And Reliability

Goal: improve quality before adding more feature modules.

Scope:

- Improve visual design and interaction details.
- Add form validation.
- Add basic offline and retry behavior where needed.
- Add crash-safe error handling.
- Review database rules.
- Add basic tests for important pure logic.

Done when:

- The app is comfortable enough for daily private use.
- Common failure cases are handled.
- Important data access rules have been reviewed.

## Later Modules

These modules should be added only after the app foundation and shared data
model are stable:

- Shared photo memories
- Gift ideas
- Random date picker
- Reminder notifications
- Travel plans
- Monthly memory summary
- Conflict cooldown page
- Personal preference notes

## Not In Scope For The First Version

- Public social features
- Content recommendation feeds
- Multi-couple support
- Commercial payment features
- Complex analytics
- Public user profiles
- App Store release process
- iOS distribution

## Documentation Backlog

- `docs/SETUP.md`: local development setup
- `docs/ARCHITECTURE.md`: app structure and major decisions
- `docs/DATABASE.md`: Supabase schema and access rules
- `docs/RELEASE.md`: Android build and release notes
