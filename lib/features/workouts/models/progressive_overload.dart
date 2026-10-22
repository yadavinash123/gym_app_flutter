import 'package:flutter/foundation.dart';
import 'workout_session.dart';

@immutable
class PersonalRecord {
  const PersonalRecord({
    required this.exerciseId,
    required this.maxWeightKg,
    required this.maxRepsAtMaxWeight,
    required this.maxSessionVolumeKg,
    required this.estimatedOneRepMaxKg,
    required this.achievedAt,
  });

  final String exerciseId;
  final double maxWeightKg;
  final int maxRepsAtMaxWeight;
  final double maxSessionVolumeKg;
  final double estimatedOneRepMaxKg;
  final DateTime achievedAt;

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'maxWeightKg': maxWeightKg,
        'maxRepsAtMaxWeight': maxRepsAtMaxWeight,
        'maxSessionVolumeKg': maxSessionVolumeKg,
        'estimatedOneRepMaxKg': estimatedOneRepMaxKg,
        'achievedAt': achievedAt.toIso8601String(),
      };

  factory PersonalRecord.fromJson(Map<String, dynamic> json) => PersonalRecord(
        exerciseId: json['exerciseId'] as String,
        maxWeightKg: (json['maxWeightKg'] as num?)?.toDouble() ?? 0.0,
        maxRepsAtMaxWeight: json['maxRepsAtMaxWeight'] as int? ?? 0,
        maxSessionVolumeKg:
            (json['maxSessionVolumeKg'] as num?)?.toDouble() ?? 0.0,
        estimatedOneRepMaxKg:
            (json['estimatedOneRepMaxKg'] as num?)?.toDouble() ?? 0.0,
        achievedAt: DateTime.parse(json['achievedAt'] as String),
      );
}

enum ProgressionDecision {
  increaseLoad,
  increaseReps,
  maintainLoad,
  deloadOrRest,
  painWarning,
}

@immutable
class ProgressionRecommendation {
  const ProgressionRecommendation({
    required this.exerciseId,
    required this.decision,
    required this.message,
    this.suggestedWeightKg,
    this.suggestedReps,
  });

  final String exerciseId;
  final ProgressionDecision decision;
  final String message;
  final double? suggestedWeightKg;
  final int? suggestedReps;
}

class ProgressiveOverloadCalculator {
  /// Brzycki 1RM formula: Weight * (36 / (37 - Reps))
  /// Valid for reps between 1 and 10. For reps > 10, estimates become approximate.
  static double estimateOneRepMax(double weightKg, int reps) {
    if (weightKg <= 0 || reps <= 0) return 0.0;
    if (reps == 1) return weightKg;
    final cappedReps = reps.clamp(1, 15);
    final oneRm = weightKg * (36.0 / (37.0 - cappedReps));
    return double.parse(oneRm.toStringAsFixed(1));
  }

  /// Calculates personal records for an exercise across all past workout sessions.
  static PersonalRecord? calculatePR({
    required String exerciseId,
    required List<WorkoutSession> sessions,
  }) {
    double maxWeight = 0.0;
    int maxReps = 0;
    double maxVolume = 0.0;
    double max1Rm = 0.0;
    DateTime? bestDate;

    for (final session in sessions) {
      for (final ex in session.exercises) {
        if (ex.exerciseId != exerciseId) continue;
        if (ex.totalVolumeKg > maxVolume) {
          maxVolume = ex.totalVolumeKg;
        }
        for (final set in ex.sets) {
          if (!set.isCompleted) continue;
          final est1Rm = estimateOneRepMax(set.weightKg, set.actualReps);
          if (est1Rm > max1Rm) {
            max1Rm = est1Rm;
          }
          if (set.weightKg > maxWeight) {
            maxWeight = set.weightKg;
            maxReps = set.actualReps;
            bestDate = session.completedAt;
          } else if (set.weightKg == maxWeight && set.actualReps > maxReps) {
            maxReps = set.actualReps;
            bestDate = session.completedAt;
          }
        }
      }
    }

    if (bestDate == null && maxVolume <= 0 && maxWeight <= 0) return null;

    return PersonalRecord(
      exerciseId: exerciseId,
      maxWeightKg: maxWeight,
      maxRepsAtMaxWeight: maxReps,
      maxSessionVolumeKg: maxVolume,
      estimatedOneRepMaxKg: max1Rm,
      achievedAt: bestDate ?? DateTime.now(),
    );
  }

  /// Evaluates previous performance and returns conservative, evidence-based progression guidance.
  /// Never increases intensity if the user reported pain or discomfort, or if RPE >= 9.
  static ProgressionRecommendation evaluateProgression({
    required String exerciseId,
    required List<WorkoutSession> pastSessions,
    required bool isBodyweight,
    required bool isLowerBody,
  }) {
    // Find the latest session containing this exercise
    CompletedExercise? lastExercise;
    for (final session in pastSessions.reversed) {
      final match = session.exercises.where((e) => e.exerciseId == exerciseId);
      if (match.isNotEmpty) {
        lastExercise = match.first;
        break;
      }
    }

    if (lastExercise == null || lastExercise.sets.isEmpty) {
      return ProgressionRecommendation(
        exerciseId: exerciseId,
        decision: ProgressionDecision.maintainLoad,
        message: 'First time recording this exercise. Start with a comfortable baseline weight.',
      );
    }

    // Check for pain or discomfort
    final painReported = lastExercise.painReported ||
        lastExercise.sets.any((s) => s.painReported);
    if (painReported) {
      return ProgressionRecommendation(
        exerciseId: exerciseId,
        decision: ProgressionDecision.painWarning,
        message: 'Pain or discomfort was reported in the previous session. Do not increase load. Consider lighter form review or an alternative movement.',
      );
    }

    final completedSets =
        lastExercise.sets.where((s) => s.isCompleted).toList();
    if (completedSets.isEmpty) {
      return ProgressionRecommendation(
        exerciseId: exerciseId,
        decision: ProgressionDecision.maintainLoad,
        message: 'Previous session sets were incomplete. Repeat at current load.',
      );
    }

    // Check average RPE
    final avgRpe = completedSets.fold<int>(0, (sum, s) => sum + s.rpe) /
        completedSets.length;
    final lastWeight = completedSets.last.weightKg;
    final lastReps = completedSets.last.actualReps;

    if (avgRpe >= 9.0) {
      return ProgressionRecommendation(
        exerciseId: exerciseId,
        decision: ProgressionDecision.deloadOrRest,
        message: 'High perceived effort (RPE ${avgRpe.toStringAsFixed(1)}). Maintain or slightly decrease load to prioritize recovery and form.',
        suggestedWeightKg: lastWeight,
        suggestedReps: lastReps,
      );
    }

    if (avgRpe > 7.5) {
      return ProgressionRecommendation(
        exerciseId: exerciseId,
        decision: ProgressionDecision.maintainLoad,
        message: 'Solid training stimulus (RPE ${avgRpe.toStringAsFixed(1)}). Maintain current weight to solidify movement mastery.',
        suggestedWeightKg: lastWeight,
        suggestedReps: lastReps,
      );
    }

    // RPE <= 7.5: user handled the load comfortably with reserve.
    if (isBodyweight || lastWeight <= 0.0) {
      final newReps = (lastReps + 1).clamp(1, 25);
      return ProgressionRecommendation(
        exerciseId: exerciseId,
        decision: ProgressionDecision.increaseReps,
        message: 'Strong completion at moderate effort. Try adding 1-2 repetitions per set.',
        suggestedWeightKg: 0.0,
        suggestedReps: newReps,
      );
    } else {
      // Conservative weight increments: 1.25kg - 2.5kg for upper body, 2.5kg - 5.0kg for lower body.
      final increment = isLowerBody ? 2.5 : 1.25;
      final newWeight = lastWeight + increment;
      return ProgressionRecommendation(
        exerciseId: exerciseId,
        decision: ProgressionDecision.increaseLoad,
        message: 'Smooth completion with reserve (RPE ${avgRpe.toStringAsFixed(1)}). Conservative increase of +${increment.toStringAsFixed(2)} kg recommended.',
        suggestedWeightKg: newWeight,
        suggestedReps: lastReps,
      );
    }
  }
}
