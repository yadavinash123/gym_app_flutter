import 'package:flutter/material.dart';

/// Supported external or internal origins for health and activity data.
enum HealthSourceType {
  healthConnect,
  appleHealth,
  deviceSensor,
  fitforgeSession,
  manualEntry,
}

/// Typed representation of a health data source with provenance and metadata.
class HealthSource {
  const HealthSource({
    required this.type,
    required this.name,
    this.deviceModel,
    this.appPackage,
    this.isVerified = true,
  });

  final HealthSourceType type;
  final String name;
  final String? deviceModel;
  final String? appPackage;
  final bool isVerified;

  String get displayName {
    switch (type) {
      case HealthSourceType.healthConnect:
        return deviceModel != null
            ? 'Health Connect ($deviceModel)'
            : 'Google Health Connect';
      case HealthSourceType.appleHealth:
        return deviceModel != null
            ? 'Apple Health ($deviceModel)'
            : 'Apple Health';
      case HealthSourceType.deviceSensor:
        return 'Device Hardware Sensor';
      case HealthSourceType.fitforgeSession:
        return 'FitForge Workout Engine';
      case HealthSourceType.manualEntry:
        return 'Manual Entry (User Logged)';
    }
  }

  String get shortBadge {
    switch (type) {
      case HealthSourceType.healthConnect:
        return 'Health Connect';
      case HealthSourceType.appleHealth:
        return 'Apple Health';
      case HealthSourceType.deviceSensor:
        return 'Hardware Sensor';
      case HealthSourceType.fitforgeSession:
        return 'FitForge';
      case HealthSourceType.manualEntry:
        return 'Manual Log';
    }
  }

  IconData get icon {
    switch (type) {
      case HealthSourceType.healthConnect:
        return Icons.favorite_outline;
      case HealthSourceType.appleHealth:
        return Icons.health_and_safety_outlined;
      case HealthSourceType.deviceSensor:
        return Icons.watch_outlined;
      case HealthSourceType.fitforgeSession:
        return Icons.fitness_center;
      case HealthSourceType.manualEntry:
        return Icons.edit_note;
    }
  }

  Color get badgeColor {
    switch (type) {
      case HealthSourceType.healthConnect:
        return const Color(0xFF00D4FF);
      case HealthSourceType.appleHealth:
        return const Color(0xFFFF2D55);
      case HealthSourceType.deviceSensor:
        return const Color(0xFFFFB800);
      case HealthSourceType.fitforgeSession:
        return const Color(0xFFB6FF3B);
      case HealthSourceType.manualEntry:
        return const Color(0xFFA7B0BF);
    }
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'name': name,
    if (deviceModel != null) 'deviceModel': deviceModel,
    if (appPackage != null) 'appPackage': appPackage,
    'isVerified': isVerified,
  };

  factory HealthSource.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'manualEntry';
    final type = HealthSourceType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => HealthSourceType.manualEntry,
    );
    return HealthSource(
      type: type,
      name: json['name'] as String? ?? 'Unknown Source',
      deviceModel: json['deviceModel'] as String?,
      appPackage: json['appPackage'] as String?,
      isVerified: json['isVerified'] as bool? ?? true,
    );
  }

  static const manual = HealthSource(
    type: HealthSourceType.manualEntry,
    name: 'Manual Entry',
  );

  static const fitforge = HealthSource(
    type: HealthSourceType.fitforgeSession,
    name: 'FitForge AI Session',
  );

  static const healthConnect = HealthSource(
    type: HealthSourceType.healthConnect,
    name: 'Health Connect by Android',
    appPackage: 'com.google.android.apps.healthdata',
  );

  static const appleHealth = HealthSource(
    type: HealthSourceType.appleHealth,
    name: 'Apple HealthKit',
  );

  static const hardwarePedometer = HealthSource(
    type: HealthSourceType.deviceSensor,
    name: 'Onboard Step Counter',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthSource &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          name == other.name &&
          deviceModel == other.deviceModel;

  @override
  int get hashCode => Object.hash(type, name, deviceModel);
}
