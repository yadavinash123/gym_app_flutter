import 'package:flutter_test/flutter_test.dart';
import 'package:fitforge_ai/features/profile/profile.dart';
import 'package:fitforge_ai/features/planning/initial_plan.dart';

Profile sample({
  String level = 'Beginner',
  String goal = 'Build muscle',
  int days = 3,
  List<int> rests = const [],
  bool limited = false,
}) => Profile(
  name: 'Avi',
  level: level,
  goal: goal,
  days: days,
  environment: 'Home',
  restDays: rests,
  hasLimitations: limited,
);

void main() {
  test(
    'weekly outline meets every valid availability and respects rest days',
    () {
      for (var mask = 0; mask < 128; mask++) {
        final rests = List.generate(
          7,
          (i) => i,
        ).where((i) => mask & (1 << i) != 0).toList();
        for (var days = 1; days <= 7 - rests.length; days++) {
          for (final goal in Profile.goals) {
            final profile = sample(days: days, rests: rests, goal: goal);
            final plan = InitialPlan.generate(profile);
            expect(plan.length, 7);
            expect(plan.where((s) => s != 'Recovery').length, days);
            expect(rests.every((day) => plan[day] == 'Recovery'), isTrue);
            expect(InitialPlan.generate(profile), plan);
          }
        }
      }
    },
  );
  test(
    'limitations always withhold strength and cardio across goals and levels',
    () {
      for (final level in Profile.levels) {
        for (final goal in Profile.goals) {
          expect(
            InitialPlan.generate(
              sample(level: level, goal: goal, limited: true),
            ).every((s) => s == 'Recovery' || s == 'Mobility'),
            isTrue,
          );
        }
      }
    },
  );
  test(
    'beginner muscle outline adds lighter days beyond three strength slots',
    () {
      final plan = InitialPlan.generate(sample(days: 7));
      expect(plan.where((s) => s.contains('strength')).length, 3);
    },
  );
  test('impossible availability is rejected', () {
    expect(
      () => InitialPlan.generate(sample(days: 7, rests: [6])),
      throwsFormatException,
    );
  });
  test('adult estimates use chosen coefficient, not gender identity', () {
    final data = sample().toJson()
      ..addAll({
        'age': 30,
        'weightKg': 80.0,
        'heightCm': 180.0,
        'energyEquation': 'Male coefficient',
        'gender': 'Female',
      });
    final estimate = NutritionEstimate.forProfile(Profile.fromJson(data));
    expect(estimate.restingKcal, 1780);
    expect(estimate.maintenanceKcal, closeTo(2492, 0.001));
    expect(estimate.proteinLow, closeTo(112, 0.001));
    expect(estimate.proteinHigh, 160);
    expect(estimate.bmi, closeTo(24.691358, 0.00001));
    data['energyEquation'] = 'Female coefficient';
    expect(
      NutritionEstimate.forProfile(Profile.fromJson(data)).restingKcal,
      1614,
    );
  });
  test(
    'unknown age, minors and personal guidance suppress automatic nutrition',
    () {
      for (final age in [null, 17, 30]) {
        final data = sample().toJson()
          ..addAll({
            'age': age,
            'weightKg': 80.0,
            'heightCm': 180.0,
            'energyEquation': 'Male coefficient',
            'clinicalNutrition': age == 30,
          });
        final estimate = NutritionEstimate.forProfile(Profile.fromJson(data));
        expect(estimate.maintenanceKcal, isNull);
        expect(estimate.proteinLow, isNull);
        expect(estimate.bmi, isNull);
      }
    },
  );
  test('skipping the coefficient does not invent an energy estimate', () {
    final data = sample().toJson()
      ..addAll({'age': 30, 'weightKg': 80.0, 'heightCm': 180.0});
    expect(
      NutritionEstimate.forProfile(Profile.fromJson(data)).restingKcal,
      isNull,
    );
  });
  test('personal nutrition targets and schedule round-trip unchanged', () {
    final data = sample().toJson()
      ..addAll({
        'calorieTarget': 2400.0,
        'proteinTarget': 125.0,
        'schedule': [
          'Easy cardio',
          'Recovery',
          'Mobility',
          'Recovery',
          'Full-body strength',
          'Recovery',
          'Recovery',
        ],
      });
    final p = Profile.fromJson(data);
    expect(p.toJson(), data);
    expect(InitialPlan.scheduleFor(p), data['schedule']);
  });
  test(
    'invalid values, duplicate rest days and conflicting plans are rejected',
    () {
      for (final change in [
        {'weightKg': double.nan},
        {'heightCm': -10},
        {'age': 30.5},
        {'activityFactor': 10},
        {
          'restDays': [1, 1],
        },
        {
          'days': 7,
          'restDays': [6],
        },
        {
          'schedule': ['Recovery'],
        },
        {'schedule': List.filled(7, 'Recovery')},
        {'secondaryGoal': 'Build muscle'},
        {
          'equipment': ['unknown'],
        },
        {
          'hasLimitations': true,
          'schedule': [
            'Full-body strength',
            'Recovery',
            'Mobility',
            'Recovery',
            'Mobility',
            'Recovery',
            'Recovery',
          ],
        },
      ]) {
        expect(
          () => Profile.fromJson(sample().toJson()..addAll(change)),
          throwsFormatException,
        );
      }
    },
  );
}
