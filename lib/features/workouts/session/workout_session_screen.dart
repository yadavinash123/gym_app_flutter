import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../exercises/exercise.dart';
import '../../profile/profile_repository.dart';
import '../data/workout_repository.dart';
import '../models/planned_workout.dart';
import '../models/progressive_overload.dart';
import 'rest_timer_widget.dart';
import 'workout_session_controller.dart';
import 'workout_summary_screen.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  const WorkoutSessionScreen({super.key, required this.routine});
  final PlannedRoutine routine;

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  late double _currentWeightKg;
  late int _currentReps;
  int _currentRpe = 7;
  bool _painReported = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final firstSet =
        widget.routine.exercises.isNotEmpty &&
            widget.routine.exercises[0].sets.isNotEmpty
        ? widget.routine.exercises[0].sets[0]
        : const PlannedSet(setNumber: 1, targetReps: 10);
    _currentWeightKg = firstSet.targetWeightKg;
    _currentReps = firstSet.targetReps;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(activeWorkoutSessionProvider.notifier)
          .startSession(widget.routine);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _syncWithCurrentPlanned(PlannedSet set) {
    setState(() {
      _currentWeightKg = set.targetWeightKg;
      _currentReps = set.targetReps;
      _currentRpe = 7;
      _painReported = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(activeWorkoutSessionProvider);
    final controller = ref.read(activeWorkoutSessionProvider.notifier);
    final profile = ref.watch(profileProvider).value;
    final pastSessions = ref.watch(workoutSessionsProvider).value ?? [];

    if (sessionState == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0F14),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final minutes = sessionState.elapsedSeconds ~/ 60;
    final seconds = sessionState.elapsedSeconds % 60;
    final timerString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final currentEx = sessionState.currentPlannedExercise;
    final currentSet = sessionState.currentPlannedSet;

    // Progression recommendation for current exercise
    final isLowerBody = currentEx.primaryMuscles.any(
      (m) =>
          m == 'Quadriceps' ||
          m == 'Glutes' ||
          m == 'Hamstrings' ||
          m == 'Calves',
    );
    final isBodyweight = _currentWeightKg <= 0.0;
    final progression = ProgressiveOverloadCalculator.evaluateProgression(
      exerciseId: currentEx.exerciseId,
      pastSessions: pastSessions,
      isBodyweight: isBodyweight,
      isLowerBody: isLowerBody,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmExit(
          context,
          sessionState,
          controller,
          profile?.weightKg ?? 70.0,
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F14),
        appBar: AppBar(
          backgroundColor: const Color(0xFF151B23),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.routine.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB6FF3B),
                ),
              ),
              Text(
                timerString,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: sessionState.isPaused
                      ? const Color(0xFFFFB547)
                      : Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: sessionState.isPaused ? 'Resume timer' : 'Pause timer',
              icon: Icon(
                sessionState.isPaused ? Icons.play_arrow : Icons.pause,
                color: sessionState.isPaused
                    ? const Color(0xFFFFB547)
                    : Colors.white,
              ),
              onPressed: controller.togglePause,
            ),
            TextButton(
              onPressed: () => _finishWorkout(
                context,
                sessionState,
                controller,
                profile?.weightKg ?? 70.0,
              ),
              child: const Text(
                'Finish',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB6FF3B),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'EXERCISE ${sessionState.currentExerciseIndex + 1} OF ${widget.routine.exercises.length}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFA7B0BF),
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total Volume: ${sessionState.totalVolumeKg.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          color: Color(0xFF00D4FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:
                          (sessionState.currentExerciseIndex + 1) /
                          widget.routine.exercises.length,
                      backgroundColor: const Color(0xFF1C2430),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFB6FF3B),
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Current Exercise Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151B23),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF1C2430)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentEx.exerciseName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: currentEx.primaryMuscles.map((m) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1C2430),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          m,
                                          style: const TextStyle(
                                            color: Color(0xFF00D4FF),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Technique guide & animation',
                              icon: const Icon(
                                Icons.help_outline,
                                color: Color(0xFFB6FF3B),
                              ),
                              onPressed: () => context.push(
                                '/exercises/${currentEx.exerciseId}',
                              ),
                            ),
                          ],
                        ),
                        if (currentEx.notes.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            currentEx.notes,
                            style: const TextStyle(
                              color: Color(0xFFA7B0BF),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () => _showReplaceExerciseDialog(
                                context,
                                controller,
                              ),
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              label: const Text('Swap Exercise'),
                            ),
                            if (!sessionState.isLastExercise)
                              TextButton.icon(
                                onPressed: controller.skipExercise,
                                icon: const Icon(Icons.skip_next, size: 18),
                                label: const Text('Skip Exercise'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progressive Overload suggestion card
                  if (progression.decision !=
                          ProgressionDecision.maintainLoad ||
                      progression.message.contains('Smooth completion'))
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            progression.decision ==
                                ProgressionDecision.painWarning
                            ? const Color(0xFF381519)
                            : const Color(0xFF142C30),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              progression.decision ==
                                  ProgressionDecision.painWarning
                              ? const Color(0xFFFF5D73)
                              : const Color(0xFF00D4FF),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            progression.decision ==
                                    ProgressionDecision.painWarning
                                ? Icons.warning_amber_rounded
                                : Icons.trending_up,
                            color:
                                progression.decision ==
                                    ProgressionDecision.painWarning
                                ? const Color(0xFFFF5D73)
                                : const Color(0xFF00D4FF),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  progression.decision ==
                                          ProgressionDecision.painWarning
                                      ? 'SAFETY GUIDANCE'
                                      : 'PROGRESSION SUGGESTION',
                                  style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        progression.decision ==
                                            ProgressionDecision.painWarning
                                        ? const Color(0xFFFF5D73)
                                        : const Color(0xFF00D4FF),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  progression.message,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Set Logger Card
                  Material(
                    color: const Color(0xFF151B23),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: const Color(0xFFB6FF3B).withAlpha(80),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                'SET ${sessionState.currentSetIndex + 1} OF ${currentEx.sets.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: Color(0xFFB6FF3B),
                                ),
                              ),
                              Text(
                                'Target: ${currentSet.targetReps} reps • ${currentSet.targetRestSeconds}s rest',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFA7B0BF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Weight and Reps selectors
                          Row(
                            children: [
                              // Weight Selector
                              Expanded(
                                child: _MetricCounter(
                                  label:
                                      'Weight (${profile?.units == 'Imperial' ? 'lbs' : 'kg'})',
                                  value: _currentWeightKg.toStringAsFixed(1),
                                  onDecrement: () {
                                    setState(() {
                                      _currentWeightKg =
                                          (_currentWeightKg - 2.5).clamp(
                                            0.0,
                                            500.0,
                                          );
                                    });
                                  },
                                  onIncrement: () {
                                    setState(() {
                                      _currentWeightKg =
                                          (_currentWeightKg + 2.5).clamp(
                                            0.0,
                                            500.0,
                                          );
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Reps Selector
                              Expanded(
                                child: _MetricCounter(
                                  label: 'Reps',
                                  value: '$_currentReps',
                                  onDecrement: () {
                                    setState(() {
                                      _currentReps = (_currentReps - 1).clamp(
                                        1,
                                        100,
                                      );
                                    });
                                  },
                                  onIncrement: () {
                                    setState(() {
                                      _currentReps = (_currentReps + 1).clamp(
                                        1,
                                        100,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // RPE Slider
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Perceived Effort (RPE)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFA7B0BF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_currentRpe / 10',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _currentRpe.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            activeColor: _currentRpe >= 9
                                ? const Color(0xFFFF5D73)
                                : const Color(0xFFB6FF3B),
                            onChanged: (val) {
                              setState(() {
                                _currentRpe = val.round();
                              });
                            },
                          ),
                          const SizedBox(height: 8),

                          // Discomfort / Pain Checkbox
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _painReported = !_painReported;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Checkbox(
                                    value: _painReported,
                                    activeColor: const Color(0xFFFF5D73),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (val) {
                                      setState(() {
                                        _painReported = val ?? false;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Report discomfort or joint pain',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Logs pain for progression safety checks',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFFA7B0BF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Big Log Set Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                controller.logCurrentSet(
                                  actualReps: _currentReps,
                                  weightKg: _currentWeightKg,
                                  rpe: _currentRpe,
                                  painReported: _painReported,
                                );
                                // Sync next set default
                                final nextSetIndex =
                                    sessionState.currentSetIndex + 1;
                                if (nextSetIndex < currentEx.sets.length) {
                                  _syncWithCurrentPlanned(
                                    currentEx.sets[nextSetIndex],
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'LOG SET & START REST',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Completed Sets for this exercise
                  Text(
                    'Logged Sets for ${currentEx.exerciseName}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Color(0xFFA7B0BF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final loggedEx = sessionState
                          .loggedExercises[sessionState.currentExerciseIndex];
                      if (loggedEx.sets.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No sets completed yet for this exercise.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: loggedEx.sets.map((set) {
                          return Card(
                            color: const Color(0xFF151B23),
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFB6FF3B),
                                child: Text(
                                  '${set.setNumber}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                '${set.weightKg > 0 ? '${set.weightKg} kg × ' : ''}${set.actualReps} reps',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'RPE ${set.rpe}${set.painReported ? ' • Discomfort reported' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: set.painReported
                                      ? const Color(0xFFFF5D73)
                                      : const Color(0xFFA7B0BF),
                                ),
                              ),
                              trailing: Text(
                                '${set.volumeKg.toStringAsFixed(0)} kg',
                                style: const TextStyle(
                                  color: Color(0xFF00D4FF),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Rest Timer Overlay when Resting
            if (sessionState.isResting)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha(200),
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: RestTimerWidget(
                    initialSeconds: sessionState.restSecondsRemaining,
                    nextExerciseName:
                        sessionState.currentPlannedExercise.exerciseName,
                    nextSetNumber: sessionState.currentSetIndex + 1,
                    onComplete: controller.dismissRest,
                    onSkip: controller.dismissRest,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showReplaceExerciseDialog(
    BuildContext context,
    WorkoutSessionController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151B23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            final catalogAsync = ref.watch(exerciseCatalogProvider);
            return catalogAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text('Could not load catalog')),
              data: (exercises) {
                return ListView.builder(
                  controller: scrollController,
                  itemCount: exercises.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Choose Replacement Exercise',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    final ex = exercises[index - 1];
                    return ListTile(
                      title: Text(ex.name),
                      subtitle: Text(
                        '${ex.group} • ${ex.equipment.join(', ')}',
                      ),
                      onTap: () {
                        controller.replaceCurrentExercise(ex);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _confirmExit(
    BuildContext context,
    WorkoutSessionState state,
    WorkoutSessionController controller,
    double userWeightKg,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151B23),
        title: const Text('Leave Workout Session?'),
        content: const Text(
          'Would you like to finish and save your completed sets, or discard this session?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: const Text(
              'Discard',
              style: TextStyle(color: Color(0xFFFF5D73)),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _finishWorkout(context, state, controller, userWeightKg);
            },
            child: const Text('Save & Finish'),
          ),
        ],
      ),
    );
  }

  void _finishWorkout(
    BuildContext context,
    WorkoutSessionState state,
    WorkoutSessionController controller,
    double userWeightKg,
  ) {
    final session = controller.buildSessionSummary(
      userWeightKg: userWeightKg,
      overallRpe: _currentRpe,
    );
    if (session == null) return;
    controller.clearSession();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => WorkoutSummaryScreen(session: session)),
    );
  }
}

class _MetricCounter extends StatelessWidget {
  const _MetricCounter({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final String value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFA7B0BF),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2430),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 40),
                onPressed: onDecrement,
                icon: const Icon(Icons.remove, size: 18),
                color: Colors.white,
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 40),
                onPressed: onIncrement,
                icon: const Icon(Icons.add, size: 18),
                color: const Color(0xFFB6FF3B),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
