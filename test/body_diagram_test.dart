import 'dart:io';

import 'package:fitforge_ai/features/exercises/muscle_map/body_diagram_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return File(key).readAsString();
  }

  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.view(bytes.buffer);
  }
}

void main() {
  test('BodyDiagramRepository loads male and female front and back diagrams', () async {
    final repo = BodyDiagramRepository.instance;
    final bundle = TestAssetBundle();
    final diagrams = await repo.load(bundle);

    expect(diagrams.containsKey('male_front'), isTrue);
    expect(diagrams.containsKey('male_back'), isTrue);
    expect(diagrams.containsKey('female_front'), isTrue);
    expect(diagrams.containsKey('female_back'), isTrue);

    // Verify male front
    final maleFront = diagrams['male_front']!;
    expect(maleFront.muscles.containsKey('chest'), isTrue);
    expect(maleFront.muscles.containsKey('abs'), isTrue);
    expect(maleFront.muscles.containsKey('biceps'), isTrue);
    expect(maleFront.silhouette.isNotEmpty, isTrue);

    // Verify female front
    final femaleFront = diagrams['female_front']!;
    expect(femaleFront.muscles.containsKey('chest'), isTrue);
    expect(femaleFront.muscles.containsKey('abs'), isTrue);
    expect(femaleFront.silhouette.isNotEmpty, isTrue);

    // Verify female back
    final femaleBack = diagrams['female_back']!;
    expect(femaleBack.muscles.containsKey('gluteal'), isTrue);
    expect(femaleBack.muscles.containsKey('hamstring'), isTrue);
    expect(femaleBack.muscles.containsKey('upper-back'), isTrue);
  });
}
