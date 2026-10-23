import 'package:flutter/foundation.dart';

enum MuscleRecoveryState {
  fresh,       // 90% - 100% recovered
  recovering,  // 60% - 89% recovered
  fatigued,    // 30% - 59% recovered
  overreaching // 0% - 29% heavily fatigued
}

@immutable
class MuscleGroupRecovery {
  const MuscleGroupRecovery({
    required this.muscleGroup,
    required this.recoveryPercentage,
    required this.state,
    required this.hoursSinceLastTrained,
    this.lastTrainedAt,
    required this.estimatedHoursToFullRecovery,
    this.setsInLast48Hours = 0,
    this.totalVolumeInLast48Hours = 0.0,
  });

  final String muscleGroup; // e.g. Chest, Back, Shoulders, Legs, Arms, Core
  final double recoveryPercentage; // 0.0 to 100.0
  final MuscleRecoveryState state;
  final double hoursSinceLastTrained;
  final DateTime? lastTrainedAt;
  final int estimatedHoursToFullRecovery;
  final int setsInLast48Hours;
  final double totalVolumeInLast48Hours;

  String get stateDisplayName {
    switch (state) {
      case MuscleRecoveryState.fresh:
        return 'Fresh';
      case MuscleRecoveryState.recovering:
        return 'Recovering';
      case MuscleRecoveryState.fatigued:
        return 'Fatigued';
      case MuscleRecoveryState.overreaching:
        return 'Overreaching';
    }
  }

  Map<String, dynamic> toJson() => {
        'muscleGroup': muscleGroup,
        'recoveryPercentage': recoveryPercentage,
        'state': state.name,
        'hoursSinceLastTrained': hoursSinceLastTrained,
        if (lastTrainedAt != null)
          'lastTrainedAt': lastTrainedAt!.toIso8601String(),
        'estimatedHoursToFullRecovery': estimatedHoursToFullRecovery,
        'setsInLast48Hours': setsInLast48Hours,
        'totalVolumeInLast48Hours': totalVolumeInLast48Hours,
      };

  factory MuscleGroupRecovery.fromJson(Map<String, dynamic> json) =>
      MuscleGroupRecovery(
        muscleGroup: json['muscleGroup'] as String,
        recoveryPercentage:
            (json['recoveryPercentage'] as num).toDouble(),
        state: MuscleRecoveryState.values.firstWhere(
          (e) => e.name == json['state'],
          orElse: () => MuscleRecoveryState.fresh,
        ),
        hoursSinceLastTrained:
            (json['hoursSinceLastTrained'] as num).toDouble(),
        lastTrainedAt: json['lastTrainedAt'] != null
            ? DateTime.tryParse(json['lastTrainedAt'] as String)
            : null,
        estimatedHoursToFullRecovery:
            (json['estimatedHoursToFullRecovery'] as num).toInt(),
        setsInLast48Hours: (json['setsInLast48Hours'] as num?)?.toInt() ?? 0,
        totalVolumeInLast48Hours:
            (json['totalVolumeInLast48Hours'] as num?)?.toDouble() ?? 0.0,
      );
}

@immutable
class OverallSystemReadiness {
  const OverallSystemReadiness({
    required this.readinessScore, // 0 to 100
    required this.muscles,
    required this.sleepFactor,
    required this.heartRateFactor,
    required this.advice,
  });

  final int readinessScore;
  final List<MuscleGroupRecovery> muscles;
  final double sleepFactor; // e.g. 1.0 = optimal, < 1.0 = deficit
  final double heartRateFactor; // e.g. 1.0 = resting baseline, < 1.0 = elevated
  final String advice;

  String get readinessLabel {
    if (readinessScore >= 85) return 'Optimal Readiness';
    if (readinessScore >= 70) return 'Good to Train';
    if (readinessScore >= 50) return 'Moderate Fatigue';
    return 'Rest Recommended';
  }
}
