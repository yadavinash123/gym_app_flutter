import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/coach_conversation.dart';
import 'muscle_silhouette_badge.dart';

class WorkoutPlanCard extends StatelessWidget {
  const WorkoutPlanCard({super.key, required this.data});

  final WorkoutPlanCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF131A22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Provide option to start workout or view routine
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF151B23),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB6FF3B)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              color: Color(0xFFB6FF3B),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  data.targetMuscles,
                                  style: const TextStyle(
                                    color: Color(0xFFA7B0BF),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB6FF3B),
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push('/workouts');
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text(
                          'Start This Workout Now',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Icon + Title + Chevron
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Color(0xFF00D4FF),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Exercise Rows
                ...data.exercises.map((exercise) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        // Exercise thumbnail/icon squircle
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2836),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Icon(
                            exercise.icon,
                            color: const Color(0xFFB6FF3B),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title and sets/reps
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                exercise.setsReps,
                                style: const TextStyle(
                                  color: Color(0xFFA7B0BF),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Anatomical Muscle Target Badge
                        MuscleSilhouetteBadge(
                          targetMuscle: exercise.targetMuscle,
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // Footer chips row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Color(0xFF00D4FF),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data.duration,
                            style: const TextStyle(
                              color: Color(0xFF00D4FF),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.accessibility_new_rounded,
                              color: Color(0xFFB6FF3B),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                data.targetMuscles,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFA7B0BF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
