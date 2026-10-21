import '../profile/profile.dart';

/// Adult-only estimates, never sensor readings or medical prescriptions.
/// Sources and limitations: docs/phase-2.md.
class NutritionEstimate {
  const NutritionEstimate({
    this.restingKcal,
    this.maintenanceKcal,
    this.proteinLow,
    this.proteinHigh,
    this.bmi,
  });
  final double? restingKcal, maintenanceKcal, proteinLow, proteinHigh, bmi;

  static NutritionEstimate forProfile(Profile p) {
    if (p.age == null || p.age! < 18 || p.clinicalNutrition) {
      return const NutritionEstimate();
    }
    final weight = p.weightKg;
    final height = p.heightCm;
    double? resting;
    if (weight != null &&
        height != null &&
        p.energyEquation != 'Skip estimate') {
      resting =
          10 * weight +
          6.25 * height -
          5 * p.age! +
          (p.energyEquation == 'Male coefficient' ? 5 : -161);
      if (resting <= 0) resting = null;
    }
    return NutritionEstimate(
      restingKcal: resting,
      maintenanceKcal: resting == null ? null : resting * p.activityFactor,
      proteinLow: weight == null ? null : weight * 1.4,
      proteinHigh: weight == null ? null : weight * 2,
      bmi: height == null || weight == null
          ? null
          : weight / ((height / 100) * (height / 100)),
    );
  }
}

class InitialPlan {
  static List<String> generate(Profile p) {
    final available = List.generate(
      7,
      (i) => i,
    ).where((i) => !p.restDays.contains(i)).toList();
    if (available.length < p.days) {
      throw const FormatException('Not enough available days');
    }
    final result = List.filled(7, 'Recovery');
    for (var i = 0; i < p.days; i++) {
      final day = available[i * available.length ~/ p.days];
      result[day] = _focus(p, i);
    }
    return result;
  }

  static String _focus(Profile p, int index) {
    // Do not interpret free text as medical clearance or attempt diagnosis.
    if (p.hasLimitations || p.goal == 'Improve mobility') return 'Mobility';
    if (p.goal == 'Improve endurance') {
      return index % 3 == 2 ? 'Full-body strength' : 'Easy cardio';
    }
    if (index >= 3 && p.level == 'Beginner') {
      return index.isEven ? 'Mobility' : 'Easy cardio';
    }
    if (p.goal == 'Improve fitness' ||
        p.goal == 'Fat loss' ||
        p.goal == 'Weight maintenance') {
      return index.isOdd ? 'Easy cardio' : 'Full-body strength';
    }
    if (p.level != 'Beginner' && p.days >= 4) {
      if (index >= 4) return 'Mobility';
      return index.isEven ? 'Upper-body strength' : 'Lower-body strength';
    }
    return index < 3 ? 'Full-body strength' : 'Mobility';
  }

  static List<String> scheduleFor(Profile p) =>
      p.schedule.isEmpty ? generate(p) : p.schedule;
}
