import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/json_store.dart';
import '../../profile/profile_repository.dart';
import '../models/meal_log.dart';
import '../models/nutrition_targets.dart';

class NutritionRepository {
  NutritionRepository(this.store);

  final JsonStore store;
  Future<void> _tail = Future.value();

  Future<Map<String, DailyNutritionLog>> loadAllLogs() async {
    await _tail;
    return _readAllLogs();
  }

  Future<Map<String, DailyNutritionLog>> _readAllLogs() async {
    final data = await store.read('nutrition_logs');
    if (data == null) return {};
    if (data['version'] != 1 || data['logs'] is! Map) {
      throw const FormatException('Invalid nutrition logs storage');
    }
    final rawLogs = data['logs'] as Map<String, dynamic>;
    return rawLogs.map(
      (k, v) =>
          MapEntry(k, DailyNutritionLog.fromJson(v as Map<String, dynamic>)),
    );
  }

  Future<DailyNutritionLog> getDailyLog(
    String date, {
    int waterTarget = 2500,
  }) async {
    final logs = await loadAllLogs();
    return logs[date] ??
        DailyNutritionLog.empty(date, waterTarget: waterTarget);
  }

  Future<DailyNutritionLog> saveDailyLog(DailyNutritionLog log) {
    final result = _tail.then((_) async {
      final logs = await _readAllLogs();
      logs[log.date] = log;
      await store.write('nutrition_logs', {
        'version': 1,
        'logs': logs.map((k, v) => MapEntry(k, v.toJson())),
      });
      return log;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<DailyNutritionLog> addFoodToMeal({
    required String date,
    required String mealType,
    required LoggedFoodItem item,
    int waterTarget = 2500,
  }) {
    final result = _tail.then((_) async {
      final logs = await _readAllLogs();
      final current =
          logs[date] ?? DailyNutritionLog.empty(date, waterTarget: waterTarget);

      final meal = current.meals[mealType] ?? Meal(type: mealType);
      final updatedItems = List<LoggedFoodItem>.from(meal.items)..add(item);
      final updatedMeals = Map<String, Meal>.from(current.meals);
      updatedMeals[mealType] = Meal(type: mealType, items: updatedItems);

      final updatedLog = current.copyWith(meals: updatedMeals);
      logs[date] = updatedLog;

      await store.write('nutrition_logs', {
        'version': 1,
        'logs': logs.map((k, v) => MapEntry(k, v.toJson())),
      });
      return updatedLog;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<DailyNutritionLog> removeFoodFromMeal({
    required String date,
    required String mealType,
    required String itemId,
    int waterTarget = 2500,
  }) {
    final result = _tail.then((_) async {
      final logs = await _readAllLogs();
      final current =
          logs[date] ?? DailyNutritionLog.empty(date, waterTarget: waterTarget);

      final meal = current.meals[mealType];
      if (meal == null) return current;

      final updatedItems = List<LoggedFoodItem>.from(meal.items)
        ..removeWhere((i) => i.id == itemId);
      final updatedMeals = Map<String, Meal>.from(current.meals);
      updatedMeals[mealType] = Meal(type: mealType, items: updatedItems);

      final updatedLog = current.copyWith(meals: updatedMeals);
      logs[date] = updatedLog;

      await store.write('nutrition_logs', {
        'version': 1,
        'logs': logs.map((k, v) => MapEntry(k, v.toJson())),
      });
      return updatedLog;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<DailyNutritionLog> updateWater({
    required String date,
    required int waterMl,
    int waterTarget = 2500,
  }) {
    final result = _tail.then((_) async {
      final logs = await _readAllLogs();
      final current =
          logs[date] ?? DailyNutritionLog.empty(date, waterTarget: waterTarget);
      final updatedLog = current.copyWith(waterMl: waterMl.clamp(0, 10000));
      logs[date] = updatedLog;

      await store.write('nutrition_logs', {
        'version': 1,
        'logs': logs.map((k, v) => MapEntry(k, v.toJson())),
      });
      return updatedLog;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<DailyNutritionLog> addWater({
    required String date,
    required int amountMl,
    int waterTarget = 2500,
  }) async {
    final current = await getDailyLog(date, waterTarget: waterTarget);
    return updateWater(
      date: date,
      waterMl: current.waterMl + amountMl,
      waterTarget: waterTarget,
    );
  }

  Future<DailyNutritionLog> copyMeals({
    required String fromDate,
    required String toDate,
    int waterTarget = 2500,
  }) {
    final result = _tail.then((_) async {
      final logs = await _readAllLogs();
      final source = logs[fromDate];
      if (source == null) {
        return logs[toDate] ??
            DailyNutritionLog.empty(toDate, waterTarget: waterTarget);
      }

      final copiedMeals = <String, Meal>{};
      source.meals.forEach((type, meal) {
        copiedMeals[type] = Meal(
          type: type,
          items: meal.items
              .map(
                (i) => LoggedFoodItem(
                  id: '${DateTime.now().millisecondsSinceEpoch}_${i.id}',
                  foodId: i.foodId,
                  name: i.name,
                  portionName: i.portionName,
                  grams: i.grams,
                  quantity: i.quantity,
                  calories: i.calories,
                  protein: i.protein,
                  carbs: i.carbs,
                  fat: i.fat,
                  fiber: i.fiber,
                ),
              )
              .toList(),
        );
      });

      final target =
          logs[toDate] ??
          DailyNutritionLog.empty(toDate, waterTarget: waterTarget);
      final updated = target.copyWith(meals: copiedMeals);
      logs[toDate] = updated;

      await store.write('nutrition_logs', {
        'version': 1,
        'logs': logs.map((k, v) => MapEntry(k, v.toJson())),
      });
      return updated;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<DailyNutritionLog> clearMeals({
    required String date,
    int waterTarget = 2500,
  }) {
    final result = _tail.then((_) async {
      final logs = await _readAllLogs();
      final current =
          logs[date] ?? DailyNutritionLog.empty(date, waterTarget: waterTarget);
      final updated = DailyNutritionLog.empty(
        date,
        waterTarget: current.waterTargetMl,
      ).copyWith(waterMl: current.waterMl);
      logs[date] = updated;

      await store.write('nutrition_logs', {
        'version': 1,
        'logs': logs.map((k, v) => MapEntry(k, v.toJson())),
      });
      return updated;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}

final nutritionRepositoryProvider = Provider<NutritionRepository>(
  (ref) => NutritionRepository(ref.watch(storeProvider)),
);

final nutritionTargetsProvider = Provider<NutritionTargets>((ref) {
  final profile = ref.watch(profileProvider).value;
  return NutritionCalculator.calculate(profile);
});

final nutritionLogsProvider =
    AsyncNotifierProvider<
      NutritionLogsController,
      Map<String, DailyNutritionLog>
    >(NutritionLogsController.new);

class NutritionLogsController
    extends AsyncNotifier<Map<String, DailyNutritionLog>> {
  @override
  Future<Map<String, DailyNutritionLog>> build() =>
      ref.watch(nutritionRepositoryProvider).loadAllLogs();

  Future<void> addFood({
    required String date,
    required String mealType,
    required LoggedFoodItem item,
  }) async {
    final targets = ref.read(nutritionTargetsProvider);
    await ref
        .read(nutritionRepositoryProvider)
        .addFoodToMeal(
          date: date,
          mealType: mealType,
          item: item,
          waterTarget: targets.waterMl,
        );
    final updatedMap = await ref
        .read(nutritionRepositoryProvider)
        .loadAllLogs();
    if (ref.mounted) state = AsyncData(updatedMap);
  }

  Future<void> removeFood({
    required String date,
    required String mealType,
    required String itemId,
  }) async {
    final targets = ref.read(nutritionTargetsProvider);
    await ref
        .read(nutritionRepositoryProvider)
        .removeFoodFromMeal(
          date: date,
          mealType: mealType,
          itemId: itemId,
          waterTarget: targets.waterMl,
        );
    final updatedMap = await ref
        .read(nutritionRepositoryProvider)
        .loadAllLogs();
    if (ref.mounted) state = AsyncData(updatedMap);
  }

  Future<void> addWater({required String date, required int amountMl}) async {
    final targets = ref.read(nutritionTargetsProvider);
    await ref
        .read(nutritionRepositoryProvider)
        .addWater(date: date, amountMl: amountMl, waterTarget: targets.waterMl);
    final updatedMap = await ref
        .read(nutritionRepositoryProvider)
        .loadAllLogs();
    if (ref.mounted) state = AsyncData(updatedMap);
  }

  Future<void> setWater({required String date, required int waterMl}) async {
    final targets = ref.read(nutritionTargetsProvider);
    await ref
        .read(nutritionRepositoryProvider)
        .updateWater(
          date: date,
          waterMl: waterMl,
          waterTarget: targets.waterMl,
        );
    final updatedMap = await ref
        .read(nutritionRepositoryProvider)
        .loadAllLogs();
    if (ref.mounted) state = AsyncData(updatedMap);
  }

  Future<void> copyFrom({
    required String fromDate,
    required String toDate,
  }) async {
    final targets = ref.read(nutritionTargetsProvider);
    await ref
        .read(nutritionRepositoryProvider)
        .copyMeals(
          fromDate: fromDate,
          toDate: toDate,
          waterTarget: targets.waterMl,
        );
    final updatedMap = await ref
        .read(nutritionRepositoryProvider)
        .loadAllLogs();
    if (ref.mounted) state = AsyncData(updatedMap);
  }

  Future<void> clearAllMeals({required String date}) async {
    final targets = ref.read(nutritionTargetsProvider);
    await ref
        .read(nutritionRepositoryProvider)
        .clearMeals(date: date, waterTarget: targets.waterMl);
    final updatedMap = await ref
        .read(nutritionRepositoryProvider)
        .loadAllLogs();
    if (ref.mounted) state = AsyncData(updatedMap);
  }
}

String todayIsoDate() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

final dailyNutritionLogProvider = Provider.family<DailyNutritionLog, String>((
  ref,
  date,
) {
  final logsAsync = ref.watch(nutritionLogsProvider);
  final targets = ref.watch(nutritionTargetsProvider);
  final logs = logsAsync.value ?? {};
  return logs[date] ??
      DailyNutritionLog.empty(date, waterTarget: targets.waterMl);
});

final todayNutritionLogProvider = Provider<DailyNutritionLog>((ref) {
  final date = todayIsoDate();
  return ref.watch(dailyNutritionLogProvider(date));
});
