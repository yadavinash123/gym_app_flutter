import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitforge_ai/app/app.dart';
import 'package:fitforge_ai/core/storage/json_store.dart';
import 'package:fitforge_ai/features/profile/profile.dart';
import 'package:fitforge_ai/features/profile/profile_repository.dart';

Future<void> start(
  WidgetTester tester,
  MemoryProfileRepository repository,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final tempDir = Directory.systemTemp.createTempSync('widget_test_store');
  addTearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });
  final store = JsonStore(tempDir);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(store),
        profileRepositoryProvider.overrideWithValue(repository),
      ],
      child: const FitForgeApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> reveal(
  WidgetTester tester,
  Finder finder, {
  double direction = 250,
}) async {
  await tester.scrollUntilVisible(
    finder,
    direction,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> press(WidgetTester tester, String text) async {
  await reveal(tester, find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String key, String value) async {
  await reveal(tester, find.byKey(ValueKey(key)));
  await tester.enterText(find.byKey(ValueKey(key)), value);
  await tester.pumpAndSettle();
}

Future<void> choose(
  WidgetTester tester,
  String label,
  String current,
  String value,
) async {
  final finder = find.byKey(ValueKey('$label:$current'));
  await reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'ten-step onboarding validates, previews, retries save, and navigates on a phone',
    (tester) async {
      final repository = MemoryProfileRepository()..failSave = true;
      await start(tester, repository);
      await press(tester, 'Continue');
      expect(find.text('Enter Name or nickname'), findsOneWidget);
      await enter(tester, 'name', 'Avi');
      await press(tester, 'Continue'); // identity
      await press(tester, 'Continue'); // experience
      await press(tester, 'Continue'); // measurements
      await enter(tester, 'age', '30');
      await enter(tester, 'height', '180');
      await enter(tester, 'weight', '80');
      await choose(
        tester,
        'Energy equation (optional)',
        'Skip estimate',
        'Male coefficient',
      );
      await press(tester, 'Continue'); // goals
      await press(tester, 'Continue'); // environment
      await choose(tester, 'Training environment', 'Gym', 'Home');
      await press(tester, 'Continue'); // availability
      await press(tester, 'Sunday');
      await press(tester, 'Continue'); // food
      await enter(tester, 'allergies', 'Peanuts');
      await enter(tester, 'budget', '150');
      await press(tester, 'Continue'); // limitations
      await enter(tester, 'limitations', 'Knee pain');
      await press(tester, 'Continue'); // review
      expect(find.text('Your starting plan.'), findsOneWidget);
      expect(repository.profile, isNull); // Preview must not persist anything.
      await enter(tester, 'calories', '0');
      await press(tester, 'Save profile and plan');
      expect(repository.saveAttempts, 0);
      await enter(tester, 'calories', '2400');
      await enter(tester, 'protein', '125');
      await press(tester, 'Save profile and plan');
      expect(
        find.textContaining('Could not save your profile.'),
        findsOneWidget,
      );
      expect(repository.profile, isNull);
      repository.failSave = false;
      await press(tester, 'Save profile and plan');
      expect(repository.profile!.allergies, 'Peanuts');
      expect(repository.profile!.budgetInr, 150);
      expect(repository.profile!.calorieTarget, 2400);
      expect(repository.profile!.proteinTarget, 125);
      expect(repository.profile!.hasLimitations, isTrue);
      expect(repository.profile!.schedule[6], 'Recovery');
      expect(
        repository.profile!.schedule.where((s) => s != 'Recovery').toSet(),
        {'Mobility'},
      );
      expect(find.text('Welcome back,\nAvi.'), findsOneWidget);
      await tester.tap(find.text('Workouts'));
      await tester.pumpAndSettle();
      expect(find.text('Your weekly outline'), findsOneWidget);
      await tester.tap(find.text('Nutrition'));
      await tester.pumpAndSettle();
      expect(find.text('DAILY MEALS'), findsOneWidget);
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      expect(find.text('Coming in a later phase'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'settings converts units, cancels without saving, and edits targets',
    (tester) async {
      final repository = MemoryProfileRepository()
        ..profile = const Profile(
          name: 'Avi',
          level: 'Beginner',
          goal: 'Build muscle',
          days: 3,
          environment: 'Home',
          age: 30,
          heightCm: 177.8,
          weightKg: 70,
          waistCm: 81.28,
        );
      await start(tester, repository);
      await tester.tap(find.byTooltip('Profile settings'));
      await tester.pumpAndSettle();
      await press(tester, 'Measurements & units');
      await choose(tester, 'Measurement units', 'Metric', 'Imperial');
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('height')))
            .controller!
            .text,
        '70.00',
      );
      expect(
        double.parse(
          tester
              .widget<TextFormField>(find.byKey(const ValueKey('weight')))
              .controller!
              .text,
        ),
        closeTo(154.32, 0.01),
      );
      await press(tester, 'Cancel changes');
      expect(repository.saveAttempts, 0);
      expect(repository.profile!.units, 'Metric');
      await tester.tap(find.byTooltip('Back to home'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back,\nAvi.'), findsOneWidget);
      await tester.tap(find.byTooltip('Profile settings'));
      await tester.pumpAndSettle();
      await press(tester, 'Plan & personal targets');
      await enter(tester, 'calories', '2300');
      await press(tester, 'Save profile and plan');
      expect(repository.profile!.calorieTarget, 2300);
      expect(repository.profile!.heightCm, 177.8);
      expect(repository.profile!.schedule.length, 7);
      expect(find.text('Welcome back,\nAvi.'), findsOneWidget);
    },
  );

  testWidgets('profile editing remains usable at large text size', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repository = MemoryProfileRepository()
      ..profile = const Profile(
        name: 'Avi',
        level: 'Beginner',
        goal: 'Build muscle',
        days: 3,
        environment: 'Home',
      );
    await start(tester, repository);
    await tester.tap(find.byTooltip('Profile settings'));
    await tester.pumpAndSettle();
    await press(tester, 'Goals');
    expect(find.text('Choose your direction.'), findsOneWidget);
    await press(tester, 'Cancel changes');
    await press(tester, 'Plan & personal targets');
    await press(tester, 'Save profile and plan');
    expect(repository.saveAttempts, 1);
    expect(find.text('Welcome back,\nAvi.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('conflicting rest days block advancing and can be corrected', (
    tester,
  ) async {
    final repository = MemoryProfileRepository()
      ..profile = const Profile(
        name: 'Avi',
        level: 'Beginner',
        goal: 'Build muscle',
        days: 7,
        environment: 'Home',
      );
    await start(tester, repository);
    await tester.tap(find.byTooltip('Profile settings'));
    await tester.pumpAndSettle();
    await press(tester, 'Training availability');
    await press(tester, 'Sunday');
    await press(tester, 'Continue');
    expect(
      find.text('Choose fewer training days or release a preferred rest day.'),
      findsOneWidget,
    );
    await press(tester, 'Sunday');
    await press(tester, 'Continue');
    expect(find.text('Food that fits you.'), findsOneWidget);
    expect(repository.saveAttempts, 0);
  });
}

class MemoryProfileRepository extends ProfileRepository {
  MemoryProfileRepository() : super(JsonStore(Directory('/unused')));
  Profile? profile;
  bool failSave = false;
  int saveAttempts = 0;
  @override
  Future<Profile?> load() async => profile;
  @override
  Future<void> save(Profile value) async {
    saveAttempts++;
    if (failSave) throw const FileSystemException('Simulated storage failure');
    profile = Profile.fromJson(value.toJson());
  }
}
