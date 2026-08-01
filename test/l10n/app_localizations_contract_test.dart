import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const bundlePaths = <String>[
    'lib/l10n/app_es.arb',
    'lib/l10n/app_it.arb',
    'lib/l10n/app_en.arb',
    'lib/l10n/app_zh_Hans.arb',
    'lib/l10n/app_zh.arb',
  ];

  late Map<String, Map<String, Object?>> bundles;

  setUpAll(() async {
    bundles = {
      for (final path in bundlePaths)
        path:
            jsonDecode(await File(path).readAsString()) as Map<String, Object?>,
    };
  });

  test('tutti i bundle hanno le stesse chiavi e valori non vuoti', () {
    final template = bundles[bundlePaths.first]!;
    final templateKeys = _messageKeys(template);

    for (final entry in bundles.entries) {
      expect(
        _messageKeys(entry.value),
        templateKeys,
        reason: '${entry.key} deve restare allineato al template spagnolo.',
      );
      for (final key in templateKeys) {
        expect(
          entry.value[key],
          isA<String>().having(
            (value) => value.trim(),
            '$key non vuota',
            isNotEmpty,
          ),
        );
      }
    }
  });

  test('i placeholder coincidono in tutti i locale', () {
    final template = bundles[bundlePaths.first]!;

    for (final key in _messageKeys(template)) {
      final expected = _placeholders(template[key]! as String);
      for (final entry in bundles.entries.skip(1)) {
        expect(
          _placeholders(entry.value[key]! as String),
          expected,
          reason: 'Placeholder non allineati per $key in ${entry.key}.',
        );
      }
    }
  });

  test('il bundle tecnico zh replica in modo sicuro lo spagnolo', () {
    final spanish = bundles['lib/l10n/app_es.arb']!;
    final technicalChinese = bundles['lib/l10n/app_zh.arb']!;

    for (final key in _messageKeys(spanish)) {
      expect(
        technicalChinese[key],
        spanish[key],
        reason: 'app_zh.arb deve usare il fallback spagnolo per $key.',
      );
    }
  });

  test('il template documenta ogni placeholder', () {
    final template = bundles['lib/l10n/app_es.arb']!;

    for (final key in _messageKeys(template)) {
      final placeholders = _placeholders(template[key]! as String);
      if (placeholders.isEmpty) {
        continue;
      }

      final metadata = template['@$key'];
      expect(
        metadata,
        isA<Map<String, Object?>>(),
        reason: 'Mancano i metadati del messaggio $key.',
      );
      final metadataMap = metadata! as Map<String, Object?>;
      final documented = (metadataMap['placeholders']! as Map<String, Object?>)
          .keys
          .toSet();
      expect(documented, placeholders);
    }
  });
}

Set<String> _messageKeys(Map<String, Object?> bundle) {
  return bundle.keys.where((key) => !key.startsWith('@')).toSet();
}

Set<String> _placeholders(String message) {
  return RegExp(
    r'\{([A-Za-z][A-Za-z0-9_]*)\}',
  ).allMatches(message).map((match) => match.group(1)!).toSet();
}
