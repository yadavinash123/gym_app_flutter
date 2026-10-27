import 'health_metric_type.dart';

/// Status of an individual health data permission.
enum HealthPermissionStatus {
  granted,
  denied,
  notDetermined,
  restricted;

  bool get isGranted => this == HealthPermissionStatus.granted;
}

/// Access mode requested for a health metric.
enum HealthAccessMode { read, write, readWrite }

/// Represents a permission request and grant record for a specific metric.
class HealthPermission {
  const HealthPermission({
    required this.metric,
    required this.mode,
    required this.status,
    this.updatedAt,
    this.notes,
  });

  final HealthMetricType metric;
  final HealthAccessMode mode;
  final HealthPermissionStatus status;
  final DateTime? updatedAt;
  final String? notes;

  bool get isGranted => status == HealthPermissionStatus.granted;

  HealthPermission copyWith({
    HealthPermissionStatus? status,
    DateTime? updatedAt,
    String? notes,
  }) {
    return HealthPermission(
      metric: metric,
      mode: mode,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'metric': metric.name,
    'mode': mode.name,
    'status': status.name,
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (notes != null) 'notes': notes,
  };

  factory HealthPermission.fromJson(Map<String, dynamic> json) {
    final metricName = json['metric'] as String? ?? 'steps';
    final metric = HealthMetricType.values.firstWhere(
      (e) => e.name == metricName,
      orElse: () => HealthMetricType.steps,
    );

    final modeName = json['mode'] as String? ?? 'read';
    final mode = HealthAccessMode.values.firstWhere(
      (e) => e.name == modeName,
      orElse: () => HealthAccessMode.read,
    );

    final statusName = json['status'] as String? ?? 'notDetermined';
    final status = HealthPermissionStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => HealthPermissionStatus.notDetermined,
    );

    return HealthPermission(
      metric: metric,
      mode: mode,
      status: status,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  static List<HealthPermission> defaultPermissions() {
    return HealthMetricType.values.map((metric) {
      return HealthPermission(
        metric: metric,
        mode: metric == HealthMetricType.workouts
            ? HealthAccessMode.readWrite
            : HealthAccessMode.read,
        status: HealthPermissionStatus.notDetermined,
      );
    }).toList();
  }
}
