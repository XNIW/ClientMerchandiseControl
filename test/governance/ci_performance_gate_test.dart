import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('CI separa coverage concorrente e benchmark seriali', () {
    final workflow = File('.github/workflows/ci.yml').readAsStringSync();

    expect(
      workflow,
      contains('flutter test --coverage --exclude-tags performance'),
    );
    expect(
      workflow,
      contains('flutter test --tags performance --concurrency=1'),
    );
    expect(
      RegExp(
        r'^\s*run: flutter test --coverage\s*$',
        multiLine: true,
      ).hasMatch(workflow),
      isFalse,
      reason: 'i benchmark non devono condividere il runner concorrente',
    );
  });

  test('CI Quality conserva la history richiesta dalla governance', () {
    final workflow = File('.github/workflows/ci.yml').readAsStringSync();
    final document = loadYaml(workflow);

    expect(document, isA<YamlMap>());
    final jobs = (document as YamlMap)['jobs'];
    expect(jobs, isA<YamlMap>());
    final quality = (jobs as YamlMap)['quality'];
    expect(quality, isA<YamlMap>());
    final steps = (quality as YamlMap)['steps'];
    expect(steps, isA<YamlList>());
    final checkout = (steps as YamlList).whereType<YamlMap>().singleWhere(
      (step) => step['name'] == 'Checkout',
    );
    final checkoutWith = checkout['with'];

    expect(checkoutWith, isA<YamlMap>());
    expect((checkoutWith as YamlMap).keys, unorderedEquals(['fetch-depth']));
    expect(checkoutWith['fetch-depth'], 0);
  });
}
