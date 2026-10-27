import 'package:flutter/foundation.dart';

@immutable
class CompletedSet {
  const CompletedSet({
    required this.setNumber,
    required this.targetReps,
    required this.actualReps,
    required this.weightKg,
    this.rpe = 7,
    this.isCompleted = true,
    this.painReported = false,
    this.notes = '',
  });

  final int setNumber;
  final int targetReps;
  final int actualReps;
  final double weightKg;
  final int rpe;
  final bool isCompleted;
  final bool painReported;
  final String notes;

  double get volumeKg => isCompleted ? (weightKg * actualReps) : 0.0;

  CompletedSet copyWith({
    int? setNumber,
    int? targetReps,
    int? actualReps,
    double? weightKg,
    int? rpe,
    bool? isCompleted,
    bool? painReported,
    String? notes,
  }) => CompletedSet(
    setNumber: setNumber ?? this.setNumber,
    targetReps: targetReps ?? this.targetReps,
    actualReps: actualReps ?? this.actualReps,
    weightKg: weightKg ?? this.weightKg,
    rpe: rpe ?? this.rpe,
    isCompleted: isCompleted ?? this.isCompleted,
    painReported: painReported ?? this.painReported,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'targetReps': targetReps,
    'actualReps': actualReps,
    'weightKg': weightKg,
    'rpe': rpe,
    'isCompleted': isCompleted,
    'painReported': painReported,
    'notes': notes,
  };

  factory CompletedSet.fromJson(Map<String, dynamic> json) => CompletedSet(
    setNumber: json['setNumber'] as int? ?? 1,
    targetReps: json['targetReps'] as int? ?? 10,
    actualReps: json['actualReps'] as int? ?? 10,
    weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
    rpe: json['rpe'] as int? ?? 7,
    isCompleted: json['isCompleted'] as bool? ?? true,
    painReported: json['painReported'] as bool? ?? false,
    notes: json['notes'] as String? ?? '',
  );
}

@immutable
class CompletedExercise {
  const CompletedExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.primaryMuscles,
    required this.sets,
    this.painReported = false,
    this.notes = '',
  });

  final String exerciseId;
  final String exerciseName;
  final List<String> primaryMuscles;
  final List<CompletedSet> sets;
  final bool painReported;
  final String notes;

  int get completedSetsCount => sets.where((s) => s.isCompleted).length;

  double get totalVolumeKg => sets.fold(0.0, (sum, set) => sum + set.volumeKg);

  CompletedExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    List<String>? primaryMuscles,
    List<CompletedSet>? sets,
    bool? painReported,
    String? notes,
  }) => CompletedExercise(
    exerciseId: exerciseId ?? this.exerciseId,
    exerciseName: exerciseName ?? this.exerciseName,
    primaryMuscles: primaryMuscles ?? this.primaryMuscles,
    sets: sets ?? this.sets,
    painReported: painReported ?? this.painReported,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'primaryMuscles': primaryMuscles,
    'sets': sets.map((s) => s.toJson()).toList(),
    'painReported': painReported,
    'notes': notes,
  };

  factory CompletedExercise.fromJson(Map<String, dynamic> json) =>
      CompletedExercise(
        exerciseId: json['exerciseId'] as String,
        exerciseName: json['exerciseName'] as String,
        primaryMuscles:
            (json['primaryMuscles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        sets:
            (json['sets'] as List<dynamic>?)
                ?.map((s) => CompletedSet.fromJson(s as Map<String, dynamic>))
                .toList() ??
            const [],
        painReported: json['painReported'] as bool? ?? false,
        notes: json['notes'] as String? ?? '',
      );
}

@immutable
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.startedAt,
    required this.completedAt,
    required this.durationSeconds,
    required this.exercises,
    required this.totalVolumeKg,
    required this.estimatedCalories,
    required this.musclesTrained,
    this.overallRpe = 7,
    this.painReported = false,
    this.notes = '',
  });

  final String id;
  final String routineId;
  final String routineName;
  final DateTime startedAt;
  final DateTime completedAt;
  final int durationSeconds;
  final List<CompletedExercise> exercises;
  final double totalVolumeKg;
  final int estimatedCalories;
  final List<String> musclesTrained;
  final int overallRpe;
  final bool painReported;
  final String notes;

  int get totalCompletedSets =>
      exercises.fold(0, (sum, ex) => sum + ex.completedSetsCount);

  Map<String, dynamic> toJson() => {
    'id': id,
    'routineId': routineId,
    'routineName': routineName,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'totalVolumeKg': totalVolumeKg,
    'estimatedCalories': estimatedCalories,
    'musclesTrained': musclesTrained,
    'overallRpe': overallRpe,
    'painReported': painReported,
    'notes': notes,
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'] as String,
    routineId: json['routineId'] as String? ?? 'custom',
    routineName: json['routineName'] as String? ?? 'Workout Session',
    startedAt: DateTime.parse(json['startedAt'] as String),
    completedAt: DateTime.parse(json['completedAt'] as String),
    durationSeconds: json['durationSeconds'] as int? ?? 0,
    exercises:
        (json['exercises'] as List<dynamic>?)
            ?.map((e) => CompletedExercise.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    totalVolumeKg: (json['totalVolumeKg'] as num?)?.toDouble() ?? 0.0,
    estimatedCalories: json['estimatedCalories'] as int? ?? 0,
    musclesTrained:
        (json['musclesTrained'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    overallRpe: json['overallRpe'] as int? ?? 7,
    painReported: json['painReported'] as bool? ?? false,
    notes: json['notes'] as String? ?? '',
  );

  /// Approximate energy expenditure using standard MET (Metabolic Equivalent of Task).
  /// General resistance training is estimated at ~5.0 - 6.0 METs.
  /// Calculation: kcal = MET * weightKg * (durationHours)
  /// Always marked as approximate estimate.
  static int calculateEstimatedCalories({
    required double weightKg,
    required int durationSeconds,
    double met = 5.5,
  }) {
    if (durationSeconds <= 0 || weightKg <= 0) return 0;
    final hours = durationSeconds / 3600.0;
    final kcal = met * weightKg * hours;
    return kcal.round();
  }
}
