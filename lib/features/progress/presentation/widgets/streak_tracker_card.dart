import 'package:flutter/material.dart';

import '../../models/habit_streak.dart';

class StreakTrackerCard extends StatelessWidget {
  const StreakTrackerCard({
    super.key,
    required this.workoutStreak,
    this.nutritionStreak,
    this.hydrationStreak,
  });

  final HabitStreak workoutStreak;
  final HabitStreak? nutritionStreak;
  final HabitStreak? hydrationStreak;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Flame icon badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF9500), width: 1.5),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFFF9500),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${workoutStreak.currentStreak}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'DAY STREAK',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Color(0xFFFF9500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Personal Best: ${workoutStreak.longestStreak} days • ${workoutStreak.weeklyAdherenceRate.toStringAsFixed(0)}% weekly adherence',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFA7B0BF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          // 7-day activity visual
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final dayDate = now.subtract(Duration(days: 6 - i));
              final dayStr = _formatDate(dayDate);
              final isActive = workoutStreak.isDateActive(dayStr);
              final dayLetter = _dayLetter(dayDate.weekday);
              final isToday = i == 6;

              return Column(
                children: [
                  Text(
                    dayLetter,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                      color: isToday ? const Color(0xFFB6FF3B) : const Color(0xFFA7B0BF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? const Color(0xFFB6FF3B)
                          : Colors.white.withOpacity(0.06),
                      border: isToday
                          ? Border.all(
                              color: const Color(0xFFB6FF3B).withOpacity(0.8),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: isActive
                          ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Color(0xFF0B0F14),
                            )
                          : Text(
                              '${dayDate.day}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
          if (nutritionStreak != null || hydrationStreak != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (nutritionStreak != null)
                  Expanded(
                    child: _buildSecondaryStreakPill(
                      icon: Icons.restaurant_rounded,
                      color: const Color(0xFF00D4FF),
                      label: 'Nutrition: ${nutritionStreak!.currentStreak}d',
                    ),
                  ),
                if (nutritionStreak != null && hydrationStreak != null)
                  const SizedBox(width: 8),
                if (hydrationStreak != null)
                  Expanded(
                    child: _buildSecondaryStreakPill(
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFF00D4FF),
                      label: 'Hydration: ${hydrationStreak!.currentStreak}d',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecondaryStreakPill({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _dayLetter(int weekday) {
    switch (weekday) {
      case 1:
        return 'M';
      case 2:
        return 'T';
      case 3:
        return 'W';
      case 4:
        return 'T';
      case 5:
        return 'F';
      case 6:
        return 'S';
      case 7:
        return 'S';
      default:
        return '';
    }
  }
}
