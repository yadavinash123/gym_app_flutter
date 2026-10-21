import 'dart:io';

import 'package:fitforge_ai/core/storage/json_store.dart';
import 'package:fitforge_ai/features/exercises/exercise.dart';
import 'package:fitforge_ai/features/exercises/exercise_animation_player.dart';
import 'package:fitforge_ai/features/exercises/trainer/exercise_asset_repository.dart';
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
  final assets = await tester.runAsync(
    () => ExerciseAssetRepository().catalog(),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        favoritesRepositoryProvider.overrideWithValue(repository),
        exerciseCatalogProvider.overrideWith((ref) async => catalog!),
        exercise3DAssetsProvider.overrideWith((ref) async => assets!),
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
  test('installed exercise matches an animated, self-contained GLB', () async {
    final catalog = await loadCatalog();
    expect(catalog.length, 22);
    final repo = ExerciseAssetRepository();
    final assets = await repo.catalog();
    expect(assets.keys, ['push-up']);
    for (final exercise in catalog.where((e) => e.animation != null)) {
      expect(assets.containsKey(exercise.animation), isTrue);
      await repo.load(assets[exercise.animation]!);
    }
    final bytes = await repo.load(assets['push-up']!);
    expect(
      () => validateAnimatedGlb(bytes, ['wrong-exercise']),
      throwsFormatException,
    );
    expect(
      () => validateAnimatedGlb(bytes.sublist(0, 100), ['Human.rig']),
      throwsFormatException,
    );
  });
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
          (e) => e.matches(query: 'squat', equipmentFilter: 'Barbell'),
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
      await tester.enterText(find.byType(TextField), 'squat');
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
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('missing 3D asset is an honest illustration fallback', (
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
    expect(find.text('3D animation not installed'), findsOneWidget);
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
    expect(find.text('3D animation not installed'), findsOneWidget);
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
