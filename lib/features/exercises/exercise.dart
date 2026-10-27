import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  'Full body',
];

class Exercise {
  Exercise({
    required this.id,
    required this.name,
    this.rawName = '',
    this.group = 'Full body',
    this.bodyPart = '',
    this.primary = const ['Full body'],
    this.target = '',
    this.secondary = const [],
    this.equipment = const ['Bodyweight'],
    this.rawEquipment = '',
    this.level = 'Intermediate',
    this.movement = 'Strength',
    this.category = '',
    this.description = '',
    this.instructions = const [],
    this.startingPosition = '',
    this.steps = const [],
    this.cue = '',
    this.mistake = '',
    this.source = 'FitForge',
    this.url = '',
    this.animation,
    this.hasLicensedAnimation = true,
    this.clip,
    this.still,
    this.videoUrl,
    this.stillUrl,
    this.muscleMap = const {},
    this.femaleVariant,
    this.femaleClip,
    this.femaleStill,
    this.femaleVideoUrl,
    this.femaleStillUrl,
    this.maleVariant,
    this.variantOf,
    this.alternatives = const [],
  });

  Exercise.fromJson(Map<String, dynamic> json)
    : id = (json['id'] as String).trim(),
      name = (json['name'] as String? ?? json['id'] as String).trim(),
      rawName =
          json['rawName'] as String? ??
          (json['name'] as String? ?? '').toLowerCase(),
      group =
          json['group'] as String? ??
          _capitalize(json['bodyPart'] as String? ?? 'Full body'),
      bodyPart = json['bodyPart'] as String? ?? '',
      primary = _toStringList(
        json['primary'] ??
            (json['target'] != null ? [json['target']] : ['Full body']),
      ),
      target = json['target'] as String? ?? '',
      secondary = _toStringList(json['secondary'] ?? json['secondaryMuscles']),
      equipment = _toStringList(
        json['equipment'] ??
            (json['rawEquipment'] != null
                ? [json['rawEquipment']]
                : ['Body weight']),
      ),
      rawEquipment =
          json['rawEquipment'] as String? ??
          (json['equipment'] is List && (json['equipment'] as List).isNotEmpty
              ? json['equipment'][0].toString().toLowerCase()
              : ''),
      level = json['level'] as String? ?? 'Intermediate',
      movement =
          json['movement'] as String? ??
          _capitalize(json['category'] as String? ?? 'Strength'),
      category = json['category'] as String? ?? '',
      description = json['description'] as String? ?? '',
      instructions = _toStringList(json['instructions'] ?? json['steps']),
      startingPosition =
          json['startingPosition'] as String? ??
          (_toStringList(json['instructions'] ?? json['steps']).isNotEmpty
              ? _toStringList(json['instructions'] ?? json['steps']).first
              : ''),
      steps = _toStringList(json['steps'] ?? json['instructions']),
      cue = json['cue'] as String? ?? '',
      mistake = json['mistake'] as String? ?? '',
      source = json['source'] as String? ?? 'FitForge',
      url = json['url'] as String? ?? 'https://fitforge.ai',
      animation =
          json['animation'] as String? ??
          '${(json['id'] as String).trim()}.mp4',
      hasLicensedAnimation = json['hasLicensedAnimation'] as bool? ?? true,
      clip =
          json['clip'] as String? ??
          (json['animation'] as String? ??
              '${(json['id'] as String).trim()}.mp4'),
      still =
          json['still'] as String? ?? '${(json['id'] as String).trim()}.webp',
      videoUrl =
          json['videoUrl'] as String? ??
          'https://raw.githubusercontent.com/DuarteSantos8/openGym/main/catalogue/media/clip/${json['clip'] ?? json['animation'] ?? "${(json['id'] as String).trim()}.mp4"}',
      stillUrl =
          json['stillUrl'] as String? ??
          'https://raw.githubusercontent.com/DuarteSantos8/openGym/main/catalogue/media/still/${json['still'] ?? "${(json['id'] as String).trim()}.webp"}',
      muscleMap = json['muscleMap'] is Map<String, dynamic>
          ? json['muscleMap'] as Map<String, dynamic>
          : const {},
      femaleVariant = json['femaleVariant'] as String?,
      maleVariant = json['maleVariant'] as String?,
      femaleClip = json['femaleClip'] as String?,
      femaleStill = json['femaleStill'] as String?,
      femaleVideoUrl = json['femaleVideoUrl'] as String?,
      femaleStillUrl = json['femaleStillUrl'] as String?,
      variantOf = json['variantOf'] as String?,
      alternatives = _toStringList(json['alternatives']) {
    if (id.isEmpty) {
      throw const FormatException('Invalid exercise: ID is empty');
    }
  }

  final String id;
  final String name;
  final String rawName;
  final String group;
  final String bodyPart;
  final List<String> primary;
  final String target;
  final List<String> secondary;
  final List<String> equipment;
  final String rawEquipment;
  final String level;
  final String movement;
  final String category;
  final String description;
  final List<String> instructions;
  final String startingPosition;
  final List<String> steps;
  final String cue;
  final String mistake;
  final String source;
  final String url;
  final String? animation;
  final bool hasLicensedAnimation;
  final String? clip;
  final String? still;
  final String? videoUrl;
  final String? stillUrl;
  final Map<String, dynamic> muscleMap;
  final String? femaleVariant;
  final String? femaleClip;
  final String? femaleStill;
  final String? femaleVideoUrl;
  final String? femaleStillUrl;
  final String? maleVariant;
  final String? variantOf;
  final List<String> alternatives;

  String get effectiveVideoUrl =>
      videoUrl ??
      'https://raw.githubusercontent.com/DuarteSantos8/openGym/main/catalogue/media/clip/${clip ?? "$id.mp4"}';

  String get effectiveStillUrl =>
      stillUrl ??
      'https://raw.githubusercontent.com/DuarteSantos8/openGym/main/catalogue/media/still/${still ?? "$id.webp"}';

  String get localAssetClip =>
      'assets/exercises/media/clip/${clip ?? "$id.mp4"}';
  String get localAssetStill =>
      'assets/exercises/media/still/${still ?? "$id.webp"}';

  /// Returns the HD video URL according to character figure selection (male/female)
  String videoUrlForFigure(String figure) {
    if (figure.toLowerCase() == 'female' && femaleVariant != null && femaleVariant!.isNotEmpty) {
      return femaleVideoUrl ??
          'https://raw.githubusercontent.com/DuarteSantos8/openGym/main/catalogue/media/clip/${femaleClip ?? "$femaleVariant.mp4"}';
    }
    if (figure.toLowerCase() == 'male' && maleVariant != null && maleVariant!.isNotEmpty) {
      return 'https://raw.githubusercontent.com/DuarteSantos8/openGym/main/catalogue/media/clip/$maleVariant.mp4';
    }
    return effectiveVideoUrl;
  }

  /// Returns the WebP preview image according to character figure selection (male/female)
  String stillUrlForFigure(String figure) {
    if (figure.toLowerCase() == 'female' && femaleVariant != null && femaleVariant!.isNotEmpty) {
      return femaleStillUrl ??
          'https://raw.githubusercontent.com/DuarteSantos8/openGym/main/catalogue/media/still/${femaleStill ?? "$femaleVariant.webp"}';
    }
    if (figure.toLowerCase() == 'male' && maleVariant != null && maleVariant!.isNotEmpty) {
      return 'https://raw.githubusercontent.com/DuarteSantos8/openGym/main/catalogue/media/still/$maleVariant.webp';
    }
    return effectiveStillUrl;
  }

  /// Returns the video clip filename according to character figure selection (male/female)
  String clipForFigure(String figure) {
    if (figure.toLowerCase() == 'female' && femaleVariant != null && femaleVariant!.isNotEmpty) {
      return femaleClip ?? '$femaleVariant.mp4';
    }
    if (figure.toLowerCase() == 'male' && maleVariant != null && maleVariant!.isNotEmpty) {
      return '$maleVariant.mp4';
    }
    return clip ?? '$id.mp4';
  }

  /// Returns the still image filename according to character figure selection (male/female)
  String stillForFigure(String figure) {
    if (figure.toLowerCase() == 'female' && femaleVariant != null && femaleVariant!.isNotEmpty) {
      return femaleStill ?? '$femaleVariant.webp';
    }
    if (figure.toLowerCase() == 'male' && maleVariant != null && maleVariant!.isNotEmpty) {
      return '$maleVariant.webp';
    }
    return still ?? '$id.webp';
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static List<String> _toStringList(dynamic val) {
    if (val == null) return const [];
    if (val is List) {
      return List<String>.unmodifiable(
        val
            .map((e) => _capitalize(e.toString().trim()))
            .where((e) => e.isNotEmpty),
      );
    }
    return [_capitalize(val.toString().trim())];
  }

  bool matches({
    String query = '',
    String? muscle,
    String? equipmentFilter,
    String? levelFilter,
    String? categoryFilter,
    Set<String>? favorites,
  }) {
    if (favorites != null && !favorites.contains(id)) {
      return false;
    }

    if (levelFilter != null &&
        levelFilter.isNotEmpty &&
        level.toLowerCase() != levelFilter.toLowerCase()) {
      return false;
    }

    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      final catMatch =
          category.toLowerCase() == categoryFilter.toLowerCase() ||
          movement.toLowerCase() == categoryFilter.toLowerCase();
      if (!catMatch) return false;
    }

    if (equipmentFilter != null && equipmentFilter.isNotEmpty) {
      final efLower = equipmentFilter.toLowerCase();
      final hasEq =
          equipment.any(
            (e) =>
                e.toLowerCase() == efLower || e.toLowerCase().contains(efLower),
          ) ||
          rawEquipment.toLowerCase().contains(efLower);
      if (!hasEq) return false;
    }

    if (muscle != null && muscle.isNotEmpty) {
      final mLower = muscle.toLowerCase();
      final inPrimary = primary.any(
        (m) => m.toLowerCase() == mLower || m.toLowerCase().contains(mLower),
      );
      final inSecondary = secondary.any(
        (m) => m.toLowerCase() == mLower || m.toLowerCase().contains(mLower),
      );
      final inTarget = target.toLowerCase().contains(mLower);
      final inGroup = group.toLowerCase().contains(mLower);
      final inBodyPart = bodyPart.toLowerCase().contains(mLower);
      if (!inPrimary && !inSecondary && !inTarget && !inGroup && !inBodyPart) {
        return false;
      }
    }

    if (query.isNotEmpty) {
      final terms = query
          .toLowerCase()
          .trim()
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();
      if (terms.isNotEmpty) {
        final haystack = [
          id,
          name,
          rawName,
          group,
          bodyPart,
          target,
          ...primary,
          ...secondary,
          ...equipment,
          movement,
          category,
          description,
        ].join(' ').toLowerCase();

        for (final term in terms) {
          if (!haystack.contains(term)) {
            return false;
          }
        }
      }
    }

    return true;
  }
}

List<Exercise>? _cachedCatalog;
Map<String, String> _cachedAliases = {};

/// Global read-only access to catalog variant aliases (e.g. "3053" -> "0174")
Map<String, String> get catalogAliases => Map.unmodifiable(_cachedAliases);

/// Resolves an exercise ID or alias ID (like "3053" resolving to "0174")
Exercise? findExerciseById(Iterable<Exercise> catalog, String id) {
  final trimmed = id.trim();
  final direct = catalog.where((e) => e.id == trimmed).firstOrNull;
  if (direct != null) return direct;
  final aliasTarget = _cachedAliases[trimmed];
  if (aliasTarget != null) {
    return catalog.where((e) => e.id == aliasTarget).firstOrNull;
  }
  return null;
}

List<Exercise> _parseCatalogRaw(String rawJson) {
  final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
  final rawList = decoded['exercises'] as List<dynamic>? ?? [];
  final aliasesMap = decoded['aliases'] as Map<String, dynamic>? ?? {};
  _cachedAliases = aliasesMap.map((k, v) => MapEntry(k, v.toString()));

  final items = <Exercise>[];
  for (final entry in rawList) {
    if (entry is Map<String, dynamic>) {
      items.add(Exercise.fromJson(entry));
    }
  }
  return List.unmodifiable(items);
}

Future<List<Exercise>> loadCatalog([AssetBundle? bundle]) async {
  if (_cachedCatalog != null && bundle == null) {
    return _cachedCatalog!;
  }

  final effectiveBundle = bundle ?? rootBundle;
  final jsonString = await effectiveBundle.loadString(
    'assets/exercises/catalog.json',
  );
  final result = _parseCatalogRaw(jsonString);

  if (bundle == null) {
    _cachedCatalog = result;
  }
  return result;
}

final exerciseCatalogProvider = FutureProvider<List<Exercise>>(
  (ref) => loadCatalog(),
);
