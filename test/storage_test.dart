import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitforge_ai/core/storage/json_store.dart';
import 'package:fitforge_ai/features/profile/profile.dart';
import 'package:fitforge_ai/features/profile/profile_repository.dart';

void main() {
  late Directory directory;
  late JsonStore store;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('fitforge_test_');
    store = JsonStore(directory);
  });
  tearDown(() async => directory.delete(recursive: true));

  test('version 1 migration preserves identity, keeps optional data absent, and upgrades on save', () async {
    final legacy = {
      'schemaVersion': 1,
      'name': 'Legacy',
      'level': 'Advanced',
      'goal': 'Build strength',
      'days': 4,
      'environment': 'Both',
    };
    await store.write('profile', legacy);
    final repository = ProfileRepository(store);
    final migrated = (await repository.load())!;
    expect(migrated.name, 'Legacy');
    expect(migrated.level, 'Advanced');
    expect(migrated.days, 4);
    expect(migrated.age, isNull);
    expect(migrated.weightKg, isNull);
    expect(migrated.energyEquation, 'Skip estimate');
    expect((await store.read('profile'))!['schemaVersion'], 1);
    await repository.save(migrated);
    expect((await store.read('profile'))!['schemaVersion'], 2);
    expect(
      (await ProfileRepository(JsonStore(directory)).load())!.toJson(),
      migrated.toJson(),
    );
  });
  test('expanded profile and custom plan survive a storage restart', () async {
    final p = Profile(
      name: 'Avi',
      level: 'Beginner',
      goal: 'Improve fitness',
      days: 2,
      environment: 'Home',
      units: 'Imperial',
      age: 28,
      weightKg: 70,
      heightCm: 175,
      restDays: [1, 3, 5, 6],
      schedule: [
        'Mobility',
        'Recovery',
        'Easy cardio',
        'Recovery',
        'Recovery',
        'Recovery',
        'Recovery',
      ],
      allergies: 'Peanuts',
      foodRestrictions: 'No dairy',
      equipment: ['Resistance bands'],
      calorieTarget: 2100,
      proteinTarget: 100,
      budgetInr: 150,
      meals: 4,
    );
    await ProfileRepository(store).save(p);
    final loaded = (await ProfileRepository(JsonStore(directory)).load())!;
    expect(loaded.toJson(), p.toJson());
  });
  test('profile persists across repository and store instances', () async {
    const profile = Profile(
      name: 'Avi',
      level: 'Beginner',
      goal: 'Build muscle',
      days: 3,
      environment: 'Gym',
    );
    await ProfileRepository(store).save(profile);
    final restored = await ProfileRepository(JsonStore(directory)).load();
    expect(restored!.toJson(), profile.toJson());
  });
  test(
    'serialized writes preserve newest state and recover previous data',
    () async {
      await Future.wait(
        List.generate(20, (i) => store.write('sample', {'count': i})),
      );
      expect((await store.read('sample'))!['count'], 19);
      await File('${directory.path}/sample.json').writeAsString('{broken');
      expect((await JsonStore(directory).read('sample'))!['count'], 18);
      await store.write('sample', {'count': 20});
      expect((await store.read('sample'))!['count'], 20);
    },
  );
  test('corrupt unbacked files are preserved and reported', () async {
    final file = File('${directory.path}/sample.json');
    await file.writeAsString('{broken');
    await expectLater(store.read('sample'), throwsFormatException);
    expect(await file.readAsString(), '{broken');
  });
  test('unknown schema is rejected without overwriting', () async {
    await store.write('profile', {'schemaVersion': 99});
    await expectLater(ProfileRepository(store).load(), throwsFormatException);
    expect((await store.read('profile'))!['schemaVersion'], 99);
  });
  test('invalid profile is rejected before save', () async {
    await expectLater(
      () => ProfileRepository(store).save(
        const Profile(
          name: '',
          level: 'Beginner',
          goal: 'Build muscle',
          days: 3,
          environment: 'Gym',
        ),
      ),
      throwsFormatException,
    );
    expect(await store.read('profile'), isNull);
  });
}
