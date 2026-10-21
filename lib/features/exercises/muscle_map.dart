import 'package:flutter/material.dart';

import 'exercise.dart';

/// Regions are shared by painting and hit testing, in a normalized canvas.
Map<String, List<Rect>> muscleRegions(bool back) => {
  'Shoulders': [
    const Rect.fromLTWH(.23, .22, .12, .09),
    const Rect.fromLTWH(.65, .22, .12, .09),
  ],
  if (!back) 'Chest': [const Rect.fromLTWH(.36, .23, .28, .12)],
  if (back) 'Back': [const Rect.fromLTWH(.36, .23, .28, .23)],
  if (!back) 'Abdominals': [const Rect.fromLTWH(.40, .37, .20, .16)],
  if (back) 'Glutes': [const Rect.fromLTWH(.36, .48, .28, .10)],
  back ? 'Triceps' : 'Biceps': [
    const Rect.fromLTWH(.21, .32, .11, .14),
    const Rect.fromLTWH(.68, .32, .11, .14),
  ],
  'Forearms': [
    const Rect.fromLTWH(.17, .48, .10, .14),
    const Rect.fromLTWH(.73, .48, .10, .14),
  ],
  back ? 'Hamstrings' : 'Quadriceps': [
    const Rect.fromLTWH(.36, .59, .12, .16),
    const Rect.fromLTWH(.52, .59, .12, .16),
  ],
  'Calves': [
    const Rect.fromLTWH(.37, .78, .10, .14),
    const Rect.fromLTWH(.53, .78, .10, .14),
  ],
};

class MuscleMap extends StatefulWidget {
  const MuscleMap({
    super.key,
    this.primary = const [],
    this.secondary = const [],
    this.onSelect,
  });
  final List<String> primary, secondary;
  final ValueChanged<String>? onSelect;
  @override
  State<MuscleMap> createState() => _MuscleMapState();
}

class _MuscleMapState extends State<MuscleMap> {
  bool back = false;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('Front')),
          ButtonSegment(value: true, label: Text('Back')),
        ],
        selected: {back},
        onSelectionChanged: (value) => setState(() => back = value.single),
      ),
      const SizedBox(height: 12),
      Semantics(
        label:
            'Simplified ${back ? 'back' : 'front'} muscle illustration. '
            'Primary: ${widget.primary.join(', ')}. Secondary: ${widget.secondary.join(', ')}.',
        child: SizedBox(
          width: 240,
          height: 300,
          child: GestureDetector(
            onTapUp: widget.onSelect == null
                ? null
                : (event) {
                    final p = Offset(
                      event.localPosition.dx / 240,
                      event.localPosition.dy / 300,
                    );
                    for (final entry in muscleRegions(back).entries) {
                      if (entry.value.any((rect) => rect.contains(p))) {
                        widget.onSelect!(entry.key);
                        break;
                      }
                    }
                  },
            child: CustomPaint(
              key: const ValueKey('muscle-map-canvas'),
              painter: _MusclePainter(back, widget.primary, widget.secondary),
            ),
          ),
        ),
      ),
      const Text(
        'Simplified muscle illustration',
        style: TextStyle(color: Color(0xFFA7B0BF)),
      ),
      if (widget.onSelect != null) ...[
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          children: [
            for (final muscle in muscleGroups)
              FilterChip(
                label: Text(muscle),
                selected: widget.primary.contains(muscle),
                onSelected: (_) => widget.onSelect!(muscle),
              ),
          ],
        ),
      ],
    ],
  );
}

class _MusclePainter extends CustomPainter {
  _MusclePainter(this.back, this.primary, this.secondary);
  final bool back;
  final List<String> primary, secondary;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width, size.height);
    final base = Paint()..color = const Color(0xFF334051);
    canvas.drawOval(const Rect.fromLTWH(.41, .03, .18, .14), base);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(.46, .16, .08, .07),
        const Radius.circular(.02),
      ),
      base,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(.33, .21, .34, .37),
        const Radius.circular(.06),
      ),
      base,
    );
    for (final entry in muscleRegions(back).entries) {
      final color = primary.contains(entry.key)
          ? const Color(0xFFB6FF3B)
          : secondary.contains(entry.key)
          ? const Color(0xFF00D4FF)
          : const Color(0xFF526175);
      for (final rect in entry.value) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(.025)),
          Paint()..color = color,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MusclePainter oldDelegate) =>
      back != oldDelegate.back ||
      primary != oldDelegate.primary ||
      secondary != oldDelegate.secondary;
}
