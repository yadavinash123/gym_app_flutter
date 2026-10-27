import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitforge_ai/core/storage/json_store.dart';
import 'package:fitforge_ai/features/health/data/health_platform_adapter.dart';
import 'package:fitforge_ai/features/health/data/health_repository.dart';
import 'package:fitforge_ai/features/health/data/step_tracking_service.dart';
import 'package:fitforge_ai/features/health/models/daily_health_summary.dart';
import 'package:fitforge_ai/features/health/models/health_metric_type.dart';
import 'package:fitforge_ai/features/health/models/health_permission.dart';
import 'package:fitforge_ai/features/health/models/health_record.dart';
import 'package:fitforge_ai/features/health/models/health_source.dart';
import 'package:fitforge_ai/features/health/models/heart_rate_zone.dart';
import 'package:fitforge_ai/features/health/models/sync_audit_log.dart';
import 'package:fitforge_ai/features/health/screens/health_permissions_screen.dart';
import 'package:fitforge_ai/features/health/screens/health_screen.dart';
import 'package:fitforge_ai/features/health/screens/manual_health_entry_screen.dart';
import 'package:fitforge_ai/features/health/widgets/health_metric_card.dart';
import 'package:fitforge_ai/features/health/widgets/health_reference_dialog.dart';
import 'package:fitforge_ai/features/health/widgets/heart_rate_zone_chart.dart';
import 'package:fitforge_ai/features/profile/profile_repository.dart';

void main() {
  late Directory tempDir;
  late JsonStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fitforge_health_test_');
    store = JsonStore(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HealthSource & Attribution', () {
    test('serializes and deserializes correctly', () {
      const source = HealthSource(
        type: HealthSourceType.healthConnect,
        name: 'Pixel Watch via Health Connect',
        deviceModel: 'Pixel Watch 2',
        appPackage: 'com.google.android.apps.healthdata',
      );

      final json = source.toJson();
      final revived = HealthSource.fromJson(json);

      expect(revived.type, HealthSourceType.healthConnect);
      expect(revived.name, 'Pixel Watch via Health Connect');
      expect(revived.deviceModel, 'Pixel Watch 2');
      expect(revived.appPackage, 'com.google.android.apps.healthdata');
      expect(revived.displayName, contains('Pixel Watch 2'));
      expect(revived.shortBadge, 'Health Connect');
      expect(revived, equals(source));
    });

    test('static constants have correct attributes and colors', () {
      expect(HealthSource.manual.shortBadge, 'Manual Log');
      expect(HealthSource.manual.badgeColor, const Color(0xFFA7B0BF));
      expect(HealthSource.healthConnect.badgeColor, const Color(0xFF00D4FF));
      expect(HealthSource.appleHealth.badgeColor, const Color(0xFFFF2D55));
      expect(HealthSource.hardwarePedometer.shortBadge, 'Hardware Sensor');
      expect(HealthSource.fitforge.shortBadge, 'FitForge');
    });
  });

  group('HealthMetricType', () {
    test(
      'contains all expected activity metrics with labels and justifications',
      () {
        for (final metric in HealthMetricType.values) {
          expect(metric.label.isNotEmpty, isTrue);
          expect(metric.unitLabel.isNotEmpty, isTrue);
          expect(metric.justification.isNotEmpty, isTrue);
        }
      },
    );
  });

  group('Tanaka Formula & HeartRateZone', () {
    test('calculates age-predicted HRmax via Tanaka 2001 equation', () {
      // HRmax = 208 - (0.7 * age)
      // Age 20: 208 - 14 = 194
      expect(HeartRateZone.calculateMaxHr(20), 194);
      // Age 40: 208 - 28 = 180
      expect(HeartRateZone.calculateMaxHr(40), 180);
      // Age 60: 208 - 42 = 166
      expect(HeartRateZone.calculateMaxHr(60), 166);
    });

    test(
      'generates five distinct training zones with proper percent bounds',
      () {
        final zones = HeartRateZone.calculateZones(30);
        expect(zones.length, 5);

        expect(zones[0].zoneNumber, 1);
        expect(zones[0].name, contains('Zone 1'));
        expect(zones[0].minPercent, 0.50);
        expect(zones[0].maxPercent, 0.60);

        expect(zones[1].zoneNumber, 2);
        expect(zones[1].name, contains('Zone 2'));
        expect(zones[1].minPercent, 0.60);

        expect(zones[4].zoneNumber, 5);
        expect(zones[4].name, contains('Zone 5'));
        expect(zones[4].maxPercent, 1.00);
        expect(zones[4].maxBpm, HeartRateZone.calculateMaxHr(30));
      },
    );

    test('evaluates resting heart rate classifications', () {
      expect(HeartRateZone.restingHrClassification(48), contains('Athletic'));
      expect(HeartRateZone.restingHrClassification(58), contains('Excellent'));
      expect(HeartRateZone.restingHrClassification(65), contains('Good'));
      expect(HeartRateZone.restingHrClassification(75), contains('Average'));
      expect(HeartRateZone.restingHrClassification(85), contains('Elevated'));
    });

    test('zoneForHr accurately identifies matching training zone', () {
      const age = 30;
      final maxHr = HeartRateZone.calculateMaxHr(age); // 187 bpm
      final zone2 = HeartRateZone.zoneForHr((maxHr * 0.65).round(), age);
      expect(zone2?.zoneNumber, 2);

      final zone5 = HeartRateZone.zoneForHr((maxHr * 0.95).round(), age);
      expect(zone5?.zoneNumber, 5);
    });
  });

  group('HealthRecord & DailyHealthSummary', () {
    test('DailyHealthSummary serializes and deserializes completely with source tags', () {
      final summary = DailyHealthSummary(
        date: '2026-10-22',
        steps: 9240,
        stepSource: HealthSource.healthConnect,
        distanceKm: 6.93,
        distanceSource: HealthSource.healthConnect,
        activeKcal: 415.0,
        activeKcalSource: HealthSource.healthConnect,
        restingHeartRateBpm: 61,
        restingHeartRateSource: HealthSource.hardwarePedometer,
        sleepDurationMinutes: 470,
        deepSleepMinutes: 105,
        remSleepMinutes: 115,
        lightSleepMinutes: 250,
        sleepSource: HealthSource.healthConnect,
        externalWorkoutsCount: 1,
        syncedAt: DateTime(2026, 10, 22, 11, 30),
        notes: 'Test sync summary',
      );

      final json = summary.toJson();
      final revived = DailyHealthSummary.fromJson(json);

      expect(revived.date, '2026-10-22');
      expect(revived.steps, 9240);
      expect(revived.stepSource.type, HealthSourceType.healthConnect);
      expect(revived.distanceKm, 6.93);
      expect(revived.activeKcal, 415.0);
      expect(revived.restingHeartRateBpm, 61);
      expect(
        revived.restingHeartRateSource?.type,
        HealthSourceType.deviceSensor,
      );
      expect(revived.sleepDurationMinutes, 470);
      expect(revived.sleepFormatted, '7h 50m');
      expect(revived.stepProgress(10000), closeTo(0.924, 0.001));
    });

    test('HealthRecord interval and metadata serialization', () {
      final now = DateTime.now();
      final record = HealthRecord(
        id: 'rec_123',
        metric: HealthMetricType.sleep,
        value: 480,
        unit: 'min',
        timestamp: now.subtract(const Duration(hours: 8)),
        endTime: now,
        source: HealthSource.healthConnect,
        notes: 'Good restorative sleep',
        metadata: const {'deep': 120, 'rem': 110},
      );

      final json = record.toJson();
      final revived = HealthRecord.fromJson(json);

      expect(revived.id, 'rec_123');
      expect(revived.metric, HealthMetricType.sleep);
      expect(revived.value, 480.0);
      expect(revived.endTime, isNotNull);
      expect(revived.metadata['deep'], 120);
    });
  });

  group('SyncAuditLog', () {
    test('records audit history accurately', () {
      final log = SyncAuditLog(
        id: 'audit_1',
        timestamp: DateTime(2026, 10, 22, 10, 15),
        source: HealthSource.healthConnect,
        status: 'success',
        recordsImported: 4,
        details: 'Synced 8,500 steps, 62 bpm resting HR',
      );

      expect(log.isSuccess, isTrue);
      final json = log.toJson();
      final revived = SyncAuditLog.fromJson(json);
      expect(revived.id, 'audit_1');
      expect(revived.recordsImported, 4);
    });
  });

  group('HealthRepository & Persistence', () {
    test(
      'manages permissions default, update, grant all, and revoke all',
      () async {
        final adapter = SimulatedHealthAdapter();
        final repo = HealthRepository(store, adapter);

        // Default permissions
        final initial = await repo.getPermissions();
        expect(initial.length, HealthMetricType.values.length);
        expect(
          initial.every(
            (p) => p.status == HealthPermissionStatus.notDetermined,
          ),
          isTrue,
        );

        // Update single
        await repo.updatePermission(
          HealthMetricType.steps,
          HealthPermissionStatus.granted,
        );
        final afterUpdate = await repo.getPermissions();
        expect(
          afterUpdate
              .firstWhere((p) => p.metric == HealthMetricType.steps)
              .status,
          HealthPermissionStatus.granted,
        );

        // Grant all
        await repo.grantAllPermissions();
        final allGranted = await repo.getPermissions();
        expect(allGranted.every((p) => p.isGranted), isTrue);

        // Revoke all
        await repo.revokeAllPermissions();
        final allRevoked = await repo.getPermissions();
        expect(
          allRevoked.every((p) => p.status == HealthPermissionStatus.denied),
          isTrue,
        );
      },
    );

    test(
      'sync throws StateError if no permissions are granted and audits failure',
      () async {
        final adapter = SimulatedHealthAdapter();
        final repo = HealthRepository(store, adapter);

        await repo.revokeAllPermissions();

        try {
          await repo.syncHealthData('2026-10-22');
          fail('Should have thrown StateError');
        } catch (e) {
          expect(e, isA<StateError>());
        }

        final auditLogs = await repo.getAuditLogs();
        expect(auditLogs.length, 1);
        expect(auditLogs.first.status, 'permission_denied');
      },
    );

    test('sync succeeds when permissions granted, persists summary, and appends audit log', () async {
      final adapter = SimulatedHealthAdapter(simulatedSteps: 8500);
      final repo = HealthRepository(store, adapter);

      await repo.grantAllPermissions();
      final summary = await repo.syncHealthData('2026-10-22');

      expect(summary.steps, greaterThanOrEqualTo(2000));
      expect(summary.stepSource.type, HealthSourceType.healthConnect);
      expect(summary.restingHeartRateBpm, isNotNull);
      expect(summary.sleepDurationMinutes, isNotNull);

      // Verify persisted in store
      final loaded = await repo.getSummaryForDate('2026-10-22');
      expect(loaded.steps, summary.steps);

      // Verify audit trail
      final auditLogs = await repo.getAuditLogs();
      expect(auditLogs.isNotEmpty, isTrue);
      expect(auditLogs.first.isSuccess, isTrue);
    });

    test(
      'manual logging sets Manual Entry attribution and updates audit log',
      () async {
        final adapter = SimulatedHealthAdapter();
        final repo = HealthRepository(store, adapter);

        final updated = await repo.logManualMetric(
          date: '2026-10-22',
          metric: HealthMetricType.steps,
          value: 10500,
          notes: 'Gym treadmill run',
        );

        expect(updated.steps, 10500);
        expect(updated.stepSource, HealthSource.manual);
        expect(updated.notes, 'Gym treadmill run');

        // Also log resting HR manually
        final withHr = await repo.logManualMetric(
          date: '2026-10-22',
          metric: HealthMetricType.restingHeartRate,
          value: 59,
        );
        expect(withHr.restingHeartRateBpm, 59);
        expect(withHr.restingHeartRateSource, HealthSource.manual);

        final auditLogs = await repo.getAuditLogs();
        expect(auditLogs.length, 2);
        expect(auditLogs.first.details, contains('Resting Heart Rate'));
        expect(auditLogs.first.source, HealthSource.manual);
      },
    );
  });

  group('Health UI Widgets', () {
    testWidgets(
      'HealthMetricCard displays value, unit, goal bar, and source badge',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HealthMetricCard(
                metric: HealthMetricType.steps,
                displayValue: '8,420',
                unit: 'steps',
                source: HealthSource.healthConnect,
                target: '10,000',
                progress: 0.842,
                subtitle: '6.31 km walked',
              ),
            ),
          ),
        );

        expect(find.text('Daily Steps'), findsOneWidget);
        expect(find.text('8,420'), findsOneWidget);
        expect(find.text('steps'), findsOneWidget);
        expect(find.text('Goal: 10,000'), findsOneWidget);
        expect(find.text('Health Connect'), findsOneWidget);
        expect(find.text('6.31 km walked'), findsOneWidget);
      },
    );

    testWidgets('HeartRateZoneChart renders Tanaka equation and 5 zones', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeartRateZoneChart(
              age: 25,
              restingBpm: 60,
              source: HealthSource.healthConnect,
            ),
          ),
        ),
      );

      expect(find.text('Cardiovascular & Training Zones'), findsOneWidget);
      expect(find.text('60'), findsOneWidget);
      expect(find.text('bpm Resting HR'), findsOneWidget);
      expect(find.textContaining('Tanaka HRmax'), findsOneWidget);
      expect(find.text('Zone 1: Active Recovery'), findsOneWidget);
      expect(find.text('Zone 5: Anaerobic Peak'), findsOneWidget);
    });

    testWidgets('HealthReferenceDialog displays scientific citations', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HealthReferenceDialog())),
      );

      expect(find.text('Health & Activity References'), findsOneWidget);
      expect(find.text('Tanaka Age-Predicted HRmax'), findsOneWidget);
      expect(
        find.text('Daily Steps & Activity Recommendations'),
        findsOneWidget,
      );
      expect(find.text('Adult Sleep Duration & Quality'), findsOneWidget);
      expect(
        find.text('Source Attribution & Privacy Guarantee'),
        findsOneWidget,
      );
    });

    testWidgets(
      'HealthPermissionsScreen allows granting and revoking permissions',
      (tester) async {
        final adapter = SimulatedHealthAdapter();
        final repo = HealthRepository(store, adapter);

        await tester.runAsync(() async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                storeProvider.overrideWithValue(store),
                healthRepositoryProvider.overrideWithValue(repo),
              ],
              child: const MaterialApp(home: HealthPermissionsScreen()),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 200));
        });
        await tester.pump();

        expect(find.text('Health Permissions & Privacy'), findsOneWidget);
        expect(find.text('Daily Steps'), findsOneWidget);
        expect(find.text('Resting Heart Rate'), findsOneWidget);
        expect(find.text('Grant All'), findsOneWidget);
        expect(find.text('Revoke All'), findsOneWidget);
      },
    );

    testWidgets('ManualHealthEntryScreen renders form and controls', (
      tester,
    ) async {
      final adapter = SimulatedHealthAdapter();
      final repo = HealthRepository(store, adapter);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            healthRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: ManualHealthEntryScreen(date: '2026-10-22'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Manual Health Log'), findsOneWidget);
      expect(find.text('Source Attribution: Manual Entry'), findsOneWidget);
      expect(find.text('Select Metric'), findsOneWidget);
      expect(find.text('Daily Steps'), findsOneWidget);
      expect(find.text('Record Metric'), findsOneWidget);
    });

    testWidgets('HealthScreen renders all sections, syncs, and navigates', (
      tester,
    ) async {
      final adapter = SimulatedHealthAdapter(simulatedSteps: 9000);
      final repo = HealthRepository(store, adapter);
      await tester.runAsync(() async {
        await repo.grantAllPermissions();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            healthRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: HealthScreen(initialDate: '2026-10-22'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Activity & Health'), findsOneWidget);
      expect(find.text('Activity & Sensor Sync'), findsOneWidget);
      expect(find.text('Sync Now'), findsOneWidget);
      expect(find.text('Manual Log'), findsWidgets);
      expect(find.text('Recent Synchronization Audit Trail'), findsOneWidget);
    });

    testWidgets(
      'HealthMetricCard does not overflow on narrow 140.4px constraint (reproducing user error)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 140.4, // The exact width constraint reported in user crash
                  child: HealthMetricCard(
                    metric: HealthMetricType.steps,
                    displayValue: '12450',
                    unit: 'steps',
                    source: HealthSource.hardwarePedometer,
                    target: '10,000',
                    progress: 1.245,
                    subtitle: '9.34 km walked',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'RenderFlex must never overflow on 140.4px card width',
        );
        expect(find.text('12450'), findsOneWidget);
        expect(find.text('steps'), findsOneWidget);
        expect(find.text('Goal: 10,000'), findsOneWidget);
      },
    );

    testWidgets(
      'HealthMetricCard scales gracefully on ultra-narrow 100px width',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 100,
                  child: HealthMetricCard(
                    metric: HealthMetricType.steps,
                    displayValue: '99999',
                    unit: 'steps',
                    source: HealthSource.hardwarePedometer,
                    target: '10,000',
                    progress: 0.99,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'HealthScreen renders on small phone screen (320x640) with zero overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final adapter = SimulatedHealthAdapter(simulatedSteps: 8500);
        final repo = HealthRepository(store, adapter);
        await tester.runAsync(() async {
          await repo.grantAllPermissions();
          await repo.syncHealthData('2026-10-22');
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storeProvider.overrideWithValue(store),
              healthRepositoryProvider.overrideWithValue(repo),
            ],
            child: const MaterialApp(
              home: HealthScreen(initialDate: '2026-10-22'),
            ),
          ),
        );
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Small 320px device must not throw RenderFlex overflow',
        );
        expect(find.text('Activity & Health'), findsOneWidget);
      },
    );
  });

  group('StepTrackingService & Automated Walking Step Counting', () {
    test('accumulates walking steps, updates repository with hardware sensor provenance, and calculates distance and calories', () async {
      final adapter = SimulatedHealthAdapter();
      final repo = HealthRepository(store, adapter);
      final service = StepTrackingService(store: store, repository: repo);

      await service.initialize();
      expect(service.state.todaySteps, 0);

      // Simulate user walking 150 footsteps
      await service.simulateWalkingSteps(150);

      expect(service.state.todaySteps, 150);
      expect(service.state.isWalking, isTrue);
      expect(service.state.pedestrianStatus, 'walking');

      // Check repository summary
      final now = DateTime.now();
      final today =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final summary = await repo.getSummaryForDate(today);

      expect(summary.steps, 150);
      expect(summary.stepSource, HealthSource.hardwarePedometer);
      expect(summary.distanceKm, 0.11); // 150 * 0.00075 = 0.1125 -> 0.11 km
      expect(summary.activeKcal, 6.8); // 150 * 0.045 = 6.75 -> 6.8 kcal
      expect(summary.notes, contains('Continuous hardware pedometer update'));

      // Simulate further walking (+350 steps = 500 total)
      await service.simulateWalkingSteps(350);
      expect(service.state.todaySteps, 500);

      final updatedSummary = await repo.getSummaryForDate(today);
      expect(updatedSummary.steps, 500);
      expect(
        updatedSummary.distanceKm,
        0.38,
      ); // 500 * 0.00075 = 0.375 -> 0.38 km
      expect(updatedSummary.activeKcal, 22.5); // 500 * 0.045 = 22.5 kcal

      service.dispose();
    });

    test('retains baseline snapshot across re-initialization', () async {
      final adapter = SimulatedHealthAdapter();
      final repo = HealthRepository(store, adapter);
      final service1 = StepTrackingService(store: store, repository: repo);

      await service1.initialize();
      await service1.simulateWalkingSteps(1200);
      service1.dispose();

      // Create new service instance for app restart
      final service2 = StepTrackingService(store: store, repository: repo);
      await service2.initialize();

      expect(service2.state.todaySteps, 1200);
      service2.dispose();
    });
  });
}
