import 'dart:io';

import 'package:fitforge_ai/core/storage/json_store.dart';
import 'package:fitforge_ai/features/exercises/exercise.dart';
import 'package:fitforge_ai/features/exercises/exercise_animation_player.dart';
import 'package:fitforge_ai/features/exercises/exercise_screens.dart';
import 'package:fitforge_ai/features/exercises/favorites.dart';
import 'package:fitforge_ai/features/exercises/muscle_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryFavorites extends FavoritesRepository {
  MemoryFavorites() : super(JsonStore(Directory('/unused')));
  Set<String> ids = {};
  bool fail = false;
  @override
  Future<Set<String>> load() async => Set.of(ids);
  @override
  Future<Set<String>> toggle(String id) async {
    if (fail) throw const FileSystemException('Test write failure');
    if (!ids.remove(id)) ids.add(id);
    return Set.of(ids);
  }
}

Future<void> screen(
  WidgetTester tester,
  Widget child,
  MemoryFavorites repository, {
  double textScale = 1,
  bool reduced = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final catalog = await tester.runAsync(loadCatalog);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        favoritesRepositoryProvider.overrideWithValue(repository),
        exerciseCatalogProvider.overrideWith((ref) async => catalog!),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduced,
          ),
          child: child!,
        ),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'installed exercises match animated HD video clips from openGym and have no numeric names',
    () async {
      final catalog = await loadCatalog();
      expect(catalog.length, greaterThanOrEqualTo(5600));
      expect(catalog.every((e) => e.clip != null && e.still != null), isTrue);
      expect(
        catalog.every(
          (e) => e.videoUrl != null && e.videoUrl!.endsWith('.mp4'),
        ),
        isTrue,
      );
      expect(
        catalog.every(
          (e) => e.stillUrl != null && e.stillUrl!.endsWith('.webp'),
        ),
        isTrue,
      );

      // Verify no exercises are named with raw numeric IDs like "3053"
      expect(
        catalog.every((e) => !RegExp(r'^\d+$').hasMatch(e.name)),
        isTrue,
        reason: 'All exercises must have descriptive human-readable names, never numeric IDs',
      );

      // Verify female variant alias resolution for "3053" -> "0174" Cable Judo Flip
      final judoFlip = findExerciseById(catalog, '3053');
      expect(judoFlip, isNotNull);
      expect(judoFlip!.id, '0174');
      expect(judoFlip.name.toLowerCase(), contains('judo flip'));
      expect(judoFlip.femaleVariant, '3053');
      expect(judoFlip.videoUrlForFigure('male'), contains('0174.mp4'));
      expect(judoFlip.videoUrlForFigure('female'), contains('3053.mp4'));
    },
  );
  test(
    'filters combine query, secondary muscle, equipment, level and favorites',
    () async {
      final catalog = await loadCatalog();
      final found = catalog.where(
        (e) => e.matches(
          query: '  curl dumbbell ',
          muscle: 'Forearms',
          equipmentFilter: 'Dumbbells',
          levelFilter: 'Beginner',
          favorites: {'dumbbell-curl'},
        ),
      );
      expect(found.map((e) => e.id), ['dumbbell-curl']);
      expect(
        catalog.where(
          (e) => e.matches(
            query: 'nonexistentfoobarexercise',
            equipmentFilter: 'Barbell',
          ),
        ),
        isEmpty,
      );
      expect(catalog.where((e) => e.matches(favorites: {})), isEmpty);
    },
  );
  test('concurrent favorite changes survive a repository restart', () async {
    final directory = await Directory.systemTemp.createTemp(
      'fitforge-favorites-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repo = FavoritesRepository(JsonStore(directory));
    await Future.wait([
      repo.toggle('squat'),
      repo.toggle('row'),
      repo.toggle('squat'),
      repo.toggle('plank'),
    ]);
    expect(await FavoritesRepository(JsonStore(directory)).load(), {
      'row',
      'plank',
    });
    await repo.toggle('row');
    expect(await repo.load(), {'plank'});
  });
  test('invalid preferences are preserved and never overwritten', () async {
    final directory = await Directory.systemTemp.createTemp(
      'fitforge-invalid-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/exercise_preferences.json');
    const invalid = '{"version":9,"favorites":[1]}';
    await file.writeAsString(invalid);
    final repo = FavoritesRepository(JsonStore(directory));
    await expectLater(repo.load(), throwsFormatException);
    await expectLater(repo.toggle('squat'), throwsFormatException);
    expect(await file.readAsString(), invalid);
  });
  testWidgets(
    'library searches and persists a favorite; failed saves retain prior state',
    (tester) async {
      final repository = MemoryFavorites();
      await screen(tester, const ExerciseLibraryScreen(), repository);
      await tester.enterText(find.byType(TextField), 'bodyweight squat');
      await tester.pumpAndSettle();
      await reveal(
        tester,
        find.byTooltip('Save Bodyweight squat to favorites'),
      );
      await tester.tap(find.byTooltip('Save Bodyweight squat to favorites'));
      await tester.pumpAndSettle();
      expect(repository.ids, {'squat'});
      repository.fail = true;
      await tester.tap(
        find.byTooltip('Remove Bodyweight squat from favorites'),
      );
      await tester.pumpAndSettle();
      expect(repository.ids, {'squat'});
      expect(find.textContaining('Could not save favorite.'), findsOneWidget);
      final exc = tester.takeException();
      if (exc != null) {
        FlutterError.dumpErrorToConsole(FlutterErrorDetails(exception: exc));
      }
      expect(exc, isNull);
    },
  );
  testWidgets('missing video asset falls back cleanly to anatomical diagram', (
    tester,
  ) async {
    await screen(
      tester,
      const Scaffold(
        body: SingleChildScrollView(
          child: ExerciseAnimationPlayer(
            animationId: 'unavailable',
            primary: ['Chest'],
            secondary: ['Triceps'],
          ),
        ),
      ),
      MemoryFavorites(),
    );
    expect(find.byType(ExerciseAnimationPlayer), findsOneWidget);
    expect(find.text('HD VIDEO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'muscle map taps use painted regions and back view exposes hamstrings',
    (tester) async {
      String? selected;
      await screen(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: MuscleMap(onSelect: (m) => selected = m),
          ),
        ),
        MemoryFavorites(),
      );
      final canvas = find.byKey(const ValueKey('muscle-map-canvas'));
      final rect = tester.getRect(canvas);
      await tester.tapAt(
        rect.topLeft + Offset(rect.width * .5, rect.height * .28),
      );
      expect(selected, 'Chest');
      await tester.tap(find.text('Back').first);
      await tester.pumpAndSettle();
      final backRect = tester.getRect(canvas);
      await tester.tapAt(
        backRect.topLeft + Offset(backRect.width * .42, backRect.height * .65),
      );
      expect(selected, 'Hamstrings');
    },
  );
  testWidgets('detail fallback and large text stay usable on a phone', (
    tester,
  ) async {
    await screen(
      tester,
      const ExerciseDetailScreen(id: 'plank'),
      MemoryFavorites(),
      textScale: 2,
    );
    expect(find.text('HD VIDEO'), findsOneWidget);
    await reveal(tester, find.text('Step by step'));
    expect(find.text('Step by step'), findsOneWidget);
    await reveal(tester, find.text('Copy reference link'));
    expect(tester.takeException(), isNull);
  });
  testWidgets('unknown exercise displays a recovery action', (tester) async {
    await screen(
      tester,
      const ExerciseDetailScreen(id: 'missing'),
      MemoryFavorites(),
    );
    expect(find.text('Exercise not found'), findsOneWidget);
    expect(find.text('Open exercise library'), findsOneWidget);
  });
}
