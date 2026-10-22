import 'health_metric_type.dart';
import 'health_source.dart';

/// Aggregated daily health metrics with granular source attribution for each metric.
class DailyHealthSummary {
  const DailyHealthSummary({
    required this.date,
    this.steps = 0,
    this.stepSource = HealthSource.manual,
    this.distanceKm = 0.0,
    this.distanceSource = HealthSource.manual,
    this.activeKcal = 0.0,
    this.activeKcalSource = HealthSource.manual,
    this.restingHeartRateBpm,
    this.restingHeartRateSource,
    this.sleepDurationMinutes,
    this.deepSleepMinutes,
    this.remSleepMinutes,
    this.lightSleepMinutes,
    this.sleepSource,
    this.externalWorkoutsCount = 0,
    this.syncedAt,
    this.notes,
  });

  final String date; // YYYY-MM-DD
  final int steps;
  final HealthSource stepSource;

  final double distanceKm;
  final HealthSource distanceSource;

  final double activeKcal;
  final HealthSource activeKcalSource;

  final int? restingHeartRateBpm;
  final HealthSource? restingHeartRateSource;

  final int? sleepDurationMinutes;
  final int? deepSleepMinutes;
  final int? remSleepMinutes;
  final int? lightSleepMinutes;
  final HealthSource? sleepSource;

  final int externalWorkoutsCount;
  final DateTime? syncedAt;
  final String? notes;

  String get sleepFormatted {
    if (sleepDurationMinutes == null || sleepDurationMinutes == 0) return 'No sleep data';
    final hours = sleepDurationMinutes! ~/ 60;
    final mins = sleepDurationMinutes! % 60;
    return '${hours}h ${mins}m';
  }

  double stepProgress(int targetSteps) {
    if (targetSteps <= 0) return 0.0;
    return (steps / targetSteps).clamp(0.0, 1.0);
  }

  /// Returns the attributed source for a given metric.
  HealthSource sourceFor(HealthMetricType metric) {
    switch (metric) {
      case HealthMetricType.steps:
        return stepSource;
      case HealthMetricType.distance:
        return distanceSource;
      case HealthMetricType.activeEnergy:
        return activeKcalSource;
      case HealthMetricType.restingHeartRate:
        return restingHeartRateSource ?? HealthSource.manual;
      case HealthMetricType.sleep:
        return sleepSource ?? HealthSource.manual;
      case HealthMetricType.workouts:
        return HealthSource.fitforge;
    }
  }

  DailyHealthSummary copyWith({
    int? steps,
    HealthSource? stepSource,
    double? distanceKm,
    HealthSource? distanceSource,
    double? activeKcal,
    HealthSource? activeKcalSource,
    int? restingHeartRateBpm,
    HealthSource? restingHeartRateSource,
    int? sleepDurationMinutes,
    int? deepSleepMinutes,
    int? remSleepMinutes,
    int? lightSleepMinutes,
    HealthSource? sleepSource,
    int? externalWorkoutsCount,
    DateTime? syncedAt,
    String? notes,
  }) {
    return DailyHealthSummary(
      date: date,
      steps: steps ?? this.steps,
      stepSource: stepSource ?? this.stepSource,
      distanceKm: distanceKm ?? this.distanceKm,
      distanceSource: distanceSource ?? this.distanceSource,
      activeKcal: activeKcal ?? this.activeKcal,
      activeKcalSource: activeKcalSource ?? this.activeKcalSource,
      restingHeartRateBpm: restingHeartRateBpm ?? this.restingHeartRateBpm,
      restingHeartRateSource: restingHeartRateSource ?? this.restingHeartRateSource,
      sleepDurationMinutes: sleepDurationMinutes ?? this.sleepDurationMinutes,
      deepSleepMinutes: deepSleepMinutes ?? this.deepSleepMinutes,
      remSleepMinutes: remSleepMinutes ?? this.remSleepMinutes,
      lightSleepMinutes: lightSleepMinutes ?? this.lightSleepMinutes,
      sleepSource: sleepSource ?? this.sleepSource,
      externalWorkoutsCount: externalWorkoutsCount ?? this.externalWorkoutsCount,
      syncedAt: syncedAt ?? this.syncedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'steps': steps,
        'stepSource': stepSource.toJson(),
        'distanceKm': distanceKm,
        'distanceSource': distanceSource.toJson(),
        'activeKcal': activeKcal,
        'activeKcalSource': activeKcalSource.toJson(),
        if (restingHeartRateBpm != null) 'restingHeartRateBpm': restingHeartRateBpm,
        if (restingHeartRateSource != null)
          'restingHeartRateSource': restingHeartRateSource!.toJson(),
        if (sleepDurationMinutes != null)
          'sleepDurationMinutes': sleepDurationMinutes,
        if (deepSleepMinutes != null) 'deepSleepMinutes': deepSleepMinutes,
        if (remSleepMinutes != null) 'remSleepMinutes': remSleepMinutes,
        if (lightSleepMinutes != null) 'lightSleepMinutes': lightSleepMinutes,
        if (sleepSource != null) 'sleepSource': sleepSource!.toJson(),
        'externalWorkoutsCount': externalWorkoutsCount,
        if (syncedAt != null) 'syncedAt': syncedAt!.toIso8601String(),
        if (notes != null) 'notes': notes,
      };

  factory DailyHealthSummary.fromJson(Map<String, dynamic> json) {
    return DailyHealthSummary(
      date: json['date'] as String,
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      stepSource: HealthSource.fromJson(json['stepSource'] as Map<String, dynamic>? ?? {}),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      distanceSource:
          HealthSource.fromJson(json['distanceSource'] as Map<String, dynamic>? ?? {}),
      activeKcal: (json['activeKcal'] as num?)?.toDouble() ?? 0.0,
      activeKcalSource:
          HealthSource.fromJson(json['activeKcalSource'] as Map<String, dynamic>? ?? {}),
      restingHeartRateBpm: (json['restingHeartRateBpm'] as num?)?.toInt(),
      restingHeartRateSource: json['restingHeartRateSource'] != null
          ? HealthSource.fromJson(json['restingHeartRateSource'] as Map<String, dynamic>)
          : null,
      sleepDurationMinutes: (json['sleepDurationMinutes'] as num?)?.toInt(),
      deepSleepMinutes: (json['deepSleepMinutes'] as num?)?.toInt(),
      remSleepMinutes: (json['remSleepMinutes'] as num?)?.toInt(),
      lightSleepMinutes: (json['lightSleepMinutes'] as num?)?.toInt(),
      sleepSource: json['sleepSource'] != null
          ? HealthSource.fromJson(json['sleepSource'] as Map<String, dynamic>)
          : null,
      externalWorkoutsCount: (json['externalWorkoutsCount'] as num?)?.toInt() ?? 0,
      syncedAt: json['syncedAt'] != null ? DateTime.tryParse(json['syncedAt'] as String) : null,
      notes: json['notes'] as String?,
    );
  }

  static DailyHealthSummary empty(String date) {
    return DailyHealthSummary(date: date);
  }
}
