import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const muscleGroups = [
  'Chest',
  'Back',
  'Shoulders',
  'Biceps',
  'Triceps',
  'Forearms',
  'Abdominals',
  'Glutes',
  'Quadriceps',
  'Hamstrings',
  'Calves',
];

class Exercise {
  Exercise.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      group = json['group'] as String,
      primary = List<String>.unmodifiable(json['primary'] as List),
      secondary = List<String>.unmodifiable(json['secondary'] as List),
      equipment = List<String>.unmodifiable(json['equipment'] as List),
      level = json['level'] as String,
      movement = json['movement'] as String,
      steps = List<String>.unmodifiable(json['steps'] as List),
      cue = json['cue'] as String,
      mistake = json['mistake'] as String,
      source = json['source'] as String,
      url = json['url'] as String,
      animation = json['animation'] as String?,
      alternatives = List<String>.unmodifiable(json['alternatives'] as List) {
    if (!RegExp(r'^[a-z][a-z0-9-]*$').hasMatch(id) ||
        name.trim().isEmpty ||
        steps.isEmpty ||
        primary.isEmpty ||
        equipment.isEmpty ||
        [...primary, ...secondary].any((m) => !muscleGroups.contains(m)) ||
        Uri.tryParse(url)?.scheme != 'https') {
      throw const FormatException('Invalid exercise');
    }
  }
  final String id, name, group, level, movement, cue, mistake, source, url;
  final List<String> primary, secondary, equipment, steps, alternatives;
  final String? animation;

  bool matches({
    String query = '',
    String? muscle,
    String? equipmentFilter,
    String? levelFilter,
    Set<String>? favorites,
  }) {
    final haystack = [
      name,
      group,
      movement,
      ...primary,
      ...secondary,
      ...equipment,
    ].join(' ').toLowerCase();
    return query
            .toLowerCase()
            .trim()
            .split(RegExp(r'\s+'))
            .every(haystack.contains) &&
        (muscle == null ||
            primary.contains(muscle) ||
            secondary.contains(muscle)) &&
        (equipmentFilter == null || equipment.contains(equipmentFilter)) &&
        (levelFilter == null || level == levelFilter) &&
        (favorites == null || favorites.contains(id));
  }
}

Future<List<Exercise>> loadCatalog([AssetBundle? bundle]) async {
  final json = jsonDecode(
    await (bundle ?? rootBundle).loadString('assets/exercises/catalog.json'),
  ) as Map<String, dynamic>;
  if (json['version'] != 1) {
    throw const FormatException('Unknown catalog version');
  }
  final items = (json['exercises'] as List)
      .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
      .toList();
  final ids = items.map((e) => e.id).toSet();
  if (ids.length != items.length ||
      items.any(
        (e) => e.alternatives.any((id) => !ids.contains(id) || id == e.id),
      )) {
    throw const FormatException('Invalid exercise references');
  }
  return List.unmodifiable(items);
}

final exerciseCatalogProvider = FutureProvider<List<Exercise>>(
  (ref) => loadCatalog(),
);
