import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/workout_repository.dart';
import '../models/progressive_overload.dart';
import '../models/workout_session.dart';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  const WorkoutSummaryScreen({super.key, required this.session});
  final WorkoutSession session;

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  late TextEditingController _notesController;
  late int _overallRpe;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.session.notes);
    _overallRpe = widget.session.overallRpe;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final pastSessions = ref.watch(workoutSessionsProvider).value ?? [];

    // Find any new PRs achieved in this session compared to past
    final newPrs = <String>[];
    for (final ex in session.exercises) {
      final prevPr = ProgressiveOverloadCalculator.calculatePR(
        exerciseId: ex.exerciseId,
        sessions: pastSessions,
      );
      for (final s in ex.sets) {
        if (!s.isCompleted) continue;
        if (prevPr == null || s.weightKg > prevPr.maxWeightKg) {
          if (!newPrs.contains(ex.exerciseName)) {
            newPrs.add(ex.exerciseName);
          }
        }
      }
    }

    final durationMinutes = session.durationSeconds ~/ 60;
    final durationSeconds = session.durationSeconds % 60;
    final durationString = '${durationMinutes}m ${durationSeconds}s';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF151B23),
        title: const Text(
          'WORKOUT SUMMARY',
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: Color(0xFFB6FF3B),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Celebration Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF243B1D), Color(0xFF142C30)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFFB6FF3B).withAlpha(100),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    color: Color(0xFFB6FF3B),
                    size: 44,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Great Job!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You finished "${session.routineName}". Consistency builds strength.',
                    style: const TextStyle(
                      color: Color(0xFFA7B0BF),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'TOTAL TIME',
                    value: durationString,
                    icon: Icons.timer_outlined,
                    accentColor: const Color(0xFFB6FF3B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'TOTAL VOLUME',
                    value: '${session.totalVolumeKg.toStringAsFixed(0)} kg',
                    icon: Icons.fitness_center,
                    accentColor: const Color(0xFF00D4FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'SETS COMPLETED',
                    value: '${session.totalCompletedSets}',
                    icon: Icons.check_circle_outline,
                    accentColor: const Color(0xFF35D399),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'EST. ENERGY',
                    value: '~${session.estimatedCalories} kcal',
                    icon: Icons.local_fire_department_outlined,
                    accentColor: const Color(0xFFFFB547),
                    footnote: 'Approximate estimate',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // PRs Highlight
            if (newPrs.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF232514),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFB547)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.military_tech_outlined,
                      color: Color(0xFFFFB547),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NEW PERSONAL BEST!',
                            style: TextStyle(
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFFFFB547),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hit new record load on: ${newPrs.join(', ')}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Muscle Groups Trained
            const Text(
              'MUSCLES TARGETED',
              style: TextStyle(
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFFA7B0BF),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: session.musclesTrained.isEmpty
                  ? [
                      const Chip(
                        label: Text('General'),
                        backgroundColor: Color(0xFF151B23),
                      ),
                    ]
                  : session.musclesTrained.map((m) {
                      return Chip(
                        label: Text(m),
                        backgroundColor: const Color(0xFF151B23),
                        labelStyle: const TextStyle(
                          color: Color(0xFF00D4FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        side: const BorderSide(color: Color(0xFF1C2430)),
                      );
                    }).toList(),
            ),
            const SizedBox(height: 24),

            // Session Notes & RPE
            const Text(
              'SESSION NOTES & PERCEIVED EFFORT',
              style: TextStyle(
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFFA7B0BF),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151B23),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1C2430)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Overall Workout RPE:',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_overallRpe / 10',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: _overallRpe.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: const Color(0xFFB6FF3B),
                    onChanged: (val) {
                      setState(() {
                        _overallRpe = val.round();
                      });
                    },
                  ),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Add reflections or recovery notes...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_saveError != null) ...[
              Text(
                _saveError!,
                style: const TextStyle(color: Color(0xFFFF5D73)),
              ),
              const SizedBox(height: 12),
            ],

            // Save Workout Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB6FF3B),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isSaving ? null : () => _saveAndExit(context),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'SAVE SESSION & COMPLETE',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            fontSize: 15,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndExit(BuildContext context) async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final finalSession = WorkoutSession(
      id: widget.session.id,
      routineId: widget.session.routineId,
      routineName: widget.session.routineName,
      startedAt: widget.session.startedAt,
      completedAt: widget.session.completedAt,
      durationSeconds: widget.session.durationSeconds,
      exercises: widget.session.exercises,
      totalVolumeKg: widget.session.totalVolumeKg,
      estimatedCalories: widget.session.estimatedCalories,
      musclesTrained: widget.session.musclesTrained,
      overallRpe: _overallRpe,
      painReported: widget.session.painReported,
      notes: _notesController.text.trim(),
    );

    try {
      await ref.read(workoutSessionsProvider.notifier).addSession(finalSession);
      if (context.mounted) {
        context.go('/workouts');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError = 'Failed to save session. Please retry: $e';
        });
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.footnote,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA7B0BF),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: 4),
            Text(
              footnote!,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white38,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
