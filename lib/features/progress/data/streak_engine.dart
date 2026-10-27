import '../../nutrition/models/meal_log.dart';
import '../../workouts/models/workout_session.dart';
import '../models/habit_streak.dart';

class StreakEngine {
  /// Computes habit streaks for workouts from workout sessions.
  static HabitStreak computeWorkoutStreak(
    List<WorkoutSession> sessions, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final activeDates = <String>{};

    for (final session in sessions) {
      final dateStr = _formatDate(session.completedAt);
      activeDates.add(dateStr);
    }

    return _calculateStreak(
      type: HabitType.workouts,
      activeDates: activeDates,
      referenceDate: now,
    );
  }

  /// Computes habit streaks for nutrition from daily logs.
  static HabitStreak computeNutritionStreak(
    Map<String, DailyNutritionLog> logs, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final activeDates = <String>{};

    for (final entry in logs.entries) {
      if (entry.value.totalCalories > 0 ||
          entry.value.totalFoodItemsCount > 0) {
        activeDates.add(entry.key);
      }
    }

    return _calculateStreak(
      type: HabitType.nutrition,
      activeDates: activeDates,
      referenceDate: now,
    );
  }

  /// Computes habit streaks for hydration from daily logs.
  static HabitStreak computeHydrationStreak(
    Map<String, DailyNutritionLog> logs, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final activeDates = <String>{};

    for (final entry in logs.entries) {
      if (entry.value.waterMl >= entry.value.waterTargetMl &&
          entry.value.waterTargetMl > 0) {
        activeDates.add(entry.key);
      }
    }

    return _calculateStreak(
      type: HabitType.hydration,
      activeDates: activeDates,
      referenceDate: now,
    );
  }

  /// Computes overall consistency streak where any positive habit was logged.
  static HabitStreak computeOverallStreak({
    required List<WorkoutSession> sessions,
    required Map<String, DailyNutritionLog> logs,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final activeDates = <String>{};

    for (final s in sessions) {
      activeDates.add(_formatDate(s.completedAt));
    }
    for (final entry in logs.entries) {
      if (!entry.value.isEmpty) {
        activeDates.add(entry.key);
      }
    }

    return _calculateStreak(
      type: HabitType.overall,
      activeDates: activeDates,
      referenceDate: now,
    );
  }

  static HabitStreak _calculateStreak({
    required HabitType type,
    required Set<String> activeDates,
    required DateTime referenceDate,
  }) {
    if (activeDates.isEmpty) {
      return HabitStreak(
        type: type,
        currentStreak: 0,
        longestStreak: 0,
        activeDates: activeDates,
        weeklyAdherenceRate: 0.0,
      );
    }

    final todayStr = _formatDate(referenceDate);
    final yesterdayStr = _formatDate(
      referenceDate.subtract(const Duration(days: 1)),
    );

    // Calculate current streak
    int current = 0;
    DateTime checkDate;

    if (activeDates.contains(todayStr)) {
      current = 1;
      checkDate = referenceDate.subtract(const Duration(days: 1));
      while (activeDates.contains(_formatDate(checkDate))) {
        current++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else if (activeDates.contains(yesterdayStr)) {
      current = 1;
      checkDate = referenceDate.subtract(const Duration(days: 2));
      while (activeDates.contains(_formatDate(checkDate))) {
        current++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else {
      current = 0;
    }

    // Calculate longest historical streak
    final sortedDates =
        activeDates
            .map((d) => DateTime.tryParse(d))
            .whereType<DateTime>()
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet()
            .toList()
          ..sort();

    int longest = 0;
    int running = 0;
    DateTime? prev;

    for (final d in sortedDates) {
      if (prev == null) {
        running = 1;
      } else {
        final diffDays = d.difference(prev).inDays;
        if (diffDays == 1) {
          running++;
        } else if (diffDays > 1) {
          running = 1;
        }
      }
      if (running > longest) {
        longest = running;
      }
      prev = d;
    }

    if (current > longest) {
      longest = current;
    }

    // Weekly adherence rate (days active in the last 7 calendar days)
    int activeLast7 = 0;
    for (int i = 0; i < 7; i++) {
      final d = referenceDate.subtract(Duration(days: i));
      if (activeDates.contains(_formatDate(d))) {
        activeLast7++;
      }
    }
    final weeklyAdherence = (activeLast7 / 7.0) * 100.0;

    // Find the latest active date
    String? latest;
    if (activeDates.isNotEmpty) {
      final allSorted = activeDates.toList()..sort();
      latest = allSorted.last;
    }

    return HabitStreak(
      type: type,
      currentStreak: current,
      longestStreak: longest,
      lastActiveDate: latest,
      activeDates: activeDates,
      weeklyAdherenceRate: double.parse(weeklyAdherence.toStringAsFixed(1)),
    );
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
