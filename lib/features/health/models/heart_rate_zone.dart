import 'package:flutter/material.dart';

/// Calculated Heart Rate Zone based on Tanaka et al. (2001) formula.
class HeartRateZone {
  const HeartRateZone({
    required this.zoneNumber,
    required this.name,
    required this.minPercent,
    required this.maxPercent,
    required this.minBpm,
    required this.maxBpm,
    required this.description,
    required this.color,
  });

  final int zoneNumber;
  final String name;
  final double minPercent;
  final double maxPercent;
  final int minBpm;
  final int maxBpm;
  final String description;
  final Color color;

  String get rangeLabel => '$minBpm–$maxBpm bpm';
  String get percentLabel => '${(minPercent * 100).round()}%–${(maxPercent * 100).round()}% HRmax';

  /// Tanaka et al. (2001) age-predicted maximal heart rate:
  /// HRmax = 208 - (0.7 * age)
  static int calculateMaxHr(int age) {
    final clampedAge = age.clamp(10, 100);
    return (208 - (0.7 * clampedAge)).round();
  }

  /// Calculates the five physiological training zones for a given age.
  static List<HeartRateZone> calculateZones(int age) {
    final maxHr = calculateMaxHr(age);

    return [
      HeartRateZone(
        zoneNumber: 1,
        name: 'Zone 1: Active Recovery',
        minPercent: 0.50,
        maxPercent: 0.60,
        minBpm: (maxHr * 0.50).round(),
        maxBpm: (maxHr * 0.60).round(),
        description: 'Warm-up, cooldown, active recovery, and gentle circulation without metabolic stress.',
        color: const Color(0xFF34D399),
      ),
      HeartRateZone(
        zoneNumber: 2,
        name: 'Zone 2: Aerobic Base',
        minPercent: 0.60,
        maxPercent: 0.70,
        minBpm: (maxHr * 0.60).round() + 1,
        maxBpm: (maxHr * 0.70).round(),
        description: 'Mitochondrial density, fatty acid oxidation, and aerobic endurance foundation.',
        color: const Color(0xFF00D4FF),
      ),
      HeartRateZone(
        zoneNumber: 3,
        name: 'Zone 3: Tempo / Aerobic',
        minPercent: 0.70,
        maxPercent: 0.80,
        minBpm: (maxHr * 0.70).round() + 1,
        maxBpm: (maxHr * 0.80).round(),
        description: 'Cardiovascular efficiency and glycogen-sparing muscular endurance.',
        color: const Color(0xFFB6FF3B),
      ),
      HeartRateZone(
        zoneNumber: 4,
        name: 'Zone 4: Lactate Threshold',
        minPercent: 0.80,
        maxPercent: 0.90,
        minBpm: (maxHr * 0.80).round() + 1,
        maxBpm: (maxHr * 0.90).round(),
        description: 'Sustained high-intensity effort near the anaerobic lactate accumulation threshold.',
        color: const Color(0xFFFF9500),
      ),
      HeartRateZone(
        zoneNumber: 5,
        name: 'Zone 5: Anaerobic Peak',
        minPercent: 0.90,
        maxPercent: 1.00,
        minBpm: (maxHr * 0.90).round() + 1,
        maxBpm: maxHr,
        description: 'Maximum neuromuscular output and sprint capacity; short sustainable bursts.',
        color: const Color(0xFFFF2D55),
      ),
    ];
  }

  /// Determines which zone a given heart rate falls into.
  static HeartRateZone? zoneForHr(int hr, int age) {
    final zones = calculateZones(age);
    for (final z in zones) {
      if (hr >= z.minBpm && hr <= z.maxBpm) {
        return z;
      }
    }
    if (hr < zones.first.minBpm) return zones.first;
    if (hr > zones.last.maxBpm) return zones.last;
    return null;
  }

  /// Resting heart rate classification context.
  static String restingHrClassification(int rhr) {
    if (rhr < 50) return 'Athletic / Low Resting HR';
    if (rhr < 60) return 'Excellent Cardiovascular Fitness';
    if (rhr < 70) return 'Good Resting HR';
    if (rhr < 80) return 'Average Resting HR';
    return 'Elevated Resting HR';
  }
}
