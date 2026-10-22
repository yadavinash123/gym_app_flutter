import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/food_catalog_repository.dart';
import '../models/food_item.dart';

class CustomFoodScreen extends ConsumerStatefulWidget {
  const CustomFoodScreen({super.key});

  @override
  ConsumerState<CustomFoodScreen> createState() => _CustomFoodScreenState();
}

class _CustomFoodScreenState extends ConsumerState<CustomFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _servingSizeController = TextEditingController(text: '100');
  final _portionNameController = TextEditingController(text: '1 serving');
  final _portionGramsController = TextEditingController(text: '100');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController(text: '0');
  final _brandController = TextEditingController();

  String _selectedCategory = FoodItem.categories.first;
  String _selectedDiet = FoodItem.diets.first;
  String _servingUnit = 'g';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _servingSizeController.dispose();
    _portionNameController.dispose();
    _portionGramsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final slug = name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      final id = 'custom-${slug.isEmpty ? "item" : slug}-${DateTime.now().millisecondsSinceEpoch % 10000}';

      final servingSize = double.parse(_servingSizeController.text.trim());
      final portionName = _portionNameController.text.trim().isEmpty
          ? '1 serving'
          : _portionNameController.text.trim();
      final portionGrams = double.tryParse(_portionGramsController.text.trim()) ?? servingSize;

      final calories = double.parse(_caloriesController.text.trim());
      final protein = double.parse(_proteinController.text.trim());
      final carbs = double.parse(_carbsController.text.trim());
      final fat = double.parse(_fatController.text.trim());
      final fiber = double.tryParse(_fiberController.text.trim()) ?? 0.0;
      final brand = _brandController.text.trim();

      final food = FoodItem(
        id: id,
        name: name,
        category: _selectedCategory,
        diet: _selectedDiet,
        servingSize: servingSize,
        servingUnit: _servingUnit,
        portions: [
          PortionUnit(name: portionName, grams: portionGrams),
          if (portionGrams != servingSize)
            PortionUnit(name: '${servingSize.toStringAsFixed(0)}$_servingUnit', grams: servingSize),
        ],
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
        source: brand.isEmpty ? 'User Added' : brand,
        url: 'https://fitforge.app/custom',
        isCustom: true,
      );

      await ref.read(customFoodsProvider.notifier).addCustomFood(food);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "${food.name}" to your custom foods')),
        );
        Navigator.of(context).pop(food);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving food: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Custom Food'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB6FF3B))),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              key: const ValueKey('custom_food_name'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Food Name *',
                hintText: 'e.g. Homemade Protein Oats',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: FoodItem.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCategory = v);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedDiet,
              decoration: const InputDecoration(labelText: 'Dietary Preference'),
              items: FoodItem.diets
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedDiet = v);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _servingSizeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Serving Size *'),
                    validator: (v) {
                      final num = double.tryParse(v ?? '');
                      if (num == null || num <= 0) return 'Invalid size';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _servingUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: const [
                      DropdownMenuItem(value: 'g', child: Text('Grams (g)')),
                      DropdownMenuItem(value: 'ml', child: Text('Milliliters (ml)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _servingUnit = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _portionNameController,
                    decoration: const InputDecoration(
                      labelText: 'Portion Name',
                      hintText: 'e.g. 1 bowl / 1 slice',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _portionGramsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Portion Weight (g/ml)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Nutrition per Serving Size',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFFB6FF3B),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const ValueKey('custom_calories'),
                    controller: _caloriesController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Calories (kcal) *'),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const ValueKey('custom_protein'),
                    controller: _proteinController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Protein (g) *'),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Required';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const ValueKey('custom_carbs'),
                    controller: _carbsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Carbohydrates (g) *'),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const ValueKey('custom_fat'),
                    controller: _fatController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Total Fat (g) *'),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Required';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fiberController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Dietary Fiber (g)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(labelText: 'Brand / Recipe (Optional)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.check),
              label: const Text('Save Custom Food'),
            ),
          ],
        ),
      ),
    );
  }
}
