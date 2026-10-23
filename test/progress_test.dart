import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitforge_ai/core/storage/json_store.dart';
import 'package:fitforge_ai/features/health/data/health_platform_adapter.dart';
import 'package:fitforge_ai/features/health/data/health_repository.dart';
import 'package:fitforge_ai/features/health/models/daily_health_summary.dart';
import 'package:fitforge_ai/features/nutrition/data/nutrition_repository.dart';
import 'package:fitforge_ai/features/nutrition/models/meal_log.dart';
import 'package:fitforge_ai/features/profile/profile.dart';
import 'package:fitforge_ai/features/profile/profile_repository.dart';
import 'package:fitforge_ai/features/progress/data/milestone_engine.dart';
import 'package:fitforge_ai/features/progress/data/progress_repository.dart';
import 'package:fitforge_ai/features/progress/data/recovery_calculator.dart';
import 'package:fitforge_ai/features/progress/data/streak_engine.dart';
import 'package:fitforge_ai/features/progress/models/body_measurement.dart';
import 'package:fitforge_ai/features/progress/models/habit_streak.dart';
import 'package:fitforge_ai/features/progress/models/milestone_badge.dart';
import 'package:fitforge_ai/features/progress/models/muscle_recovery.dart';
import 'package:fitforge_ai/features/progress/models/notification_schedule.dart';
import 'package:fitforge_ai/features/progress/presentation/progress_screen.dart';
import 'package:fitforge_ai/features/progress/presentation/reminder_settings_screen.dart';
import 'package:fitforge_ai/features/progress/presentation/widgets/interactive_line_chart.dart';
import 'package:fitforge_ai/features/progress/presentation/widgets/muscle_recovery_card.dart';
import 'package:fitforge_ai/features/progress/presentation/widgets/streak_tracker_card.dart';
import 'package:fitforge_ai/features/progress/presentation/widgets/volume_bar_chart.dart';
import 'package:fitforge_ai/features/progress/presentation/widgets/weight_entry_dialog.dart';
import 'package:fitforge_ai/features/workouts/data/workout_repository.dart';
import 'package:fitforge_ai/features/workouts/models/progressive_overload.dart';
import 'package:fitforge_ai/features/workouts/models/workout_session.dart';

WorkoutSession createTestSession({
  required String id,
  required DateTime completedAt,
  double volumeKg = 1000.0,
  int setsCount = 4,
  List<String> muscles = const ['Chest', 'Triceps'],
}) {
  return WorkoutSession(
    id: id,
    routineId: 'routine_$id',
    routineName: 'Routine $id',
    startedAt: completedAt.subtract(const Duration(minutes: 45)),
    completedAt: completedAt,
    durationSeconds: 2700,
    exercises: [
      CompletedExercise(
        exerciseId: 'bench-press',
        exerciseName: 'Bench Press',
        primaryMuscles: muscles,
        sets: List.generate(
          setsCount,
          (i) => CompletedSet(
            setNumber: i + 1,
            targetReps: 10,
            actualReps: 10,
            weightKg: volumeKg / (setsCount * 10),
          ),
        ),
      ),
    ],
    totalVolumeKg: volumeKg,
    estimatedCalories: 300,
    musclesTrained: muscles,
  );
}

void main() {
  late Directory tempDir;
  late JsonStore store;
  late ProgressRepository progressRepo;
  late WorkoutRepository workoutRepo;
  late NutritionRepository nutritionRepo;
  late HealthRepository healthRepo;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('progress_test_');
    store = JsonStore(tempDir);
    progressRepo = ProgressRepository(store);
    workoutRepo = WorkoutRepository(store);
    nutritionRepo = NutritionRepository(store);
    healthRepo = HealthRepository(store, SimulatedHealthAdapter());
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('BodyMeasurementEntry', () {
    test('serializes and deserializes correctly', () {
      final entry = BodyMeasurementEntry(
        id: 'w1',
        date: '2026-10-20',
        weightKg: 75.5,
        waistCm: 82.0,
        bodyFatPercentage: 15.2,
        notes: 'Morning weigh-in',
      );

      final json = entry.toJson();
      final loaded = BodyMeasurementEntry.fromJson(json);

      expect(loaded.id, 'w1');
      expect(loaded.date, '2026-10-20');
      expect(loaded.weightKg, 75.5);
      expect(loaded.waistCm, 82.0);
      expect(loaded.bodyFatPercentage, 15.2);
      expect(loaded.notes, 'Morning weigh-in');
    });

    test('converts units between metric and imperial accurately', () {
      final entry = const BodyMeasurementEntry(
        id: 'w2',
        date: '2026-10-21',
        weightKg: 80.0,
        waistCm: 81.28, // ~32 inches
      );

      expect(entry.weightInUnits('Metric'), 80.0);
      expect(entry.weightInUnits('Imperial'), 176.4);

      expect(entry.waistInUnits('Metric'), 81.3);
      expect(entry.waistInUnits('Imperial'), 32.0);

      expect(BodyMeasurementEntry.toKg(176.37, 'Imperial'), closeTo(80.0, 0.1));
      expect(BodyMeasurementEntry.toCm(32.0, 'Imperial'), closeTo(81.28, 0.1));
    });
  });

  group('RecoveryCalculator', () {
    test('returns 100% fresh readiness when no workouts have occurred', () {
      final readiness = RecoveryCalculator.calculateReadiness(
        sessions: const [],
      );

      expect(readiness.readinessScore, 100);
      expect(readiness.muscles.length, 6);
      for (final muscle in readiness.muscles) {
        expect(muscle.state, MuscleRecoveryState.fresh);
        expect(muscle.recoveryPercentage, 100.0);
        expect(muscle.estimatedHoursToFullRecovery, 0);
      }
    });

    test('applies fatigue drop immediately post-workout and recovers over time', () {
      final now = DateTime(2026, 10, 23, 12, 0);
      // Session finished 1 hour ago
      final sessionJustDone = createTestSession(
        id: 's_recent',
        completedAt: now.subtract(const Duration(hours: 1)),
        setsCount: 8,
        muscles: const ['Chest', 'Arms'],
      );

      final immediateReadiness = RecoveryCalculator.calculateReadiness(
        sessions: [sessionJustDone],
        currentTime: now,
      );

      final chest = immediateReadiness.muscles.firstWhere((m) => m.muscleGroup == 'Chest');
      expect(chest.recoveryPercentage, lessThan(65.0));
      expect(chest.state, anyOf(MuscleRecoveryState.fatigued, MuscleRecoveryState.overreaching));
      expect(chest.estimatedHoursToFullRecovery, greaterThan(20));

      // After 48 hours, recovery should reach >= 80%
      final fortyEightHoursLater = now.add(const Duration(hours: 48));
      final recoveredReadiness = RecoveryCalculator.calculateReadiness(
        sessions: [sessionJustDone],
        currentTime: fortyEightHoursLater,
      );

      final chestRecovered = recoveredReadiness.muscles.firstWhere((m) => m.muscleGroup == 'Chest');
      expect(chestRecovered.recoveryPercentage, greaterThan(80.0));
    });

    test('modulates system readiness with sleep duration and resting heart rate', () {
      final now = DateTime(2026, 10, 23, 12, 0);
      final healthPoorSleep = const DailyHealthSummary(
        date: '2026-10-23',
        sleepDurationMinutes: 240, // 4 hours severe restriction
        restingHeartRateBpm: 88,    // elevated HR
      );

      final poorReadiness = RecoveryCalculator.calculateReadiness(
        sessions: const [],
        latestHealth: healthPoorSleep,
        currentTime: now,
      );

      expect(poorReadiness.sleepFactor, lessThan(1.0));
      expect(poorReadiness.heartRateFactor, lessThan(1.0));
      expect(poorReadiness.readinessScore, lessThan(100));
    });
  });

  group('StreakEngine', () {
    test('computes active consecutive streak when today is active', () {
      final ref = DateTime(2026, 10, 23, 10, 0);
      final s1 = createTestSession(id: '1', completedAt: DateTime(2026, 10, 21));
      final s2 = createTestSession(id: '2', completedAt: DateTime(2026, 10, 22));
      final s3 = createTestSession(id: '3', completedAt: DateTime(2026, 10, 23));

      final streak = StreakEngine.computeWorkoutStreak(
        [s1, s2, s3],
        referenceDate: ref,
      );

      expect(streak.currentStreak, 3);
      expect(streak.longestStreak, 3);
    });

    test('preserves active streak if yesterday was active and today not yet logged', () {
      final ref = DateTime(2026, 10, 23, 8, 0);
      final s1 = createTestSession(id: '1', completedAt: DateTime(2026, 10, 21));
      final s2 = createTestSession(id: '2', completedAt: DateTime(2026, 10, 22));

      final streak = StreakEngine.computeWorkoutStreak(
        [s1, s2],
        referenceDate: ref,
      );

      expect(streak.currentStreak, 2);
    });

    test('resets current streak to 0 if a gap of 2 or more days occurs', () {
      final ref = DateTime(2026, 10, 23, 8, 0);
      // Active on 18th and 19th, gap on 20th, 21st, 22nd
      final s1 = createTestSession(id: '1', completedAt: DateTime(2026, 10, 18));
      final s2 = createTestSession(id: '2', completedAt: DateTime(2026, 10, 19));

      final streak = StreakEngine.computeWorkoutStreak(
        [s1, s2],
        referenceDate: ref,
      );

      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 2);
    });
  });

  group('MilestoneEngine', () {
    test('unlocks first workout and century club milestones', () {
      final catalog = MilestoneBadge.defaultCatalog();
      final sessions = [
        createTestSession(id: 's1', completedAt: DateTime.now(), setsCount: 50, volumeKg: 3000),
        createTestSession(id: 's2', completedAt: DateTime.now(), setsCount: 60, volumeKg: 3000),
      ];

      final updated = MilestoneEngine.evaluateMilestones(
        existingBadges: catalog,
        sessions: sessions,
        prs: const [],
        workoutStreak: const HabitStreak(type: HabitType.workouts, currentStreak: 2, longestStreak: 2),
        nutritionLogs: const {},
        healthSummaries: const {},
      );

      final firstWorkout = updated.firstWhere((b) => b.id == 'first_workout');
      final centuryClub = updated.firstWhere((b) => b.id == 'century_club');
      final volume5k = updated.firstWhere((b) => b.id == 'volume_5k');

      expect(firstWorkout.isUnlocked, isTrue);
      expect(firstWorkout.unlockedAt, isNotNull);
      expect(centuryClub.isUnlocked, isTrue);
      expect(volume5k.isUnlocked, isTrue);
    });
  });

  group('ProgressRepository', () {
    test('saves, loads, and deletes body measurements safely', () async {
      final m1 = const BodyMeasurementEntry(
        id: 'm1',
        date: '2026-10-20',
        weightKg: 78.0,
      );
      final m2 = const BodyMeasurementEntry(
        id: 'm2',
        date: '2026-10-21',
        weightKg: 77.5,
      );

      await progressRepo.addMeasurement(m1);
      await progressRepo.addMeasurement(m2);

      var list = await progressRepo.loadMeasurements();
      expect(list.length, 2);
      expect(list.first.weightKg, 78.0);
      expect(list.last.weightKg, 77.5);

      // Delete m1
      await progressRepo.deleteMeasurement('m1');
      list = await progressRepo.loadMeasurements();
      expect(list.length, 1);
      expect(list.first.id, 'm2');
    });

    test('persists and updates notification preferences', () async {
      final defaults = await progressRepo.loadReminderPreferences();
      expect(defaults.isNotEmpty, isTrue);

      final modified = defaults.map((r) {
        if (r.id == 'rem_workout') {
          return r.copyWith(hour: 6, minute: 45);
        }
        return r;
      }).toList();

      await progressRepo.saveReminderPreferences(modified);
      final loaded = await progressRepo.loadReminderPreferences();

      final workoutRem = loaded.firstWhere((r) => r.id == 'rem_workout');
      expect(workoutRem.hour, 6);
      expect(workoutRem.minute, 45);
      expect(workoutRem.timeFormatted, '6:45 AM');
    });
  });

  group('Progress Widgets', () {
    testWidgets('InteractiveLineChart renders data points, title, and target line', (tester) async {
      final points = [
        ChartDataPoint(date: DateTime(2026, 10, 1), value: 80.0),
        ChartDataPoint(date: DateTime(2026, 10, 15), value: 78.5),
        ChartDataPoint(date: DateTime(2026, 10, 23), value: 77.0),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveLineChart(
              points: points,
              unit: 'kg',
              targetValue: 75.0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('77.0'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);
      expect(find.text('Target: 75.0 kg'), findsOneWidget);
    });

    testWidgets('VolumeBarChart renders weekly volume bars and labels', (tester) async {
      final bars = [
        const VolumeBarData(label: 'W1', volumeKg: 5000, setCount: 24, sessionCount: 3),
        const VolumeBarData(label: 'W2', volumeKg: 7500, setCount: 32, sessionCount: 4),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VolumeBarChart(bars: bars),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('W1'), findsOneWidget);
      expect(find.text('W2'), findsOneWidget);
      expect(find.text('4 sessions • 32 sets'), findsOneWidget);
    });

    testWidgets('StreakTrackerCard renders flame, streak count and day badges', (tester) async {
      const streak = HabitStreak(
        type: HabitType.workouts,
        currentStreak: 5,
        longestStreak: 12,
        weeklyAdherenceRate: 71.4,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakTrackerCard(workoutStreak: streak),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('DAY STREAK'), findsOneWidget);
      expect(find.textContaining('Personal Best: 12 days'), findsOneWidget);
    });

    testWidgets('MuscleRecoveryCard renders readiness score and muscle rows', (tester) async {
      final readiness = OverallSystemReadiness(
        readinessScore: 85,
        sleepFactor: 1.0,
        heartRateFactor: 1.0,
        advice: 'All systems ready for training.',
        muscles: RecoveryCalculator.canonicalMuscleGroups.map((g) {
          return MuscleGroupRecovery(
            muscleGroup: g,
            recoveryPercentage: 92.0,
            state: MuscleRecoveryState.fresh,
            hoursSinceLastTrained: 72.0,
            estimatedHoursToFullRecovery: 0,
          );
        }).toList(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MuscleRecoveryCard(readiness: readiness),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Legs'), findsOneWidget);
      expect(find.text('Shoulders'), findsOneWidget);
      expect(find.text('Arms'), findsOneWidget);
      expect(find.text('Core'), findsOneWidget);
    });

    testWidgets('WeightEntryDialog validates and saves measurement', (tester) async {
      BodyMeasurementEntry? saved;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => WeightEntryDialog(
                      units: 'Metric',
                      onSave: (entry) => saved = entry,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Log Measurement'), findsOneWidget);

      // Enter weight
      final weightField = find.byType(TextField).first;
      await tester.enterText(weightField, '76.8');
      await tester.pump();

      // Submit
      await tester.tap(find.text('Save Record'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.weightKg, 76.8);
    });

    testWidgets('ReminderSettingsScreen renders and toggles notification switch', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressRepositoryProvider.overrideWithValue(progressRepo),
          ],
          child: const MaterialApp(
            home: ReminderSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Reminders & Alerts'), findsOneWidget);
      expect(find.text('Daily Training Session'), findsOneWidget);

      // Toggle first switch
      final switches = find.byType(Switch);
      expect(switches, findsWidgets);
      await tester.tap(switches.first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProgressScreen renders overview, charts, and recovery tabs without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testProfile = const Profile(
        name: 'Test Athlete',
        level: 'Intermediate',
        goal: 'Build muscle',
        days: 4,
        environment: 'Gym',
        weightKg: 78.0,
      );

      await store.write('profile', testProfile.toJson());
      await progressRepo.addMeasurement(const BodyMeasurementEntry(
        id: 'w1',
        date: '2026-10-23',
        weightKg: 78.0,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            progressRepositoryProvider.overrideWithValue(progressRepo),
            workoutRepositoryProvider.overrideWithValue(workoutRepo),
            nutritionRepositoryProvider.overrideWithValue(nutritionRepo),
            healthRepositoryProvider.overrideWithValue(healthRepo),
          ],
          child: const MaterialApp(
            home: ProgressScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('PROGRESS & ANALYTICS'), findsOneWidget);
      expect(find.text('BODY WEIGHT'), findsOneWidget);

      // Tap CHARTS tab
      await tester.tap(find.text('CHARTS'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('BODY WEIGHT TREND'), findsOneWidget);

      // Tap RECOVERY tab
      await tester.tap(find.text('RECOVERY'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Supercompensation & Recovery Curve'), findsOneWidget);

      // Tap BADGES tab
      await tester.tap(find.text('BADGES'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('MILESTONES & ACHIEVEMENTS'), findsOneWidget);
    });
  });
}
