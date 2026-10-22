import 'package:flutter/material.dart';

class MacroProgressBar extends StatelessWidget {
  const MacroProgressBar({
    super.key,
    required this.label,
    required this.currentGrams,
    required this.targetGrams,
    required this.color,
    this.unit = 'g',
  });

  final String label;
  final double currentGrams;
  final double targetGrams;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final progress = targetGrams > 0
        ? (currentGrams / targetGrams).clamp(0.0, 1.0)
        : 0.0;
    final percent = targetGrams > 0
        ? (currentGrams / targetGrams * 100).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFA7B0BF),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${currentGrams.toStringAsFixed(0)} / ${targetGrams.toStringAsFixed(0)} $unit ($percent%)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF1C2430),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
