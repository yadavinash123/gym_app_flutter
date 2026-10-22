import '../../exercises/exercise.dart';
import '../../profile/profile.dart';
import '../models/planned_workout.dart';

class WorkoutGenerator {
  /// Generates a concrete planned routine for a given session kind, matching profile constraints.
  static PlannedRoutine generateRoutineForDay({
    required Profile profile,
    required String sessionKind,
    required List<Exercise> catalog,
    int? dayIndex,
  }) {
    if (sessionKind == 'Recovery') {
      return PlannedRoutine(
        id: 'routine-recovery-${dayIndex ?? 0}',
        name: 'Active Recovery & Rest',
        category: 'Recovery',
        targetDurationMinutes: 15,
        exercises: _selectMobilityExercises(profile, catalog, limit: 2),
      );
    }

    final available = _filterExercisesForProfile(profile, catalog);
    final targetSets = _calculateTargetSets(profile.minutes);
    final (reps, restSeconds) = _repsAndRestForGoal(profile.goal);

    List<Exercise> chosen = [];

    switch (sessionKind) {
      case 'Upper-body strength':
        chosen = _selectUpperBody(available);
        break;
      case 'Lower-body strength':
        chosen = _selectLowerBody(available);
        break;
      case 'Easy cardio':
        chosen = _selectCardio(available);
        break;
      case 'Mobility':
        chosen = _selectMobility(available);
        break;
      case 'Full-body strength':
      default:
        chosen = _selectFullBody(available);
        break;
    }

    // Limit exercise count based on session minutes
    final maxExercises = (profile.minutes ~/ 8).clamp(3, 7);
    if (chosen.length > maxExercises) {
      chosen = chosen.take(maxExercises).toList();
    }

    final plannedExercises = chosen.map((ex) {
      final sets = List.generate(
        targetSets,
        (i) => PlannedSet(
          setNumber: i + 1,
          targetReps: reps,
          targetWeightKg: 0.0,
          targetRestSeconds: restSeconds,
        ),
      );
      return PlannedExercise(
        exerciseId: ex.id,
        exerciseName: ex.name,
        primaryMuscles: ex.primary,
        sets: sets,
        notes: ex.cue,
      );
    }).toList();

    return PlannedRoutine(
      id: 'routine-${sessionKind.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}-${dayIndex ?? 0}',
      name: sessionKind,
      category: sessionKind,
      targetDurationMinutes: profile.minutes,
      exercises: plannedExercises,
    );
  }

  static List<Exercise> _filterExercisesForProfile(
    Profile profile,
    List<Exercise> catalog,
  ) {
    final userEquipment = profile.equipment.toSet();
    final hasDumbbells = userEquipment.contains('Dumbbells');
    final hasBarbell = userEquipment.contains('Barbell');

    return catalog.where((ex) {
      // Equipment check
      final needsDumbbell = ex.equipment.contains('Dumbbells');
      final needsBarbell = ex.equipment.contains('Barbell');
      final isBodyweight = ex.equipment.contains('Bodyweight');

      if (!isBodyweight) {
        if (needsDumbbell && !hasDumbbells) return false;
        if (needsBarbell && !hasBarbell) return false;
      }

      // Limitations check
      if (profile.hasLimitations) {
        // Strict safety rule: If user has reported limitations, only gentle mobility is chosen.
        if (ex.movement != 'Mobility' &&
            ex.movement != 'Core stability' &&
            ex.movement != 'Low-impact aerobic') {
          return false;
        }
      }

      // Avoided exercises
      if (profile.avoidedExercises.isNotEmpty) {
        final avoided = profile.avoidedExercises.toLowerCase();
        if (avoided.contains(ex.name.toLowerCase()) ||
            avoided.contains(ex.id.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  static List<Exercise> _selectFullBody(List<Exercise> pool) {
    final selected = <Exercise>[];
    _addFirstMatching(selected, pool, ['Chest', 'Shoulders']);
    _addFirstMatching(selected, pool, ['Quadriceps', 'Glutes']);
    _addFirstMatching(selected, pool, ['Back', 'Biceps']);
    _addFirstMatching(selected, pool, ['Abdominals', 'Core stability']);
    _addFirstMatching(selected, pool, ['Triceps', 'Shoulders']);

    // Fallback if pool was small
    if (selected.length < 3) {
      for (final ex in pool) {
        if (!selected.contains(ex)) selected.add(ex);
        if (selected.length >= 4) break;
      }
    }
    return selected;
  }

  static List<Exercise> _selectUpperBody(List<Exercise> pool) {
    final selected = <Exercise>[];
    _addFirstMatching(selected, pool, ['Chest']);
    _addFirstMatching(selected, pool, ['Back']);
    _addFirstMatching(selected, pool, ['Shoulders']);
    _addFirstMatching(selected, pool, ['Biceps']);
    _addFirstMatching(selected, pool, ['Triceps']);
    if (selected.length < 3) {
      for (final ex in pool) {
        if (!selected.contains(ex)) selected.add(ex);
        if (selected.length >= 4) break;
      }
    }
    return selected;
  }

  static List<Exercise> _selectLowerBody(List<Exercise> pool) {
    final selected = <Exercise>[];
    _addFirstMatching(selected, pool, ['Quadriceps']);
    _addFirstMatching(selected, pool, ['Glutes']);
    _addFirstMatching(selected, pool, ['Hamstrings']);
    _addFirstMatching(selected, pool, ['Calves']);
    _addFirstMatching(selected, pool, ['Abdominals']);
    if (selected.length < 3) {
      for (final ex in pool) {
        if (!selected.contains(ex)) selected.add(ex);
        if (selected.length >= 4) break;
      }
    }
    return selected;
  }

  static List<Exercise> _selectCardio(List<Exercise> pool) {
    final cardio = pool.where((e) =>
        e.movement == 'Low-impact aerobic' ||
        e.movement == 'Step' ||
        e.id == 'walking' ||
        e.id == 'step-up' ||
        e.id == 'calf-raise').toList();
    if (cardio.isNotEmpty) return cardio;
    return pool.take(3).toList();
  }

  static List<Exercise> _selectMobility(List<Exercise> pool) {
    final mobility = pool.where((e) =>
        e.movement == 'Mobility' ||
        e.movement == 'Core stability' ||
        e.primary.contains('Abdominals')).toList();
    if (mobility.isNotEmpty) return mobility;
    return pool.take(3).toList();
  }

  static List<PlannedExercise> _selectMobilityExercises(
    Profile profile,
    List<Exercise> catalog, {
    int limit = 2,
  }) {
    final matches = catalog.where((e) =>
        e.movement == 'Mobility' ||
        e.id == 'chest-stretch' ||
        e.id == 'ankle-mobility' ||
        e.id == 'seated-rotation').take(limit);

    return matches.map((ex) => PlannedExercise(
          exerciseId: ex.id,
          exerciseName: ex.name,
          primaryMuscles: ex.primary,
          sets: [
            const PlannedSet(
              setNumber: 1,
              targetReps: 10,
              targetRestSeconds: 30,
            ),
            const PlannedSet(
              setNumber: 2,
              targetReps: 10,
              targetRestSeconds: 30,
            ),
          ],
          notes: ex.cue,
        )).toList();
  }

  static void _addFirstMatching(
    List<Exercise> selected,
    List<Exercise> pool,
    List<String> targetGroups,
  ) {
    for (final ex in pool) {
      if (selected.contains(ex)) continue;
      if (targetGroups.any((g) => ex.primary.contains(g) || ex.group == g)) {
        selected.add(ex);
        return;
      }
    }
  }

  static int _calculateTargetSets(int minutes) {
    if (minutes <= 20) return 2;
    if (minutes >= 50) return 4;
    return 3;
  }

  static (int reps, int rest) _repsAndRestForGoal(String goal) {
    switch (goal) {
      case 'Build strength':
        return (5, 90);
      case 'Build muscle':
      case 'Body recomposition':
        return (10, 60);
      case 'Fat loss':
      case 'Improve endurance':
        return (14, 45);
      case 'Improve mobility':
        return (10, 30);
      case 'Improve fitness':
      case 'Weight maintenance':
      default:
        return (10, 60);
    }
  }
}
