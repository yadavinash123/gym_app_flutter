import 'package:flutter/foundation.dart';

@immutable
class BodyMeasurementEntry {
  const BodyMeasurementEntry({
    required this.id,
    required this.date, // YYYY-MM-DD
    required this.weightKg,
    this.waistCm,
    this.bodyFatPercentage,
    this.notes = '',
    DateTime? loggedAt,
  }) : loggedAt = loggedAt;

  final String id;
  final String date;
  final double weightKg;
  final double? waistCm;
  final double? bodyFatPercentage;
  final String notes;
  final DateTime? loggedAt;

  DateTime get timestamp =>
      loggedAt ?? DateTime.tryParse(date) ?? DateTime.now();

  double weightInUnits(String units) {
    if (units.toLowerCase() == 'imperial') {
      return double.parse((weightKg * 2.20462).toStringAsFixed(1));
    }
    return double.parse(weightKg.toStringAsFixed(1));
  }

  double? waistInUnits(String units) {
    if (waistCm == null) return null;
    if (units.toLowerCase() == 'imperial') {
      return double.parse((waistCm! / 2.54).toStringAsFixed(1));
    }
    return double.parse(waistCm!.toStringAsFixed(1));
  }

  static double toKg(double value, String units) {
    if (units.toLowerCase() == 'imperial') {
      return value / 2.20462;
    }
    return value;
  }

  static double toCm(double value, String units) {
    if (units.toLowerCase() == 'imperial') {
      return value * 2.54;
    }
    return value;
  }

  BodyMeasurementEntry copyWith({
    String? id,
    String? date,
    double? weightKg,
    double? waistCm,
    double? bodyFatPercentage,
    String? notes,
    DateTime? loggedAt,
  }) => BodyMeasurementEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    weightKg: weightKg ?? this.weightKg,
    waistCm: waistCm ?? this.waistCm,
    bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
    notes: notes ?? this.notes,
    loggedAt: loggedAt ?? this.loggedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'weightKg': weightKg,
    if (waistCm != null) 'waistCm': waistCm,
    if (bodyFatPercentage != null) 'bodyFatPercentage': bodyFatPercentage,
    'notes': notes,
    if (loggedAt != null) 'loggedAt': loggedAt!.toIso8601String(),
  };

  factory BodyMeasurementEntry.fromJson(Map<String, dynamic> json) =>
      BodyMeasurementEntry(
        id: json['id'] as String,
        date: json['date'] as String,
        weightKg: (json['weightKg'] as num).toDouble(),
        waistCm: (json['waistCm'] as num?)?.toDouble(),
        bodyFatPercentage: (json['bodyFatPercentage'] as num?)?.toDouble(),
        notes: json['notes'] as String? ?? '',
        loggedAt: json['loggedAt'] != null
            ? DateTime.tryParse(json['loggedAt'] as String)
            : null,
      );
}
