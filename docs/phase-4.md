# Phase 4: Workout Engine

## Overview

Phase 4 implements the interactive workout execution and progressive overload system for FitForge AI.
Users can inspect daily routines generated deterministically from their profile and the offline exercise catalog, customize exercises and sets, run live workout sessions with rest timers, log weight and repetitions set-by-set with RPE, track personal records, and store session history locally on their device.

All existing Phase 1, Phase 2, and Phase 3 features and tests remain preserved and 100% passing.

---

## Architecture & Components

### 1. Data Models (`lib/features/workouts/models/`)
- `planned_workout.dart`:
  - `PlannedSet`: target repetitions, target weight, target rest duration.
  - `PlannedExercise`: catalog exercise reference, muscle tags, planned sets list, cues.
  - `PlannedRoutine`: routine ID, category, list of planned exercises, target duration, custom routine flag.
- `workout_session.dart`:
  - `CompletedSet`: set number, target reps, actual reps, weight (kg/lbs), RPE (1–10), pain flag, notes, calculated volume.
  - `CompletedExercise`: exercise ID, name, muscles, completed sets, pain flag.
  - `WorkoutSession`: atomic session record with duration, total volume (kg), MET-based approximate calorie expenditure, muscles trained, overall RPE, and notes.
- `progressive_overload.dart`:
  - `PersonalRecord`: tracks max weight, max reps at max weight, max single-session volume, and Brzycki estimated 1RM ($1RM = weight \times \frac{36}{37 - reps}$).
  - `ProgressionRecommendation`: conservative, evidence-based recommendations:
    - If previous RPE $\le$ 7.5 and no discomfort: recommends conservative weight increase (+1.25 kg for upper body / +2.5 kg for lower body) or reps increase for bodyweight.
    - If pain or discomfort was reported: withholds load progression, displays safety alert, recommends reviewing technique or consulting a professional.
    - If previous RPE $\ge$ 9: recommends consolidating or deloading weight.

### 2. Deterministic Routine Generator (`lib/features/workouts/data/workout_generator.dart`)
- Generates concrete routines for weekly outline sessions (`Full-body strength`, `Upper-body strength`, `Lower-body strength`, `Easy cardio`, `Mobility`, `Recovery`).
- Equipment awareness: checks user profile equipment (`Dumbbells`, `Barbell`, `Bodyweight`) and only prescribes matching movements.
- Safety filtering: if user reported limitations (`hasLimitations = true`), restricts selection to gentle mobility and core stability movements.
- Filters out user-specified avoided exercises.
- Configures target sets, reps, and rest duration according to session duration and fitness goal (`Build strength`, `Build muscle`, `Fat loss`, `Improve mobility`).

### 3. Repository & Local Storage (`lib/features/workouts/data/workout_repository.dart`)
- Persists session logs into `<application-support>/fitforge/workout_sessions.json`.
- Persists user custom templates into `<application-support>/fitforge/workout_templates.json`.
- Serializes file read/modify/write operations via atomic `_tail` queue in `JsonStore`, guaranteeing data safety, backup creation (`.bak`), and corruption recovery.
- Exposes Riverpod providers: `workoutRepositoryProvider`, `workoutSessionsProvider`, `workoutTemplatesProvider`, and `personalRecordsProvider`.

### 4. Live Session Player (`lib/features/workouts/session/`)
- `workout_session_controller.dart`: StateNotifier/Notifier tracking active session time, current exercise and set, paused status, resting status, and set logs.
- `workout_session_screen.dart`:
  - Elapsed session timer with pause/resume.
  - Progress indicator showing current exercise step.
  - Exercise card with muscle chips, technique guide shortcut (with 3D push-up viewer / illustration), and exercise swap capability.
  - Progressive overload guidance card displaying previous performance and conservative recommendations.
  - Interactive set logger: adjustable weight and reps counters, RPE slider, and discomfort reporting toggle.
  - Logged sets history table with live volume calculation.
  - Exit protection with option to save completed sets or discard.
- `rest_timer_widget.dart`:
  - Animated circular progress ring with remaining time.
  - Preset duration chips (30s, 60s, 90s, 120s).
  - +15s extension, pause/resume, and skip controls.
  - Haptic feedback when rest period finishes (`HapticFeedback.heavyImpact()`).
- `workout_summary_screen.dart`:
  - Celebration banner with workout stats: total duration, volume lifted, completed sets, and estimated energy expenditure (labeled approximate).
  - Personal record unlock notifications.
  - Target muscles overview and session notes/RPE confirmation.
  - Atomic persistence to local storage.

### 5. Workout History & Custom Routines (`lib/features/workouts/history/`, `custom/`)
- `workout_history_screen.dart`: aggregate volume and duration metrics, personal records carousel, and reverse-chronological session list.
- `workout_detail_screen.dart`: set-by-set breakdown of past workouts and option to delete records.
- `custom_workout_screen.dart`: create custom workout routines, add/remove exercises from the catalog, configure sets, reps, and rest duration, and launch directly.

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
   Result: **All 40 tests passed!**
   - 29 original regression tests (onboarding, storage migrations, exercise catalog, 3D viewer, planning, settings).
   - 11 new Phase 4 unit and integration tests (`test/workout_engine_test.dart`):
     - Routine generation for various fitness goals and equipment constraints.
     - Limitations safety enforcement and avoided exercise filtering.
     - 1RM calculation via Brzycki formula.
     - Conservative progressive overload rules (pain safety checks, RPE thresholds).
     - Calorie expenditure estimation (MET formula).
     - Atomic JSON persistence and session deletion.
     - Template persistence and retrieval.
