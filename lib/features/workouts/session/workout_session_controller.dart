import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../exercises/exercise.dart';
import '../models/planned_workout.dart';
import '../models/workout_session.dart';

@immutable
class WorkoutSessionState {
  const WorkoutSessionState({
    required this.routine,
    required this.startedAt,
    required this.currentExerciseIndex,
    required this.currentSetIndex,
    required this.elapsedSeconds,
    required this.isPaused,
    required this.isResting,
    required this.restSecondsRemaining,
    required this.loggedExercises,
    this.painReported = false,
    this.sessionNotes = '',
  });

  final PlannedRoutine routine;
  final DateTime startedAt;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final int elapsedSeconds;
  final bool isPaused;
  final bool isResting;
  final int restSecondsRemaining;
  final List<CompletedExercise> loggedExercises;
  final bool painReported;
  final String sessionNotes;

  PlannedExercise get currentPlannedExercise =>
      routine.exercises[currentExerciseIndex];

  PlannedSet get currentPlannedSet =>
      currentPlannedExercise.sets[currentSetIndex];

  bool get isLastExercise =>
      currentExerciseIndex >= routine.exercises.length - 1;

  bool get isLastSetOfExercise =>
      currentSetIndex >= currentPlannedExercise.sets.length - 1;

  double get totalVolumeKg {
    double total = 0.0;
    for (final ex in loggedExercises) {
      total += ex.totalVolumeKg;
    }
    return total;
  }

  int get totalCompletedSets {
    int total = 0;
    for (final ex in loggedExercises) {
      total += ex.completedSetsCount;
    }
    return total;
  }

  WorkoutSessionState copyWith({
    PlannedRoutine? routine,
    DateTime? startedAt,
    int? currentExerciseIndex,
    int? currentSetIndex,
    int? elapsedSeconds,
    bool? isPaused,
    bool? isResting,
    int? restSecondsRemaining,
    List<CompletedExercise>? loggedExercises,
    bool? painReported,
    String? sessionNotes,
  }) => WorkoutSessionState(
    routine: routine ?? this.routine,
    startedAt: startedAt ?? this.startedAt,
    currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
    currentSetIndex: currentSetIndex ?? this.currentSetIndex,
    elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    isPaused: isPaused ?? this.isPaused,
    isResting: isResting ?? this.isResting,
    restSecondsRemaining: restSecondsRemaining ?? this.restSecondsRemaining,
    loggedExercises: loggedExercises ?? this.loggedExercises,
    painReported: painReported ?? this.painReported,
    sessionNotes: sessionNotes ?? this.sessionNotes,
  );
}

class WorkoutSessionController extends Notifier<WorkoutSessionState?> {
  Timer? _ticker;

  @override
  WorkoutSessionState? build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return null;
  }

  void startSession(PlannedRoutine routine) {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state;
      if (current != null && !current.isPaused) {
        state = current.copyWith(elapsedSeconds: current.elapsedSeconds + 1);
      }
    });

    final initialLogs = routine.exercises.map((pEx) {
      return CompletedExercise(
        exerciseId: pEx.exerciseId,
        exerciseName: pEx.exerciseName,
        primaryMuscles: pEx.primaryMuscles,
        sets: [],
      );
    }).toList();

    state = WorkoutSessionState(
      routine: routine,
      startedAt: DateTime.now(),
      currentExerciseIndex: 0,
      currentSetIndex: 0,
      elapsedSeconds: 0,
      isPaused: false,
      isResting: false,
      restSecondsRemaining: 60,
      loggedExercises: initialLogs,
    );
  }

  void togglePause() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(isPaused: !current.isPaused);
  }

  void logCurrentSet({
    required int actualReps,
    required double weightKg,
    required int rpe,
    bool painReported = false,
    String notes = '',
  }) {
    final current = state;
    if (current == null) return;

    final currentExIndex = current.currentExerciseIndex;
    final currentSetIndex = current.currentSetIndex;
    final currentPlannedEx = current.currentPlannedExercise;
    final targetReps = current.currentPlannedSet.targetReps;
    final restDuration = current.currentPlannedSet.targetRestSeconds;

    final newSet = CompletedSet(
      setNumber: currentSetIndex + 1,
      targetReps: targetReps,
      actualReps: actualReps,
      weightKg: weightKg,
      rpe: rpe,
      isCompleted: true,
      painReported: painReported,
      notes: notes,
    );

    final updatedLogs = List<CompletedExercise>.from(current.loggedExercises);
    final currentLoggedEx = updatedLogs[currentExIndex];
    final updatedSets = List<CompletedSet>.from(currentLoggedEx.sets)
      ..add(newSet);

    updatedLogs[currentExIndex] = currentLoggedEx.copyWith(
      sets: updatedSets,
      painReported: currentLoggedEx.painReported || painReported,
    );

    final overallPain = current.painReported || painReported;

    int nextExIndex = currentExIndex;
    int nextSetIndex = currentSetIndex + 1;
    bool resting = true;

    if (nextSetIndex >= currentPlannedEx.sets.length) {
      if (currentExIndex < current.routine.exercises.length - 1) {
        nextExIndex = currentExIndex + 1;
        nextSetIndex = 0;
      } else {
        resting = false;
      }
    }

    state = current.copyWith(
      loggedExercises: updatedLogs,
      currentExerciseIndex: nextExIndex,
      currentSetIndex: nextSetIndex,
      isResting: resting,
      restSecondsRemaining: restDuration,
      painReported: overallPain,
    );
  }

  void dismissRest() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(isResting: false);
  }

  void skipExercise() {
    final current = state;
    if (current == null) return;
    if (current.currentExerciseIndex < current.routine.exercises.length - 1) {
      state = current.copyWith(
        currentExerciseIndex: current.currentExerciseIndex + 1,
        currentSetIndex: 0,
        isResting: false,
      );
    }
  }

  void replaceCurrentExercise(Exercise newExercise) {
    final current = state;
    if (current == null) return;

    final curIndex = current.currentExerciseIndex;
    final oldPlanned = current.routine.exercises[curIndex];

    final updatedPlannedEx = PlannedExercise(
      exerciseId: newExercise.id,
      exerciseName: newExercise.name,
      primaryMuscles: newExercise.primary,
      sets: oldPlanned.sets,
      notes: newExercise.cue,
    );

    final updatedExercises = List<PlannedExercise>.from(
      current.routine.exercises,
    );
    updatedExercises[curIndex] = updatedPlannedEx;

    final updatedRoutine = current.routine.copyWith(
      exercises: updatedExercises,
    );

    final updatedLogs = List<CompletedExercise>.from(current.loggedExercises);
    updatedLogs[curIndex] = CompletedExercise(
      exerciseId: newExercise.id,
      exerciseName: newExercise.name,
      primaryMuscles: newExercise.primary,
      sets: [],
    );

    state = current.copyWith(
      routine: updatedRoutine,
      loggedExercises: updatedLogs,
      currentSetIndex: 0,
    );
  }

  void setSessionNotes(String notes) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(sessionNotes: notes);
  }

  WorkoutSession? buildSessionSummary({
    required double userWeightKg,
    int overallRpe = 7,
  }) {
    final current = state;
    if (current == null) return null;

    final completedAt = DateTime.now();
    final durationSeconds = current.elapsedSeconds;
    final estimatedKcal = WorkoutSession.calculateEstimatedCalories(
      weightKg: userWeightKg,
      durationSeconds: durationSeconds,
    );

    final musclesTrained = <String>{};
    for (final ex in current.loggedExercises) {
      if (ex.completedSetsCount > 0) {
        musclesTrained.addAll(ex.primaryMuscles);
      }
    }

    return WorkoutSession(
      id: 'session-${completedAt.millisecondsSinceEpoch}',
      routineId: current.routine.id,
      routineName: current.routine.name,
      startedAt: current.startedAt,
      completedAt: completedAt,
      durationSeconds: durationSeconds,
      exercises: current.loggedExercises,
      totalVolumeKg: current.totalVolumeKg,
      estimatedCalories: estimatedKcal,
      musclesTrained: musclesTrained.toList(),
      overallRpe: overallRpe,
      painReported: current.painReported,
      notes: current.sessionNotes,
    );
  }

  void clearSession() {
    _ticker?.cancel();
    state = null;
  }
}

final activeWorkoutSessionProvider =
    NotifierProvider<WorkoutSessionController, WorkoutSessionState?>(
      WorkoutSessionController.new,
    );
