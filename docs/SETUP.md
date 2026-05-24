# Local Setup

This project is an Android-first Flutter app with Supabase planned for shared
data and authentication.

## Requirements

- Flutter stable
- Android Studio or Android SDK command line tools
- Android SDK configured for Flutter
- A Supabase project for Phase 3 and later

## Verify Flutter

```powershell
flutter doctor -v
```

The Flutter SDK itself must pass. For Android development, the Android
toolchain must also be configured.

If the Android SDK is installed but Flutter cannot find it:

```powershell
flutter config --android-sdk "C:\Users\<you>\AppData\Local\Android\Sdk"
flutter doctor --android-licenses
flutter doctor -v
```

## Run The App

```powershell
flutter pub get
flutter run
```

## Supabase Configuration

Supabase is included as a dependency, but the app shell does not initialize it
yet. Do not commit private keys or local secrets.

When Supabase integration begins, use public anon configuration only in the app
and keep database access protected by Row Level Security policies.
