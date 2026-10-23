import 'dart:math' as math;
import 'package:flutter/material.dart';

class VolumeBarData {
  const VolumeBarData({
    required this.label, // e.g. "W1", "W2", "Oct 14"
    required this.volumeKg,
    required this.setCount,
    required this.sessionCount,
  });

  final String label;
  final double volumeKg;
  final int setCount;
  final int sessionCount;
}

class VolumeBarChart extends StatefulWidget {
  const VolumeBarChart({
    super.key,
    required this.bars,
    this.primaryColor = const Color(0xFF00D4FF),
    this.unit = 'kg',
    this.height = 180,
  });

  final List<VolumeBarData> bars;
  final Color primaryColor;
  final String unit;
  final double height;

  @override
  State<VolumeBarChart> createState() => _VolumeBarChartState();
}

class _VolumeBarChartState extends State<VolumeBarChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.bars.isEmpty) {
      return Container(
        height: widget.height,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF151B23),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: const Text(
          'No workout volume recorded yet',
          style: TextStyle(color: Color(0xFFA7B0BF), fontSize: 13),
        ),
      );
    }

    final maxVolume = widget.bars.map((b) => b.volumeKg).fold(0.0, math.max);
    final selectedBar = _hoveredIndex != null && _hoveredIndex! < widget.bars.length
        ? widget.bars[_hoveredIndex!]
        : widget.bars.last;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedBar.label,
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
                        _formatNumber(selectedBar.volumeKg),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.unit,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: widget.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedBar.sessionCount} sessions • ${selectedBar.setCount} sets',
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
          SizedBox(
            height: widget.height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(widget.bars.length, (index) {
                final bar = widget.bars[index];
                final isSelected = _hoveredIndex == index;
                final heightFactor = maxVolume <= 0
                    ? 0.05
                    : (bar.volumeKg / maxVolume).clamp(0.05, 1.0);

                return Expanded(
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _hoveredIndex = index),
                    onTapUp: (_) => setState(() => _hoveredIndex = null),
                    onTapCancel: () => setState(() => _hoveredIndex = null),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: heightFactor,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFB6FF3B)
                                        : widget.primaryColor.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFB6FF3B)
                                                  .withOpacity(0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bar.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFFA7B0BF),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double val) {
    if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(1)}k';
    }
    return val.toStringAsFixed(0);
  }
}
