import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/food_catalog_repository.dart';
import '../data/nutrition_repository.dart';
import '../models/food_item.dart';
import '../models/meal_log.dart';
import 'custom_food_screen.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({
    super.key,
    required this.date,
    this.initialMealType = MealType.breakfast,
  });

  final String date;
  final String initialMealType;

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedDiet = 'All';
  bool _highProteinOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openPortionDialog(FoodItem food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151B23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PortionLoggerSheet(
        food: food,
        date: widget.date,
        initialMealType: widget.initialMealType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodsAsync = ref.watch(allFoodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Food'),
        actions: [
          IconButton(
            tooltip: 'Create custom food',
            onPressed: () async {
              final newFood = await Navigator.of(context).push<FoodItem>(
                MaterialPageRoute(builder: (_) => const CustomFoodScreen()),
              );
              if (newFood != null && mounted) {
                _openPortionDialog(newFood);
              }
            },
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              key: const ValueKey('food_search_input'),
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search food (e.g. roti, dal, chicken, oats)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Categories'),
                  selected: _selectedCategory == 'All',
                  onSelected: (_) => setState(() => _selectedCategory = 'All'),
                ),
                const SizedBox(width: 8),
                ...FoodItem.categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(c),
                        selected: _selectedCategory == c,
                        onSelected: (_) => setState(() => _selectedCategory = c),
                      ),
                    )),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Diets'),
                  selected: _selectedDiet == 'All',
                  onSelected: (_) => setState(() => _selectedDiet = 'All'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Vegetarian'),
                  selected: _selectedDiet == 'Vegetarian',
                  onSelected: (_) => setState(() => _selectedDiet = 'Vegetarian'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Vegan'),
                  selected: _selectedDiet == 'Vegan',
                  onSelected: (_) => setState(() => _selectedDiet = 'Vegan'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('High Protein (>10g)'),
                  selected: _highProteinOnly,
                  selectedColor: const Color(0xFF2D4020),
                  onSelected: (val) => setState(() => _highProteinOnly = val),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: foodsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error loading catalog: $err'),
                ),
              ),
              data: (foods) {
                final query = _searchController.text;
                final filtered = foods
                    .where((f) => f.matches(
                          query: query,
                          categoryFilter: _selectedCategory,
                          dietFilter: _selectedDiet,
                          highProteinOnly: _highProteinOnly,
                        ))
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: Color(0xFFA7B0BF)),
                        const SizedBox(height: 12),
                        const Text(
                          'No matching foods found',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try a different search term or add a custom food item.',
                          style: TextStyle(color: Color(0xFFA7B0BF)),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final newFood = await Navigator.of(context).push<FoodItem>(
                              MaterialPageRoute(builder: (_) => const CustomFoodScreen()),
                            );
                            if (newFood != null && mounted) {
                              _openPortionDialog(newFood);
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Custom Food'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final food = filtered[index];
                    return ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              food.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (food.isCustom)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C2430),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'CUSTOM',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00D4FF),
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${food.calories.toStringAsFixed(0)} kcal • ${food.protein.toStringAsFixed(1)}g P • ${food.carbs.toStringAsFixed(1)}g C • ${food.fat.toStringAsFixed(1)}g F (per ${food.servingSize.toStringAsFixed(0)}${food.servingUnit})',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFA7B0BF)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${food.category} • ${food.diet} • ${food.source}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6E7681)),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFFB6FF3B)),
                        onPressed: () => _openPortionDialog(food),
                      ),
                      onTap: () => _openPortionDialog(food),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PortionLoggerSheet extends ConsumerStatefulWidget {
  const _PortionLoggerSheet({
    required this.food,
    required this.date,
    required this.initialMealType,
  });

  final FoodItem food;
  final String date;
  final String initialMealType;

  @override
  ConsumerState<_PortionLoggerSheet> createState() => _PortionLoggerSheetState();
}

class _PortionLoggerSheetState extends ConsumerState<_PortionLoggerSheet> {
  late String _selectedMeal;
  late PortionUnit _selectedPortion;
  double _quantity = 1.0;
  final _qtyController = TextEditingController(text: '1.0');

  @override
  void initState() {
    super.initState();
    _selectedMeal = widget.initialMealType;
    _selectedPortion = widget.food.portions.first;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _adjustQty(double delta) {
    final next = (_quantity + delta).clamp(0.25, 20.0);
    setState(() {
      _quantity = next;
      _qtyController.text = next.toStringAsFixed(next % 1 == 0 ? 0 : 2);
    });
  }

  Future<void> _logFood() async {
    final totalGrams = _selectedPortion.grams * _quantity;
    final nutrition = widget.food.nutritionForGrams(totalGrams);

    final item = LoggedFoodItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${widget.food.id}',
      foodId: widget.food.id,
      name: widget.food.name,
      portionName: _selectedPortion.name,
      grams: totalGrams,
      quantity: _quantity,
      calories: nutrition.calories,
      protein: nutrition.protein,
      carbs: nutrition.carbs,
      fat: nutrition.fat,
      fiber: nutrition.fiber,
    );

    await ref.read(nutritionLogsProvider.notifier).addFood(
          date: widget.date,
          mealType: _selectedMeal,
          item: item,
        );

    if (mounted) {
      Navigator.of(context).pop(); // close bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged ${item.quantity} × ${item.portionName} to $_selectedMeal'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalGrams = _selectedPortion.grams * _quantity;
    final nutrition = widget.food.nutritionForGrams(totalGrams);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.food.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Target Meal',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFA7B0BF)),
          ),
          const SizedBox(height: 6),
          Row(
            children: MealType.all
                .map((m) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: ChoiceChip(
                          label: Text(m, style: const TextStyle(fontSize: 11)),
                          selected: _selectedMeal == m,
                          onSelected: (_) => setState(() => _selectedMeal = m),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Portion Measure',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFA7B0BF)),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<PortionUnit>(
                      initialValue: _selectedPortion,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: widget.food.portions
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text('${p.name} (${p.grams.toStringAsFixed(0)}g)', style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (p) {
                        if (p != null) setState(() => _selectedPortion = p);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFA7B0BF)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _adjustQty(-0.5),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _qtyController,
                            textAlign: TextAlign.center,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (val) {
                              final num = double.tryParse(val);
                              if (num != null && num > 0) {
                                setState(() => _quantity = num);
                              }
                            },
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _adjustQty(0.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2430),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2D3748)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _macroMetric(nutrition.calories.toStringAsFixed(0), 'Calories', const Color(0xFFB6FF3B)),
                _macroMetric('${nutrition.protein.toStringAsFixed(1)}g', 'Protein', const Color(0xFFB6FF3B)),
                _macroMetric('${nutrition.carbs.toStringAsFixed(1)}g', 'Carbs', const Color(0xFF00D4FF)),
                _macroMetric('${nutrition.fat.toStringAsFixed(1)}g', 'Fat', const Color(0xFFFFB800)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const ValueKey('log_food_button'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: const Color(0xFFB6FF3B),
              foregroundColor: Colors.black,
            ),
            onPressed: _logFood,
            icon: const Icon(Icons.check),
            label: Text(
              'Add to $_selectedMeal (${nutrition.calories.toStringAsFixed(0)} kcal)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroMetric(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFFA7B0BF)),
        ),
      ],
    );
  }
}
