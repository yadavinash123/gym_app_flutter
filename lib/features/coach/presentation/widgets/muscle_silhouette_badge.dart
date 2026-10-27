import 'package:flutter/material.dart';

class MuscleSilhouetteBadge extends StatelessWidget {
  const MuscleSilhouetteBadge({
    super.key,
    required this.targetMuscle,
    this.size = 28.0,
  });

  final String targetMuscle;
  final double size;

  @override
  Widget build(BuildContext context) {
    Color highlightColor;
    final lower = targetMuscle.toLowerCase();
    if (lower.contains('chest')) {
      highlightColor = const Color(0xFFF87171); // Coral red
    } else if (lower.contains('shoulder')) {
      highlightColor = const Color(0xFFFB923C); // Orange
    } else if (lower.contains('tricep') ||
        lower.contains('arm') ||
        lower.contains('bicep')) {
      highlightColor = const Color(0xFF38BDF8); // Cyan
    } else if (lower.contains('back') || lower.contains('lat')) {
      highlightColor = const Color(0xFFA78BFA); // Purple
    } else {
      highlightColor = const Color(0xFFB6FF3B); // Lime
    }

    return Container(
      width: size,
      height: size + 6,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2836).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base anatomy silhouette icon
          Icon(
            Icons.accessibility_new_rounded,
            size: size * 0.75,
            color: const Color(0xFF64748B),
          ),
          // Highlight dot/accent indicating active muscle group
          Positioned(
            top: lower.contains('shoulder')
                ? 7
                : (lower.contains('chest') ? 9 : 12),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: highlightColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: highlightColor.withValues(alpha: 0.8),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
