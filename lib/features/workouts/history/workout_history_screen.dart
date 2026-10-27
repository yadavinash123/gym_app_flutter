import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/workout_repository.dart';
import 'workout_detail_screen.dart';

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(workoutSessionsProvider);
    final prs = ref.watch(personalRecordsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151B23),
        title: const Text(
          'WORKOUT HISTORY',
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: Color(0xFFB6FF3B),
          ),
        ),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load workout history.'),
              TextButton(
                onPressed: () => ref.invalidate(workoutSessionsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.history_toggle_off_outlined,
                      size: 64,
                      color: Color(0xFFA7B0BF),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Recorded Workouts Yet',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complete your first workout to start tracking your progressive overload, personal records, and volume.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFA7B0BF)),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB6FF3B),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => context.go('/workouts'),
                      child: const Text('Start A Workout'),
                    ),
                  ],
                ),
              ),
            );
          }

          final totalVolume = sessions.fold<double>(
            0.0,
            (sum, s) => sum + s.totalVolumeKg,
          );
          final totalMinutes =
              sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Overall Totals Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF151B23),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF1C2430)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryMetric(
                      label: 'SESSIONS',
                      value: '${sessions.length}',
                      color: const Color(0xFFB6FF3B),
                    ),
                    _SummaryMetric(
                      label: 'TOTAL VOL',
                      value: '${totalVolume.toStringAsFixed(0)} kg',
                      color: const Color(0xFF00D4FF),
                    ),
                    _SummaryMetric(
                      label: 'TRAINING TIME',
                      value: '${totalMinutes}m',
                      color: const Color(0xFF35D399),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personal Records Spotlight
              if (prs.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'PERSONAL RECORDS',
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
                      '${prs.length} Exercises',
                      style: const TextStyle(
                        color: Color(0xFFFFB547),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: prs.entries.map((entry) {
                      final pr = entry.value;
                      return Container(
                        width: 170,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151B23),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFB547).withAlpha(80),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              pr.exerciseId.replaceAll('-', ' ').toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFB547),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pr.maxWeightKg > 0
                                  ? '${pr.maxWeightKg} kg × ${pr.maxRepsAtMaxWeight}'
                                  : 'Vol: ${pr.maxSessionVolumeKg.toStringAsFixed(0)} kg',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Est. 1RM: ${pr.estimatedOneRepMaxKg.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFA7B0BF),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Session History List
              const Text(
                'PAST SESSIONS',
                style: TextStyle(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFFA7B0BF),
                ),
              ),
              const SizedBox(height: 12),
              ...sessions.map((session) {
                final dateStr =
                    '${session.completedAt.year}-${session.completedAt.month.toString().padLeft(2, '0')}-${session.completedAt.day.toString().padLeft(2, '0')}';
                final minutes = session.durationSeconds ~/ 60;
                return Card(
                  color: const Color(0xFF151B23),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFF1C2430)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WorkoutDetailScreen(session: session),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  session.routineName,
                                  maxLines: 1,
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
                                dateStr,
                                style: const TextStyle(
                                  color: Color(0xFFA7B0BF),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${minutes}m duration • ${session.totalCompletedSets} sets',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFA7B0BF),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${session.totalVolumeKg.toStringAsFixed(0)} kg',
                                style: const TextStyle(
                                  color: Color(0xFF00D4FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (session.musclesTrained.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              children: session.musclesTrained.take(4).map((m) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C2430),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    m,
                                    style: const TextStyle(
                                      color: Color(0xFFA7B0BF),
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA7B0BF),
            ),
          ),
        ],
      ),
    );
  }
}
