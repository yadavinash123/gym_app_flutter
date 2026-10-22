import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/workout_repository.dart';
import '../models/workout_session.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key, required this.session});
  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = session.durationSeconds ~/ 60;
    final seconds = session.durationSeconds % 60;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151B23),
        title: Text(
          session.routineName.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFFB6FF3B),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFFF5D73)),
            tooltip: 'Delete session',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF151B23),
                  title: const Text('Delete Workout Session?'),
                  content: const Text(
                    'This action will permanently remove this record from your local history.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5D73),
                      ),
                      onPressed: () {
                        ref
                            .read(workoutSessionsProvider.notifier)
                            .removeSession(session.id);
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // Header Stats
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${session.completedAt.year}-${session.completedAt.month.toString().padLeft(2, '0')}-${session.completedAt.day.toString().padLeft(2, '0')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFA7B0BF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'RPE ${session.overallRpe} / 10',
                      style: const TextStyle(
                        color: Color(0xFFB6FF3B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DetailStat(label: 'TIME', value: '${minutes}m ${seconds}s'),
                    _DetailStat(
                      label: 'VOLUME',
                      value: '${session.totalVolumeKg.toStringAsFixed(0)} kg',
                    ),
                    _DetailStat(
                      label: 'SETS',
                      value: '${session.totalCompletedSets}',
                    ),
                    _DetailStat(
                      label: 'ENERGY',
                      value: '~${session.estimatedCalories} kcal',
                    ),
                  ],
                ),
                if (session.painReported) ...[
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFF5D73),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Discomfort or pain reported during this session',
                        style: TextStyle(
                          color: Color(0xFFFF5D73),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                if (session.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Notes: "${session.notes}"',
                    style: const TextStyle(
                      color: Color(0xFFA7B0BF),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Exercise Log Details
          const Text(
            'EXERCISES PERFORMED',
            style: TextStyle(
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFFA7B0BF),
            ),
          ),
          const SizedBox(height: 12),
          ...session.exercises.map((ex) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${ex.totalVolumeKg.toStringAsFixed(0)} kg',
                        style: const TextStyle(
                          color: Color(0xFF00D4FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(1.5),
                    },
                    children: [
                      const TableRow(
                        children: [
                          Text('SET', style: TextStyle(color: Color(0xFFA7B0BF), fontSize: 11)),
                          Text('WEIGHT', style: TextStyle(color: Color(0xFFA7B0BF), fontSize: 11)),
                          Text('REPS', style: TextStyle(color: Color(0xFFA7B0BF), fontSize: 11)),
                          Text('RPE', style: TextStyle(color: Color(0xFFA7B0BF), fontSize: 11)),
                        ],
                      ),
                      ...ex.sets.map((set) {
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text('${set.setNumber}', style: const TextStyle(color: Colors.white)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                set.weightKg > 0 ? '${set.weightKg} kg' : 'Bodyweight',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text('${set.actualReps}', style: const TextStyle(color: Colors.white)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '${set.rpe}${set.painReported ? ' ⚠️' : ''}',
                                style: TextStyle(
                                  color: set.painReported
                                      ? const Color(0xFFFF5D73)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              color: Color(0xFFA7B0BF),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
