import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitforge_ai/core/storage/json_store.dart';
import 'package:fitforge_ai/features/exercises/exercise.dart';
import 'package:fitforge_ai/features/profile/profile.dart';
import 'package:fitforge_ai/features/workouts/data/workout_generator.dart';
import 'package:fitforge_ai/features/workouts/data/workout_repository.dart';
import 'package:fitforge_ai/features/workouts/models/planned_workout.dart';
import 'package:fitforge_ai/features/workouts/models/progressive_overload.dart';
import 'package:fitforge_ai/features/workouts/models/workout_session.dart';
import 'package:fitforge_ai/features/workouts/session/workout_session_screen.dart';
import 'package:fitforge_ai/features/workouts/session/rest_timer_widget.dart';
import 'package:fitforge_ai/features/workouts/session/workout_summary_screen.dart';
import 'package:fitforge_ai/features/workouts/history/workout_history_screen.dart';
import 'package:fitforge_ai/features/workouts/history/workout_detail_screen.dart';
import 'package:fitforge_ai/features/workouts/custom/custom_workout_screen.dart';

Profile sampleProfile({
  String level = 'Beginner',
  String goal = 'Build muscle',
  int days = 3,
  int minutes = 30,
  List<String> equipment = const ['Dumbbells'],
  bool limited = false,
  String avoided = '',
}) =>
    Profile(
      name: 'Avi',
      level: level,
      goal: goal,
      days: days,
      minutes: minutes,
      environment: 'Home',
      equipment: equipment,
      hasLimitations: limited,
      avoidedExercises: avoided,
    );

List<Exercise> sampleCatalog() => [
      Exercise.fromJson({
        'id': 'push-up',
        'name': 'Push-up',
        'group': 'Chest',
        'primary': ['Chest', 'Triceps'],
        'secondary': ['Shoulders'],
        'equipment': ['Bodyweight'],
        'level': 'Intermediate',
        'movement': 'Push',
        'steps': ['Lower chest to floor', 'Press back up'],
        'cue': 'Keep core braced',
        'mistake': 'Sagging hips',
        'source': 'NASM',
        'url': 'https://example.com/pushup',
        'animation': null,
        'alternatives': <String>[],
      }),
      Exercise.fromJson({
        'id': 'squat',
        'name': 'Bodyweight squat',
        'group': 'Legs',
        'primary': ['Quadriceps', 'Glutes'],
        'secondary': ['Hamstrings'],
        'equipment': ['Bodyweight'],
        'level': 'Beginner',
        'movement': 'Squat',
        'steps': ['Bend hips and knees', 'Stand up'],
        'cue': 'Knees follow toes',
        'mistake': 'Rounding back',
        'source': 'Mayo Clinic',
        'url': 'https://example.com/squat',
        'animation': null,
        'alternatives': <String>[],
      }),
      Exercise.fromJson({
        'id': 'dumbbell-curl',
        'name': 'Dumbbell curl',
        'group': 'Biceps',
        'primary': ['Biceps'],
        'secondary': ['Forearms'],
        'equipment': ['Dumbbells'],
        'level': 'Beginner',
        'movement': 'Elbow flexion',
        'steps': ['Curl dumbbell up', 'Lower with control'],
        'cue': 'Elbows tucked',
        'mistake': 'Swinging weight',
        'source': 'Mayo Clinic',
        'url': 'https://example.com/curl',
        'animation': null,
        'alternatives': <String>[],
      }),
      Exercise.fromJson({
        'id': 'chest-stretch',
        'name': 'Chest stretch',
        'group': 'Chest',
        'primary': ['Chest', 'Shoulders'],
        'secondary': <String>[],
        'equipment': ['Bodyweight'],
        'level': 'Beginner',
        'movement': 'Mobility',
        'steps': ['Open arms wide', 'Breathe gently'],
        'cue': 'Gentle stretch only',
        'mistake': 'Over-extending',
        'source': 'NHS',
        'url': 'https://example.com/stretch',
        'animation': null,
        'alternatives': <String>[],
      }),
    ];

void main() {
  group('WorkoutGenerator', () {
    test('generates routine matching user equipment and goal', () {
      final profile = sampleProfile(
        goal: 'Build strength',
        minutes: 30,
        equipment: ['Dumbbells'],
      );
      final catalog = sampleCatalog();
      final routine = WorkoutGenerator.generateRoutineForDay(
        profile: profile,
        sessionKind: 'Full-body strength',
        catalog: catalog,
      );

      expect(routine.exercises.isNotEmpty, isTrue);
      expect(routine.category, 'Full-body strength');
      // Strength goal sets target reps to 5
      expect(routine.exercises.first.sets.first.targetReps, 5);
      expect(routine.exercises.first.sets.first.targetRestSeconds, 90);
    });

    test('strictly restricts exercises to gentle mobility when user has limitations', () {
      final profile = sampleProfile(limited: true);
      final catalog = sampleCatalog();
      final routine = WorkoutGenerator.generateRoutineForDay(
        profile: profile,
        sessionKind: 'Full-body strength',
        catalog: catalog,
      );

      // Only chest-stretch has movement == 'Mobility'
      for (final ex in routine.exercises) {
        expect(ex.exerciseId, 'chest-stretch');
      }
    });

    test('filters out avoided exercises', () {
      final profile = sampleProfile(avoided: 'push-up');
      final catalog = sampleCatalog();
      final routine = WorkoutGenerator.generateRoutineForDay(
        profile: profile,
        sessionKind: 'Full-body strength',
        catalog: catalog,
      );

      expect(
        routine.exercises.any((e) => e.exerciseId == 'push-up'),
        isFalse,
      );
    });
  });

  group('ProgressiveOverloadCalculator', () {
    test('Brzycki formula calculates accurate 1RM estimates', () {
      // 100kg for 1 rep = 100kg
      expect(ProgressiveOverloadCalculator.estimateOneRepMax(100, 1), 100.0);
      // 80kg for 5 reps: 80 * (36 / 32) = 90.0kg
      expect(ProgressiveOverloadCalculator.estimateOneRepMax(80, 5), 90.0);
    });

    test('recommends conservative load increase when effort was comfortable (RPE <= 7.5)', () {
      final session = WorkoutSession(
        id: 's1',
        routineId: 'r1',
        routineName: 'Upper',
        startedAt: DateTime.now().subtract(const Duration(days: 2)),
        completedAt: DateTime.now().subtract(const Duration(days: 2)),
        durationSeconds: 1800,
        totalVolumeKg: 600,
        estimatedCalories: 150,
        musclesTrained: ['Biceps'],
        exercises: [
          const CompletedExercise(
            exerciseId: 'dumbbell-curl',
            exerciseName: 'Dumbbell curl',
            primaryMuscles: ['Biceps'],
            sets: [
              CompletedSet(
                setNumber: 1,
                targetReps: 10,
                actualReps: 10,
                weightKg: 10.0,
                rpe: 7,
              ),
              CompletedSet(
                setNumber: 2,
                targetReps: 10,
                actualReps: 10,
                weightKg: 10.0,
                rpe: 7,
              ),
            ],
          ),
        ],
      );

      final recommendation =
          ProgressiveOverloadCalculator.evaluateProgression(
        exerciseId: 'dumbbell-curl',
        pastSessions: [session],
        isBodyweight: false,
        isLowerBody: false,
      );

      expect(
        recommendation.decision,
        ProgressionDecision.increaseLoad,
      );
      expect(recommendation.suggestedWeightKg, 11.25);
    });

    test('never increases load and gives alert if pain was reported', () {
      final session = WorkoutSession(
        id: 's2',
        routineId: 'r1',
        routineName: 'Upper',
        startedAt: DateTime.now().subtract(const Duration(days: 1)),
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
        durationSeconds: 1800,
        totalVolumeKg: 600,
        estimatedCalories: 150,
        musclesTrained: ['Chest'],
        exercises: [
          const CompletedExercise(
            exerciseId: 'push-up',
            exerciseName: 'Push-up',
            primaryMuscles: ['Chest'],
            painReported: true,
            sets: [
              CompletedSet(
                setNumber: 1,
                targetReps: 10,
                actualReps: 10,
                weightKg: 0.0,
                rpe: 6,
                painReported: true,
              ),
            ],
          ),
        ],
      );

      final recommendation =
          ProgressiveOverloadCalculator.evaluateProgression(
        exerciseId: 'push-up',
        pastSessions: [session],
        isBodyweight: true,
        isLowerBody: false,
      );

      expect(
        recommendation.decision,
        ProgressionDecision.painWarning,
      );
      expect(recommendation.message, contains('Pain or discomfort was reported'));
    });

    test('recommends deload or maintenance if RPE >= 9', () {
      final session = WorkoutSession(
        id: 's3',
        routineId: 'r1',
        routineName: 'Upper',
        startedAt: DateTime.now().subtract(const Duration(days: 1)),
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
        durationSeconds: 1800,
        totalVolumeKg: 600,
        estimatedCalories: 150,
        musclesTrained: ['Biceps'],
        exercises: [
          const CompletedExercise(
            exerciseId: 'dumbbell-curl',
            exerciseName: 'Dumbbell curl',
            primaryMuscles: ['Biceps'],
            sets: [
              CompletedSet(
                setNumber: 1,
                targetReps: 10,
                actualReps: 8,
                weightKg: 15.0,
                rpe: 10,
              ),
            ],
          ),
        ],
      );

      final recommendation =
          ProgressiveOverloadCalculator.evaluateProgression(
        exerciseId: 'dumbbell-curl',
        pastSessions: [session],
        isBodyweight: false,
        isLowerBody: false,
      );

      expect(
        recommendation.decision,
        ProgressionDecision.deloadOrRest,
      );
      expect(recommendation.message, contains('High perceived effort'));
    });
  });

  group('WorkoutSession Model & Calorie Estimation', () {
    test('calculates approximate calories with MET formula correctly', () {
      // 70kg person, 3600 seconds (1 hr), MET 5.5 = ~385 kcal
      final kcal = WorkoutSession.calculateEstimatedCalories(
        weightKg: 70.0,
        durationSeconds: 3600,
      );
      expect(kcal, 385);
    });

    test('calculates volume correctly from completed sets only', () {
      const exercise = CompletedExercise(
        exerciseId: 'squat',
        exerciseName: 'Squat',
        primaryMuscles: ['Quadriceps'],
        sets: [
          CompletedSet(
            setNumber: 1,
            targetReps: 10,
            actualReps: 10,
            weightKg: 50.0,
            isCompleted: true,
          ),
          CompletedSet(
            setNumber: 2,
            targetReps: 10,
            actualReps: 8,
            weightKg: 50.0,
            isCompleted: false, // Incomplete, should not add to volume
          ),
        ],
      );
      expect(exercise.totalVolumeKg, 500.0);
    });
  });

  group('WorkoutRepository with JsonStore', () {
    late Directory tempDir;
    late JsonStore store;
    late WorkoutRepository repo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fitforge_workout_test_');
      store = JsonStore(tempDir);
      repo = WorkoutRepository(store);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saves and loads workout sessions atomically', () async {
      final session = WorkoutSession(
        id: 'test-session-1',
        routineId: 'tmpl-full-body',
        routineName: 'Full Body Test',
        startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        completedAt: DateTime.now(),
        durationSeconds: 1800,
        exercises: const [
          CompletedExercise(
            exerciseId: 'squat',
            exerciseName: 'Bodyweight squat',
            primaryMuscles: ['Quadriceps'],
            sets: [
              CompletedSet(
                setNumber: 1,
                targetReps: 10,
                actualReps: 10,
                weightKg: 0.0,
              ),
            ],
          ),
        ],
        totalVolumeKg: 0.0,
        estimatedCalories: 160,
        musclesTrained: const ['Quadriceps'],
      );

      await repo.saveSession(session);
      final loaded = await repo.loadSessions();

      expect(loaded.length, 1);
      expect(loaded.first.id, 'test-session-1');
      expect(loaded.first.routineName, 'Full Body Test');

      // Delete session
      await repo.deleteSession('test-session-1');
      final afterDelete = await repo.loadSessions();
      expect(afterDelete.isEmpty, isTrue);
    });

    test('loads default templates and supports saving custom templates', () async {
      final templates = await repo.loadTemplates();
      expect(templates.isNotEmpty, isTrue);

      const custom = PlannedRoutine(
        id: 'custom-1',
        name: 'My Special Routine',
        category: 'Upper-body strength',
        exercises: [],
        isCustom: true,
      );

      await repo.saveTemplate(custom);
      final updated = await repo.loadTemplates();
      expect(updated.any((t) => t.id == 'custom-1'), isTrue);
    });

    testWidgets('WorkoutSessionScreen renders without overflow on narrow device', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const routine = PlannedRoutine(
        id: 'r1',
        name: 'Full Body Heavy Blast Test',
        category: 'Full-body strength',
        exercises: [
          PlannedExercise(
            exerciseId: 'squat',
            exerciseName: 'Bodyweight squat with deep range',
            primaryMuscles: ['Quadriceps', 'Glutes'],
            sets: [
              PlannedSet(setNumber: 1, targetReps: 12, targetRestSeconds: 60),
              PlannedSet(setNumber: 2, targetReps: 12, targetRestSeconds: 60),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: WorkoutSessionScreen(routine: routine),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Bodyweight squat with deep range'), findsOneWidget);

      // Verify tapping pain check
      await tester.ensureVisible(find.text('Report discomfort or joint pain'));
      await tester.tap(find.text('Report discomfort or joint pain'));
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Verify logging set
      await tester.ensureVisible(find.text('LOG SET & START REST'));
      await tester.tap(find.text('LOG SET & START REST'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.text('REST PERIOD'), findsOneWidget);
    });

    testWidgets('RestTimerWidget operates without overflow on narrow screen', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestTimerWidget(
              initialSeconds: 60,
              nextExerciseName: 'Super Long Exercise Name Overhead Extension',
              nextSetNumber: 2,
              onComplete: () {},
              onSkip: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.text('REST PERIOD'), findsOneWidget);

      // Tap +15s
      await tester.tap(find.text('+15s'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('WorkoutSummaryScreen renders on small screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = WorkoutSession(
        id: 's-sum',
        routineId: 'r-sum',
        routineName: 'Hypertrophy Upper Body Power Routine',
        startedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        completedAt: DateTime.now(),
        durationSeconds: 2700,
        exercises: const [
          CompletedExercise(
            exerciseId: 'push-up',
            exerciseName: 'Push-up',
            primaryMuscles: ['Chest'],
            sets: [
              CompletedSet(setNumber: 1, targetReps: 15, actualReps: 15, weightKg: 0),
            ],
          ),
        ],
        totalVolumeKg: 2500,
        estimatedCalories: 320,
        musclesTrained: const ['Chest', 'Triceps', 'Shoulders'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: WorkoutSummaryScreen(session: session),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Great Job!'), findsOneWidget);
    });

    testWidgets('WorkoutHistoryScreen and WorkoutDetailScreen render without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = WorkoutSession(
        id: 's-hist',
        routineId: 'r-hist',
        routineName: 'Heavy Duty Lower Body Hypertrophy Session',
        startedAt: DateTime(2026, 10, 20, 10, 0),
        completedAt: DateTime(2026, 10, 20, 10, 40),
        durationSeconds: 2400,
        exercises: const [
          CompletedExercise(
            exerciseId: 'squat',
            exerciseName: 'Barbell Back Squats with Heavy Load',
            primaryMuscles: ['Quadriceps', 'Glutes'],
            sets: [
              CompletedSet(setNumber: 1, targetReps: 8, actualReps: 8, weightKg: 100),
            ],
          ),
        ],
        totalVolumeKg: 800,
        estimatedCalories: 280,
        musclesTrained: const ['Quadriceps'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: WorkoutDetailScreen(session: session),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('EXERCISES PERFORMED'), findsOneWidget);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: WorkoutHistoryScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('CustomWorkoutScreen renders and interacts without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: CustomWorkoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('CREATE ROUTINE'), findsOneWidget);
    });
  });
}
