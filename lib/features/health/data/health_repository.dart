import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/json_store.dart';
import '../../profile/profile_repository.dart';
import '../models/daily_health_summary.dart';
import '../models/health_metric_type.dart';
import '../models/health_permission.dart';
import '../models/health_source.dart';
import '../models/sync_audit_log.dart';
import 'health_platform_adapter.dart';

class HealthRepository {
  HealthRepository(this.store, this.adapter);

  final JsonStore store;
  final HealthPlatformAdapter adapter;
  Future<void> _tail = Future.value();

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  Future<List<HealthPermission>> getPermissions() async {
    await _tail;
    return _readPermissions();
  }

  Future<List<HealthPermission>> _readPermissions() async {
    final data = await store.read('health_permissions');
    if (data == null) {
      return HealthPermission.defaultPermissions();
    }
    if (data['version'] != 1 || data['permissions'] is! List) {
      throw const FormatException('Invalid health permissions storage');
    }
    final raw = data['permissions'] as List;
    final list = raw
        .map((e) => HealthPermission.fromJson(e as Map<String, dynamic>))
        .toList();

    // Ensure all metric types exist
    final existingMetrics = list.map((p) => p.metric).toSet();
    for (final metric in HealthMetricType.values) {
      if (!existingMetrics.contains(metric)) {
        list.add(
          HealthPermission(
            metric: metric,
            mode: metric == HealthMetricType.workouts
                ? HealthAccessMode.readWrite
                : HealthAccessMode.read,
            status: HealthPermissionStatus.notDetermined,
          ),
        );
      }
    }
    return list;
  }

  Future<List<HealthPermission>> updatePermission(
    HealthMetricType metric,
    HealthPermissionStatus status,
  ) {
    final result = _tail.then((_) async {
      final permissions = await _readPermissions();
      final index = permissions.indexWhere((p) => p.metric == metric);
      final updated = HealthPermission(
        metric: metric,
        mode: metric == HealthMetricType.workouts
            ? HealthAccessMode.readWrite
            : HealthAccessMode.read,
        status: status,
        updatedAt: DateTime.now(),
      );

      if (index >= 0) {
        permissions[index] = updated;
      } else {
        permissions.add(updated);
      }

      await store.write('health_permissions', {
        'version': 1,
        'permissions': permissions.map((p) => p.toJson()).toList(),
      });
      return permissions;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<List<HealthPermission>> grantAllPermissions() {
    final result = _tail.then((_) async {
      final permissions = HealthMetricType.values.map((metric) {
        return HealthPermission(
          metric: metric,
          mode: metric == HealthMetricType.workouts
              ? HealthAccessMode.readWrite
              : HealthAccessMode.read,
          status: HealthPermissionStatus.granted,
          updatedAt: DateTime.now(),
        );
      }).toList();

      await store.write('health_permissions', {
        'version': 1,
        'permissions': permissions.map((p) => p.toJson()).toList(),
      });
      return permissions;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<List<HealthPermission>> revokeAllPermissions() {
    final result = _tail.then((_) async {
      final permissions = HealthMetricType.values.map((metric) {
        return HealthPermission(
          metric: metric,
          mode: metric == HealthMetricType.workouts
              ? HealthAccessMode.readWrite
              : HealthAccessMode.read,
          status: HealthPermissionStatus.denied,
          updatedAt: DateTime.now(),
        );
      }).toList();

      await store.write('health_permissions', {
        'version': 1,
        'permissions': permissions.map((p) => p.toJson()).toList(),
      });
      return permissions;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  // ---------------------------------------------------------------------------
  // Summaries
  // ---------------------------------------------------------------------------

  Future<Map<String, DailyHealthSummary>> loadAllSummaries() async {
    await _tail;
    return _readSummaries();
  }

  Future<Map<String, DailyHealthSummary>> _readSummaries() async {
    final data = await store.read('health_summaries');
    if (data == null) return {};
    if (data['version'] != 1 || data['summaries'] is! Map) {
      throw const FormatException('Invalid health summaries storage');
    }
    final raw = data['summaries'] as Map<String, dynamic>;
    return raw.map(
      (k, v) =>
          MapEntry(k, DailyHealthSummary.fromJson(v as Map<String, dynamic>)),
    );
  }

  Future<DailyHealthSummary> getSummaryForDate(String date) async {
    final summaries = await loadAllSummaries();
    return summaries[date] ?? DailyHealthSummary.empty(date);
  }

  Future<DailyHealthSummary> saveDailySummary(DailyHealthSummary summary) {
    final result = _tail.then((_) async {
      final summaries = await _readSummaries();
      summaries[summary.date] = summary;
      await store.write('health_summaries', {
        'version': 1,
        'summaries': summaries.map((k, v) => MapEntry(k, v.toJson())),
      });
      return summary;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  // ---------------------------------------------------------------------------
  // Sync
  // ---------------------------------------------------------------------------

  Future<DailyHealthSummary> syncHealthData(String date) async {
    final permissions = await getPermissions();
    final grantedMetrics = permissions
        .where((p) => p.status == HealthPermissionStatus.granted)
        .map((p) => p.metric)
        .toList();

    if (grantedMetrics.isEmpty) {
      final audit = SyncAuditLog(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        source: adapter.defaultSource,
        status: 'permission_denied',
        recordsImported: 0,
        details: 'No health permissions granted. Request permissions first.',
        errorMessage: 'Permissions not granted',
      );
      await _appendAuditLog(audit);
      throw StateError(
        'No health permissions granted. Please enable permissions.',
      );
    }

    try {
      final fetched = await adapter.fetchDailySummary(date, grantedMetrics);
      final current = await getSummaryForDate(date);

      // Merge fetched metrics with existing, respecting granted metrics
      final merged = current.copyWith(
        steps: grantedMetrics.contains(HealthMetricType.steps)
            ? fetched.steps
            : current.steps,
        stepSource: grantedMetrics.contains(HealthMetricType.steps)
            ? fetched.stepSource
            : current.stepSource,
        distanceKm: grantedMetrics.contains(HealthMetricType.distance)
            ? fetched.distanceKm
            : current.distanceKm,
        distanceSource: grantedMetrics.contains(HealthMetricType.distance)
            ? fetched.distanceSource
            : current.distanceSource,
        activeKcal: grantedMetrics.contains(HealthMetricType.activeEnergy)
            ? fetched.activeKcal
            : current.activeKcal,
        activeKcalSource: grantedMetrics.contains(HealthMetricType.activeEnergy)
            ? fetched.activeKcalSource
            : current.activeKcalSource,
        restingHeartRateBpm:
            grantedMetrics.contains(HealthMetricType.restingHeartRate)
            ? fetched.restingHeartRateBpm
            : current.restingHeartRateBpm,
        restingHeartRateSource:
            grantedMetrics.contains(HealthMetricType.restingHeartRate)
            ? fetched.restingHeartRateSource
            : current.restingHeartRateSource,
        sleepDurationMinutes: grantedMetrics.contains(HealthMetricType.sleep)
            ? fetched.sleepDurationMinutes
            : current.sleepDurationMinutes,
        deepSleepMinutes: grantedMetrics.contains(HealthMetricType.sleep)
            ? fetched.deepSleepMinutes
            : current.deepSleepMinutes,
        remSleepMinutes: grantedMetrics.contains(HealthMetricType.sleep)
            ? fetched.remSleepMinutes
            : current.remSleepMinutes,
        lightSleepMinutes: grantedMetrics.contains(HealthMetricType.sleep)
            ? fetched.lightSleepMinutes
            : current.lightSleepMinutes,
        sleepSource: grantedMetrics.contains(HealthMetricType.sleep)
            ? fetched.sleepSource
            : current.sleepSource,
        externalWorkoutsCount:
            grantedMetrics.contains(HealthMetricType.workouts)
            ? fetched.externalWorkoutsCount
            : current.externalWorkoutsCount,
        syncedAt: DateTime.now(),
        notes: fetched.notes,
      );

      await saveDailySummary(merged);

      final audit = SyncAuditLog(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        source: fetched.stepSource,
        status: 'success',
        recordsImported: grantedMetrics.length,
        details:
            'Synced ${merged.steps} steps, '
            '${merged.restingHeartRateBpm ?? 0} bpm resting HR, '
            '${merged.sleepDurationMinutes ?? 0}m sleep, '
            '${merged.activeKcal.toStringAsFixed(0)} active kcal.',
      );
      await _appendAuditLog(audit);

      return merged;
    } catch (e) {
      final audit = SyncAuditLog(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        source: adapter.defaultSource,
        status: 'error',
        recordsImported: 0,
        details: 'Failed to sync health data: $e',
        errorMessage: e.toString(),
      );
      await _appendAuditLog(audit);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Manual logging
  // ---------------------------------------------------------------------------

  Future<DailyHealthSummary> logManualMetric({
    required String date,
    required HealthMetricType metric,
    required double value,
    String? notes,
  }) async {
    final current = await getSummaryForDate(date);
    DailyHealthSummary updated;

    switch (metric) {
      case HealthMetricType.steps:
        final stepsVal = value.round();
        final estKm = double.parse((stepsVal * 0.00075).toStringAsFixed(2));
        updated = current.copyWith(
          steps: stepsVal,
          stepSource: HealthSource.manual,
          distanceKm: estKm,
          distanceSource: HealthSource.manual,
          notes: notes,
        );
        break;
      case HealthMetricType.distance:
        updated = current.copyWith(
          distanceKm: value,
          distanceSource: HealthSource.manual,
          notes: notes,
        );
        break;
      case HealthMetricType.activeEnergy:
        updated = current.copyWith(
          activeKcal: value,
          activeKcalSource: HealthSource.manual,
          notes: notes,
        );
        break;
      case HealthMetricType.restingHeartRate:
        updated = current.copyWith(
          restingHeartRateBpm: value.round(),
          restingHeartRateSource: HealthSource.manual,
          notes: notes,
        );
        break;
      case HealthMetricType.sleep:
        final sleepMins = value.round();
        final deep = (sleepMins * 0.2).round();
        final rem = (sleepMins * 0.25).round();
        final light = sleepMins - deep - rem;
        updated = current.copyWith(
          sleepDurationMinutes: sleepMins,
          deepSleepMinutes: deep,
          remSleepMinutes: rem,
          lightSleepMinutes: light,
          sleepSource: HealthSource.manual,
          notes: notes,
        );
        break;
      case HealthMetricType.workouts:
        updated = current.copyWith(
          externalWorkoutsCount: current.externalWorkoutsCount + value.round(),
          notes: notes,
        );
        break;
    }

    await saveDailySummary(updated);

    final audit = SyncAuditLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      source: HealthSource.manual,
      status: 'success',
      recordsImported: 1,
      details:
          'User manually recorded ${metric.label}: $value ${metric.unitLabel}',
    );
    await _appendAuditLog(audit);

    return updated;
  }

  /// Automatically updates steps and derived distance/calories from real-time hardware pedometer.
  Future<DailyHealthSummary> updateHardwareSteps({
    required String date,
    required int steps,
    DateTime? timestamp,
  }) async {
    final distance = double.parse((steps * 0.00075).toStringAsFixed(2));
    final kcal = double.parse((steps * 0.045).toStringAsFixed(1));
    final current = await getSummaryForDate(date);

    final updated = current.copyWith(
      steps: steps,
      stepSource: HealthSource.hardwarePedometer,
      distanceKm: distance,
      distanceSource: HealthSource.hardwarePedometer,
      activeKcal: kcal,
      activeKcalSource: HealthSource.hardwarePedometer,
      syncedAt: timestamp ?? DateTime.now(),
      notes: 'Continuous hardware pedometer update ($steps steps)',
    );

    await saveDailySummary(updated);
    return updated;
  }

  // ---------------------------------------------------------------------------
  // Audit logs
  // ---------------------------------------------------------------------------

  Future<List<SyncAuditLog>> getAuditLogs() async {
    await _tail;
    return _readAuditLogs();
  }

  Future<List<SyncAuditLog>> _readAuditLogs() async {
    final data = await store.read('health_audit_logs');
    if (data == null) return [];
    if (data['version'] != 1 || data['logs'] is! List) {
      throw const FormatException('Invalid health audit logs storage');
    }
    final raw = data['logs'] as List;
    return raw
        .map((e) => SyncAuditLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _appendAuditLog(SyncAuditLog log) {
    final result = _tail.then((_) async {
      final logs = await _readAuditLogs();
      logs.insert(0, log);
      // Retain max 50 recent audit logs
      final trimmed = logs.take(50).toList();
      await store.write('health_audit_logs', {
        'version': 1,
        'logs': trimmed.map((e) => e.toJson()).toList(),
      });
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}

// -----------------------------------------------------------------------------
// Riverpod Providers
// -----------------------------------------------------------------------------

final healthPlatformAdapterProvider = Provider<HealthPlatformAdapter>((ref) {
  return SimulatedHealthAdapter();
});

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final store = ref.watch(storeProvider);
  final adapter = ref.watch(healthPlatformAdapterProvider);
  return HealthRepository(store, adapter);
});

final healthPermissionsProvider =
    AsyncNotifierProvider<HealthPermissionsNotifier, List<HealthPermission>>(
      HealthPermissionsNotifier.new,
    );

class HealthPermissionsNotifier extends AsyncNotifier<List<HealthPermission>> {
  @override
  Future<List<HealthPermission>> build() async {
    final repo = ref.watch(healthRepositoryProvider);
    return repo.getPermissions();
  }

  Future<void> setPermission(
    HealthMetricType metric,
    HealthPermissionStatus status,
  ) async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(healthRepositoryProvider);
      return repo.updatePermission(metric, status);
    });
  }

  Future<void> grantAll() async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(healthRepositoryProvider);
      return repo.grantAllPermissions();
    });
  }

  Future<void> revokeAll() async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(healthRepositoryProvider);
      return repo.revokeAllPermissions();
    });
  }
}

final dailyHealthSummariesProvider =
    AsyncNotifierProvider<
      DailyHealthSummariesNotifier,
      Map<String, DailyHealthSummary>
    >(DailyHealthSummariesNotifier.new);

class DailyHealthSummariesNotifier
    extends AsyncNotifier<Map<String, DailyHealthSummary>> {
  @override
  Future<Map<String, DailyHealthSummary>> build() async {
    final repo = ref.watch(healthRepositoryProvider);
    return repo.loadAllSummaries();
  }

  Future<DailyHealthSummary> sync(String date) async {
    final repo = ref.read(healthRepositoryProvider);
    final summary = await repo.syncHealthData(date);
    ref.invalidateSelf();
    ref.invalidate(healthAuditLogsProvider);
    return summary;
  }

  Future<DailyHealthSummary> logManual({
    required String date,
    required HealthMetricType metric,
    required double value,
    String? notes,
  }) async {
    final repo = ref.read(healthRepositoryProvider);
    final summary = await repo.logManualMetric(
      date: date,
      metric: metric,
      value: value,
      notes: notes,
    );
    ref.invalidateSelf();
    ref.invalidate(healthAuditLogsProvider);
    return summary;
  }

  Future<DailyHealthSummary> updateHardwareSteps({
    required String date,
    required int steps,
    DateTime? timestamp,
  }) async {
    final repo = ref.read(healthRepositoryProvider);
    final summary = await repo.updateHardwareSteps(
      date: date,
      steps: steps,
      timestamp: timestamp,
    );
    ref.invalidateSelf();
    return summary;
  }
}

final dailyHealthSummaryProvider = Provider.family<DailyHealthSummary, String>((
  ref,
  date,
) {
  final summaries = ref.watch(dailyHealthSummariesProvider).value ?? {};
  return summaries[date] ?? DailyHealthSummary.empty(date);
});

final todayHealthSummaryProvider = Provider<DailyHealthSummary>((ref) {
  final now = DateTime.now();
  final date =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return ref.watch(dailyHealthSummaryProvider(date));
});

final healthAuditLogsProvider = FutureProvider<List<SyncAuditLog>>((ref) async {
  final repo = ref.watch(healthRepositoryProvider);
  return repo.getAuditLogs();
});
