import 'food_item.dart';

class LoggedFoodItem {
  LoggedFoodItem({
    required this.id,
    required this.foodId,
    required this.name,
    required this.portionName,
    required this.grams,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now() {
    if (quantity <= 0) {
      throw const FormatException('Quantity must be greater than zero');
    }
  }

  final String id;
  final String foodId;
  final String name;
  final String portionName;
  final double grams;
  final double quantity;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final DateTime loggedAt;

  factory LoggedFoodItem.fromFoodItem({
    required String id,
    required FoodItem food,
    required PortionUnit portion,
    required double quantity,
  }) {
    final totalGrams = portion.grams * quantity;
    final nutrition = food.nutritionForGrams(totalGrams);

    return LoggedFoodItem(
      id: id,
      foodId: food.id,
      name: food.name,
      portionName: portion.name,
      grams: totalGrams,
      quantity: quantity,
      calories: nutrition.calories,
      protein: nutrition.protein,
      carbs: nutrition.carbs,
      fat: nutrition.fat,
      fiber: nutrition.fiber,
      loggedAt: DateTime.now(),
    );
  }

  factory LoggedFoodItem.fromJson(Map<String, dynamic> json) => LoggedFoodItem(
        id: json['id'] as String,
        foodId: json['foodId'] as String,
        name: json['name'] as String,
        portionName: json['portionName'] as String,
        grams: (json['grams'] as num).toDouble(),
        quantity: (json['quantity'] as num).toDouble(),
        calories: (json['calories'] as num).toDouble(),
        protein: (json['protein'] as num).toDouble(),
        carbs: (json['carbs'] as num).toDouble(),
        fat: (json['fat'] as num).toDouble(),
        fiber: (json['fiber'] as num).toDouble(),
        loggedAt: json['loggedAt'] != null
            ? DateTime.parse(json['loggedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'foodId': foodId,
        'name': name,
        'portionName': portionName,
        'grams': grams,
        'quantity': quantity,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'loggedAt': loggedAt.toIso8601String(),
      };
}

class MealType {
  static const breakfast = 'Breakfast';
  static const lunch = 'Lunch';
  static const dinner = 'Dinner';
  static const snacks = 'Snacks';

  static const all = [breakfast, lunch, dinner, snacks];
}

class Meal {
  Meal({
    required this.type,
    List<LoggedFoodItem>? items,
  }) : items = items ?? [];

  final String type;
  final List<LoggedFoodItem> items;

  double get totalCalories =>
      items.fold(0.0, (sum, item) => sum + item.calories);
  double get totalProtein =>
      items.fold(0.0, (sum, item) => sum + item.protein);
  double get totalCarbs => items.fold(0.0, (sum, item) => sum + item.carbs);
  double get totalFat => items.fold(0.0, (sum, item) => sum + item.fat);
  double get totalFiber => items.fold(0.0, (sum, item) => sum + item.fiber);

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        type: json['type'] as String,
        items: (json['items'] as List? ?? [])
            .map((i) => LoggedFoodItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

class DailyNutritionLog {
  DailyNutritionLog({
    required this.date,
    Map<String, Meal>? meals,
    this.waterMl = 0,
    this.waterTargetMl = 2500,
    this.notes = '',
  }) : meals = meals ?? {
          MealType.breakfast: Meal(type: MealType.breakfast),
          MealType.lunch: Meal(type: MealType.lunch),
          MealType.dinner: Meal(type: MealType.dinner),
          MealType.snacks: Meal(type: MealType.snacks),
        };

  final String date; // YYYY-MM-DD
  final Map<String, Meal> meals;
  final int waterMl;
  final int waterTargetMl;
  final String notes;

  double get totalCalories =>
      meals.values.fold(0.0, (sum, m) => sum + m.totalCalories);
  double get totalProtein =>
      meals.values.fold(0.0, (sum, m) => sum + m.totalProtein);
  double get totalCarbs =>
      meals.values.fold(0.0, (sum, m) => sum + m.totalCarbs);
  double get totalFat =>
      meals.values.fold(0.0, (sum, m) => sum + m.totalFat);
  double get totalFiber =>
      meals.values.fold(0.0, (sum, m) => sum + m.totalFiber);

  int get totalFoodItemsCount =>
      meals.values.fold(0, (sum, m) => sum + m.items.length);

  bool get isEmpty => totalFoodItemsCount == 0 && waterMl == 0;

  DailyNutritionLog copyWith({
    String? date,
    Map<String, Meal>? meals,
    int? waterMl,
    int? waterTargetMl,
    String? notes,
  }) =>
      DailyNutritionLog(
        date: date ?? this.date,
        meals: meals ?? this.meals,
        waterMl: waterMl ?? this.waterMl,
        waterTargetMl: waterTargetMl ?? this.waterTargetMl,
        notes: notes ?? this.notes,
      );

  factory DailyNutritionLog.empty(String date, {int waterTarget = 2500}) =>
      DailyNutritionLog(
        date: date,
        waterTargetMl: waterTarget,
        meals: {
          MealType.breakfast: Meal(type: MealType.breakfast),
          MealType.lunch: Meal(type: MealType.lunch),
          MealType.dinner: Meal(type: MealType.dinner),
          MealType.snacks: Meal(type: MealType.snacks),
        },
      );

  factory DailyNutritionLog.fromJson(Map<String, dynamic> json) {
    final rawMeals = json['meals'] as Map<String, dynamic>? ?? {};
    final mealsMap = <String, Meal>{};

    for (final type in MealType.all) {
      if (rawMeals.containsKey(type)) {
        mealsMap[type] = Meal.fromJson(rawMeals[type] as Map<String, dynamic>);
      } else {
        mealsMap[type] = Meal(type: type);
      }
    }

    return DailyNutritionLog(
      date: json['date'] as String,
      meals: mealsMap,
      waterMl: (json['waterMl'] as num?)?.toInt() ?? 0,
      waterTargetMl: (json['waterTargetMl'] as num?)?.toInt() ?? 2500,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'meals': meals.map((k, v) => MapEntry(k, v.toJson())),
        'waterMl': waterMl,
        'waterTargetMl': waterTargetMl,
        'notes': notes,
      };
}
