import 'package:flutter/material.dart';

import '../../models/muscle_recovery.dart';

class MuscleRecoveryCard extends StatelessWidget {
  const MuscleRecoveryCard({
    super.key,
    required this.readiness,
    this.onTapDetail,
  });

  final OverallSystemReadiness readiness;
  final VoidCallback? onTapDetail;

  @override
  Widget build(BuildContext context) {
    final score = readiness.readinessScore;
    final scoreColor = _scoreColor(score);

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
          // Readiness Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular readiness score badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor.withOpacity(0.12),
                  border: Border.all(color: scoreColor, width: 2.5),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      'READY',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: scoreColor.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          readiness.readinessLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: scoreColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      readiness.advice,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA7B0BF),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          // Title
          const Text(
            'MUSCLE GROUP STATUS (SUPERCOMPENSATION)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: Color(0xFFA7B0BF),
            ),
          ),
          const SizedBox(height: 12),
          // Grid or list of 6 muscle groups
          ...readiness.muscles.map((muscle) => _buildMuscleRow(muscle)),
        ],
      ),
    );
  }

  Widget _buildMuscleRow(MuscleGroupRecovery muscle) {
    final color = _stateColor(muscle.state);
    final recoveryPct = muscle.recoveryPercentage / 100.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    muscle.muscleGroup,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (muscle.setsInLast48Hours > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '(${muscle.setsInLast48Hours} sets recent)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFA7B0BF),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Text(
                    muscle.stateDisplayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${muscle.recoveryPercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Recovery progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: recoveryPct,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          if (muscle.estimatedHoursToFullRecovery > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '~${muscle.estimatedHoursToFullRecovery}h remaining to 100% capacity',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFA7B0BF),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 85) return const Color(0xFFB6FF3B); // Lime
    if (score >= 70) return const Color(0xFF00D4FF); // Cyan
    if (score >= 50) return const Color(0xFFFF9500); // Orange
    return const Color(0xFFFF3B30); // Red
  }

  Color _stateColor(MuscleRecoveryState state) {
    switch (state) {
      case MuscleRecoveryState.fresh:
        return const Color(0xFFB6FF3B);
      case MuscleRecoveryState.recovering:
        return const Color(0xFF00D4FF);
      case MuscleRecoveryState.fatigued:
        return const Color(0xFFFF9500);
      case MuscleRecoveryState.overreaching:
        return const Color(0xFFFF3B30);
    }
  }
}
