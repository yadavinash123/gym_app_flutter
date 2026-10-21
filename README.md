# FitForge AI

An offline-first Flutter fitness app, with Phases 1–2 and the Phase 3 exercise-library starter implemented.
Personal records use **JSON files in the phone's private application support directory**.
No SQLite, Drift, PostgreSQL, Hive, Isar, cloud database, or backend.

## Run

```sh
flutter pub get
flutter run
```

Android and iOS projects are included. iOS builds require macOS and Xcode.
The project's SDK constraint reflects the installed Flutter toolchain (Dart 3.13.2+).
Dependencies are locked in `pubspec.lock`.

## Implemented

- Material 3 dark theme, five-tab navigation and phone-sized scrollable layouts.
- Ten-step onboarding with optional measurements, goals, equipment, availability,
  nutrition preferences, limitations and a plan preview.
- Profile settings, metric/imperial conversion, cancel without saving and retry on errors.
- Editable offline weekly outline that respects rest days and recorded limitations.
- Transparent adult energy/protein estimates, optional BMI context and personal targets.
- Home summaries based on the saved profile; weekly outline in the Workouts tab.
- Versioned JSON persistence, queued safe writes and a previous-revision backup.
- Non-destructive loading of Phase 1 profiles and upgrade to schema v2 on explicit save.
- 22 offline exercise guides, combined filters, front/back muscle map and saved favorites.
- One installed 3D push-up trainer with a real skinned GLB, camera/playback controls and fullscreen.
- Clearly labeled muscle illustrations for guides without installed 3D assets.

## Not yet implemented

Complete professionally reviewed exercise catalog/animations, detailed workout engine, session logging,
nutrition/meal logging, health integrations, AI providers, progress charts, notifications,
localization, portable backup import/export and permanent deletion.
No API keys are collected yet. When added, credentials will use platform secure storage.
Local JSON files are sandboxed, not application-level encrypted. Clearing app data or
uninstalling can delete them. Nutrition, Progress and AI Coach tabs are explicitly marked
as unfinished. The weekly outline is a planning aid, not an exercise prescription.

Web support is not yet configured; use an Android emulator or phone for this build.

## Development

```sh
flutter analyze
flutter test
flutter build apk --debug
```

Open **Workouts → Browse exercises → Push-up** to try the 3D trainer.
See [3D upgrade, asset licenses and remaining scope](docs/3d-upgrade.md).
See [Phase 3 scope and sources](docs/phase-3.md), [architecture and roadmap](docs/architecture.md) and [Phase 2 behavior and calculation sources](docs/phase-2.md). This is an incremental development build, not the complete production application from the master brief.
