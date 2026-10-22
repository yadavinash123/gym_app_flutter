class PortionUnit {
  const PortionUnit({required this.name, required this.grams});

  final String name;
  final double grams;

  factory PortionUnit.fromJson(Map<String, dynamic> json) => PortionUnit(
        name: json['name'] as String,
        grams: (json['grams'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'grams': grams,
      };
}

class FoodItem {
  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.diet,
    required this.servingSize,
    required this.servingUnit,
    required this.portions,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    this.micronutrients = const {},
    required this.source,
    required this.url,
    this.isCustom = false,
  }) {
    if (!RegExp(r'^[a-z][a-z0-9-]*$').hasMatch(id)) {
      throw FormatException('Invalid food id: $id');
    }
    if (name.trim().isEmpty) {
      throw const FormatException('Food name cannot be empty');
    }
    if (servingSize <= 0) {
      throw const FormatException('Serving size must be greater than zero');
    }
    if (calories < 0 || protein < 0 || carbs < 0 || fat < 0 || fiber < 0) {
      throw const FormatException('Macros cannot be negative');
    }
    if (portions.isEmpty) {
      throw const FormatException('Food must have at least one portion unit');
    }
  }

  final String id;
  final String name;
  final String category;
  final String diet;
  final double servingSize;
  final String servingUnit;
  final List<PortionUnit> portions;
  final double calories; // kcal per servingSize
  final double protein; // g per servingSize
  final double carbs; // g per servingSize
  final double fat; // g per servingSize
  final double fiber; // g per servingSize
  final Map<String, double> micronutrients;
  final String source;
  final String url;
  final bool isCustom;

  static const categories = [
    'Grains & Breads',
    'Lentils & Legumes',
    'Dairy & Plant Milks',
    'Proteins & Poultry',
    'Vegetables & Greens',
    'Fruits',
    'Nuts & Healthy Fats',
    'Snacks & Beverages',
  ];

  static const diets = [
    'Vegetarian',
    'Vegetarian with eggs',
    'Vegan',
    'Non-vegetarian',
  ];

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    final rawPortions = json['portions'] as List? ?? [];
    final rawMicros = json['micronutrients'] as Map<String, dynamic>? ?? {};

    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'Snacks & Beverages',
      diet: json['diet'] as String? ?? 'Vegetarian',
      servingSize: (json['servingSize'] as num?)?.toDouble() ?? 100.0,
      servingUnit: json['servingUnit'] as String? ?? 'g',
      portions: rawPortions
          .map((p) => PortionUnit.fromJson(p as Map<String, dynamic>))
          .toList(),
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      fiber: (json['fiber'] as num).toDouble(),
      micronutrients: rawMicros.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      source: json['source'] as String? ?? 'FitForge Database',
      url: json['url'] as String? ?? 'https://fitforge.app',
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'diet': diet,
        'servingSize': servingSize,
        'servingUnit': servingUnit,
        'portions': portions.map((p) => p.toJson()).toList(),
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'micronutrients': micronutrients,
        'source': source,
        'url': url,
        'isCustom': isCustom,
      };

  ({
    double calories,
    double protein,
    double carbs,
    double fat,
    double fiber,
  }) nutritionForGrams(double grams) {
    final factor = grams / servingSize;
    return (
      calories: calories * factor,
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
      fiber: fiber * factor,
    );
  }

  bool matches({
    String query = '',
    String? categoryFilter,
    String? dietFilter,
    bool? highProteinOnly,
  }) {
    if (categoryFilter != null &&
        categoryFilter.isNotEmpty &&
        categoryFilter != 'All' &&
        category != categoryFilter) {
      return false;
    }

    if (dietFilter != null && dietFilter.isNotEmpty && dietFilter != 'All') {
      if (dietFilter == 'Vegetarian' &&
          diet != 'Vegetarian' &&
          diet != 'Vegan') {
        return false;
      }
      if (dietFilter == 'Vegan' && diet != 'Vegan') {
        return false;
      }
      if (dietFilter == 'Vegetarian with eggs' &&
          diet != 'Vegetarian with eggs' &&
          diet != 'Vegetarian' &&
          diet != 'Vegan') {
        return false;
      }
    }

    if (highProteinOnly == true) {
      final normalizedProtein = (protein / servingSize) * 100.0;
      if (normalizedProtein < 10.0) return false;
    }

    if (query.trim().isEmpty) return true;

    final q = query.trim().toLowerCase();
    return name.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        diet.toLowerCase().contains(q);
  }
}
