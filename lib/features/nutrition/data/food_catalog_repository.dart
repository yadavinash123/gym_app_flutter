import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/json_store.dart';
import '../../profile/profile_repository.dart';
import '../models/food_item.dart';

Future<List<FoodItem>> loadFoodCatalog([AssetBundle? bundle]) async {
  final jsonString = await (bundle ?? rootBundle).loadString(
    'assets/nutrition/food_catalog.json',
  );
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  if (json['version'] != 1 || json['foods'] is! List) {
    throw const FormatException('Invalid food catalog asset');
  }

  final items = (json['foods'] as List)
      .map((f) => FoodItem.fromJson(f as Map<String, dynamic>))
      .toList();

  final ids = items.map((f) => f.id).toSet();
  if (ids.length != items.length) {
    throw const FormatException('Duplicate food item IDs found in catalog');
  }

  return List.unmodifiable(items);
}

class FoodCatalogRepository {
  FoodCatalogRepository(this.store, [this._bundle]);

  final JsonStore store;
  final AssetBundle? _bundle;
  Future<void> _tail = Future.value();
  List<FoodItem>? _cachedCatalog;

  Future<List<FoodItem>> getBaseCatalog() async {
    _cachedCatalog ??= await loadFoodCatalog(_bundle);
    return _cachedCatalog!;
  }

  Future<List<FoodItem>> loadCustomFoods() async {
    await _tail;
    return _readCustomFoods();
  }

  Future<List<FoodItem>> _readCustomFoods() async {
    final data = await store.read('custom_foods');
    if (data == null) return [];
    if (data['version'] != 1 || data['foods'] is! List) {
      throw const FormatException('Invalid custom foods storage');
    }
    return (data['foods'] as List)
        .map((f) => FoodItem.fromJson(f as Map<String, dynamic>))
        .toList();
  }

  Future<List<FoodItem>> saveCustomFood(FoodItem food) {
    final result = _tail.then((_) async {
      final custom = await _readCustomFoods();
      custom.removeWhere((f) => f.id == food.id);
      custom.insert(0, food);
      await store.write('custom_foods', {
        'version': 1,
        'foods': custom.map((f) => f.toJson()).toList(),
      });
      return custom;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<List<FoodItem>> deleteCustomFood(String id) {
    final result = _tail.then((_) async {
      final custom = await _readCustomFoods();
      custom.removeWhere((f) => f.id == id);
      await store.write('custom_foods', {
        'version': 1,
        'foods': custom.map((f) => f.toJson()).toList(),
      });
      return custom;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<List<FoodItem>> getAllFoods() async {
    final base = await getBaseCatalog();
    final custom = await loadCustomFoods();
    return List.unmodifiable([...custom, ...base]);
  }
}

final foodCatalogRepositoryProvider = Provider<FoodCatalogRepository>(
  (ref) => FoodCatalogRepository(ref.watch(storeProvider)),
);

final customFoodsProvider =
    AsyncNotifierProvider<CustomFoodsController, List<FoodItem>>(
      CustomFoodsController.new,
    );

class CustomFoodsController extends AsyncNotifier<List<FoodItem>> {
  @override
  Future<List<FoodItem>> build() =>
      ref.watch(foodCatalogRepositoryProvider).loadCustomFoods();

  Future<void> addCustomFood(FoodItem food) async {
    final updated = await ref
        .read(foodCatalogRepositoryProvider)
        .saveCustomFood(food);
    if (ref.mounted) state = AsyncData(updated);
  }

  Future<void> removeCustomFood(String id) async {
    final updated = await ref
        .read(foodCatalogRepositoryProvider)
        .deleteCustomFood(id);
    if (ref.mounted) state = AsyncData(updated);
  }
}

final allFoodsProvider = FutureProvider<List<FoodItem>>((ref) async {
  final repo = ref.watch(foodCatalogRepositoryProvider);
  final custom = ref.watch(customFoodsProvider).value ?? [];
  final base = await repo.getBaseCatalog();
  return [...custom, ...base];
});
