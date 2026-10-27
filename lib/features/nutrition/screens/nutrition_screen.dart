import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/nutrition_repository.dart';
import '../models/meal_log.dart';
import '../models/nutrition_targets.dart';
import '../widgets/macro_progress_bar.dart';
import '../widgets/nutrition_reference_dialog.dart';
import 'food_search_screen.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  String _formatDateKey(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _displayDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today, ${_monthName(dt.month)} ${dt.day}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday, ${_monthName(dt.month)} ${dt.day}';
    }
    return '${_weekdayName(dt.weekday)}, ${_monthName(dt.month)} ${dt.day}';
  }

  String _monthName(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }

  String _weekdayName(int w) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[w - 1];
  }

  void _changeDay(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _formatDateKey(_selectedDate);
    final logsState = ref.watch(nutritionLogsProvider);
    final log = ref.watch(dailyNutritionLogProvider(dateKey));
    final targets = ref.watch(nutritionTargetsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Date Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF151B23),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeDay(-1),
                  ),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Color(0xFFB6FF3B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _displayDate(_selectedDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeDay(1),
                  ),
                ],
              ),
            ),
            // Body Content
            Expanded(
              child: logsState.hasError && logsState.value == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Error loading daily log: ${logsState.error}',
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Target & Progress Overview Card
                        _buildOverviewCard(context, targets, log),
                        const SizedBox(height: 16),
                        // Hydration Card
                        _buildHydrationCard(context, dateKey, targets, log),
                        const SizedBox(height: 20),
                        // Meal Logs
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'DAILY MEALS',
                              style: TextStyle(
                                letterSpacing: 1.5,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFA7B0BF),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_horiz,
                                color: Color(0xFFA7B0BF),
                              ),
                              onSelected: (action) async {
                                if (action == 'copy_yesterday') {
                                  final yesterdayKey = _formatDateKey(
                                    _selectedDate.subtract(
                                      const Duration(days: 1),
                                    ),
                                  );
                                  await ref
                                      .read(nutritionLogsProvider.notifier)
                                      .copyFrom(
                                        fromDate: yesterdayKey,
                                        toDate: dateKey,
                                      );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Copied yesterday’s meals',
                                        ),
                                      ),
                                    );
                                  }
                                } else if (action == 'clear_today') {
                                  await ref
                                      .read(nutritionLogsProvider.notifier)
                                      .clearAllMeals(date: dateKey);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Cleared all meals for this day',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'copy_yesterday',
                                  child: Text('Copy yesterday’s meals'),
                                ),
                                const PopupMenuItem(
                                  value: 'clear_today',
                                  child: Text('Clear all meals'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final mealType in MealType.all)
                          _buildMealCard(
                            context,
                            dateKey,
                            mealType,
                            log.meals[mealType] ?? Meal(type: mealType),
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFB6FF3B),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Log Food',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FoodSearchScreen(
                date: dateKey,
                initialMealType: MealType.breakfast,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    NutritionTargets targets,
    DailyNutritionLog log,
  ) {
    final remainingKcal = targets.dailyCalories - log.totalCalories;
    final calorieProgress = targets.dailyCalories > 0
        ? (log.totalCalories / targets.dailyCalories).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1C2430)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DAILY TARGET',
                    style: TextStyle(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Color(0xFFB6FF3B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        log.totalCalories.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ ${targets.dailyCalories.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFA7B0BF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Calculation Reference',
                icon: const Icon(Icons.info_outline, color: Color(0xFFA7B0BF)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => NutritionReferenceDialog(targets: targets),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: calorieProgress,
              backgroundColor: const Color(0xFF1C2430),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFB6FF3B),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remainingKcal >= 0
                ? '${remainingKcal.toStringAsFixed(0)} kcal remaining today'
                : '${(-remainingKcal).toStringAsFixed(0)} kcal over target',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: remainingKcal >= 0
                  ? const Color(0xFFA7B0BF)
                  : const Color(0xFFFF7B72),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFF1C2430)),
          const SizedBox(height: 16),
          // Macronutrients
          MacroProgressBar(
            label: 'Protein',
            currentGrams: log.totalProtein,
            targetGrams: targets.proteinGrams,
            color: const Color(0xFFB6FF3B),
          ),
          const SizedBox(height: 12),
          MacroProgressBar(
            label: 'Carbohydrates',
            currentGrams: log.totalCarbs,
            targetGrams: targets.carbsGrams,
            color: const Color(0xFF00D4FF),
          ),
          const SizedBox(height: 12),
          MacroProgressBar(
            label: 'Fat',
            currentGrams: log.totalFat,
            targetGrams: targets.fatGrams,
            color: const Color(0xFFFFB800),
          ),
          const SizedBox(height: 12),
          MacroProgressBar(
            label: 'Dietary Fiber',
            currentGrams: log.totalFiber,
            targetGrams: targets.fiberGrams,
            color: const Color(0xFFA78BFA),
          ),
        ],
      ),
    );
  }

  Widget _buildHydrationCard(
    BuildContext context,
    String dateKey,
    NutritionTargets targets,
    DailyNutritionLog log,
  ) {
    final waterProgress = targets.waterMl > 0
        ? (log.waterMl / targets.waterMl).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1C2430)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.water_drop,
                    color: Color(0xFF00D4FF),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Hydration',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Text(
                '${log.waterMl} / ${targets.waterMl} ml',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF00D4FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: waterProgress,
              backgroundColor: const Color(0xFF1C2430),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00D4FF),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ActionChip(
                avatar: const Icon(
                  Icons.add,
                  size: 16,
                  color: Color(0xFF00D4FF),
                ),
                label: const Text('+250 ml', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  ref
                      .read(nutritionLogsProvider.notifier)
                      .addWater(date: dateKey, amountMl: 250);
                },
              ),
              ActionChip(
                avatar: const Icon(
                  Icons.add,
                  size: 16,
                  color: Color(0xFF00D4FF),
                ),
                label: const Text('+500 ml', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  ref
                      .read(nutritionLogsProvider.notifier)
                      .addWater(date: dateKey, amountMl: 500);
                },
              ),
              if (log.waterMl > 0)
                IconButton(
                  tooltip: 'Reset water',
                  icon: const Icon(
                    Icons.refresh,
                    size: 18,
                    color: Color(0xFFA7B0BF),
                  ),
                  onPressed: () {
                    ref
                        .read(nutritionLogsProvider.notifier)
                        .setWater(date: dateKey, waterMl: 0);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(
    BuildContext context,
    String dateKey,
    String mealType,
    Meal meal,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1C2430)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      mealType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (meal.items.isNotEmpty)
                      Text(
                        '${meal.totalCalories.toStringAsFixed(0)} kcal • ${meal.totalProtein.toStringAsFixed(1)}g P',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFA7B0BF),
                        ),
                      ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FoodSearchScreen(
                          date: dateKey,
                          initialMealType: mealType,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.add,
                    size: 16,
                    color: Color(0xFFB6FF3B),
                  ),
                  label: const Text(
                    'Add Food',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB6FF3B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (meal.items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'No items logged for $mealType yet.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6E7681)),
              ),
            )
          else ...[
            const Divider(height: 1, color: Color(0xFF1C2430)),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: meal.items.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Color(0xFF1C2430)),
              itemBuilder: (ctx, index) {
                final item = meal.items[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${item.quantity % 1 == 0 ? item.quantity.toStringAsFixed(0) : item.quantity.toStringAsFixed(1)} × ${item.portionName} (${item.grams.toStringAsFixed(0)}g) • ${item.calories.toStringAsFixed(0)} kcal • ${item.protein.toStringAsFixed(1)}g P',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA7B0BF),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Color(0xFFA7B0BF),
                    ),
                    onPressed: () {
                      ref
                          .read(nutritionLogsProvider.notifier)
                          .removeFood(
                            date: dateKey,
                            mealType: mealType,
                            itemId: item.id,
                          );
                    },
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
