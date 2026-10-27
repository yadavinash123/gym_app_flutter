import 'package:flutter/material.dart';

import '../models/health_source.dart';
import '../models/heart_rate_zone.dart';

class HeartRateZoneChart extends StatelessWidget {
  const HeartRateZoneChart({
    super.key,
    required this.age,
    this.restingBpm,
    this.source,
  });

  final int age;
  final int? restingBpm;
  final HealthSource? source;

  @override
  Widget build(BuildContext context) {
    final maxHr = HeartRateZone.calculateMaxHr(age);
    final zones = HeartRateZone.calculateZones(age);

    return Container(
      padding: const EdgeInsets.all(18),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2D55).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFFF2D55),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Cardiovascular & Training Zones',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (source != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: source!.badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: source!.badgeColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    source!.shortBadge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: source!.badgeColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (restingBpm != null) ...[
            Row(
              children: [
                Text(
                  '$restingBpm',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                const Flexible(
                  child: Text(
                    'bpm Resting HR',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFA7B0BF),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2430),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    HeartRateZone.restingHrClassification(restingBpm!),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB6FF3B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Tanaka HRmax = 208 − (0.7 × $age) = $maxHr bpm',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFA7B0BF),
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 14),
          ...zones.map((z) => _ZoneRow(zone: z, maxHr: maxHr)),
        ],
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({required this.zone, required this.maxHr});

  final HeartRateZone zone;
  final int maxHr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  zone.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${zone.minBpm}–${zone.maxBpm} bpm (${(zone.minPercent * 100).round()}–${(zone.maxPercent * 100).round()}%)',
                style: TextStyle(
                  fontSize: 11,
                  color: zone.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: zone.maxPercent,
              minHeight: 5,
              backgroundColor: const Color(0xFF1C2430),
              valueColor: AlwaysStoppedAnimation<Color>(zone.color),
            ),
          ),
        ],
      ),
    );
  }
}
