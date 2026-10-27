import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitforge_ai/core/storage/json_store.dart';
import 'package:fitforge_ai/features/nutrition/data/food_catalog_repository.dart';
import 'package:fitforge_ai/features/nutrition/data/nutrition_repository.dart';
import 'package:fitforge_ai/features/nutrition/models/food_item.dart';
import 'package:fitforge_ai/features/nutrition/models/meal_log.dart';
import 'package:fitforge_ai/features/nutrition/models/nutrition_targets.dart';
import 'package:fitforge_ai/features/nutrition/widgets/macro_progress_bar.dart';
import 'package:fitforge_ai/features/nutrition/widgets/nutrition_reference_dialog.dart';
import 'package:fitforge_ai/features/profile/profile.dart';

FoodItem sampleFood({
  String id = 'roti-whole-wheat',
  String name = 'Roti',
  String category = 'Grains & Breads',
  String diet = 'Vegan',
  double servingSize = 100.0,
  double calories = 264.0,
  double protein = 9.5,
  double carbs = 53.0,
  double fat = 1.2,
  double fiber = 8.0,
}) => FoodItem(
  id: id,
  name: name,
  category: category,
  diet: diet,
  servingSize: servingSize,
  servingUnit: 'g',
  portions: const [
    PortionUnit(name: '1 roti', grams: 35.0),
    PortionUnit(name: '100g', grams: 100.0),
  ],
  calories: calories,
  protein: protein,
  carbs: carbs,
  fat: fat,
  fiber: fiber,
  source: 'ICMR-NIN IFCT 2017',
  url: 'https://example.com/roti',
);

void main() {
  group('FoodItem Model & Validation', () {
    test('validates ID regex and non-empty properties', () {
      expect(
        () => FoodItem(
          id: 'INVALID_ID!',
          name: 'Food',
          category: 'Fruits',
          diet: 'Vegan',
          servingSize: 100,
          servingUnit: 'g',
          portions: const [PortionUnit(name: '1 serving', grams: 100)],
          calories: 100,
          protein: 5,
          carbs: 20,
          fat: 2,
          fiber: 3,
          source: 'USDA',
          url: 'https://example.com',
        ),
        throwsFormatException,
      );

      expect(
        () => FoodItem(
          id: 'valid-id',
          name: '   ',
          category: 'Fruits',
          diet: 'Vegan',
          servingSize: 100,
          servingUnit: 'g',
          portions: const [PortionUnit(name: '1 serving', grams: 100)],
          calories: 100,
          protein: 5,
          carbs: 20,
          fat: 2,
          fiber: 3,
          source: 'USDA',
          url: 'https://example.com',
        ),
        throwsFormatException,
      );

      expect(
        () => FoodItem(
          id: 'valid-id',
          name: 'Food',
          category: 'Fruits',
          diet: 'Vegan',
          servingSize: 0,
          servingUnit: 'g',
          portions: const [PortionUnit(name: '1 serving', grams: 100)],
          calories: 100,
          protein: 5,
          carbs: 20,
          fat: 2,
          fiber: 3,
          source: 'USDA',
          url: 'https://example.com',
        ),
        throwsFormatException,
      );
    });

    test('scales nutrition accurately for custom portion gram amounts', () {
      final food = sampleFood(
        servingSize: 100.0,
        calories: 200.0,
        protein: 20.0,
        carbs: 10.0,
        fat: 4.0,
        fiber: 2.0,
      );

      // 50 grams (half portion)
      final half = food.nutritionForGrams(50.0);
      expect(half.calories, closeTo(100.0, 0.01));
      expect(half.protein, closeTo(10.0, 0.01));
      expect(half.carbs, closeTo(5.0, 0.01));
      expect(half.fat, closeTo(2.0, 0.01));
      expect(half.fiber, closeTo(1.0, 0.01));

      // 150 grams (1.5x portion)
      final more = food.nutritionForGrams(150.0);
      expect(more.calories, closeTo(300.0, 0.01));
      expect(more.protein, closeTo(30.0, 0.01));
    });

    test(
      'matches filtering by query, category, diet, and high protein tag',
      () {
        final chicken = sampleFood(
          id: 'chicken-breast',
          name: 'Grilled Chicken Breast',
          category: 'Proteins & Poultry',
          diet: 'Non-vegetarian',
          calories: 165.0,
          protein: 31.0,
          carbs: 0.0,
          fat: 3.6,
        );

        final dal = sampleFood(
          id: 'yellow-dal',
          name: 'Moong Dal Soup',
          category: 'Lentils & Legumes',
          diet: 'Vegan',
          calories: 105.0,
          protein: 7.0,
          carbs: 16.0,
          fat: 1.5,
        );

        expect(chicken.matches(query: 'chicken'), isTrue);
        expect(chicken.matches(query: 'dal'), isFalse);
        expect(chicken.matches(categoryFilter: 'Proteins & Poultry'), isTrue);
        expect(chicken.matches(categoryFilter: 'Fruits'), isFalse);
        expect(chicken.matches(dietFilter: 'Vegetarian'), isFalse);
        expect(chicken.matches(highProteinOnly: true), isTrue);

        expect(dal.matches(dietFilter: 'Vegetarian'), isTrue);
        expect(dal.matches(dietFilter: 'Vegan'), isTrue);
        expect(dal.matches(highProteinOnly: true), isFalse);
      },
    );
  });

  group('Nutrition Targets & Calculations', () {
    test('calculates Mifflin-St Jeor BMR and TDEE with goal offsets', () {
      const maleProfile = Profile(
        name: 'Avi',
        level: 'Intermediate',
        goal: 'Build muscle',
        days: 4,
        environment: 'Gym',
        age: 30,
        heightCm: 180.0,
        weightKg: 80.0,
        energyEquation: 'Male coefficient',
        activityFactor: 1.5,
      );

      // BMR = 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780 kcal
      // TDEE = 1780 * 1.5 = 2670 kcal
      // Build muscle goal = +250 kcal => 2920 kcal
      final targets = NutritionCalculator.calculate(maleProfile);
      expect(targets.dailyCalories, closeTo(2920.0, 1.0));
      expect(targets.isEstimated, isTrue);
      expect(targets.isPersonalCalorie, isFalse);
      // Protein: 1.8 * 80kg = 144g
      expect(targets.proteinGrams, closeTo(144.0, 1.0));
      // Fat: 25% of 2920 kcal / 9 = ~81.1g
      expect(targets.fatGrams, closeTo(81.1, 1.0));
      // Water: 80kg * 35 = 2800 ml
      expect(targets.waterMl, 2800);
    });

    test('applies fat loss calorie deficit', () {
      const cuttingProfile = Profile(
        name: 'Avi',
        level: 'Intermediate',
        goal: 'Fat loss',
        days: 4,
        environment: 'Gym',
        age: 30,
        heightCm: 180.0,
        weightKg: 80.0,
        energyEquation: 'Male coefficient',
        activityFactor: 1.4,
      );

      // BMR = 1780
      // TDEE = 1780 * 1.4 = 2492 kcal
      // Fat loss = -400 kcal => 2092 kcal
      final targets = NutritionCalculator.calculate(cuttingProfile);
      expect(targets.dailyCalories, closeTo(2092.0, 1.0));
      // Higher protein preservation in deficit: 2.0 * 80 = 160g
      expect(targets.proteinGrams, closeTo(160.0, 1.0));
    });

    test('user personal calorie and protein targets override estimates', () {
      const customProfile = Profile(
        name: 'Avi',
        level: 'Beginner',
        goal: 'Weight maintenance',
        days: 3,
        environment: 'Home',
        calorieTarget: 2350.0,
        proteinTarget: 150.0,
      );

      final targets = NutritionCalculator.calculate(customProfile);
      expect(targets.dailyCalories, 2350.0);
      expect(targets.proteinGrams, 150.0);
      expect(targets.isPersonalCalorie, isTrue);
      expect(targets.isPersonalProtein, isTrue);
      expect(targets.isEstimated, isFalse);
    });

    test(
      'suppresses automatic estimates for minors and clinical nutrition',
      () {
        const minorProfile = Profile(
          name: 'Young',
          level: 'Beginner',
          goal: 'Build muscle',
          days: 3,
          environment: 'Home',
          age: 16,
        );

        const clinicalProfile = Profile(
          name: 'Patient',
          level: 'Beginner',
          goal: 'Weight maintenance',
          days: 3,
          environment: 'Home',
          clinicalNutrition: true,
        );

        final minorTargets = NutritionCalculator.calculate(minorProfile);
        expect(minorTargets.isClinicalSuppressed, isTrue);
        expect(minorTargets.isEstimated, isFalse);

        final clinicalTargets = NutritionCalculator.calculate(clinicalProfile);
        expect(clinicalTargets.isClinicalSuppressed, isTrue);
        expect(clinicalTargets.isEstimated, isFalse);
      },
    );
  });

  group('MealLog & DailyNutritionLog Models', () {
    test('LoggedFoodItem calculates macros and rounds correctly', () {
      final food = sampleFood();
      final item = LoggedFoodItem.fromFoodItem(
        id: 'log-1',
        food: food,
        portion: const PortionUnit(name: '1 roti', grams: 35.0),
        quantity: 2.0, // 70g total
      );

      expect(item.grams, 70.0);
      expect(item.quantity, 2.0);
      // Roti is 264 kcal / 100g -> 70g is 184.8 kcal
      expect(item.calories, closeTo(184.8, 0.1));
      // Protein 9.5g / 100g -> 70g is 6.65g
      expect(item.protein, closeTo(6.65, 0.1));
    });

    test('DailyNutritionLog aggregates totals and round-trips to JSON', () {
      final food = sampleFood();
      final item1 = LoggedFoodItem.fromFoodItem(
        id: 'item-1',
        food: food,
        portion: const PortionUnit(name: '1 roti', grams: 35.0),
        quantity: 2.0,
      );
      final item2 = LoggedFoodItem.fromFoodItem(
        id: 'item-2',
        food: food,
        portion: const PortionUnit(name: '1 roti', grams: 35.0),
        quantity: 1.0,
      );

      final log = DailyNutritionLog(
        date: '2026-10-22',
        meals: {
          MealType.breakfast: Meal(type: MealType.breakfast, items: [item1]),
          MealType.lunch: Meal(type: MealType.lunch, items: [item2]),
          MealType.dinner: Meal(type: MealType.dinner),
          MealType.snacks: Meal(type: MealType.snacks),
        },
        waterMl: 1250,
        waterTargetMl: 2500,
      );

      expect(log.totalCalories, closeTo(184.8 + 92.4, 0.2));
      expect(log.totalFoodItemsCount, 2);
      expect(log.isEmpty, isFalse);

      final json = log.toJson();
      final restored = DailyNutritionLog.fromJson(json);

      expect(restored.date, '2026-10-22');
      expect(restored.waterMl, 1250);
      expect(restored.meals[MealType.breakfast]!.items.length, 1);
      expect(restored.meals[MealType.lunch]!.items.length, 1);
      expect(restored.totalCalories, closeTo(log.totalCalories, 0.1));
    });
  });

  group('NutritionRepository and Storage Persistence', () {
    late Directory tempDir;
    late JsonStore store;
    late NutritionRepository repository;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('nutrition_repo_test');
      store = JsonStore(tempDir);
      repository = NutritionRepository(store);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'returns empty log for unlogged date and persists newly added food',
      () async {
        final initial = await repository.getDailyLog('2026-10-22');
        expect(initial.isEmpty, isTrue);
        expect(initial.waterMl, 0);

        final food = sampleFood();
        final item = LoggedFoodItem.fromFoodItem(
          id: 'f-1',
          food: food,
          portion: const PortionUnit(name: '1 roti', grams: 35.0),
          quantity: 2.0,
        );

        await repository.addFoodToMeal(
          date: '2026-10-22',
          mealType: MealType.breakfast,
          item: item,
        );

        final updated = await repository.getDailyLog('2026-10-22');
        expect(updated.meals[MealType.breakfast]!.items.length, 1);
        expect(updated.meals[MealType.breakfast]!.items.first.name, 'Roti');
        expect(updated.totalCalories, closeTo(184.8, 0.1));

        // Remove item
        await repository.removeFoodFromMeal(
          date: '2026-10-22',
          mealType: MealType.breakfast,
          itemId: 'f-1',
        );

        final afterRemove = await repository.getDailyLog('2026-10-22');
        expect(afterRemove.meals[MealType.breakfast]!.items.isEmpty, isTrue);
      },
    );

    test('tracks and updates water intake correctly', () async {
      await repository.addWater(date: '2026-10-22', amountMl: 250);
      var log = await repository.getDailyLog('2026-10-22');
      expect(log.waterMl, 250);

      await repository.addWater(date: '2026-10-22', amountMl: 500);
      log = await repository.getDailyLog('2026-10-22');
      expect(log.waterMl, 750);

      await repository.updateWater(date: '2026-10-22', waterMl: 0);
      log = await repository.getDailyLog('2026-10-22');
      expect(log.waterMl, 0);
    });

    test('copies meals from another day and clears meals', () async {
      final food = sampleFood();
      await repository.addFoodToMeal(
        date: '2026-10-21',
        mealType: MealType.lunch,
        item: LoggedFoodItem.fromFoodItem(
          id: 'prev-1',
          food: food,
          portion: const PortionUnit(name: '1 roti', grams: 35.0),
          quantity: 3.0,
        ),
      );

      await repository.copyMeals(fromDate: '2026-10-21', toDate: '2026-10-22');

      final target = await repository.getDailyLog('2026-10-22');
      expect(target.meals[MealType.lunch]!.items.length, 1);
      expect(target.meals[MealType.lunch]!.items.first.quantity, 3.0);

      // Clear target meals
      await repository.clearMeals(date: '2026-10-22');
      final cleared = await repository.getDailyLog('2026-10-22');
      expect(cleared.meals[MealType.lunch]!.items.isEmpty, isTrue);
    });

    test('recovers from backup file if primary file is corrupted', () async {
      final log = DailyNutritionLog.empty('2026-10-22').copyWith(waterMl: 1000);
      await repository.saveDailyLog(log);

      // Trigger second write so .bak is created
      final updatedLog = log.copyWith(waterMl: 1500);
      await repository.saveDailyLog(updatedLog);

      // Corrupt primary file
      final primaryFile = File('${tempDir.path}/nutrition_logs.json');
      await primaryFile.writeAsString('{{CORRUPT_JSON}}');

      // Read should safely recover previous valid backup
      final recovered = await repository.getDailyLog('2026-10-22');
      expect(recovered.waterMl, 1000);
    });
  });

  group('FoodCatalogRepository & Custom Foods', () {
    late Directory tempDir;
    late JsonStore store;
    late FoodCatalogRepository catalogRepo;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('catalog_repo_test');
      store = JsonStore(tempDir);
      catalogRepo = FoodCatalogRepository(store);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('saves custom food and deletes it cleanly', () async {
      final custom = sampleFood(
        id: 'custom-paneer-bhurji',
        name: 'Homemade Paneer Bhurji',
        category: 'Dairy & Plant Milks',
        diet: 'Vegetarian',
      );

      await catalogRepo.saveCustomFood(custom);
      var customs = await catalogRepo.loadCustomFoods();
      expect(customs.length, 1);
      expect(customs.first.name, 'Homemade Paneer Bhurji');

      await catalogRepo.deleteCustomFood(custom.id);
      customs = await catalogRepo.loadCustomFoods();
      expect(customs.isEmpty, isTrue);
    });
  });

  group('UI Widgets Tests', () {
    testWidgets('MacroProgressBar renders label and metrics without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 320,
                child: MacroProgressBar(
                  label: 'Dietary Fiber',
                  currentGrams: 22,
                  targetGrams: 30,
                  color: Colors.purple,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Dietary Fiber'), findsOneWidget);
      expect(find.text('22 / 30 g (73%)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'NutritionReferenceDialog opens and displays scientific citations',
      (tester) async {
        const targets = NutritionTargets(
          dailyCalories: 2200,
          proteinGrams: 140,
          carbsGrams: 240,
          fatGrams: 60,
          fiberGrams: 30,
          waterMl: 2500,
          explanation: 'Mifflin–St Jeor estimate: BMR 1700 kcal × 1.4',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: NutritionReferenceDialog(targets: targets)),
          ),
        );

        expect(find.text('Calculation Reference'), findsOneWidget);
        expect(find.textContaining('Mifflin–St Jeor estimate'), findsOneWidget);
        expect(find.text('Scientific Foundations'), findsOneWidget);
        expect(find.text('Energy Expenditure (BMR)'), findsOneWidget);
        expect(find.text('Protein Intake'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);
      },
    );
  });
}
