import 'health_metric_type.dart';
import 'health_source.dart';

/// Single atomic health measurement or interval recorded with source attribution.
class HealthRecord {
  const HealthRecord({
    required this.id,
    required this.metric,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.endTime,
    required this.source,
    this.notes,
    this.metadata = const {},
  });

  final String id;
  final HealthMetricType metric;
  final double value;
  final String unit;
  final DateTime timestamp;
  final DateTime? endTime;
  final HealthSource source;
  final String? notes;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
        'id': id,
        'metric': metric.name,
        'value': value,
        'unit': unit,
        'timestamp': timestamp.toIso8601String(),
        if (endTime != null) 'endTime': endTime!.toIso8601String(),
        'source': source.toJson(),
        if (notes != null) 'notes': notes,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    final metricName = json['metric'] as String? ?? 'steps';
    final metric = HealthMetricType.values.firstWhere(
      (e) => e.name == metricName,
      orElse: () => HealthMetricType.steps,
    );

    return HealthRecord(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      metric: metric,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? metric.unitLabel,
      timestamp: DateTime.parse(json['timestamp'] as String),
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime'] as String) : null,
      source: HealthSource.fromJson(json['source'] as Map<String, dynamic>? ?? {}),
      notes: json['notes'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }
}
