import 'dart:convert';
import 'dart:io';

import 'package:fitforge_ai/features/exercises/muscle_map/svg_path_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses all SVG paths from body_diagram_paths.json without error', () {
    final content = File('assets/exercises/body_diagram_paths.json').readAsStringSync();
    final data = jsonDecode(content) as Map<String, dynamic>;
    int parsedCount = 0;
    final errors = <String>[];

    for (final gender in ['male', 'female']) {
      for (final view in ['front', 'back']) {
        final pMap = data[gender][view]['p'] as Map<String, dynamic>;
        for (final entry in pMap.entries) {
          for (final pStr in entry.value) {
            try {
              final path = SvgPathParser.parse(pStr as String);
              expect(path, isNotNull);
              parsedCount++;
            } catch (e) {
              errors.add('$gender $view ${entry.key}: $e\nPath: $pStr');
            }
          }
        }
      }
    }

    if (errors.isNotEmpty) {
      fail('SVG Parser failed on ${errors.length} paths:\n${errors.take(10).join("\n")}');
    }
    expect(parsedCount, greaterThan(100));
  });
}
