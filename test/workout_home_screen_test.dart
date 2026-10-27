import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitforge_ai/core/storage/json_store.dart';
import 'package:fitforge_ai/features/exercises/exercise.dart';
import 'package:fitforge_ai/features/profile/profile.dart';
import 'package:fitforge_ai/features/profile/profile_repository.dart';
import 'package:fitforge_ai/features/workouts/data/workout_repository.dart';
import 'package:fitforge_ai/features/workouts/models/planned_workout.dart';
import 'package:fitforge_ai/features/workouts/workout_home_screen.dart';

class FakeWorkoutTemplatesController extends WorkoutTemplatesController {
  FakeWorkoutTemplatesController(this._initial);
  final List<PlannedRoutine> _initial;
  final List<PlannedRoutine> saved = [];

  @override
  Future<List<PlannedRoutine>> build() async {
    saved.clear();
    saved.addAll(_initial);
    return List<PlannedRoutine>.from(saved);
  }

  @override
  Future<void> saveTemplate(PlannedRoutine template) async {
    final index = saved.indexWhere((t) => t.id == template.id);
    if (index >= 0) {
      saved[index] = template;
    } else {
      saved.add(template);
    }
    state = AsyncData(List<PlannedRoutine>.from(saved));
  }
}

void main() {
  late Directory tempDir;
  late JsonStore store;
  late WorkoutRepository workoutRepo;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('workout_home_test_');
    store = JsonStore(tempDir);
    workoutRepo = WorkoutRepository(store);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  final testProfile = const Profile(
    name: 'Champion Athlete',
    level: 'Intermediate',
    goal: 'Build muscle',
    days: 4,
    environment: 'Gym',
    minutes: 45,
    equipment: ['Barbell', 'Dumbbells', 'Bodyweight'],
    weightKg: 80.0,
  );

  final List<Exercise> testCatalog = [
    Exercise(
      id: 'squat',
      name: 'Bodyweight squat',
      cue: 'Chest up, knees tracking over toes.',
      primary: ['Quadriceps', 'Glutes'],
      secondary: ['Hamstrings'],
      equipment: ['Bodyweight'],
      level: 'Beginner',
      movement: 'Squat',
    ),
    Exercise(
      id: 'push-up',
      name: 'Push-up',
      cue: 'Core braced, elbows 45 degrees.',
      primary: ['Chest', 'Triceps'],
      secondary: ['Shoulders'],
      equipment: ['Bodyweight'],
      level: 'Beginner',
      movement: 'Horizontal press',
    ),
  ];

  final testTemplates = [
    const PlannedRoutine(
      id: 'tmpl-full-body',
      name: 'Classic Full Body',
      category: 'Full-body strength',
      targetDurationMinutes: 30,
      isCustom: false,
      exercises: [],
    ),
  ];

  Widget createTestWidget({
    Profile? profile,
    List<Exercise>? catalog,
    FakeWorkoutTemplatesController? templatesController,
    double textScale = 1.0,
  }) {
    final controller =
        templatesController ?? FakeWorkoutTemplatesController(testTemplates);
    return ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(store),
        workoutRepositoryProvider.overrideWithValue(workoutRepo),
        profileProvider.overrideWith((ref) async => profile ?? testProfile),
        exerciseCatalogProvider.overrideWith(
          (ref) async => catalog ?? testCatalog,
        ),
        workoutTemplatesProvider.overrideWith(() => controller),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const WorkoutHomeScreen(),
      ),
    );
  }

  testWidgets(
    'WorkoutHomeScreen renders all main sections without overflow on phone (360x640)',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('WORKOUTS'), findsOneWidget);
      expect(find.text("TODAY'S WORKOUT"), findsOneWidget);
      expect(find.text('WEEKLY SCHEDULE'), findsOneWidget);
      expect(find.text('EXPLORE EXERCISES'), findsOneWidget);
      expect(find.text('Interactive Muscle Map'), findsOneWidget);

      // Scroll down to check subsequent sections
      final mainScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('QUICK WORKOUT'),
        200,
        scrollable: mainScrollable,
      );
      expect(find.text('QUICK WORKOUT'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('WORKOUT PLANS & ROUTINES'),
        200,
        scrollable: mainScrollable,
      );
      expect(find.text('WORKOUT PLANS & ROUTINES'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('WORKOUT PROGRESS'),
        200,
        scrollable: mainScrollable,
      );
      expect(find.text('WORKOUT PROGRESS'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'WorkoutHomeScreen duplicate button duplicates template to custom routines',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = FakeWorkoutTemplatesController(testTemplates);

      await tester.pumpWidget(
        createTestWidget(templatesController: controller),
      );
      await tester.pumpAndSettle();

      // Drag down using top app bar area to scroll vertically past the weekly schedule
      await tester.drag(find.text('WORKOUTS'), const Offset(0, -900));
      await tester.pumpAndSettle();

      final duplicateButtons = find.byTooltip('Duplicate routine');
      expect(duplicateButtons, findsWidgets);

      await tester.tap(duplicateButtons.first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(controller.saved.any((t) => t.name.contains('(Copy)')), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'WorkoutHomeScreen renders at large accessibility text scale without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(textScale: 1.5));
      await tester.pumpAndSettle();

      expect(find.text('WORKOUTS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
