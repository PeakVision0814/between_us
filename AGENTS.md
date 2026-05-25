# Repository Guidelines

## Project Structure & Module Organization

This is a Flutter mobile app for Android-first development. Dart source lives in `lib/`.
The app entry point is `lib/main.dart`, app-level setup is under `lib/app/`, reusable UI is
under `lib/shared/widgets/`, and feature screens are grouped in `lib/features/<feature>/`.
Android platform files are in `android/`. Tests live in `test/`, currently starting with
`test/widget_test.dart`. Project documentation is in `docs/`, including setup and roadmap notes.

## Build, Test, and Development Commands

- `flutter pub get`: install Dart and Flutter dependencies from `pubspec.yaml`.
- `flutter run`: run the app on a connected emulator or device.
- `flutter analyze`: run static analysis using `analysis_options.yaml`.
- `flutter test`: run all widget and unit tests in `test/`.
- `flutter build apk`: create an Android APK build.

Run commands from the repository root. Keep `pubspec.lock` committed so dependency resolution is
stable for contributors.

## Coding Style & Naming Conventions

Use Dart defaults with `package:flutter_lints/flutter.yaml`. Format Dart code with `dart format .`
before committing. Prefer two-space indentation, trailing commas for multi-line Flutter widgets,
and small composable widgets over deeply nested build methods.

Use `snake_case.dart` for files, `PascalCase` for widget/class names, and `camelCase` for methods,
variables, and parameters. Feature code should stay inside its feature folder unless it is genuinely
shared across screens.

## Testing Guidelines

Use `flutter_test` for widget tests and standard Dart tests. Name test files with the `_test.dart`
suffix and place them under `test/`. Add or update tests when changing user-visible behavior,
navigation, shared widgets, or state logic. Run `flutter test` and `flutter analyze` before opening
a pull request.

## Commit & Pull Request Guidelines

Recent commits use short imperative summaries, for example `Initialize Flutter app skeleton` and
`Add development roadmap`. Follow that style: start with a verb, keep the subject concise, and avoid
mixing unrelated changes.

Pull requests should include a brief description, test results, and screenshots or screen recordings
for UI changes. Link related issues or roadmap items when applicable, and call out any Android,
Supabase, or configuration changes reviewers need to reproduce.

## Security & Configuration Tips

Do not commit secrets, API keys, local keystores, or machine-specific IDE settings. Keep private
configuration in local environment files or platform-specific secure storage.

## Agent-Specific Instructions

Do not batch-delete files or directories in this repository. Any deletion must target exactly one
explicit path and must be confirmed before execution. Bulk deletion requests must be declined under
the project safety rule.
