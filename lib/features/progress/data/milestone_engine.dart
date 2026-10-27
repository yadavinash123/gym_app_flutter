import '../../health/models/daily_health_summary.dart';
import '../../nutrition/models/meal_log.dart';
import '../../workouts/models/progressive_overload.dart';
import '../../workouts/models/workout_session.dart';
import '../models/habit_streak.dart';
import '../models/milestone_badge.dart';

class MilestoneEngine {
  /// Evaluates catalog milestones against user fitness data and returns updated badges.
  static List<MilestoneBadge> evaluateMilestones({
    required List<MilestoneBadge> existingBadges,
    required List<WorkoutSession> sessions,
    required List<PersonalRecord> prs,
    required HabitStreak workoutStreak,
    required Map<String, DailyNutritionLog> nutritionLogs,
    required Map<String, DailyHealthSummary> healthSummaries,
    DateTime? checkTime,
  }) {
    final now = checkTime ?? DateTime.now();
    final badgeMap = {for (final b in existingBadges) b.id: b};

    // Calculate aggregated stats
    final totalWorkouts = sessions.length;
    final totalSets = sessions.fold(0, (sum, s) => sum + s.totalCompletedSets);
    final totalVolume = sessions.fold(0.0, (sum, s) => sum + s.totalVolumeKg);
    final prCount = prs.length;
    final maxStreak = workoutStreak.longestStreak;

    // Nutrition stats
    final loggedNutritionDays = nutritionLogs.values
        .where((log) => log.totalCalories > 0 || log.totalFoodItemsCount > 0)
        .length;

    final hydrationGoalDays = nutritionLogs.values
        .where(
          (log) => log.waterMl >= log.waterTargetMl && log.waterTargetMl > 0,
        )
        .length;

    // Health stats: sleep days >= 7 hours (420 mins)
    final sleepDays = healthSummaries.values
        .where((h) => (h.sleepDurationMinutes ?? 0) >= 420)
        .length;

    final updated = <MilestoneBadge>[];

    for (final base in MilestoneBadge.defaultCatalog()) {
      final current = badgeMap[base.id] ?? base;
      double newCurrentValue = 0.0;

      switch (base.id) {
        case 'first_workout':
          newCurrentValue = totalWorkouts.toDouble();
          break;
        case 'workout_5':
          newCurrentValue = totalWorkouts.toDouble();
          break;
        case 'century_club':
          newCurrentValue = totalSets.toDouble();
          break;
        case 'streak_7':
          newCurrentValue = maxStreak.toDouble();
          break;
        case 'streak_30':
          newCurrentValue = maxStreak.toDouble();
          break;
        case 'volume_5k':
          newCurrentValue = totalVolume;
          break;
        case 'volume_25k':
          newCurrentValue = totalVolume;
          break;
        case 'volume_100k':
          newCurrentValue = totalVolume;
          break;
        case 'pr_breaker_3':
          newCurrentValue = prCount.toDouble();
          break;
        case 'nutrition_novice':
          newCurrentValue = loggedNutritionDays.toDouble();
          break;
        case 'hydration_hero':
          newCurrentValue = hydrationGoalDays.toDouble();
          break;
        case 'sleep_champion':
          newCurrentValue = sleepDays.toDouble();
          break;
        default:
          newCurrentValue = current.currentValue;
      }

      final newlyUnlocked =
          !current.isUnlocked && newCurrentValue >= base.targetValue;
      final isNowUnlocked = current.isUnlocked || newlyUnlocked;
      final unlockedTimestamp = newlyUnlocked ? now : current.unlockedAt;

      updated.add(
        current.copyWith(
          currentValue: newCurrentValue,
          isUnlocked: isNowUnlocked,
          unlockedAt: unlockedTimestamp,
        ),
      );
    }

    return updated;
  }
}
