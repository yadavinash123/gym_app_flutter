import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../exercises/exercise.dart';
import '../data/workout_repository.dart';
import '../models/planned_workout.dart';
import '../session/workout_session_screen.dart';

class CustomWorkoutScreen extends ConsumerStatefulWidget {
  const CustomWorkoutScreen({super.key, this.initialRoutine});
  final PlannedRoutine? initialRoutine;

  @override
  ConsumerState<CustomWorkoutScreen> createState() =>
      _CustomWorkoutScreenState();
}

class _CustomWorkoutScreenState extends ConsumerState<CustomWorkoutScreen> {
  late TextEditingController _nameController;
  String _category = 'Full-body strength';
  int _targetMinutes = 30;
  List<PlannedExercise> _exercises = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRoutine;
    _nameController = TextEditingController(
      text: initial?.name ?? 'Custom Workout Routine',
    );
    _category = initial?.category ?? 'Full-body strength';
    _targetMinutes = initial?.targetDurationMinutes ?? 30;
    _exercises = initial != null
        ? List<PlannedExercise>.from(initial.exercises)
        : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  PlannedRoutine _buildRoutine() {
    final id =
        widget.initialRoutine?.id ??
        'custom-${DateTime.now().millisecondsSinceEpoch}';
    return PlannedRoutine(
      id: id,
      name: _nameController.text.trim().isEmpty
          ? 'Custom Routine'
          : _nameController.text.trim(),
      category: _category,
      targetDurationMinutes: _targetMinutes,
      exercises: _exercises,
      isCustom: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151B23),
        title: Text(
          widget.initialRoutine == null ? 'CREATE ROUTINE' : 'EDIT ROUTINE',
          style: const TextStyle(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFFB6FF3B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving || _exercises.isEmpty ? null : _saveRoutine,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFFB6FF3B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // Routine Name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Routine Name',
              hintText: 'e.g. Upper Body Blast',
              filled: true,
              fillColor: Color(0xFF151B23),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Category Dropdown
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Focus / Category',
              filled: true,
              fillColor: Color(0xFF151B23),
              border: OutlineInputBorder(),
            ),
            dropdownColor: const Color(0xFF151B23),
            items: const [
              DropdownMenuItem(
                value: 'Full-body strength',
                child: Text('Full-body strength'),
              ),
              DropdownMenuItem(
                value: 'Upper-body strength',
                child: Text('Upper-body strength'),
              ),
              DropdownMenuItem(
                value: 'Lower-body strength',
                child: Text('Lower-body strength'),
              ),
              DropdownMenuItem(value: 'Mobility', child: Text('Mobility')),
              DropdownMenuItem(
                value: 'Easy cardio',
                child: Text('Easy cardio'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _category = val);
            },
          ),
          const SizedBox(height: 16),

          // Duration Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Target Duration:',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xFFA7B0BF), fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$_targetMinutes minutes',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Slider(
            value: _targetMinutes.toDouble(),
            min: 10,
            max: 90,
            divisions: 16,
            activeColor: const Color(0xFFB6FF3B),
            onChanged: (val) {
              setState(() => _targetMinutes = val.round());
            },
          ),
          const SizedBox(height: 20),

          // Exercises Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'EXERCISES IN ROUTINE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFFA7B0BF),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_exercises.length} Exercises',
                style: const TextStyle(
                  color: Color(0xFF00D4FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_exercises.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF151B23),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1C2430)),
              ),
              child: const Center(
                child: Text(
                  'No exercises added yet. Tap below to select exercises from the library.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFA7B0BF)),
                ),
              ),
            ),

          ..._exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final ex = entry.value;
            final setsCount = ex.sets.length;
            final reps = ex.sets.isNotEmpty ? ex.sets.first.targetReps : 10;
            final rest = ex.sets.isNotEmpty
                ? ex.sets.first.targetRestSeconds
                : 60;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151B23),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1C2430)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          ex.exerciseName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFFF5D73),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _exercises.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Sets Counter
                      _CounterControl(
                        label: 'Sets',
                        value: '$setsCount',
                        onDecrement: () {
                          if (setsCount > 1) {
                            setState(() {
                              final newSets = List<PlannedSet>.from(ex.sets)
                                ..removeLast();
                              _exercises[index] = ex.copyWith(sets: newSets);
                            });
                          }
                        },
                        onIncrement: () {
                          setState(() {
                            final newSets = List<PlannedSet>.from(ex.sets)
                              ..add(
                                PlannedSet(
                                  setNumber: setsCount + 1,
                                  targetReps: reps,
                                  targetRestSeconds: rest,
                                ),
                              );
                            _exercises[index] = ex.copyWith(sets: newSets);
                          });
                        },
                      ),
                      // Reps Counter
                      _CounterControl(
                        label: 'Target Reps',
                        value: '$reps',
                        onDecrement: () {
                          if (reps > 1) {
                            setState(() {
                              final newSets = ex.sets
                                  .map((s) => s.copyWith(targetReps: reps - 1))
                                  .toList();
                              _exercises[index] = ex.copyWith(sets: newSets);
                            });
                          }
                        },
                        onIncrement: () {
                          setState(() {
                            final newSets = ex.sets
                                .map((s) => s.copyWith(targetReps: reps + 1))
                                .toList();
                            _exercises[index] = ex.copyWith(sets: newSets);
                          });
                        },
                      ),
                      // Rest Duration
                      _CounterControl(
                        label: 'Rest',
                        value: '${rest}s',
                        onDecrement: () {
                          if (rest > 15) {
                            setState(() {
                              final newSets = ex.sets
                                  .map(
                                    (s) => s.copyWith(
                                      targetRestSeconds: rest - 15,
                                    ),
                                  )
                                  .toList();
                              _exercises[index] = ex.copyWith(sets: newSets);
                            });
                          }
                        },
                        onIncrement: () {
                          setState(() {
                            final newSets = ex.sets
                                .map(
                                  (s) =>
                                      s.copyWith(targetRestSeconds: rest + 15),
                                )
                                .toList();
                            _exercises[index] = ex.copyWith(sets: newSets);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFB6FF3B)),
            ),
            onPressed: () => _showAddExerciseSheet(context),
            icon: const Icon(Icons.add, color: Color(0xFFB6FF3B)),
            label: const Text(
              'Add Exercise to Routine',
              style: TextStyle(
                color: Color(0xFFB6FF3B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Start Now Button
          if (_exercises.isNotEmpty)
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB6FF3B),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  final routine = _buildRoutine();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorkoutSessionScreen(routine: routine),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'START THIS ROUTINE NOW',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showAddExerciseSheet(BuildContext context) {
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
                  const Center(child: Text('Could not load exercise catalog')),
              data: (exercises) {
                return ListView.builder(
                  controller: scrollController,
                  itemCount: exercises.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Add Exercise to Routine',
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
                      trailing: const Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFFB6FF3B),
                      ),
                      onTap: () {
                        setState(() {
                          _exercises.add(
                            PlannedExercise(
                              exerciseId: ex.id,
                              exerciseName: ex.name,
                              primaryMuscles: ex.primary,
                              sets: const [
                                PlannedSet(
                                  setNumber: 1,
                                  targetReps: 10,
                                  targetRestSeconds: 60,
                                ),
                                PlannedSet(
                                  setNumber: 2,
                                  targetReps: 10,
                                  targetRestSeconds: 60,
                                ),
                                PlannedSet(
                                  setNumber: 3,
                                  targetReps: 10,
                                  targetRestSeconds: 60,
                                ),
                              ],
                              notes: ex.cue,
                            ),
                          );
                        });
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

  Future<void> _saveRoutine() async {
    setState(() => _isSaving = true);
    final routine = _buildRoutine();
    try {
      await ref.read(workoutTemplatesProvider.notifier).saveTemplate(routine);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save routine: $e')));
      }
    }
  }
}

class _CounterControl extends StatelessWidget {
  const _CounterControl({
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
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFFA7B0BF)),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2430),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onDecrement,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.remove, size: 14, color: Colors.white70),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
              InkWell(
                onTap: onIncrement,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.add, size: 14, color: Color(0xFFB6FF3B)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
