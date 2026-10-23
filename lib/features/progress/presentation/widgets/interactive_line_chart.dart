import 'dart:math' as math;
import 'package:flutter/material.dart';

class ChartDataPoint {
  const ChartDataPoint({
    required this.date,
    required this.value,
    this.label,
  });

  final DateTime date;
  final double value;
  final String? label;
}

class InteractiveLineChart extends StatefulWidget {
  const InteractiveLineChart({
    super.key,
    required this.points,
    this.lineColor = const Color(0xFFB6FF3B),
    this.targetValue,
    this.targetLabel,
    this.unit = '',
    this.height = 220,
    this.emptyMessage = 'No data available for this range',
  });

  final List<ChartDataPoint> points;
  final Color lineColor;
  final double? targetValue;
  final String? targetLabel;
  final String unit;
  final double height;
  final String emptyMessage;

  @override
  State<InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<InteractiveLineChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return Container(
        height: widget.height,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF151B23),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Text(
          widget.emptyMessage,
          style: const TextStyle(color: Color(0xFFA7B0BF), fontSize: 13),
        ),
      );
    }

    // Determine bounds
    var minY = widget.points.map((p) => p.value).reduce(math.min);
    var maxY = widget.points.map((p) => p.value).reduce(math.max);
    if (widget.targetValue != null) {
      minY = math.min(minY, widget.targetValue!);
      maxY = math.max(maxY, widget.targetValue!);
    }
    // Add vertical headroom
    final range = maxY - minY;
    final padding = range == 0 ? 5.0 : range * 0.15;
    minY -= padding;
    maxY += padding;

    final selected = _selectedIndex != null && _selectedIndex! < widget.points.length
        ? widget.points[_selectedIndex!]
        : widget.points.last;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151B23),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header showing inspected value or latest value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(selected.date),
                    style: const TextStyle(
                      color: Color(0xFFA7B0BF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        selected.value.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.unit.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          widget.unit,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: widget.lineColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              if (widget.targetValue != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    'Target: ${widget.targetValue!.toStringAsFixed(1)} ${widget.unit}',
                    style: const TextStyle(
                      color: Color(0xFFA7B0BF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart Canvas
          SizedBox(
            height: widget.height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanDown: (details) => _handleTouch(details.localPosition.dx, constraints.maxWidth),
                  onPanUpdate: (details) => _handleTouch(details.localPosition.dx, constraints.maxWidth),
                  onPanEnd: (_) => setState(() => _selectedIndex = null),
                  onPanCancel: () => setState(() => _selectedIndex = null),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, widget.height),
                    painter: _LineChartPainter(
                      points: widget.points,
                      minY: minY,
                      maxY: maxY,
                      lineColor: widget.lineColor,
                      targetValue: widget.targetValue,
                      selectedIndex: _selectedIndex,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleTouch(double dx, double width) {
    if (widget.points.length <= 1) return;
    final step = width / (widget.points.length - 1);
    final index = (dx / step).round().clamp(0, widget.points.length - 1);
    setState(() {
      _selectedIndex = index;
    });
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.points,
    required this.minY,
    required this.maxY,
    required this.lineColor,
    this.targetValue,
    this.selectedIndex,
  });

  final List<ChartDataPoint> points;
  final double minY;
  final double maxY;
  final Color lineColor;
  final double? targetValue;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final yRange = math.max(0.001, maxY - minY);
    final count = points.length;
    final stepX = count <= 1 ? 0.0 : size.width / (count - 1);

    // Draw horizontal grid guide lines (3 lines)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    for (int i = 0; i < 3; i++) {
      final y = size.height * (i / 2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw target line if available
    if (targetValue != null) {
      final targetY = size.height - ((targetValue! - minY) / yRange * size.height);
      final targetPaint = Paint()
        ..color = const Color(0xFF00D4FF).withOpacity(0.4)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Dashed line
      const dashWidth = 5.0;
      const dashSpace = 4.0;
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, targetY),
          Offset(math.min(startX + dashWidth, size.width), targetY),
          targetPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    // If single point, render centered dot
    if (count == 1) {
      final y = size.height - ((points.first.value - minY) / yRange * size.height);
      canvas.drawCircle(
        Offset(size.width / 2, y),
        6,
        Paint()..color = lineColor,
      );
      return;
    }

    // Build line path and fill path
    final path = Path();
    final fillPath = Path();

    final offsets = <Offset>[];
    for (int i = 0; i < count; i++) {
      final x = i * stepX;
      final y = size.height - ((points[i].value - minY) / yRange * size.height);
      offsets.add(Offset(x, y));
    }

    path.moveTo(offsets.first.dx, offsets.first.dy);
    fillPath.moveTo(offsets.first.dx, size.height);
    fillPath.lineTo(offsets.first.dx, offsets.first.dy);

    for (int i = 0; i < count - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      fillPath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(offsets.last.dx, size.height);
    fillPath.close();

    // Draw gradient under line
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(0.25),
          lineColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw dots and active touch indicator
    final dotPaint = Paint()..color = lineColor;
    final dotOuterPaint = Paint()
      ..color = const Color(0xFF151B23)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < offsets.length; i++) {
      final offset = offsets[i];
      if (selectedIndex == i) {
        // Vertical cursor guide line
        canvas.drawLine(
          Offset(offset.dx, 0),
          Offset(offset.dx, size.height),
          Paint()
            ..color = Colors.white.withOpacity(0.2)
            ..strokeWidth = 1,
        );
        // Highlighted active dot
        canvas.drawCircle(offset, 8, Paint()..color = lineColor.withOpacity(0.3));
        canvas.drawCircle(offset, 5, dotPaint);
        canvas.drawCircle(offset, 5, dotOuterPaint);
      } else {
        canvas.drawCircle(offset, 3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.targetValue != targetValue;
  }
}
