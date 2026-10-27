import 'health_source.dart';

/// Audit record of an external health synchronization attempt.
class SyncAuditLog {
  const SyncAuditLog({
    required this.id,
    required this.timestamp,
    required this.source,
    required this.status,
    required this.recordsImported,
    required this.details,
    this.errorMessage,
  });

  final String id;
  final DateTime timestamp;
  final HealthSource source;
  final String status; // 'success', 'error', 'permission_denied'
  final int recordsImported;
  final String details;
  final String? errorMessage;

  bool get isSuccess => status == 'success';

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'source': source.toJson(),
    'status': status,
    'recordsImported': recordsImported,
    'details': details,
    if (errorMessage != null) 'errorMessage': errorMessage,
  };

  factory SyncAuditLog.fromJson(Map<String, dynamic> json) {
    return SyncAuditLog(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: HealthSource.fromJson(
        json['source'] as Map<String, dynamic>? ?? {},
      ),
      status: json['status'] as String? ?? 'success',
      recordsImported: (json['recordsImported'] as num?)?.toInt() ?? 0,
      details: json['details'] as String? ?? '',
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
