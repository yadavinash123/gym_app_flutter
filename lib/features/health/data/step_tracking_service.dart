import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';

import '../../../core/storage/json_store.dart';
import '../../profile/profile_repository.dart';
import 'health_repository.dart';

/// State of continuous step counting and walking activity.
class StepTrackingState {
  const StepTrackingState({
    this.isTracking = false,
    this.isWalking = false,
    this.pedestrianStatus = 'stationary',
    this.todaySteps = 0,
    this.hasHardwareSensor = true,
    this.errorMessage,
    this.lastUpdated,
  });

  final bool isTracking;
  final bool isWalking;
  final String pedestrianStatus;
  final int todaySteps;
  final bool hasHardwareSensor;
  final String? errorMessage;
  final DateTime? lastUpdated;

  StepTrackingState copyWith({
    bool? isTracking,
    bool? isWalking,
    String? pedestrianStatus,
    int? todaySteps,
    bool? hasHardwareSensor,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return StepTrackingState(
      isTracking: isTracking ?? this.isTracking,
      isWalking: isWalking ?? this.isWalking,
      pedestrianStatus: pedestrianStatus ?? this.pedestrianStatus,
      todaySteps: todaySteps ?? this.todaySteps,
      hasHardwareSensor: hasHardwareSensor ?? this.hasHardwareSensor,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Continuous automated step tracking service that interfaces directly with
/// hardware pedometer and pedestrian status sensors without requiring manual logging.
class StepTrackingService {
  StepTrackingService({
    required this.store,
    required this.repository,
    this.customStepStream,
    this.customStatusStream,
  });

  final JsonStore store;
  final HealthRepository repository;
  final Stream<StepCount>? customStepStream;
  final Stream<PedestrianStatus>? customStatusStream;

  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;

  final _stateController = StreamController<StepTrackingState>.broadcast();
  Stream<StepTrackingState> get stateStream => _stateController.stream;

  StepTrackingState _state = const StepTrackingState();
  StepTrackingState get state => _state;

  String? _baselineDate;
  int? _bootBaseSteps;
  int _todayAccumulated = 0;

  static const String _storageKey = 'hardware_step_baseline';

  String _currentDateIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Initialize stored baseline state from local private JsonStore.
  Future<void> initialize() async {
    try {
      final data = await store.read(_storageKey);
      final today = _currentDateIso();
      if (data != null && data['version'] == 1 && data['date'] == today) {
        _baselineDate = data['date'] as String?;
        _bootBaseSteps = data['bootBaseSteps'] as int?;
        _todayAccumulated = (data['todayAccumulated'] as int?) ?? 0;
        _emitState(_state.copyWith(todaySteps: _todayAccumulated));
      } else {
        _baselineDate = today;
        _bootBaseSteps = null;
        _todayAccumulated = 0;
      }
    } catch (e) {
      debugPrint('Error initializing StepTrackingService: $e');
    }
  }

  /// Start automatic continuous step counting.
  Future<void> startTracking() async {
    if (_state.isTracking) return;

    await initialize();

    _emitState(_state.copyWith(
      isTracking: true,
      errorMessage: null,
    ));

    // Listen to pedometer step counter stream
    try {
      final stepStream = customStepStream ?? Pedometer.stepCountStream;
      _stepSubscription = stepStream.listen(
        _onStepCount,
        onError: _onStepError,
        cancelOnError: false,
      );
    } catch (e) {
      _onStepError(e);
    }

    // Listen to pedestrian status stream (walking / stopped)
    try {
      final statusStream = customStatusStream ?? Pedometer.pedestrianStatusStream;
      _statusSubscription = statusStream.listen(
        _onPedestrianStatus,
        onError: (e) {
          debugPrint('Pedestrian status stream error: $e');
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Unable to bind pedestrian status stream: $e');
    }
  }

  void _onStepCount(StepCount event) async {
    final today = _currentDateIso();
    final sensorSteps = event.steps;

    // Day rollover detection
    if (_baselineDate != today || _bootBaseSteps == null) {
      _baselineDate = today;
      _bootBaseSteps = sensorSteps;
      _todayAccumulated = 0;
    } else if (sensorSteps < _bootBaseSteps!) {
      // Device rebooted during the day, reset baseline to current sensor reading
      _bootBaseSteps = sensorSteps;
    }

    final incremental = sensorSteps - _bootBaseSteps!;
    final effectiveToday = incremental > 0 ? incremental : 0;
    if (effectiveToday >= _todayAccumulated) {
      _todayAccumulated = effectiveToday;
    }

    _emitState(_state.copyWith(
      todaySteps: _todayAccumulated,
      hasHardwareSensor: true,
      lastUpdated: event.timeStamp,
    ));

    // Persist baseline snapshot
    await store.write(_storageKey, {
      'version': 1,
      'date': today,
      'bootBaseSteps': _bootBaseSteps,
      'todayAccumulated': _todayAccumulated,
      'lastSensorReading': sensorSteps,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Automatically update today's health summary in the repository
    try {
      await repository.updateHardwareSteps(
        date: today,
        steps: _todayAccumulated,
        timestamp: event.timeStamp,
      );
    } catch (e) {
      debugPrint('Error syncing automated steps to repository: $e');
    }
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    final status = event.status.toLowerCase();
    final isWalking = status == 'walking';

    _emitState(_state.copyWith(
      isWalking: isWalking,
      pedestrianStatus: status,
      lastUpdated: event.timeStamp,
    ));
  }

  void _onStepError(dynamic error) {
    debugPrint('Hardware pedometer unavailable or error: $error');
    _emitState(_state.copyWith(
      hasHardwareSensor: false,
      errorMessage: error.toString(),
    ));
  }

  /// Simulate footsteps when walking on emulators, desktop, or automated test runners.
  Future<void> simulateWalkingSteps(int count) async {
    final today = _currentDateIso();
    _todayAccumulated += count;
    final now = DateTime.now();

    _emitState(_state.copyWith(
      todaySteps: _todayAccumulated,
      isWalking: true,
      pedestrianStatus: 'walking',
      lastUpdated: now,
    ));

    await store.write(_storageKey, {
      'version': 1,
      'date': today,
      'bootBaseSteps': _bootBaseSteps ?? 0,
      'todayAccumulated': _todayAccumulated,
      'lastSensorReading': _todayAccumulated,
      'updatedAt': now.toIso8601String(),
    });

    await repository.updateHardwareSteps(
      date: today,
      steps: _todayAccumulated,
      timestamp: now,
    );

    // Reset walking indicator after a brief period
    Future.delayed(const Duration(seconds: 4), () {
      if (_state.isTracking) {
        _emitState(_state.copyWith(
          isWalking: false,
          pedestrianStatus: 'stopped',
        ));
      }
    });
  }

  void _emitState(StepTrackingState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  /// Stop tracking and cancel streams.
  Future<void> stopTracking() async {
    await _stepSubscription?.cancel();
    _stepSubscription = null;
    await _statusSubscription?.cancel();
    _statusSubscription = null;
    _emitState(_state.copyWith(
      isTracking: false,
      isWalking: false,
      pedestrianStatus: 'stopped',
    ));
  }

  void dispose() {
    stopTracking();
    _stateController.close();
  }
}

// -----------------------------------------------------------------------------
// Riverpod Providers for Real-Time Step Tracking
// -----------------------------------------------------------------------------

final stepTrackingServiceProvider = Provider<StepTrackingService>((ref) {
  final store = ref.watch(storeProvider);
  final repo = ref.watch(healthRepositoryProvider);

  final service = StepTrackingService(
    store: store,
    repository: repo,
  );

  // Automatically start continuous hardware step tracking when provider mounts
  service.startTracking();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

final stepTrackingStateProvider =
    StreamProvider<StepTrackingState>((ref) {
  final service = ref.watch(stepTrackingServiceProvider);
  return service.stateStream;
});

final isWalkingNowProvider = Provider<bool>((ref) {
  final state = ref.watch(stepTrackingStateProvider).value;
  return state?.isWalking ?? false;
});
