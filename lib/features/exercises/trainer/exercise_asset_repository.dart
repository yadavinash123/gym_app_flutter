import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Exercise3DAsset {
  Exercise3DAsset.fromJson(Map<String, dynamic> data)
    : exerciseId = data['exerciseId'] as String,
      path = data['path'] as String,
      label = data['label'] as String,
      license = data['license'] as String,
      clips = List<String>.unmodifiable(data['clips'] as List),
      phases = List<Map<String, dynamic>>.unmodifiable(
        (data['phases'] as List).map(
          (p) => Map<String, dynamic>.from(p as Map),
        ),
      ) {
    if (!RegExp(r'^assets/trainer/[a-z0-9-]+\.glb$').hasMatch(path) ||
        clips.isEmpty ||
        clips.any((c) => c.isEmpty) ||
        phases.isEmpty ||
        license.isEmpty) {
      throw const FormatException('Invalid 3D asset manifest');
    }
    double previous = -1;
    for (final phase in phases) {
      final at = (phase['at'] as num).toDouble();
      if (!at.isFinite ||
          at < 0 ||
          at >= 1 ||
          at <= previous ||
          phase['label'] is! String) {
        throw const FormatException('Invalid exercise phase');
      }
      previous = at;
    }
    if (phases.first['at'] != 0) {
      throw const FormatException('Missing initial phase');
    }
  }
  final String exerciseId, path, label, license;
  final List<String> clips;
  final List<Map<String, dynamic>> phases;

  Map<String, dynamic> options({
    double startTime = 0,
    bool fullscreen = false,
  }) => {
    'clips': clips,
    'phases': phases,
    'startTime': startTime,
    'fullscreen': fullscreen,
  };
}

class ExerciseAssetRepository {
  ExerciseAssetRepository({AssetBundle? bundle})
    : bundle = bundle ?? rootBundle;
  final AssetBundle bundle;
  final Map<String, Future<Uint8List>> _cache = {};

  Future<Map<String, Exercise3DAsset>> catalog() async {
    final json = jsonDecode(
      await bundle.loadString('assets/trainer/manifest.json'),
    ) as Map<String, dynamic>;
    if (json['version'] != 1) {
      throw const FormatException('Unknown 3D manifest');
    }
    final items = (json['assets'] as List)
        .map((v) => Exercise3DAsset.fromJson(v as Map<String, dynamic>))
        .toList();
    final ids = items.map((a) => a.exerciseId).toSet();
    if (ids.length != items.length) {
      throw const FormatException('Duplicate 3D exercise');
    }
    return Map.unmodifiable({for (final item in items) item.exerciseId: item});
  }

  Future<Uint8List> load(Exercise3DAsset asset) async {
    // One installed character in memory. Failed loads are never cached permanently.
    if (!_cache.containsKey(asset.path)) {
      _cache.clear();
      _cache[asset.path] = _read(asset);
    }
    try {
      return await _cache[asset.path]!;
    } catch (_) {
      _cache.remove(asset.path);
      rethrow;
    }
  }

  Future<Uint8List> _read(Exercise3DAsset asset) async {
    final bytes = await bundle.load(asset.path);
    final data = bytes.buffer.asUint8List(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    validateAnimatedGlb(data, asset.clips);
    return data;
  }
}

/// Reject static, truncated, externally dependent or mismatched files before
/// handing bytes to the renderer. The browser then checks loaded skinned meshes.
void validateAnimatedGlb(Uint8List bytes, List<String> clips) {
  if (bytes.length < 20) throw const FormatException('Truncated GLB');
  final header = ByteData.sublistView(bytes);
  if (header.getUint32(0, Endian.little) != 0x46546c67 ||
      header.getUint32(4, Endian.little) != 2 ||
      header.getUint32(8, Endian.little) != bytes.length ||
      header.getUint32(16, Endian.little) != 0x4e4f534a) {
    throw const FormatException('Invalid GLB header');
  }
  final length = header.getUint32(12, Endian.little);
  if (length > bytes.length - 20) {
    throw const FormatException('Invalid GLB JSON');
  }
  final json = jsonDecode(
    utf8.decode(bytes.sublist(20, 20 + length)),
  ) as Map<String, dynamic>;
  final animations = (json['animations'] as List?) ?? [];
  final names = animations.map((a) => a['name']).toSet();
  final skins = (json['skins'] as List?) ?? [];
  if (skins.isEmpty ||
      !clips.every(names.contains) ||
      animations.any((a) => (a['channels'] as List).isEmpty)) {
    throw const FormatException('Missing skeletal exercise animation');
  }
  for (final entry in [
    ...(json['buffers'] as List? ?? []),
    ...(json['images'] as List? ?? []),
  ]) {
    if (entry['uri'] != null) {
      throw const FormatException('External GLB resources are not allowed');
    }
  }
}

final exerciseAssetRepositoryProvider = Provider(
  (ref) => ExerciseAssetRepository(),
);
final exercise3DAssetsProvider = FutureProvider(
  (ref) => ref.watch(exerciseAssetRepositoryProvider).catalog(),
);
