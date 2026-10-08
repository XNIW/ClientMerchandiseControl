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
    expect(
      (checkoutWith as YamlMap).keys,
      unorderedEquals(['ref', 'fetch-depth']),
    );
    expect(
      checkoutWith['ref'],
      r'${{ github.event.pull_request.head.sha || github.sha }}',
    );
    expect(checkoutWith['fetch-depth'], 0);
  });

  test('tutti i job CI verificano il commit esatto del candidato', () {
    final document =
        loadYaml(File('.github/workflows/ci.yml').readAsStringSync())
            as YamlMap;
    final jobs = document['jobs'] as YamlMap;

    expect(jobs.length, 6);
    for (final entry in jobs.entries) {
      final steps = (entry.value as YamlMap)['steps'] as YamlList;
      final checkout = steps.whereType<YamlMap>().singleWhere(
        (step) => step['name'] == 'Checkout',
      );
      final inputs = checkout['with'] as YamlMap;

      expect(
        inputs.keys,
        unorderedEquals(
          entry.key == 'quality' ? ['ref', 'fetch-depth'] : ['ref'],
        ),
        reason: 'input checkout non previsti nel job ${entry.key}',
      );
      expect(
        inputs['ref'],
        r'${{ github.event.pull_request.head.sha || github.sha }}',
        reason: 'il job ${entry.key} deve verificare lo stesso candidato',
      );
    }
  });
}
