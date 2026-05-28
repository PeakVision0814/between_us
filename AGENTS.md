# Repository Guidelines

## Project Structure & Module Organization
`lib/` contains the Flutter app. Keep app-wide state, theme, strings, and shell code in `lib/app/`; feature screens in `lib/features/<feature>/`; reusable UI in `lib/shared/widgets/`; and Supabase-backed records in `lib/data/models/`. Tests live in `test/` and should mirror the feature or entry point they cover, for example `test/calendar_screen_test.dart`. Backend schema and RPC changes belong in `supabase/migrations/` with timestamped filenames. Product and architecture decisions live in `docs/`.

## Build, Test, and Development Commands
- `flutter pub get` installs Dart and Flutter dependencies.
- `flutter run` launches the Android-first app locally.
- `flutter test` runs widget tests in `test/`.
- `flutter analyze` applies the analyzer and `flutter_lints` rules.
- `flutter build apk` creates a release Android package.
- `supabase db push` applies local SQL migrations to the configured Supabase project.

## Coding Style & Naming Conventions
Follow Dart defaults: 2-space indentation, trailing commas where formatting benefits, and run `dart format .` before review. Use `snake_case` for files (`home_screen.dart`), `PascalCase` for classes and widgets, and a leading underscore for private members. Keep feature code localized to its module instead of growing `lib/app/`. Prefer short, explicit widget names and keep user-facing copy aligned with the app's Chinese-first product direction.

## Testing Guidelines
Use `flutter_test` for widget coverage and add tests for navigation, locale/theme behavior, empty states, and Supabase-related UI fallbacks. Name tests with the `*_test.dart` suffix and keep descriptions behavior-focused, such as `calendar shows empty state when no events`. Run `flutter analyze` and `flutter test` before opening a PR.

## Commit & Pull Request Guidelines
Recent history follows Conventional Commit style: `feat: ...`, `feat(scope): ...`, and `fix: ...`. Keep subjects short, imperative, and scoped when helpful, for example `feat(home): load cards from Supabase`. PRs should state the user-visible change, list affected screens or migrations, and include screenshots for UI updates. If you change product structure, terminology, or data boundaries, update the relevant files in `docs/` in the same PR.

## Security & Configuration Tips
Do not commit service-role keys, local `.env` files, or machine-specific SDK paths. App code should use only public Supabase client configuration, and every schema change must preserve Row Level Security expectations documented in `docs/DATABASE.md`.
