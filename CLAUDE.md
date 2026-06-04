# CLAUDE.md

This file provides guidance to AI coding assistants when working with code in this repository.

## Project Overview

Between Us is a private-first Flutter mobile app for two people in a relationship. It's a lightweight shared life space — not a task tool or diary. Default language is Simplified Chinese, with English as an optional setting. Android-first, iOS later.

## Commands

```powershell
flutter pub get          # Install dependencies
flutter test             # Run all widget tests
flutter test test/widget_test.dart  # Run a single test file
flutter analyze          # Static analysis (uses flutter_lints)
flutter run              # Run on connected device/emulator
flutter build apk        # Create a release Android package
supabase db push         # Apply local SQL migrations to the configured Supabase project
```

No custom build scripts, linters, or CI pipelines exist yet.

## Project Structure

```
lib/
  main.dart
  app/              # App-wide state, theme, strings, shell, Supabase config
  data/models/      # Supabase-backed record types
  features/         # Feature screens, each in its own directory
    anniversaries/    — AnniversariesScreen (upcoming anniversaries list)
    auth/             — Email OTP sign-in, registration, first profile setup
    home/             — HomeScreen + widgets/ (couple_overview_card, daily_note_card)
    profile/          — Legacy placeholder (migrated to settings/)
    settings/         — UsScreen (main "我们" tab) + SettingsMoreScreen (preferences & account)
    timeline/         — TimelineScreen
    wishlist/         — WishlistScreen (placeholder)
  shared/widgets/   # Reusable UI components
test/               # Widget tests, mirroring features
supabase/migrations/ # Timestamped SQL migrations
docs/               # Product and architecture decisions (Chinese)
```

## Architecture

### Entry Point & App Widget

`main()` runs `BetweenUsApp`, which creates an `AppController`, wraps the tree in `AppScope` (an `InheritedNotifier`), and builds a `MaterialApp` with locale/theme from the controller. Uses `AnimatedBuilder` to rebuild on controller changes.

### App Shell & Navigation

`lib/app/app_shell.dart` — 4-tab `NavigationBar` with `IndexedStack` for tab persistence:
1. 首页 (Home) — couple overview, next date, recent updates, quick actions
2. 日历 (Calendar) — dated content: anniversaries, date plans, reminders
3. 计划笔记 (Plans & Notes) — internal split: Plans (undated ideas) + Notes (casual shared notes)
4. 我们 (Us) — shared couple space overview, partner profile, space settings

The "我们" tab's AppBar includes a settings icon that navigates to `SettingsMoreScreen` (preferences, theme, language, sign-out).

Home screen navigates to other tabs via callbacks (`onOpenCalendar`, `onOpenPlansNotes`, etc.) and can open Plans/Notes in a specific sub-mode via `_openPlansWithMode()` using the `PlansNotesMode` enum (defined in `app_strings.dart`).

### State Management

`lib/app/app_controller.dart` — a single `ChangeNotifier` exposed via `AppScope` (an `InheritedNotifier`). Holds:
- `AppLanguage` (zhCn / en) → `Locale`
- `AppThemePreference` (system / light / dark) → `ThemeMode`
- `notificationPreviewEnabled`

Access anywhere: `AppScope.of(context)`.

### Localization

`lib/app/app_strings.dart` — NOT using Flutter's `intl`/ARB system. Instead, a hand-rolled `AppStrings` class with a boolean `isChinese` toggle. All UI strings live here. Adding a new string means adding a getter pair (Chinese + English) in this single file.

Calendar data (entries, occurrences, formatting) is also derived centrally in `AppStrings`. The `CalendarEntryData` model, `CalendarRepeatRule` (once/yearly), and `CalendarEntryType` (anniversary/date/reminder) enums are defined there. The `PlansNotesMode` enum also lives here.

### Theme

`lib/app/app_theme.dart` — Material 3 `ThemeData` for light and dark modes.

### Data Models

`lib/data/models/` — Supabase-backed record types: `CalendarEventRecord`, `PlanRecord`, `NoteRecord`.

### Shared Widgets

`lib/shared/widgets/` — `AppPage`, `CircleBadge`, `FeatureTile`, `SectionHeader`, plus page visual language utilities (`PageSectionHeader`, `PageListItem`, `PageIconBadge`, `PageInsetPanel`, etc.).

### Supabase (Backend Foundation)

`supabase/migrations/` contains the shared foundation SQL. 7 tables: `profiles`, `couple_spaces`, `couple_memberships`, `couple_invites`, `calendar_events`, `plans`, `notes`. RPCs for invite lifecycle. RLS enforced.

The Flutter app is now connected to Supabase for the shared Alpha:
- `AppController` initializes Supabase, manages auth session state, loads profile fields, and owns the active `currentSpaceId`.
- Email OTP login/registration, profile setup, invite generation/acceptance, calendar events, plans, and notes use Supabase.
- Home, Calendar, and Plans & Notes read shared data from Supabase using `AppController.currentSpaceId`.
- Local sample data remains only as UI fallback/prototype copy where a feature has no shared records yet.

`lib/app/supabase_config.dart` holds public client configuration. `lib/app/couple_space_guard.dart` guards routes that require an active couple space.

## Coding Style & Naming Conventions

- Follow Dart defaults: 2-space indentation, trailing commas where formatting benefits.
- Run `dart format .` before review.
- `snake_case` for files (`home_screen.dart`), `PascalCase` for classes and widgets, leading underscore for private members.
- Keep feature code localized to its module instead of growing `lib/app/`.
- Prefer short, explicit widget names.
- Keep user-facing copy aligned with the app's Chinese-first product direction.

## Key Conventions

- **Vertical slices**: each feature goes definition → copy → static prototype → local interaction → tests → backend wiring.
- **Page boundaries are strict**: dated content → Calendar; undated plans → Plans; casual writing → Notes; settings → Us. Don't blur these.
- **Sensitive data** (cycle records): not yet implemented. Default-not-shared, explicit authorization required when added.
- **Soft delete** for shared content (`deleted_at` columns), no physical DELETE from client.
- **Copy tone**: calm, warm, couples-oriented. Avoid task-management language, 打卡 pressure, or PM-style explanations.
- **Docs are in Chinese**: `docs/ARCHITECTURE.md`, `docs/DATABASE.md`, `docs/WORKFLOW.md`, `docs/ROADMAP.md`, `docs/BACKEND_SHARED_FOUNDATION.md` — all written in Chinese.

## Testing

Use `flutter_test` for widget coverage. Add tests for navigation, locale/theme behavior, empty states, and Supabase-related UI fallbacks. Name tests with the `*_test.dart` suffix and keep descriptions behavior-focused, e.g. `calendar shows empty state when no events`. Run `flutter analyze` and `flutter test` before opening a PR.

Current test files:
- `test/widget_test.dart` — main widget test suite
- `test/calendar_screen_test.dart` — calendar screen tests
- `test/couple_space_guard_test.dart` — couple space guard tests

## Commit & Pull Request Guidelines

Follow Conventional Commit style: `feat: ...`, `feat(scope): ...`, `fix: ...`. Keep subjects short, imperative, and scoped when helpful, e.g. `feat(home): load cards from Supabase`. PRs should state the user-visible change, list affected screens or migrations, and include screenshots for UI updates. If you change product structure, terminology, or data boundaries, update the relevant files in `docs/` in the same PR.

## Security & Configuration

Do not commit service-role keys, local `.env` files, or machine-specific SDK paths. App code should use only public Supabase client configuration, and every schema change must preserve Row Level Security expectations documented in `docs/DATABASE.md`.

## Docs

Before changing product structure or data boundaries, update these:
- `docs/ROADMAP.md` — phase plan and delivery checkpoints
- `docs/ARCHITECTURE.md` — page responsibilities, content rules, information architecture (in Chinese)
- `docs/DATABASE.md` — schema design, RLS direction, data ownership rules
- `docs/WORKFLOW.md` — development workflow, review checklist, merge criteria
- `docs/BACKEND_SHARED_FOUNDATION.md` — what's landed in Supabase and what's explicitly deferred
