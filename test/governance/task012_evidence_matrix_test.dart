import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TASK-012 registra una riga univoca per ogni CA e test case', () {
    final evidence = File(
      'docs/TASKS/EVIDENCE/TASK-012/execution-evidence.md',
    ).readAsLinesSync();

    final caRows = evidence
        .where((line) => RegExp(r'^\| CA-\d{2}(?: |–)').hasMatch(line))
        .toList();
    final testRows = evidence
        .where((line) => RegExp(r'^\| T-\d{2}(?: |–)').hasMatch(line))
        .toList();

    expect(caRows, hasLength(39));
    expect(testRows, hasLength(34));

    for (var index = 1; index <= 39; index++) {
      final identifier = 'CA-${index.toString().padLeft(2, '0')}';
      expect(
        caRows.where((row) => row.startsWith('| $identifier |')),
        hasLength(1),
        reason: '$identifier deve avere una sola riga evidence',
      );
    }

    for (var index = 1; index <= 34; index++) {
      final identifier = 'T-${index.toString().padLeft(2, '0')}';
      expect(
        testRows.where((row) => row.startsWith('| $identifier |')),
        hasLength(1),
        reason: '$identifier deve avere una sola riga evidence',
      );
    }

    final allowedOutcomeRow = RegExp(
      r'^\| (?:CA|T)-\d{2} \| (?:PASS|FAIL|NOT_RUN|BLOCKED) \| .+ \|$',
    );
    expect([...caRows, ...testRows], everyElement(matches(allowedOutcomeRow)));
  });
}
