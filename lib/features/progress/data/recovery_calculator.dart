import 'dart:math' as math;

import '../../health/models/daily_health_summary.dart';
import '../../workouts/models/workout_session.dart';
import '../models/muscle_recovery.dart';

class RecoveryCalculator {
  static const List<String> canonicalMuscleGroups = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
  ];

  /// Maps specific catalog exercise muscle tags to canonical muscle groups.
  static String mapToCanonicalGroup(String muscleTag) {
    final lower = muscleTag.toLowerCase().trim();
    if (lower.contains('chest') || lower.contains('pectoral')) return 'Chest';
    if (lower.contains('back') ||
        lower.contains('lat') ||
        lower.contains('rhomboid') ||
        lower.contains('trapezius'))
      return 'Back';
    if (lower.contains('leg') ||
        lower.contains('quad') ||
        lower.contains('hamstring') ||
        lower.contains('glute') ||
        lower.contains('calf') ||
        lower.contains('calves'))
      return 'Legs';
    if (lower.contains('shoulder') || lower.contains('deltoid'))
      return 'Shoulders';
    if (lower.contains('bicep') ||
        lower.contains('tricep') ||
        lower.contains('arm') ||
        lower.contains('forearm'))
      return 'Arms';
    if (lower.contains('core') ||
        lower.contains('ab') ||
        lower.contains('oblique') ||
        lower.contains('spine'))
      return 'Core';
    return 'Core';
  }

  /// Evaluates recovery state for each muscle group based on recent workouts and health metrics.
  static OverallSystemReadiness calculateReadiness({
    required List<WorkoutSession> sessions,
    DailyHealthSummary? latestHealth,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();

    // Map to accumulate training history per muscle group
    final muscleHistory = <String, _MuscleTrainingStats>{};
    for (final group in canonicalMuscleGroups) {
      muscleHistory[group] = _MuscleTrainingStats();
    }

    // Inspect sessions in chronological order
    final sortedSessions = List<WorkoutSession>.from(sessions)
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    for (final session in sortedSessions) {
      final hoursAgo = now.difference(session.completedAt).inMinutes / 60.0;
      if (hoursAgo < 0) continue; // Future timestamp safeguard

      for (final exercise in session.exercises) {
        final groups = <String>{};
        for (final m in exercise.primaryMuscles) {
          groups.add(mapToCanonicalGroup(m));
        }
        if (groups.isEmpty) {
          groups.add('Core');
        }

        final setsCount = exercise.completedSetsCount;
        final volume = exercise.totalVolumeKg;

        for (final group in groups) {
          final stats = muscleHistory[group] ??= _MuscleTrainingStats();
          if (stats.lastTrainedAt == null ||
              session.completedAt.isAfter(stats.lastTrainedAt!)) {
            stats.lastTrainedAt = session.completedAt;
            stats.hoursSinceLastTrained = hoursAgo;
          }
          if (hoursAgo <= 48.0) {
            stats.setsInLast48Hours += setsCount;
            stats.volumeInLast48Hours += volume;
          }
          if (hoursAgo <= 72.0) {
            stats.setsInLast72Hours += setsCount;
            stats.volumeInLast72Hours += volume;
          }
        }
      }
    }

    final recoveries = <MuscleGroupRecovery>[];
    for (final group in canonicalMuscleGroups) {
      final stats = muscleHistory[group]!;
      recoveries.add(_computeGroupRecovery(group, stats, now));
    }

    // Autonomic factors from health summary
    double sleepFactor = 1.0;
    if (latestHealth?.sleepDurationMinutes != null) {
      final sleepMinutes = latestHealth!.sleepDurationMinutes!;
      if (sleepMinutes >= 450) {
        sleepFactor = 1.05; // >7.5h sleep promotes supercompensation
      } else if (sleepMinutes >= 390) {
        sleepFactor = 1.0; // 6.5 - 7.5h
      } else if (sleepMinutes >= 300) {
        sleepFactor = 0.88; // 5 - 6.5h
      } else {
        sleepFactor = 0.75; // Severe sleep restriction
      }
    }

    double hrFactor = 1.0;
    if (latestHealth?.restingHeartRateBpm != null) {
      final rhr = latestHealth!.restingHeartRateBpm!;
      if (rhr < 60) {
        hrFactor = 1.05; // Excellent parasympathetic tone
      } else if (rhr <= 75) {
        hrFactor = 1.0;
      } else if (rhr <= 85) {
        hrFactor = 0.92;
      } else {
        hrFactor = 0.85; // Elevated resting HR
      }
    }

    // Compute average muscle recovery score
    final avgMuscleRecovery = recoveries.isEmpty
        ? 100.0
        : recoveries.map((m) => m.recoveryPercentage).reduce((a, b) => a + b) /
              recoveries.length;

    // Modulate system readiness with autonomic recovery factors
    final autonomicScore = (sleepFactor * hrFactor * 100).clamp(50.0, 110.0);
    final rawSystemScore = (avgMuscleRecovery * 0.70) + (autonomicScore * 0.30);
    final finalReadiness = rawSystemScore.round().clamp(0, 100);

    // Generate actionable physiological advice
    final freshGroups = recoveries
        .where((r) => r.state == MuscleRecoveryState.fresh)
        .map((r) => r.muscleGroup)
        .toList();
    final fatiguedGroups = recoveries
        .where(
          (r) =>
              r.state == MuscleRecoveryState.fatigued ||
              r.state == MuscleRecoveryState.overreaching,
        )
        .map((r) => r.muscleGroup)
        .toList();

    String advice;
    if (fatiguedGroups.isEmpty) {
      advice = 'All major muscle groups are fully recovered and primed for progressive overload.';
    } else if (freshGroups.isNotEmpty) {
      advice =
          '${freshGroups.join(", ")} are fresh and ready for high-intensity stimulus. Allow ${fatiguedGroups.join(", ")} more recovery time.';
    } else {
      advice = 'Systemic fatigue is elevated across trained muscle groups. Consider an active recovery or rest day.';
    }

    return OverallSystemReadiness(
      readinessScore: finalReadiness,
      muscles: recoveries,
      sleepFactor: sleepFactor,
      heartRateFactor: hrFactor,
      advice: advice,
    );
  }

  static MuscleGroupRecovery _computeGroupRecovery(
    String group,
    _MuscleTrainingStats stats,
    DateTime now,
  ) {
    if (stats.lastTrainedAt == null) {
      return MuscleGroupRecovery(
        muscleGroup: group,
        recoveryPercentage: 100.0,
        state: MuscleRecoveryState.fresh,
        hoursSinceLastTrained: 999.0,
        estimatedHoursToFullRecovery: 0,
        setsInLast48Hours: 0,
        totalVolumeInLast48Hours: 0.0,
      );
    }

    final hours = math.max(0.0, stats.hoursSinceLastTrained);

    // Recovery curve calculation:
    // Immediate fatigue floor drops with volume
    final volumeSets = stats.setsInLast72Hours;
    final initialDrop = (volumeSets * 6.5).clamp(25.0, 75.0);
    final initialRecovery = 100.0 - initialDrop;

    // Exponential decay recovery coefficient
    // Light session recovers in ~36h, moderate in ~48h, heavy in ~72h
    final halfLifeHours = volumeSets > 10
        ? 30.0
        : (volumeSets > 5 ? 24.0 : 18.0);
    final k = math.ln2 / halfLifeHours;

    final currentRecovery =
        (initialRecovery +
                (100.0 - initialRecovery) * (1.0 - math.exp(-k * hours)))
            .clamp(0.0, 100.0);

    final hoursRemaining = currentRecovery >= 95.0
        ? 0
        : math.max(
            0,
            ((math.log(
                          (100.0 - initialRecovery) /
                              math.max(0.1, 100.0 - 95.0),
                        ) /
                        k) -
                    hours)
                .ceil(),
          );

    final state = _classifyState(currentRecovery);

    return MuscleGroupRecovery(
      muscleGroup: group,
      recoveryPercentage: double.parse(currentRecovery.toStringAsFixed(1)),
      state: state,
      hoursSinceLastTrained: double.parse(hours.toStringAsFixed(1)),
      lastTrainedAt: stats.lastTrainedAt,
      estimatedHoursToFullRecovery: hoursRemaining,
      setsInLast48Hours: stats.setsInLast48Hours,
      totalVolumeInLast48Hours: stats.volumeInLast48Hours,
    );
  }

  static MuscleRecoveryState _classifyState(double pct) {
    if (pct >= 90.0) return MuscleRecoveryState.fresh;
    if (pct >= 60.0) return MuscleRecoveryState.recovering;
    if (pct >= 30.0) return MuscleRecoveryState.fatigued;
    return MuscleRecoveryState.overreaching;
  }
}

class _MuscleTrainingStats {
  DateTime? lastTrainedAt;
  double hoursSinceLastTrained = 0.0;
  int setsInLast48Hours = 0;
  double volumeInLast48Hours = 0.0;
  int setsInLast72Hours = 0;
  double volumeInLast72Hours = 0.0;
}
