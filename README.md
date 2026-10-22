# FitForge AI

An offline-first Flutter fitness app, with Phases 1–7 implemented.
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
- Complete workout engine, live session player with rest timer, set logging, RPE, and progressive overload.
- Offline food catalog with 52 verified items (ICMR-NIN & USDA), portion scaling, custom foods, and meal logs.
- Permission-based health & activity sync (steps, distance, active kcal, resting HR, sleep architecture).
- Explicit source attribution badges (Health Connect, Apple Health, Hardware Sensors, FitForge, Manual).
- Tanaka age-predicted HRmax calculation and 5 evidence-based cardiovascular training zones.
- Local audit trail and manual health measurement logging modal.
- Bring-Your-Own-Key (BYOK) AI Coach with multi-provider support (Google Gemini, OpenAI, Custom OpenAI-compatible endpoints).
- 100% Offline Rule-Based Heuristic Coach (ISSN protein evaluation, Tanaka HR zones, progressive overload double-progression, autonomic sleep/HR readiness).
- Strict Zero-PII Prompt Guarantee: user names, emails, and account identifiers are strictly omitted from prompts.
- Granular Consent Previews: inspect exact assembled prompt payload and toggle independent data streams (Profile, Workouts, Nutrition, Health).
- Secure credentials storage with XOR-salt obfuscation at rest in `coach_credentials.json` and immediate key zeroization.
- Chat session persistence in `coach_chat.json`, 4 evidence-based coaching personas, suggested follow-up chips, and dashboard quick-access card.

## Not yet implemented

Progress charts, volume recovery tracking, habit streaks, local notifications, complete
professionally reviewed 3D exercise catalog, localization, portable backup import/export,
and permanent account/data deletion. Only the Progress tab remains explicitly marked as unfinished.
The weekly outline is a planning aid, not an exercise prescription.

Web support is not yet configured; use an Android emulator or phone for this build.

## Development

```sh
flutter analyze
flutter test
flutter build apk --debug
```

Open **Workouts → Browse exercises → Push-up** to try the 3D trainer.
Open **AI Coach** from the bottom navigation or the Dashboard to test the offline heuristic engine or configure your BYOK credentials in Coach Settings.
See [Phase 7 BYOK AI Coach details](docs/phase-7.md), [Phase 6 Health & Activity details](docs/phase-6.md), [Phase 5 Nutrition details](docs/phase-5.md), [Phase 4 Workout engine details](docs/phase-4.md), [Phase 3 3D trainer details](docs/3d-upgrade.md), [Phase 2 details](docs/phase-2.md), and [Architecture and roadmap](docs/architecture.md).

