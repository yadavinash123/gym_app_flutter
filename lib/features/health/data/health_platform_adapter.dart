import 'dart:math';

import '../models/daily_health_summary.dart';
import '../models/health_metric_type.dart';
import '../models/health_permission.dart';
import '../models/health_record.dart';
import '../models/health_source.dart';

/// Contract for interacting with device health platforms (Health Connect, HealthKit, Sensors).
abstract class HealthPlatformAdapter {
  Future<bool> isPlatformAvailable();

  HealthSource get defaultSource;

  Future<Map<HealthMetricType, HealthPermissionStatus>> checkPermissions(
    List<HealthMetricType> metrics,
  );

  Future<Map<HealthMetricType, HealthPermissionStatus>> requestPermissions(
    List<HealthMetricType> metrics,
  );

  Future<DailyHealthSummary> fetchDailySummary(
    String date,
    List<HealthMetricType> permittedMetrics,
  );

  Future<List<HealthRecord>> fetchRecentRecords(
    HealthMetricType metric,
    DateTime start,
    DateTime end,
  );
}

/// Offline simulated health provider that enables realistic demonstration,
/// automated testing, and emulator verification without external cloud APIs.
class SimulatedHealthAdapter implements HealthPlatformAdapter {
  SimulatedHealthAdapter({
    this.source = HealthSource.healthConnect,
    this.simulatedSteps = 8450,
    this.simulatedRestingHr = 64,
    this.simulatedSleepMinutes = 465, // 7h 45m
    this.simulatedActiveKcal = 420.0,
    this.simulatedDistanceKm = 6.2,
  });

  final HealthSource source;
  final int simulatedSteps;
  final int simulatedRestingHr;
  final int simulatedSleepMinutes;
  final double simulatedActiveKcal;
  final double simulatedDistanceKm;

  @override
  Future<bool> isPlatformAvailable() async => true;

  @override
  HealthSource get defaultSource => source;

  @override
  Future<Map<HealthMetricType, HealthPermissionStatus>> checkPermissions(
    List<HealthMetricType> metrics,
  ) async {
    // Default mock response: granted for all requested metrics
    return {for (final m in metrics) m: HealthPermissionStatus.granted};
  }

  @override
  Future<Map<HealthMetricType, HealthPermissionStatus>> requestPermissions(
    List<HealthMetricType> metrics,
  ) async {
    return {for (final m in metrics) m: HealthPermissionStatus.granted};
  }

  @override
  Future<DailyHealthSummary> fetchDailySummary(
    String date,
    List<HealthMetricType> permittedMetrics,
  ) async {
    // Deterministic generation based on date hash to provide realistic day-to-day variance
    final dateHash = date.hashCode.abs();
    final stepVariance = (dateHash % 2500) - 1000;
    final rhrVariance = (dateHash % 7) - 3;
    final sleepVariance = (dateHash % 60) - 30;

    final actualSteps = max(2000, simulatedSteps + stepVariance);
    final actualRhr = (simulatedRestingHr + rhrVariance).clamp(48, 95);
    final actualSleep = max(300, simulatedSleepMinutes + sleepVariance);
    final actualDistance = double.parse(
      (actualSteps * 0.00075).toStringAsFixed(2),
    );
    final actualKcal = double.parse((actualSteps * 0.045).toStringAsFixed(1));

    final deepSleep = (actualSleep * 0.22).round();
    final remSleep = (actualSleep * 0.24).round();
    final lightSleep = actualSleep - deepSleep - remSleep;

    return DailyHealthSummary(
      date: date,
      steps: permittedMetrics.contains(HealthMetricType.steps)
          ? actualSteps
          : 0,
      stepSource: source,
      distanceKm: permittedMetrics.contains(HealthMetricType.distance)
          ? actualDistance
          : 0.0,
      distanceSource: source,
      activeKcal: permittedMetrics.contains(HealthMetricType.activeEnergy)
          ? actualKcal
          : 0.0,
      activeKcalSource: source,
      restingHeartRateBpm:
          permittedMetrics.contains(HealthMetricType.restingHeartRate)
          ? actualRhr
          : null,
      restingHeartRateSource:
          permittedMetrics.contains(HealthMetricType.restingHeartRate)
          ? source
          : null,
      sleepDurationMinutes: permittedMetrics.contains(HealthMetricType.sleep)
          ? actualSleep
          : null,
      deepSleepMinutes: permittedMetrics.contains(HealthMetricType.sleep)
          ? deepSleep
          : null,
      remSleepMinutes: permittedMetrics.contains(HealthMetricType.sleep)
          ? remSleep
          : null,
      lightSleepMinutes: permittedMetrics.contains(HealthMetricType.sleep)
          ? lightSleep
          : null,
      sleepSource: permittedMetrics.contains(HealthMetricType.sleep)
          ? source
          : null,
      externalWorkoutsCount:
          permittedMetrics.contains(HealthMetricType.workouts) ? 1 : 0,
      syncedAt: DateTime.now(),
      notes: 'Synchronized via ${source.displayName}',
    );
  }

  @override
  Future<List<HealthRecord>> fetchRecentRecords(
    HealthMetricType metric,
    DateTime start,
    DateTime end,
  ) async {
    final now = DateTime.now();
    switch (metric) {
      case HealthMetricType.steps:
        return [
          HealthRecord(
            id: 'sim_steps_${now.millisecondsSinceEpoch}',
            metric: HealthMetricType.steps,
            value: simulatedSteps.toDouble(),
            unit: 'steps',
            timestamp: now,
            source: source,
          ),
        ];
      case HealthMetricType.restingHeartRate:
        return [
          HealthRecord(
            id: 'sim_rhr_${now.millisecondsSinceEpoch}',
            metric: HealthMetricType.restingHeartRate,
            value: simulatedRestingHr.toDouble(),
            unit: 'bpm',
            timestamp: now,
            source: source,
          ),
        ];
      case HealthMetricType.sleep:
        return [
          HealthRecord(
            id: 'sim_sleep_${now.millisecondsSinceEpoch}',
            metric: HealthMetricType.sleep,
            value: simulatedSleepMinutes.toDouble(),
            unit: 'min',
            timestamp: now.subtract(const Duration(hours: 8)),
            endTime: now,
            source: source,
            metadata: {
              'deepSleep': (simulatedSleepMinutes * 0.22).round(),
              'remSleep': (simulatedSleepMinutes * 0.24).round(),
            },
          ),
        ];
      case HealthMetricType.activeEnergy:
        return [
          HealthRecord(
            id: 'sim_energy_${now.millisecondsSinceEpoch}',
            metric: HealthMetricType.activeEnergy,
            value: simulatedActiveKcal,
            unit: 'kcal',
            timestamp: now,
            source: source,
          ),
        ];
      case HealthMetricType.distance:
        return [
          HealthRecord(
            id: 'sim_dist_${now.millisecondsSinceEpoch}',
            metric: HealthMetricType.distance,
            value: simulatedDistanceKm,
            unit: 'km',
            timestamp: now,
            source: source,
          ),
        ];
      case HealthMetricType.workouts:
        return [
          HealthRecord(
            id: 'sim_workout_${now.millisecondsSinceEpoch}',
            metric: HealthMetricType.workouts,
            value: 45.0,
            unit: 'min',
            timestamp: now.subtract(const Duration(hours: 3)),
            endTime: now.subtract(const Duration(hours: 2, minutes: 15)),
            source: source,
            notes: 'Outdoor brisk walk',
          ),
        ];
    }
  }
}
