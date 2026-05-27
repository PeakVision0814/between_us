# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Between Us is a private-first Flutter mobile app for two people in a relationship. It's a lightweight shared life space — not a task tool or diary. Default language is Simplified Chinese, with English as an optional setting. Android-first, iOS later.

## Commands

```powershell
flutter pub get          # Install dependencies
flutter test             # Run all widget tests
flutter test test/widget_test.dart  # Run a single test file
flutter analyze          # Static analysis (uses flutter_lints)
flutter run              # Run on connected device/emulator
```

No custom build scripts, linters, or CI pipelines exist yet.

## Architecture

### Entry Point & App Widget

`main()` runs `BetweenUsApp`, which creates an `AppController`, wraps the tree in `AppScope` (an `InheritedNotifier`), and builds a `MaterialApp` with locale/theme from the controller. Uses `AnimatedBuilder` to rebuild on controller changes.

### App Shell & Navigation

`lib/app/app_shell.dart` — 4-tab `NavigationBar` with `IndexedStack` for tab persistence:
1. 首页 (Home) — couple overview, next date, recent updates, quick actions
2. 日历 (Calendar) — dated content: anniversaries, date plans, reminders
3. 计划笔记 (Plans & Notes) — internal split: Plans (undated ideas) + Notes (casual shared notes)
4. 我们 (Us) — personal preferences + shared couple space settings

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

### Feature Screens

Under `lib/features/`:
- `home/` — `HomeScreen` + widgets (`couple_overview_card`, `daily_note_card`)
- `timeline/` — `CalendarScreen` (month view + day detail) AND `PlansNotesScreen` (plans/notes sub-views). Both the calendar and plans-notes tab screens live in this directory.
- `anniversaries/` — `AnniversariesScreen` (upcoming anniversaries list)
- `profile/` — `UsScreen` (preferences + space settings). Named `profile/` but the class is `UsScreen`.
- `wishlist/` — `WishlistScreen` (placeholder)
- `settings/` — `SettingsScreen`

### Shared Widgets

`lib/shared/widgets/` — `AppPage` (page container), `CircleBadge`, `FeatureTile`, `SectionHeader`, `DebugRefreshDiagnosticsCard`.

### Supabase (Backend Foundation)

`supabase/migrations/` contains the shared foundation SQL. 7 tables: `profiles`, `couple_spaces`, `couple_memberships`, `couple_invites`, `calendar_events`, `plans`, `notes`. RPCs for invite lifecycle. RLS enforced. The Flutter app does NOT yet connect to Supabase — all data is local prototype/sample data. The `supabase_flutter` package is a dependency but unused in the app code.

## Key Conventions

- **Vertical slices**: each feature goes definition → copy → static prototype → local interaction → tests → backend wiring.
- **Page boundaries are strict**: dated content → Calendar; undated plans → Plans; casual writing → Notes; settings → Us. Don't blur these.
- **Sensitive data** (cycle records): not yet implemented. Default-not-shared, explicit authorization required when added.
- **Soft delete** for shared content (`deleted_at` columns), no physical DELETE from client.
- **Testing**: widget tests verify Chinese defaults, tab navigation, theme/language switching, and cross-page flows (e.g., home → plans in correct sub-mode).
- **Copy tone**: calm, warm, couples-oriented. Avoid task-management language, 打卡 pressure, or PM-style explanations.
- **Docs are in Chinese**: `docs/ARCHITECTURE.md`, `docs/DATABASE.md`, `docs/WORKFLOW.md`, `docs/ROADMAP.md`, `docs/BACKEND_SHARED_FOUNDATION.md` — all written in Chinese.

## Docs

Before changing product structure or data boundaries, update these:
- `docs/ROADMAP.md` — phase plan and delivery checkpoints
- `docs/ARCHITECTURE.md` — page responsibilities, content rules, information architecture (in Chinese)
- `docs/DATABASE.md` — schema design, RLS direction, data ownership rules
- `docs/WORKFLOW.md` — development workflow, review checklist, merge criteria
- `docs/BACKEND_SHARED_FOUNDATION.md` — what's landed in Supabase and what's explicitly deferred
