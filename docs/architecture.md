# Architecture and implementation roadmap

## Structure

- `lib/app`: root app, routes, startup gate, theme.
- `lib/core/storage`: reusable filesystem persistence.
- `lib/features/profile`: typed model, validation, repository and Riverpod providers.
- `lib/features/onboarding`: initial onboarding and profile editor.
- `lib/features/dashboard`: profile, daily plan and target summaries.
- `lib/features/planning`: deterministic outline and nutrition calculations, weekly screen.
- `lib/features/exercises`: bundled catalog, filters, favorites repository, muscle map and GLB viewer.
- `lib/features/settings`: profile preference section navigation.
- `lib/shared/widgets`: bounded scrollable content and accessible information cards.

Flow: widget → repository provider → JsonStore → private phone files.
Repositories own model validation; UI never reads or writes files directly.

## Packages

| Package | Purpose | License | Notes |
| --- | --- | --- | --- |
| flutter_riverpod 3.4.3 | Async state and dependency injection | MIT | No generator needed for Phase 1 |
| go_router 18.1.1 | Declarative navigation | BSD-3-Clause | Mobile routes and shell |
| path_provider 2.1.6 | Persistent private application directory | BSD-3-Clause | Android 24+, iOS 13+ |

Official references inspected during setup:
- https://pub.dev/packages/flutter_riverpod
- https://pub.dev/packages/go_router
- https://pub.dev/packages/path_provider

Dependency resolution succeeded against the installed SDK. Platform build verification
is separate from dependency compatibility. Release signing is not configured.

## Screen map

Startup → new user: onboarding; existing user: home.
Ten-step onboarding → review and confirm → home.
Explore → home without a persisted profile.
Main shell → Home / Workouts (weekly outline) / Nutrition / Progress / AI Coach.
Profile action → settings → selected editor section → review → save → home.
Nutrition, Progress and AI Coach remain explicitly marked unfinished.

## File schema

`<application-support>/fitforge/profile.json` uses schemaVersion 2. It contains the
profile, preferences, targets and weekly outline as one document. See
[Phase 2 details](phase-2.md) for fields, migration rules and calculation sources.

`profile.json.bak` holds the previous valid JSON document. Writes are queued through
one JsonStore instance, flushed to a same-directory temporary file, then renamed.
Readers wait for pending writes. Invalid names cannot escape the storage directory.
A failed operation does not permanently poison the write queue. JSON syntax failure
triggers backup recovery. Semantic/schema errors are surfaced. Version 1 loads without
rewriting the file; the next explicit save upgrades it. Unknown versions are rejected.

This store provides single-document replacement, not cross-document transactions or
multi-isolate locking. Background workers must send writes through the owning isolate.
Future workout session files should embed sets so one session is one atomic document.
Partition growing logs by month or date. Maintain IDs, references, deduplication,
and date handling in feature repositories. Backups are not substitutes for export.

## Design system

Background #0B0F14; surfaces #151B23 and #1C2430; primary #B6FF3B;
secondary #00D4FF; muted text #A7B0BF. Material typography, 24px content spacing,
24–28px card corners, readable labels, 48px+ controls. No custom automatic animation
is introduced in the foundation. Content scrolls at small screen sizes.

## Exercise animation strategy

The original line-skeleton player has been replaced by an offline Three.js/WebView
integration and one licensed, animated push-up GLB. The asset repository validates
installed files and clip matches. Missing models use a labeled muscle illustration.
See [3D upgrade and remaining scope](3d-upgrade.md).

## Next phases

1. Foundation: implemented; physical-device verification still pending.
2. Onboarding, profile settings and deterministic initial plan generation: implemented.
3. Exercise library starter implemented: 22 guides, muscle map, favorites and one 3D animated push-up preview. Full catalog and professional review outstanding.
4. Workout planning, session timer, set logging, progressive overload, and session file persistence: implemented. See [Phase 4 details](phase-4.md).
5. Offline food catalog, validated nutrition calculations and meal logs: implemented. See [Phase 5 details](phase-5.md).
6. Permission-based activity/health integrations with source attribution: implemented. See [Phase 6 details](phase-6.md).
7. Optional bring-your-own-key AI, secure credentials and consent previews.
8. Progress charts, recovery, streaks and local notifications.
9. Export/import/deletion, localization, accessibility, device testing and release signing.

Keep the main experience offline. Use explicit placeholders only for unfinished features.

## Phase 1 verification (historical)

- `flutter analyze --no-pub`: passed with no issues.
- Five filesystem/repository tests passed (persistence, queued writes/recovery,
  corruption preservation, schema rejection and invalid profile rejection).
- Onboarding/navigation widget test passed, covering required-name validation,
  scrolling through onboarding, saving and tab navigation.
- Physical-device testing and iOS compilation are still required.
- `flutter build apk --debug`: passed; APK at `build/app/outputs/flutter-apk/app-debug.apk`.
  Initial Gradle setup took approximately 10.5 minutes. APK compilation is verified;
  installation and behavior on a physical Android device have not been checked.

## Phase 2

Expanded profile schema v2, ten-step onboarding, profile settings, offline weekly
outline and educational nutrition estimates are implemented. See
[Phase 2 details and verification](phase-2.md). Physical-device testing and iOS
compilation remain outstanding.

## Phase 4

Deterministic workout generation, live session player, interactive set logging,
smart rest timer, progressive overload calculator, personal record tracking, custom
routine builder, and atomic JSON persistence are implemented. See
[Phase 4 details and verification](phase-4.md). All 40 automated tests passed with
zero analyzer warnings.

## Phase 5

Offline verified food catalog (52 items from ICMR-NIN IFCT 2017 & USDA FoodData Central),
custom portion measurements, real-time search with multi-attribute filtering, custom food
creator, Mifflin–St Jeor BMR/TDEE calculations with goal calorie offsets, ISSN protein
guidelines, hydration tracking, atomic daily meal logging (Breakfast, Lunch, Dinner, Snacks),
backup corruption recovery, and dashboard integration are implemented. See
[Phase 5 details and verification](phase-5.md). All 61 automated tests passed with zero
analyzer warnings.

## Phase 6

Permission-based activity and health integrations (Steps, Distance, Active Energy,
Resting Heart Rate, Sleep Architecture), granular metric permissions with clinical/product
justifications, complete source attribution badges (Health Connect, Apple Health,
Hardware Sensors, FitForge, Manual Entry), Tanaka formula age-predicted HRmax and 5
training zones, atomic on-device JSON persistence (`health_summaries.json`,
`health_permissions.json`, `health_audit_logs.json`), audit trail, manual logging modal,
and dashboard integration are implemented. See [Phase 6 details](phase-6.md). All 81
automated tests passed with zero analyzer warnings.
