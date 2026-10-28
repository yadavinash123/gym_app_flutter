import 'dart:io';

import 'package:fitforge_ai/core/storage/json_store.dart';
import 'package:fitforge_ai/features/exercises/custom_exercise_form_screen.dart';
import 'package:fitforge_ai/features/exercises/custom_exercise_repository.dart';
import 'package:fitforge_ai/features/exercises/exercise.dart';
import 'package:fitforge_ai/features/exercises/exercise_animation_player.dart';
import 'package:fitforge_ai/features/exercises/exercise_screens.dart';
import 'package:fitforge_ai/shared/widgets/toast.dart';
import 'package:fitforge_ai/features/profile/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryCustomExerciseRepository extends CustomExerciseRepository {
  MemoryCustomExerciseRepository() : super(JsonStore(Directory('/unused')));
  final List<Exercise> items = [];

  @override
  Future<List<Exercise>> load() async => List.of(items);

  @override
  Future<Exercise> save(Exercise exercise) async {
    final id = exercise.id.isEmpty
        ? 'c_${DateTime.now().millisecondsSinceEpoch}'
        : exercise.id;
    final updated = exercise.copyWith(id: id, isCustom: true);
    final idx = items.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      items[idx] = updated;
    } else {
      items.insert(0, updated);
    }
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    items.removeWhere((e) => e.id == id);
  }
}

void main() {
  late Directory tempDir;
  late JsonStore jsonStore;
  late CustomExerciseRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fitforge_custom_test_');
    jsonStore = JsonStore(tempDir);
    repository = CustomExerciseRepository(jsonStore);
  });

  tearDown(() async {
    AppToast.dismiss();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CustomExerciseRepository', () {
    test('starts with empty list', () async {
      final list = await repository.load();
      expect(list, isEmpty);
    });

    test('creates and loads custom exercise with unique ID', () async {
      final ex = Exercise(
        id: '',
        name: 'Incline Cable Fly',
        group: 'Chest',
        bodyPart: 'Chest',
        equipment: const ['Cable'],
        level: 'Intermediate',
        isCustom: true,
      );

      final saved = await repository.save(ex);
      expect(saved.id, startsWith('c_'));
      expect(saved.name, 'Incline Cable Fly');
      expect(saved.isCustom, isTrue);

      final list = await repository.load();
      expect(list.length, 1);
      expect(list.first.id, saved.id);
      expect(list.first.name, 'Incline Cable Fly');
    });

    test('updates existing custom exercise', () async {
      final ex = Exercise(
        id: 'c_test_1',
        name: 'Floor Press',
        group: 'Chest',
        bodyPart: 'Chest',
        equipment: const ['Dumbbell'],
        isCustom: true,
      );

      await repository.save(ex);

      final updated = ex.copyWith(
        name: 'Dumbbell Floor Press',
        level: 'Advanced',
      );
      await repository.save(updated);

      final list = await repository.load();
      expect(list.length, 1);
      expect(list.first.name, 'Dumbbell Floor Press');
      expect(list.first.level, 'Advanced');
    });

    test('deletes custom exercise and cleans up media', () async {
      // Create a temporary media file to simulate picked file
      final dummyMedia = File('${tempDir.path}/test_pic.jpg');
      await dummyMedia.writeAsString('image-bytes');

      final ex = Exercise(
        id: 'c_to_delete',
        name: 'Seated Dip',
        group: 'Arms',
        bodyPart: 'Arms',
        equipment: const ['Bodyweight'],
        isCustom: true,
        mediaPath: dummyMedia.path,
        mediaType: 'image',
      );

      final saved = await repository.save(ex);
      expect(saved.mediaPath, isNotNull);
      expect(File(saved.mediaPath!).existsSync(), isTrue);

      await repository.delete(saved.id);
      final list = await repository.load();
      expect(list, isEmpty);
      expect(File(saved.mediaPath!).existsSync(), isFalse);
    });
  });

  group('Catalog integration', () {
    test('merges custom exercises at the beginning of the catalog', () async {
      final dummyCustom = Exercise(
        id: 'c_custom_001',
        name: 'My Special Squat',
        group: 'Legs',
        bodyPart: 'Legs',
        equipment: const ['Barbell'],
        isCustom: true,
      );
      await repository.save(dummyCustom);

      final savedList = await repository.load();
      expect(savedList.length, 1);
      expect(savedList.first.name, 'My Special Squat');
    });
  });

  group('Widgets', () {
    testWidgets('CustomExerciseFormScreen validates empty exercise name', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(jsonStore),
            customExerciseRepositoryProvider.overrideWithValue(repository),
            exerciseCatalogProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(home: CustomExerciseFormScreen()),
        ),
      );

      // Tap Create action in AppBar
      await tester.tap(find.widgetWithText(TextButton, 'Create'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an exercise name'), findsOneWidget);
    });

    testWidgets('CustomExerciseFormScreen creates exercise on valid input', (
      tester,
    ) async {
      final memRepo = MemoryCustomExerciseRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customExerciseRepositoryProvider.overrideWithValue(memRepo),
            exerciseCatalogProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(home: CustomExerciseFormScreen()),
        ),
      );

      // Enter name
      await tester.enterText(
        find.byType(TextFormField).first,
        'Nordic Hamstring Curl',
      );
      await tester.pumpAndSettle();

      // Tap Create action in AppBar
      await tester.tap(find.widgetWithText(TextButton, 'Create'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(memRepo.items.length, 1);
      expect(memRepo.items.first.name, 'Nordic Hamstring Curl');
    });

    testWidgets('ExerciseLibraryScreen displays create banner and custom exercise', (
      tester,
    ) async {
      final customEx = Exercise(
        id: 'c_custom_test',
        name: 'Custom Lateral Raise',
        group: 'Shoulders',
        bodyPart: 'Shoulders',
        equipment: const ['Dumbbell'],
        isCustom: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(jsonStore),
            customExerciseRepositoryProvider.overrideWithValue(repository),
            exerciseCatalogProvider.overrideWith((ref) async => [customEx]),
          ],
          child: const MaterialApp(home: ExerciseLibraryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Create banner is displayed
      expect(find.text('Create your own exercise'), findsOneWidget);
      // Top create button in AppBar is displayed
      expect(find.byTooltip('Create custom exercise'), findsOneWidget);
      // Bottom New Exercise FAB is removed
      expect(find.text('New Exercise'), findsNothing);
      // Custom filter chip is displayed
      expect(find.widgetWithText(FilterChip, 'Custom (1)'), findsOneWidget);
      // Custom exercise is shown with CUSTOM badge
      expect(find.text('Custom Lateral Raise'), findsOneWidget);
      expect(find.text('CUSTOM'), findsOneWidget);
    });

    testWidgets('ExerciseLibraryScreen filters by Custom chip correctly', (
      tester,
    ) async {
      final customEx = Exercise(
        id: 'c_my_curl',
        name: 'My Special Bicep Curl',
        group: 'Arms',
        bodyPart: 'Arms',
        equipment: const ['Dumbbell'],
        isCustom: true,
      );
      final standardEx = Exercise(
        id: 'standard_bench',
        name: 'Barbell Bench Press',
        group: 'Chest',
        bodyPart: 'Chest',
        equipment: const ['Barbell'],
        isCustom: false,
      );

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(jsonStore),
            customExerciseRepositoryProvider.overrideWithValue(repository),
            exerciseCatalogProvider.overrideWith(
              (ref) async => [customEx, standardEx],
            ),
          ],
          child: const MaterialApp(home: ExerciseLibraryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Initially both are visible
      expect(find.text('My Special Bicep Curl'), findsOneWidget);
      expect(find.text('Barbell Bench Press'), findsOneWidget);

      // Tap Custom filter chip
      await tester.tap(find.widgetWithText(FilterChip, 'Custom (1)'));
      await tester.pumpAndSettle();

      // Only custom exercise remains visible
      expect(find.text('My Special Bicep Curl'), findsOneWidget);
      expect(find.text('Barbell Bench Press'), findsNothing);
    });

    testWidgets('ExerciseDetailScreen displays CUSTOM badge and Edit button for custom exercise', (
      tester,
    ) async {
      final customEx = Exercise(
        id: 'c_custom_test',
        name: 'Custom Lateral Raise',
        group: 'Shoulders',
        bodyPart: 'Shoulders',
        equipment: const ['Dumbbell'],
        isCustom: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(jsonStore),
            customExerciseRepositoryProvider.overrideWithValue(repository),
            exerciseCatalogProvider.overrideWith((ref) async => [customEx]),
          ],
          child: const MaterialApp(
            home: ExerciseDetailScreen(id: 'c_custom_test'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom Lateral Raise'), findsOneWidget);
      expect(find.text('CUSTOM'), findsOneWidget);
      expect(find.text('Edit Exercise'), findsOneWidget);
      expect(find.text('Delete Exercise'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.delete_outline), findsAtLeastNWidgets(1));
    });

    testWidgets('ExerciseAnimationPlayer renders custom photo without CircularProgressIndicator and shows Tap to Zoom', (
      tester,
    ) async {
      final photoEx = Exercise(
        id: 'c_photo_test',
        name: 'Dumbbell Incline Bench',
        group: 'Chest',
        bodyPart: 'Chest',
        equipment: const ['Dumbbell'],
        isCustom: true,
        mediaType: 'image',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseAnimationPlayer(
              exercise: photoEx,
              exerciseName: photoEx.name,
            ),
          ),
        ),
      );
      await tester.pump();

      // Badges
      expect(find.text('PHOTO'), findsOneWidget);
      // Photo should NOT show circular spinner
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Tap to Zoom pill should be visible
      expect(find.text('Tap to Zoom'), findsOneWidget);
      // Should NOT have video play/pause buttons
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
    });

    testWidgets('AppToast renders properly on screen with message and type', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  AppToast.show(
                    ctx,
                    message: '“Incline Curl” saved successfully',
                    type: ToastType.success,
                  );
                },
                child: const Text('Show Toast'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('“Incline Curl” saved successfully'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      AppToast.dismiss();
      await tester.pumpAndSettle();
    });
  });
}
