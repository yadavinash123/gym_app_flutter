# Phase 6: Permission-Based Activity & Health Integrations with Source Attribution

## Overview

Phase 6 implements the complete permission-based health and activity integration engine for FitForge AI.
Users can sync or record daily physical activity (Steps, Walking Distance, Active Calories, Resting Heart Rate, and Sleep Duration & Stages), manage granular metric-by-metric permissions with clear clinical and product justifications, inspect source attribution badges across all metrics (Google Health Connect, Apple HealthKit, Hardware Sensors, FitForge Workout Sessions, and Manual Logs), view age-predicted cardiovascular training zones via the Tanaka et al. (2001) formula, and audit all synchronization operations locally on device.

All existing Phase 1, Phase 2, Phase 3, Phase 4, and Phase 5 features and tests remain preserved and 100% passing.

---

## Architecture & Components

### 1. Data Models (`lib/features/health/models/`)
- **`HealthSource` (`health_source.dart`)**:
  - Typed representation of health data provenance:
    - `HealthSourceType`: `healthConnect`, `appleHealth`, `deviceSensor`, `fitforgeSession`, `manualEntry`.
    - Human-readable display names, device model tracking, and package attributes.
    - Standardized badge tags and distinctive UI theme colors:
      - Health Connect: Cyan (`#00D4FF`).
      - Apple Health: Crimson (`#FF2D55`).
      - Device Sensor: Amber (`#FFB800`).
      - FitForge: Neon Green (`#B6FF3B`).
      - Manual Entry: Muted Gray (`#A7B0BF`).
- **`HealthMetricType` (`health_metric_type.dart`)**:
  - `steps`: Ambulatory step counts with WHO reference targets (7,500–10,000 steps/day).
  - `distance`: Walking/running distance in kilometers.
  - `activeEnergy`: Active calories expenditure in kcal, integrated with Mifflin–St Jeor TDEE balance.
  - `restingHeartRate`: Resting pulse baseline in beats per minute (BPM).
  - `sleep`: Total nocturnal sleep duration, formatted intervals, and sleep stages (Deep, REM, Light).
  - `workouts`: Completed sessions imported from external trackers.
- **`HealthPermission` (`health_permission.dart`)**:
  - Granular permission scope per metric type with access mode (`read`, `write`, `readWrite`).
  - Status tracking: `granted`, `denied`, `notDetermined`, `restricted`.
  - Timestamped modification records.
- **`HeartRateZone` (`heart_rate_zone.dart`)**:
  - Tanaka et al. (2001) age-predicted maximal heart rate:
    $$\text{HR}_{\max} = 208 - (0.7 \times \text{age})$$
  - Five evidence-based physiological training zones:
    - **Zone 1: Active Recovery** (50%–60% $\text{HR}_{\max}$): Warm-up, cooldown, active recovery.
    - **Zone 2: Aerobic Base** (60%–70% $\text{HR}_{\max}$): Mitochondrial density, fatty acid oxidation, endurance foundation.
    - **Zone 3: Tempo / Aerobic** (70%–80% $\text{HR}_{\max}$): Cardiovascular efficiency and glycogen-sparing endurance.
    - **Zone 4: Lactate Threshold** (80%–90% $\text{HR}_{\max}$): Sustained high-intensity effort near anaerobic accumulation threshold.
    - **Zone 5: Anaerobic Peak** (90%–100% $\text{HR}_{\max}$): Neuromuscular speed and sprint power.
  - Resting heart rate classifications: Athletic (<50 bpm), Excellent (50–59 bpm), Good (60–69 bpm), Average (70–79 bpm), Elevated (80+ bpm).
- **`DailyHealthSummary` (`daily_health_summary.dart`)**:
  - Date-keyed aggregate containing step counts, distance, active kcal, resting HR, sleep duration, and stage breakdown.
  - Independent source attribution for every single metric field.
- **`SyncAuditLog` (`sync_audit_log.dart`)**:
  - Full audit trail recording sync timestamp, origin source, records imported, status (`success`, `permission_denied`, `error`), and diagnostic message.

### 2. Platform Adapter Architecture (`lib/features/health/data/health_platform_adapter.dart`)
- **`HealthPlatformAdapter`**:
  - Abstract contract for checking platform availability, querying permissions, requesting permissions, fetching daily summaries, and querying time-series records.
- **`SimulatedHealthAdapter`**:
  - Offline-first provider enabling realistic demonstration and automated testing on emulators and Linux environments without Google Play Services or HealthKit binaries.
  - Deterministically generates authentic variances based on date hashing.

### 3. Storage & Safe Persistence (`lib/features/health/data/health_repository.dart`)
- **JSON Files in Private Application Support**:
  - `health_summaries.json`: Date-mapped summaries with schema version 1.
  - `health_permissions.json`: Metric permission configurations.
  - `health_audit_logs.json`: Historical sync attempts and audit records (recent 50 entries).
- **Safe Write Queue**:
  - Serialized through `_tail` Future queue in `JsonStore`, guaranteeing atomic file replacement, `.bak` backup creation, and syntax corruption recovery.
- **Riverpod State Management**:
  - `healthRepositoryProvider`: Repository instance with store and adapter.
  - `healthPermissionsProvider`: Reactive notifier managing permission state transitions.
  - `dailyHealthSummariesProvider`: AsyncNotifier managing daily summary caches and manual logging.
  - `dailyHealthSummaryProvider(date)`: Family provider for arbitrary dates.
  - `todayHealthSummaryProvider`: Provider tracking today's health metrics.
  - `healthAuditLogsProvider`: Reactive stream of audit logs.

### 4. User Interface (`lib/features/health/screens/`, `widgets/`)
- **`HealthScreen` (`/health`)**:
  - Date navigation header (`<` previous day, `>` next day, date picker).
  - Hero synchronization card with platform status, last sync timestamp, "Sync Now" button, and "Manual Log" launcher.
  - 4-card metric grid with value, units, target progress bar, and colored source attribution badges.
  - Sleep architecture breakdown card displaying Deep Sleep, REM Sleep, and Light Sleep duration chips.
  - Interactive `HeartRateZoneChart` calculating personalized Tanaka zones based on profile age.
  - Recent Synchronization Audit Trail displaying timestamps, source badges, and import counts.
  - AppBar info button opening `HealthReferenceDialog`.
- **`HealthPermissionsScreen` (`/health/permissions`)**:
  - Privacy commitment card ("Your Data Stays On Your Phone").
  - "Grant All" and "Revoke All" bulk actions.
  - Granular switch toggles with clinical and product justifications for each metric.
- **`ManualHealthEntryScreen` (`/health/log`)**:
  - Choice chips for metric selection (Steps, Distance, Active Calories, Resting Heart Rate, Sleep, Workouts).
  - Numeric input with comprehensive validation and physical boundary checks.
  - Contextual notes field.
  - Immediate persistence with "Manual Entry" source attribution.
- **Settings & Dashboard Integration**:
  - Added "Health & activity sync" setting tile in `SettingsScreen` leading to `/health`.
  - Added "DAILY ACTIVITY & HEALTH" summary card in `DashboardScreen` displaying steps, resting heart rate, and sleep with source attribution and direct link to details.

---

## Scientific Citations & Calculations

1. **Tanaka Age-Predicted HRmax Formula**:
   - Tanaka H, Monahan KD, Seals DR. (2001). *"Age-predicted maximal heart rate revisited."* Journal of the American College of Cardiology, 37(1), 153–156. DOI: [10.1016/S0735-1097(00)01054-8](https://doi.org/10.1016/S0735-1097(00)01054-8).
2. **Physical Activity & Ambulatory Step Targets**:
   - World Health Organization (2020). *"WHO guidelines on physical activity and sedentary behaviour."* British Journal of Sports Medicine, 54(24), 1451–1462. DOI: [10.1136/bjsports-2020-102955](https://doi.org/10.1136/bjsports-2020-102955).
3. **Nocturnal Sleep Duration Guidelines**:
   - Hirshkowitz M, et al. (2015). *"National Sleep Foundation’s sleep time duration recommendations: methodology and results summary."* Sleep Health, 1(1), 40–43. DOI: [10.1016/j.sleh.2014.12.010](https://doi.org/10.1016/j.sleh.2014.12.010).

### 4. Continuous Hardware Step Tracking Engine (`lib/features/health/data/step_tracking_service.dart`)
- **Automated Real-Time Step Counter**:
  - Connects to hardware step sensor stream (`Pedometer.stepCountStream`) and pedestrian motion status (`Pedometer.pedestrianStatusStream`).
  - Automatically counts footsteps continuously as the user walks, without requiring manual logging or manual sync button presses.
  - Resolves Android cumulative boot step offsets (`Sensor.TYPE_STEP_COUNTER`) by persisting day baselines (`hardware_step_baseline`) with automatic daily rollover detection and reboot compensation.
  - Automatically derives walking distance ($0.00075\text{ km/step}$) and active energy ($0.045\text{ kcal/step}$) with source provenance tagged as `HealthSource.hardwarePedometer`.
  - Live pedestrian state: Detects walking vs. stationary states in real time (`isWalkingNowProvider`) and displays dynamic visual indicators in the activity dashboard.
  - Platform permissions: Configured `android.permission.ACTIVITY_RECOGNITION` with step counter sensor hardware declarations in `AndroidManifest.xml` and `NSMotionUsageDescription` in iOS `Info.plist`.
  - Resilient offline fallback: Catches unsupported platforms/emulators gracefully without crashes and provides walking simulation APIs for automated testing and testing on devices without physical sensors.

### 5. Multi-Device Responsive UI Architecture
- **Zero-Overflow Layout on All Screen Sizes**:
  - `HealthMetricCard` (`health_metric_card.dart`): Employs `LayoutBuilder` with adaptive padding, `FittedBox(fit: BoxFit.scaleDown)` on headline metric numbers, decoupled progress/goal sub-rows, and dynamic `_SourceBadge` constraint scaling. Immune to horizontal overflow even on narrow 100px–140.4px columns.
  - Date Navigation Bar: Wrapped date display in `Flexible` + `FittedBox` with `MainAxisSize.min` to prevent unconstrained horizontal expansion on narrow displays.
  - Hero Action Buttons: Responsive `LayoutBuilder` automatically stacking buttons vertically when container width $< 280\text{px}$ and equal-width distribution on larger screens.
  - Section Headers: All headers (`Sleep Architecture & Stages`, `Recent Synchronization Audit Trail`, `Cardiovascular & Training Zones`) wrapped in `Expanded` with text ellipsis.
  - Tested across 320px (compact phones), 375px/390px/412px (standard smartphones), and tablets.

---

## Scientific Citations & Calculations

1. **Tanaka Age-Predicted HRmax Formula**:
   - Tanaka H, Monahan KD, Seals DR. (2001). *"Age-predicted maximal heart rate revisited."* Journal of the American College of Cardiology, 37(1), 153–156. DOI: [10.1016/S0735-1097(00)01054-8](https://doi.org/10.1016/S0735-1097(00)01054-8).
2. **Physical Activity & Ambulatory Step Targets**:
   - World Health Organization (2020). *"WHO guidelines on physical activity and sedentary behaviour."* British Journal of Sports Medicine, 54(24), 1451–1462. DOI: [10.1136/bjsports-2020-102955](https://doi.org/10.1136/bjsports-2020-102955).
3. **Nocturnal Sleep Duration Guidelines**:
   - Hirshkowitz M, et al. (2015). *"National Sleep Foundation’s sleep time duration recommendations: methodology and results summary."* Sleep Health, 1(1), 40–43. DOI: [10.1016/j.sleh.2014.12.010](https://doi.org/10.1016/j.sleh.2014.12.010).

---

## Verification & Test Results

1. **Static Analysis**:
   ```sh
   flutter analyze --no-pub
   ```
   Result: **No issues found!** (0 errors, 0 warnings, 0 hints).

2. **Automated Test Suite**:
   ```sh
   flutter test --no-pub
   ```
   Result: **All 86 tests passed!**
   - 61 existing regression tests covering storage migrations, onboarding, exercises, 3D viewer, planning, settings, workout engine, and nutrition catalog/logging.
   - 25 Phase 6 unit, repository, and widget tests (`test/health_test.dart`):
     - `HealthSource` serialization, deserialization, equality, badges, and colors.
     - `HealthMetricType` enum attributes, units, and justifications.
     - Tanaka formula calculation, 5 training zones, and resting HR classification.
     - `HealthRecord` and `DailyHealthSummary` JSON persistence and interval endpoints.
     - `SyncAuditLog` records and validation.
     - `HealthRepository` permission management (default, updates, grant all, revoke all).
     - Permission enforcement: state error when unpermitted and audit log creation.
     - Health data sync and atomic persistence.
     - Manual metric logging with automatic "Manual Entry" source attribution.
     - Automated `StepTrackingService` walking footsteps accumulation, continuous hardware sensor provenance, and stride distance/calorie calculation.
     - Baseline persistence across app re-initialization and day rollover.
     - `HealthMetricCard` zero RenderFlex overflow on narrow 140.4px constraint (reproducing user error).
     - `HealthMetricCard` scale down on ultra-narrow 100px width.
     - `HealthScreen` responsive render on small phone screen (320x640) with zero RenderFlex overflow.
     - `HeartRateZoneChart`, `HealthReferenceDialog`, `HealthPermissionsScreen`, `ManualHealthEntryScreen`, and `HealthScreen` widget tests.
