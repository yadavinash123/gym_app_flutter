import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/json_store.dart';
import '../../health/data/health_repository.dart';
import '../../health/models/daily_health_summary.dart';
import '../../nutrition/data/nutrition_repository.dart';
import '../../nutrition/models/meal_log.dart';
import '../../profile/profile.dart';
import '../../profile/profile_repository.dart';
import '../../workouts/data/workout_repository.dart';
import '../../workouts/models/progressive_overload.dart';
import '../../workouts/models/workout_session.dart';
import '../models/body_measurement.dart';
import '../models/habit_streak.dart';
import '../models/milestone_badge.dart';
import '../models/muscle_recovery.dart';
import '../models/notification_schedule.dart';
import 'milestone_engine.dart';
import 'recovery_calculator.dart';
import 'streak_engine.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final store = ref.watch(storeProvider);
  return ProgressRepository(store);
});

final bodyMeasurementsProvider = FutureProvider<List<BodyMeasurementEntry>>((ref) {
  return ref.watch(progressRepositoryProvider).loadMeasurements();
});

final reminderPreferencesProvider =
    FutureProvider<List<ReminderPreference>>((ref) {
  return ref.watch(progressRepositoryProvider).loadReminderPreferences();
});

final habitStreaksProvider = FutureProvider<Map<HabitType, HabitStreak>>((ref) async {
  final repo = ref.watch(progressRepositoryProvider);
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final nutritionRepo = ref.watch(nutritionRepositoryProvider);

  final sessions = await workoutRepo.loadSessions();
  final nutritionLogs = await nutritionRepo.loadAllLogs();

  return repo.computeStreaks(sessions: sessions, nutritionLogs: nutritionLogs);
});

final muscleRecoveryProvider = FutureProvider<OverallSystemReadiness>((ref) async {
  final repo = ref.watch(progressRepositoryProvider);
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final healthRepo = ref.watch(healthRepositoryProvider);

  final sessions = await workoutRepo.loadSessions();
  final today = todayIsoDate();
  final healthSummary = await healthRepo.getSummaryForDate(today);

  return repo.computeReadiness(
    sessions: sessions,
    latestHealth: healthSummary,
  );
});

final milestonesProvider = FutureProvider<List<MilestoneBadge>>((ref) async {
  final repo = ref.watch(progressRepositoryProvider);
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final nutritionRepo = ref.watch(nutritionRepositoryProvider);
  final healthRepo = ref.watch(healthRepositoryProvider);

  final sessions = await workoutRepo.loadSessions();
  final prs = ProgressRepository.computePersonalRecords(sessions);
  final nutritionLogs = await nutritionRepo.loadAllLogs();
  final healthSummaries = await healthRepo.loadAllSummaries();
  final workoutStreak = StreakEngine.computeWorkoutStreak(sessions);

  return repo.getOrEvaluateMilestones(
    sessions: sessions,
    prs: prs,
    workoutStreak: workoutStreak,
    nutritionLogs: nutritionLogs,
    healthSummaries: healthSummaries,
  );
});

class ProgressDashboardData {
  const ProgressDashboardData({
    required this.profile,
    required this.measurements,
    required this.sessions,
    required this.prs,
    required this.readiness,
    required this.streaks,
    required this.milestones,
    required this.reminders,
    required this.nutritionLogs,
    required this.healthSummaries,
  });

  final Profile? profile;
  final List<BodyMeasurementEntry> measurements;
  final List<WorkoutSession> sessions;
  final List<PersonalRecord> prs;
  final OverallSystemReadiness readiness;
  final Map<HabitType, HabitStreak> streaks;
  final List<MilestoneBadge> milestones;
  final List<ReminderPreference> reminders;
  final Map<String, DailyNutritionLog> nutritionLogs;
  final Map<String, DailyHealthSummary> healthSummaries;
}

final progressDashboardProvider = FutureProvider<ProgressDashboardData>((ref) async {
  final repo = ref.watch(progressRepositoryProvider);
  final profile = await ref.watch(profileProvider.future);
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final nutritionRepo = ref.watch(nutritionRepositoryProvider);
  final healthRepo = ref.watch(healthRepositoryProvider);

  final measurements = await repo.loadMeasurements();
  final sessions = await workoutRepo.loadSessions();
  final prs = ProgressRepository.computePersonalRecords(sessions);
  final nutritionLogs = await nutritionRepo.loadAllLogs();
  final healthSummaries = await healthRepo.loadAllSummaries();
  final reminders = await repo.loadReminderPreferences();

  final today = todayIsoDate();
  final healthToday = healthSummaries[today] ?? await healthRepo.getSummaryForDate(today);

  final readiness = repo.computeReadiness(
    sessions: sessions,
    latestHealth: healthToday,
  );

  final streaks = repo.computeStreaks(
    sessions: sessions,
    nutritionLogs: nutritionLogs,
  );

  final milestones = await repo.getOrEvaluateMilestones(
    sessions: sessions,
    prs: prs,
    workoutStreak: streaks[HabitType.workouts]!,
    nutritionLogs: nutritionLogs,
    healthSummaries: healthSummaries,
  );

  return ProgressDashboardData(
    profile: profile,
    measurements: measurements,
    sessions: sessions,
    prs: prs,
    readiness: readiness,
    streaks: streaks,
    milestones: milestones,
    reminders: reminders,
    nutritionLogs: nutritionLogs,
    healthSummaries: healthSummaries,
  );
});

class ProgressRepository {
  ProgressRepository(this.store);

  final JsonStore store;
  Future<void> _tail = Future.value();

  // ---------------------------------------------------------------------------
  // Body Measurements
  // ---------------------------------------------------------------------------

  Future<List<BodyMeasurementEntry>> loadMeasurements() async {
    await _tail;
    return _readMeasurements();
  }

  Future<List<BodyMeasurementEntry>> _readMeasurements() async {
    final data = await store.read('body_measurements');
    if (data == null) return [];
    if (data['version'] != 1 || data['measurements'] is! List) {
      throw const FormatException('Invalid body measurements storage');
    }
    final list = (data['measurements'] as List)
        .map((e) => BodyMeasurementEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Future<BodyMeasurementEntry> addMeasurement(BodyMeasurementEntry entry) {
    final result = _tail.then((_) async {
      final list = await _readMeasurements();
      final index = list.indexWhere((e) => e.date == entry.date);
      if (index >= 0) {
        list[index] = entry;
      } else {
        list.add(entry);
      }
      list.sort((a, b) => a.date.compareTo(b.date));

      await store.write('body_measurements', {
        'version': 1,
        'measurements': list.map((e) => e.toJson()).toList(),
      });
      return entry;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> deleteMeasurement(String id) {
    final result = _tail.then((_) async {
      final list = await _readMeasurements();
      list.removeWhere((e) => e.id == id);
      await store.write('body_measurements', {
        'version': 1,
        'measurements': list.map((e) => e.toJson()).toList(),
      });
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  // ---------------------------------------------------------------------------
  // Milestones Persistence
  // ---------------------------------------------------------------------------

  Future<List<MilestoneBadge>> loadMilestones() async {
    await _tail;
    return _readMilestones();
  }

  Future<List<MilestoneBadge>> _readMilestones() async {
    final data = await store.read('milestones');
    if (data == null) {
      return MilestoneBadge.defaultCatalog();
    }
    if (data['version'] != 1 || data['badges'] is! List) {
      throw const FormatException('Invalid milestones storage');
    }
    return (data['badges'] as List)
        .map((e) => MilestoneBadge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MilestoneBadge>> getOrEvaluateMilestones({
    required List<WorkoutSession> sessions,
    required List<PersonalRecord> prs,
    required HabitStreak workoutStreak,
    required Map<String, DailyNutritionLog> nutritionLogs,
    required Map<String, DailyHealthSummary> healthSummaries,
    DateTime? checkTime,
  }) async {
    await _tail;
    final existing = await _readMilestones();
    final evaluated = MilestoneEngine.evaluateMilestones(
      existingBadges: existing,
      sessions: sessions,
      prs: prs,
      workoutStreak: workoutStreak,
      nutritionLogs: nutritionLogs,
      healthSummaries: healthSummaries,
      checkTime: checkTime,
    );

    // Save evaluated milestones back to disk safely
    final result = _tail.then((_) async {
      await store.write('milestones', {
        'version': 1,
        'badges': evaluated.map((e) => e.toJson()).toList(),
      });
      return evaluated;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  // ---------------------------------------------------------------------------
  // Reminder Preferences
  // ---------------------------------------------------------------------------

  Future<List<ReminderPreference>> loadReminderPreferences() async {
    await _tail;
    return _readReminderPreferences();
  }

  Future<List<ReminderPreference>> _readReminderPreferences() async {
    final data = await store.read('notification_preferences');
    if (data == null) {
      return ReminderPreference.defaultSchedules();
    }
    if (data['version'] != 1 || data['reminders'] is! List) {
      throw const FormatException('Invalid notification preferences storage');
    }
    return (data['reminders'] as List)
        .map((e) => ReminderPreference.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReminderPreference>> saveReminderPreferences(
    List<ReminderPreference> reminders,
  ) {
    final result = _tail.then((_) async {
      await store.write('notification_preferences', {
        'version': 1,
        'reminders': reminders.map((e) => e.toJson()).toList(),
      });
      return reminders;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  // ---------------------------------------------------------------------------
  // Aggregated Recovery & Streaks Calculation
  // ---------------------------------------------------------------------------

  OverallSystemReadiness computeReadiness({
    required List<WorkoutSession> sessions,
    DailyHealthSummary? latestHealth,
    DateTime? currentTime,
  }) {
    return RecoveryCalculator.calculateReadiness(
      sessions: sessions,
      latestHealth: latestHealth,
      currentTime: currentTime,
    );
  }

  Map<HabitType, HabitStreak> computeStreaks({
    required List<WorkoutSession> sessions,
    required Map<String, DailyNutritionLog> nutritionLogs,
    DateTime? referenceDate,
  }) {
    final workoutStreak = StreakEngine.computeWorkoutStreak(
      sessions,
      referenceDate: referenceDate,
    );
    final nutritionStreak = StreakEngine.computeNutritionStreak(
      nutritionLogs,
      referenceDate: referenceDate,
    );
    final hydrationStreak = StreakEngine.computeHydrationStreak(
      nutritionLogs,
      referenceDate: referenceDate,
    );
    final overallStreak = StreakEngine.computeOverallStreak(
      sessions: sessions,
      logs: nutritionLogs,
      referenceDate: referenceDate,
    );

    return {
      HabitType.workouts: workoutStreak,
      HabitType.nutrition: nutritionStreak,
      HabitType.hydration: hydrationStreak,
      HabitType.overall: overallStreak,
    };
  }

  static List<PersonalRecord> computePersonalRecords(List<WorkoutSession> sessions) {
    final list = <PersonalRecord>[];
    final exerciseIds = <String>{};
    for (final s in sessions) {
      for (final ex in s.exercises) {
        exerciseIds.add(ex.exerciseId);
      }
    }
    for (final id in exerciseIds) {
      final pr = ProgressiveOverloadCalculator.calculatePR(
        exerciseId: id,
        sessions: sessions,
      );
      if (pr != null) {
        list.add(pr);
      }
    }
    return list;
  }
}
