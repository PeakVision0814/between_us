# Roadmap

This roadmap keeps Between Us aligned around one product question:
will a couple return often for a shared daily note and visible important dates?

## Guiding Principles

- Keep the MVP narrow enough to demo and narrow enough to evaluate.
- Do not confuse placeholder breadth with product progress.
- Define privacy boundaries before shared backend work begins.
- Make every phase reviewable through concrete demo checklists.
- Add extra modules only after the core loop shows real repeat use.

## Phase 0: Project Foundation

Goal: prepare the repository and local development environment.

Scope:

- Create the Flutter repository and Android-first app shell.
- Add license, roadmap, and setup documentation.
- Verify local Flutter tooling.

Done when:

- The repository builds on a local Android environment.
- Core project docs exist and are readable.
- `flutter doctor` can run successfully on contributor machines.

## Phase 1: Focused App Skeleton

Goal: establish the information architecture for the MVP only.

Scope:

- Define app theme, route structure, and reusable UI tokens.
- Keep primary navigation limited to `Home`, `Timeline`, and `Dates`.
- Move backlog ideas and relationship settings to secondary pages.
- Keep all data local and static in this phase.

Done when:

- The app opens on a real Android device.
- Primary navigation contains exactly three MVP destinations.
- Secondary pages are reachable without competing with the MVP tabs.
- The repo structure is clear enough to add feature code without reorganization.

## Phase 2: Local MVP Prototype

Goal: prove the core couple-app loop without backend complexity.

Scope:

- Home shows a couple overview, a clear note CTA, and the next important date.
- Timeline shows a local daily-note or memory flow with sample entries.
- Dates shows local anniversaries with countdown value.
- Empty, placeholder, and backlog messaging clearly distinguish MVP from later ideas.

Done when:

- A reviewer can open the app and identify the primary action within 10 seconds.
- The `Home -> Timeline -> Dates` flow can be demoed without explanation.
- The prototype can be shown without auth, network, or Supabase setup.
- `flutter test` and `flutter analyze` pass locally.

## Phase 3: Shared Data Architecture

Goal: lock product rules before writing shared backend code.

Scope:

- Write `docs/ARCHITECTURE.md` for app structure, information architecture, and privacy boundaries.
- Write `docs/DATABASE.md` for schema direction, invite flow, RLS, unlink, export, and delete behavior.
- Confirm how a couple space is created, joined, limited to two members, and dissolved.
- Confirm notification and preview safety rules.

Done when:

- Invite flow is documented end to end.
- Data ownership and unlink/delete rules are documented end to end.
- Planned tables and access boundaries are documented before implementation starts.
- The team can review backend work against written privacy rules instead of assumptions.

## Phase 4: Shared Alpha

Goal: connect the app to real private shared data.

Scope:

- Create the Supabase project and local configuration flow.
- Add authentication and couple-space invitation flow.
- Implement shared storage for timeline entries and anniversaries.
- Enforce Row Level Security and couple-space scoping on every shared table.
- Add loading, empty, error, and retry states for shared reads and writes.

Done when:

- Two accounts can join the same couple space through the intended invite flow.
- Each account can only read and write data for its own couple space.
- Timeline entries and anniversaries sync correctly across two test devices.
- Shared actions fail safely when the network is unavailable or authorization is missing.

## Phase 5: Reliability And Private Beta

Goal: validate repeat usage on real devices before expanding the product.

Scope:

- Add tests for countdown logic, invite flow rules, and key data ownership rules.
- Improve offline behavior, retry messaging, and conflict handling for shared data.
- Prepare Android beta distribution.
- Run a small private beta with feedback collection.

Beta checklist:

- Define target devices and minimum Android versions for testing.
- Distribute builds to at least 3 to 5 real couples or trusted testers.
- Review feedback on frequency of note usage, clarity of dates, and privacy concerns weekly.
- Record success signals such as weekly retention, completed note entries, and reported trust issues.

Done when:

- Critical pure logic has automated tests.
- Common shared-data failure cases are visible and recoverable.
- Beta feedback produces a clear keep / change / remove decision on the MVP loop.
- The team can name the next highest-value module with evidence, not preference.

## Backlog Modules

These stay out of active development until the beta validates the core loop:

- Gift ideas / wishlist
- Shared photo memories
- Reminder notifications
- Travel plans
- Home menu
- Monthly memory summary
- Conflict cooldown page
- Personal preference notes

## Not In Scope For The First Version

- Public social features
- Multi-couple support
- Commercial payments
- Public user profiles
- Feed-style recommendation systems
- iOS distribution

## Working Documents

- [docs/SETUP.md](SETUP.md): local development setup
- [docs/ARCHITECTURE.md](ARCHITECTURE.md): product boundaries and app structure
- [docs/DATABASE.md](DATABASE.md): planned shared schema and access rules
