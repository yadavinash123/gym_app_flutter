import 'package:flutter/foundation.dart';

@immutable
class PlannedSet {
  const PlannedSet({
    required this.setNumber,
    required this.targetReps,
    this.targetWeightKg = 0.0,
    this.targetRestSeconds = 60,
  });

  final int setNumber;
  final int targetReps;
  final double targetWeightKg;
  final int targetRestSeconds;

  PlannedSet copyWith({
    int? setNumber,
    int? targetReps,
    double? targetWeightKg,
    int? targetRestSeconds,
  }) => PlannedSet(
    setNumber: setNumber ?? this.setNumber,
    targetReps: targetReps ?? this.targetReps,
    targetWeightKg: targetWeightKg ?? this.targetWeightKg,
    targetRestSeconds: targetRestSeconds ?? this.targetRestSeconds,
  );

  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'targetReps': targetReps,
    'targetWeightKg': targetWeightKg,
    'targetRestSeconds': targetRestSeconds,
  };

  factory PlannedSet.fromJson(Map<String, dynamic> json) => PlannedSet(
    setNumber: json['setNumber'] as int? ?? 1,
    targetReps: json['targetReps'] as int? ?? 10,
    targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 0.0,
    targetRestSeconds: json['targetRestSeconds'] as int? ?? 60,
  );
}

@immutable
class PlannedExercise {
  const PlannedExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.primaryMuscles,
    required this.sets,
    this.notes = '',
  });

  final String exerciseId;
  final String exerciseName;
  final List<String> primaryMuscles;
  final List<PlannedSet> sets;
  final String notes;

  PlannedExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    List<String>? primaryMuscles,
    List<PlannedSet>? sets,
    String? notes,
  }) => PlannedExercise(
    exerciseId: exerciseId ?? this.exerciseId,
    exerciseName: exerciseName ?? this.exerciseName,
    primaryMuscles: primaryMuscles ?? this.primaryMuscles,
    sets: sets ?? this.sets,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'primaryMuscles': primaryMuscles,
    'sets': sets.map((s) => s.toJson()).toList(),
    'notes': notes,
  };

  factory PlannedExercise.fromJson(Map<String, dynamic> json) =>
      PlannedExercise(
        exerciseId: json['exerciseId'] as String,
        exerciseName: json['exerciseName'] as String,
        primaryMuscles:
            (json['primaryMuscles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        sets:
            (json['sets'] as List<dynamic>?)
                ?.map((s) => PlannedSet.fromJson(s as Map<String, dynamic>))
                .toList() ??
            const [],
        notes: json['notes'] as String? ?? '',
      );
}

@immutable
class PlannedRoutine {
  const PlannedRoutine({
    required this.id,
    required this.name,
    required this.category,
    required this.exercises,
    this.targetDurationMinutes = 30,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String category;
  final List<PlannedExercise> exercises;
  final int targetDurationMinutes;
  final bool isCustom;

  int get totalSets =>
      exercises.fold(0, (sum, exercise) => sum + exercise.sets.length);

  Set<String> get allTargetMuscles {
    final result = <String>{};
    for (final ex in exercises) {
      result.addAll(ex.primaryMuscles);
    }
    return result;
  }

  PlannedRoutine copyWith({
    String? id,
    String? name,
    String? category,
    List<PlannedExercise>? exercises,
    int? targetDurationMinutes,
    bool? isCustom,
  }) => PlannedRoutine(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    exercises: exercises ?? this.exercises,
    targetDurationMinutes: targetDurationMinutes ?? this.targetDurationMinutes,
    isCustom: isCustom ?? this.isCustom,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'targetDurationMinutes': targetDurationMinutes,
    'isCustom': isCustom,
  };

  factory PlannedRoutine.fromJson(Map<String, dynamic> json) => PlannedRoutine(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    exercises:
        (json['exercises'] as List<dynamic>?)
            ?.map((e) => PlannedExercise.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    targetDurationMinutes: json['targetDurationMinutes'] as int? ?? 30,
    isCustom: json['isCustom'] as bool? ?? false,
  );
}
