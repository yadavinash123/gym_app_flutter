import 'package:flutter/material.dart';
import '../models/health_metric_type.dart';
import '../models/health_source.dart';

class HealthMetricCard extends StatelessWidget {
  const HealthMetricCard({
    super.key,
    required this.metric,
    required this.displayValue,
    required this.unit,
    required this.source,
    this.target,
    this.progress,
    this.subtitle,
    this.onTap,
  });

  final HealthMetricType metric;
  final String displayValue;
  final String unit;
  final HealthSource source;
  final String? target;
  final double? progress;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 160;
          final isUltraNarrow = constraints.maxWidth < 125;
          final cardPadding = isNarrow ? (isUltraNarrow ? 8.0 : 10.0) : 16.0;
          final maxBadgeWidth = isUltraNarrow
              ? 0.0
              : (constraints.maxWidth * 0.28).clamp(24.0, 64.0);

          return Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: const Color(0xFF151B23),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1C2430)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: metric.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(metric.icon, color: metric.color, size: 16),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        metric.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFA7B0BF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _SourceBadge(
                      source: source,
                      maxTextWidth: maxBadgeWidth,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        displayValue,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFA7B0BF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (progress != null || target != null) ...[
                  const SizedBox(height: 8),
                  if (progress != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress!.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: const Color(0xFF1C2430),
                        valueColor: AlwaysStoppedAnimation<Color>(metric.color),
                      ),
                    ),
                  if (target != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (progress != null)
                          Text(
                            '${(progress! * 100).round()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: metric.color,
                            ),
                          ),
                        Flexible(
                          child: Text(
                            'Goal: $target',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFA7B0BF),
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA7B0BF),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({
    required this.source,
    this.maxTextWidth = 64.0,
  });

  final HealthSource source;
  final double maxTextWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: source.badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: source.badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(source.icon, size: 10, color: source.badgeColor),
          if (maxTextWidth > 0) ...[
            const SizedBox(width: 3),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxTextWidth),
              child: Text(
                source.shortBadge,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: source.badgeColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
