import '../../profile/profile.dart';

class NutritionTargets {
  const NutritionTargets({
    required this.dailyCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.fiberGrams,
    required this.waterMl,
    this.isPersonalCalorie = false,
    this.isPersonalProtein = false,
    this.isEstimated = true,
    this.isClinicalSuppressed = false,
    required this.explanation,
  });

  final double dailyCalories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double fiberGrams;
  final int waterMl;
  final bool isPersonalCalorie;
  final bool isPersonalProtein;
  final bool isEstimated;
  final bool isClinicalSuppressed;
  final String explanation;

  static const defaultFallback = NutritionTargets(
    dailyCalories: 2000.0,
    proteinGrams: 120.0,
    carbsGrams: 230.0,
    fatGrams: 60.0,
    fiberGrams: 28.0,
    waterMl: 2500,
    isEstimated: false,
    explanation: 'Standard baseline guide (2,000 kcal). Enter your profile metrics for personalized estimates.',
  );
}

class NutritionCalculator {
  static NutritionTargets calculate(Profile? profile) {
    if (profile == null) {
      return NutritionTargets.defaultFallback;
    }

    // Clinical nutrition or under-18 suppression
    if (profile.clinicalNutrition ||
        (profile.age != null && profile.age! < 18)) {
      final userCalories = profile.calorieTarget ?? 2000.0;
      final userProtein = profile.proteinTarget ?? 100.0;
      final fat = (userCalories * 0.25) / 9.0;
      final remainingCarbsKcal =
          userCalories - (userProtein * 4.0) - (fat * 9.0);
      final carbs = remainingCarbsKcal > 0 ? remainingCarbsKcal / 4.0 : 50.0;
      final fiber = (userCalories / 1000.0 * 14.0).clamp(20.0, 35.0);
      final weight = profile.weightKg ?? 70.0;
      final water = (weight * 35.0).round().clamp(2000, 4000);

      return NutritionTargets(
        dailyCalories: userCalories,
        proteinGrams: userProtein,
        carbsGrams: carbs,
        fatGrams: fat,
        fiberGrams: fiber,
        waterMl: water,
        isPersonalCalorie: profile.calorieTarget != null,
        isPersonalProtein: profile.proteinTarget != null,
        isEstimated: false,
        isClinicalSuppressed: true,
        explanation: profile.clinicalNutrition
            ? 'Personal clinical nutrition guidance active. Automatic estimates are disabled. Please follow your registered dietitian’s specific prescriptions.'
            : 'Automatic energy estimates are disabled for individuals under 18 years of age. Please consult a qualified pediatric healthcare professional.',
      );
    }

    final weight = profile.weightKg;
    final height = profile.heightCm;
    final age = profile.age;

    double? restingBmr;
    if (weight != null &&
        height != null &&
        age != null &&
        profile.energyEquation != 'Skip estimate') {
      final coeff = profile.energyEquation == 'Male coefficient' ? 5.0 : -161.0;
      restingBmr = (10.0 * weight) + (6.25 * height) - (5.0 * age) + coeff;
      if (restingBmr <= 0) restingBmr = null;
    }

    // Determine target calories
    double targetKcal;
    bool isPersonalCalorie = false;
    bool isEstimated = false;
    String explanation;

    if (profile.calorieTarget != null && profile.calorieTarget! > 0) {
      targetKcal = profile.calorieTarget!;
      isPersonalCalorie = true;
      isEstimated = false;
      explanation =
          'Using your personal daily calorie target (${targetKcal.toStringAsFixed(0)} kcal).';
    } else if (restingBmr != null) {
      final tdee = restingBmr * profile.activityFactor;
      double goalDelta = 0.0;
      if (profile.goal == 'Fat loss') {
        goalDelta = -400.0;
      } else if (profile.goal == 'Build muscle' ||
          profile.goal == 'Build strength') {
        goalDelta = 250.0;
      }
      targetKcal = (tdee + goalDelta).clamp(1200.0, 4500.0);
      isEstimated = true;
      explanation =
          'Mifflin–St Jeor estimate: BMR ${restingBmr.toStringAsFixed(0)} kcal × ${profile.activityFactor.toStringAsFixed(1)} activity factor ${goalDelta != 0.0 ? '${goalDelta > 0 ? '+' : ''}${goalDelta.toStringAsFixed(0)} kcal for ${profile.goal}' : ''} ≈ ${targetKcal.toStringAsFixed(0)} kcal/day.';
    } else {
      targetKcal = 2000.0;
      isEstimated = false;
      explanation = 'Standard 2,000 kcal baseline. Enter your height, weight, and age in profile settings for tailored estimates.';
    }

    // Determine protein target
    double proteinG;
    bool isPersonalProtein = false;
    if (profile.proteinTarget != null && profile.proteinTarget! > 0) {
      proteinG = profile.proteinTarget!;
      isPersonalProtein = true;
    } else if (weight != null) {
      double proteinMultiplier;
      if (profile.goal == 'Fat loss') {
        proteinMultiplier = 2.0; // Preserve lean mass during calorie deficit
      } else if (profile.goal == 'Build muscle' ||
          profile.goal == 'Build strength' ||
          profile.goal == 'Body recomposition') {
        proteinMultiplier = 1.8;
      } else {
        proteinMultiplier = 1.6;
      }
      proteinG = (weight * proteinMultiplier).clamp(60.0, 250.0);
    } else {
      proteinG = 120.0;
    }

    // Fat: 25% of total calories
    final fatG = ((targetKcal * 0.25) / 9.0).clamp(30.0, 150.0);

    // Carbs: remainder of calories
    final caloriesFromProteinAndFat = (proteinG * 4.0) + (fatG * 9.0);
    final remainingCarbsKcal = targetKcal - caloriesFromProteinAndFat;
    final carbsG = remainingCarbsKcal > 0 ? remainingCarbsKcal / 4.0 : 50.0;

    // Fiber: ~14g per 1000 kcal
    final fiberG = (targetKcal / 1000.0 * 14.0).clamp(25.0, 40.0);

    // Water: 35 ml per kg of bodyweight, minimum 2000ml
    final waterBase = weight != null ? weight * 35.0 : 2500.0;
    final waterMl = (waterBase / 50.0).round() * 50; // round to nearest 50ml
    final clampedWater = waterMl.clamp(2000, 4500);

    return NutritionTargets(
      dailyCalories: targetKcal,
      proteinGrams: proteinG,
      carbsGrams: carbsG,
      fatGrams: fatG,
      fiberGrams: fiberG,
      waterMl: clampedWater,
      isPersonalCalorie: isPersonalCalorie,
      isPersonalProtein: isPersonalProtein,
      isEstimated: isEstimated,
      isClinicalSuppressed: false,
      explanation: explanation,
    );
  }
}
