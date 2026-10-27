import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'svg_path_parser.dart';

class BodyDiagramData {
  BodyDiagramData({
    required this.viewBox,
    required this.muscles,
    required this.silhouette,
  });

  final (double x, double y, double width, double height) viewBox;
  final Map<String, List<Path>> muscles;
  final List<Path> silhouette;
}

class BodyDiagramRepository {
  static BodyDiagramRepository? _instance;
  static BodyDiagramRepository get instance =>
      _instance ??= BodyDiagramRepository._();
  BodyDiagramRepository._();

  Map<String, BodyDiagramData>? _cache;

  static const inertParts = {
    'head',
    'hair',
    'neck',
    'hands',
    'knees',
    'ankles',
    'feet',
  };

  /// Mapping from openGym's 18 muscle slugs to FitForge's 11 standard muscle groups
  static const muscleNameMap = {
    'chest': 'Chest',
    'abs': 'Abdominals',
    'biceps': 'Biceps',
    'triceps': 'Triceps',
    'deltoids': 'Shoulders',
    'obliques': 'Abdominals',
    'quadriceps': 'Quadriceps',
    'calves': 'Calves',
    'adductors': 'Adductors',
    'trapezius': 'Back',
    'upper-back': 'Back',
    'lower-back': 'Back',
    'forearm': 'Forearms',
    'gluteal': 'Glutes',
    'hamstring': 'Hamstrings',
    'tibialis': 'Calves',
    'serratus': 'Chest',
    'hip-flexors': 'Abdominals',
  };

  /// Display names matching openGym's MUSCLE_NAME
  static const openGymDisplayNames = {
    'trapezius': 'Traps',
    'deltoids': 'Shoulders',
    'chest': 'Chest',
    'upper-back': 'Upper back',
    'serratus': 'Serratus',
    'biceps': 'Biceps',
    'triceps': 'Triceps',
    'forearm': 'Forearms',
    'abs': 'Abs',
    'obliques': 'Obliques',
    'lower-back': 'Lower back',
    'gluteal': 'Glutes',
    'quadriceps': 'Quads',
    'hamstring': 'Hamstrings',
    'adductors': 'Adductors',
    'hip-flexors': 'Hip flexors',
    'calves': 'Calves',
    'tibialis': 'Shins',
  };

  static String normalizeToStandard(String raw) {
    final lower = raw.toLowerCase().trim();
    return muscleNameMap[lower] ?? raw;
  }

  static String getDisplayName(String raw) {
    final lower = raw.toLowerCase().trim();
    return openGymDisplayNames[lower] ?? normalizeToStandard(raw);
  }

  static bool isMuscleMatch(String slug, Iterable<String> targets) {
    final std = normalizeToStandard(slug).toLowerCase();
    final slugLower = slug.toLowerCase();
    final display = (openGymDisplayNames[slugLower] ?? '').toLowerCase();

    for (final target in targets) {
      final t = target.toLowerCase().trim();
      if (t == std || t == slugLower || t == display) return true;
      if (std == 'abdominals' && (t == 'abs' || t == 'core' || t == 'obliques')) return true;
      if (std == 'back' && (t == 'traps' || t == 'lats' || t == 'upper back' || t == 'lower back')) return true;
      if (std == 'chest' && (t == 'pectorals' || t == 'serratus')) return true;
      if (std == 'quadriceps' && t == 'quads') return true;
      if (std == 'glutes' && t == 'gluteal') return true;
      if (std == 'calves' && (t == 'shins' || t == 'tibialis')) return true;
      if (std == 'forearms' && t == 'forearm') return true;
      if (std == 'adductors' && (t == 'quadriceps' || t == 'legs')) return true;
    }
    return false;
  }

  Future<Map<String, BodyDiagramData>> load([AssetBundle? bundle]) async {
    if (_cache != null) return _cache!;

    final effectiveBundle = bundle ?? rootBundle;
    final jsonStr = await effectiveBundle.loadString(
      'assets/exercises/body_diagram_paths.json',
    );
    final Map<String, dynamic> raw = jsonDecode(jsonStr);

    final result = <String, BodyDiagramData>{};

    for (final gender in ['male', 'female']) {
      final genderData = raw[gender] as Map<String, dynamic>?;
      if (genderData == null) continue;

      for (final view in ['front', 'back']) {
        final viewData = genderData[view] as Map<String, dynamic>?;
        if (viewData == null) continue;

        final vbStr = viewData['vb'] as String? ?? '0 0 727 1280';
        final vbParts = vbStr
            .split(' ')
            .map((s) => double.tryParse(s) ?? 0.0)
            .toList();
        final vb = (
          vbParts.isNotEmpty ? vbParts[0] : 0.0,
          vbParts.length > 1 ? vbParts[1] : 0.0,
          vbParts.length > 2 ? vbParts[2] : 727.0,
          vbParts.length > 3 ? vbParts[3] : 1280.0,
        );

        final pathsMap = viewData['p'] as Map<String, dynamic>? ?? {};
        final muscles = <String, List<Path>>{};
        final silhouette = <Path>[];

        for (final entry in pathsMap.entries) {
          final partName = entry.key.toLowerCase();
          final pathStrings = entry.value as List<dynamic>? ?? [];

          final parsedPaths = <Path>[];
          for (final pStr in pathStrings) {
            if (pStr is String && pStr.isNotEmpty) {
              parsedPaths.add(SvgPathParser.parse(pStr));
            }
          }

          if (inertParts.contains(partName)) {
            silhouette.addAll(parsedPaths);
          } else {
            muscles[partName] = parsedPaths;
          }
        }

        result['${gender}_$view'] = BodyDiagramData(
          viewBox: vb,
          muscles: muscles,
          silhouette: silhouette,
        );
      }
    }

    _cache = result;
    return result;
  }
}
