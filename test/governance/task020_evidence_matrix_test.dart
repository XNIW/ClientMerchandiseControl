import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TASK-020 registra file, comandi, CA e test con cardinalità esatte', () {
    const expectedEvidenceFiles = {
      'README.md',
      'android-google-auth-smoke.md',
      'auth-architecture.md',
      'ci-status.md',
      'commands-and-results.md',
      'environment-audit.md',
      'git-state.md',
      'ios-google-auth-smoke.md',
      'planning-summary.md',
      'review-report.md',
      'security-review.md',
      'supabase-staging-config.md',
    };
    final actualEvidenceFiles = Directory('docs/TASKS/EVIDENCE/TASK-020')
        .listSync()
        .whereType<File>()
        .map((file) {
          return file.uri.pathSegments.last;
        })
        .toSet();
    expect(actualEvidenceFiles, unorderedEquals(expectedEvidenceFiles));

    final taskLines = File(
      'docs/TASKS/TASK-020-supabase-auth-deep-link-session-lifecycle.md',
    ).readAsLinesSync();
    final evidenceLines = File(
      'docs/TASKS/EVIDENCE/TASK-020/commands-and-results.md',
    ).readAsLinesSync();

    final expectedCaTypes = _taskTypes(taskLines, 'CA-', typeColumn: 2);
    final expectedTestTypes = _taskTypes(taskLines, 'T-', typeColumn: 2);
    final caRows = _evidenceRows(evidenceLines, 'CA-');
    final testRows = _evidenceRows(evidenceLines, 'T-');
    final commandIds = evidenceLines
        .map(_columns)
        .where(
          (columns) => columns.length == 6 && columns.first.startsWith('CMD-'),
        )
        .map((columns) => columns.first)
        .toList(growable: false);

    expect(expectedCaTypes, hasLength(40));
    expect(expectedTestTypes, hasLength(38));
    expect(caRows, hasLength(40));
    expect(testRows, hasLength(38));
    expect(commandIds.toSet(), hasLength(commandIds.length));

    _expectCompleteMatrix(
      rows: caRows,
      expectedTypes: expectedCaTypes,
      prefix: 'CA-',
      count: 40,
    );
    _expectCompleteMatrix(
      rows: testRows,
      expectedTypes: expectedTestTypes,
      prefix: 'T-',
      count: 38,
    );

    final declaredCommands = commandIds.toSet();
    for (final row in [...caRows, ...testRows]) {
      for (final referencedCommand in _referencedCommands(row[3])) {
        expect(
          declaredCommands,
          contains(referencedCommand),
          reason: '${row.first} usa $referencedCommand non dichiarato',
        );
      }
    }
    expect(
      caRows.singleWhere((row) => row.first == 'CA-22')[3],
      contains('CMD-B01'),
    );
    expect(
      testRows.singleWhere((row) => row.first == 'T-26')[3],
      contains('CMD-B01'),
    );
  });
}

Map<String, String> _taskTypes(
  List<String> lines,
  String prefix, {
  required int typeColumn,
}) {
  final result = <String, String>{};
  for (final line in lines) {
    final columns = _columns(line);
    if (columns.length <= typeColumn || !columns.first.startsWith(prefix)) {
      continue;
    }
    result[columns.first] = columns[typeColumn];
  }
  return result;
}

List<List<String>> _evidenceRows(List<String> lines, String prefix) {
  return lines
      .map(_columns)
      .where(
        (columns) => columns.length == 4 && columns.first.startsWith(prefix),
      )
      .toList(growable: false);
}

List<String> _columns(String line) {
  final normalized = line.trim();
  if (!normalized.startsWith('|') || !normalized.endsWith('|')) {
    return const [];
  }
  return normalized
      .substring(1, normalized.length - 1)
      .split('|')
      .map((value) => value.trim())
      .toList(growable: false);
}

void _expectCompleteMatrix({
  required List<List<String>> rows,
  required Map<String, String> expectedTypes,
  required String prefix,
  required int count,
}) {
  const allowedStates = {'PASS', 'FAIL', 'BLOCKED', 'NOT_RUN'};
  for (var index = 1; index <= count; index++) {
    final identifier = '$prefix${index.toString().padLeft(2, '0')}';
    final matches = rows.where((row) => row.first == identifier).toList();
    expect(matches, hasLength(1), reason: '$identifier deve essere univoco');
    final row = matches.single;
    expect(
      row[1],
      expectedTypes[identifier],
      reason: '$identifier deve usare il tipo dichiarato dal task',
    );
    expect(
      allowedStates,
      contains(row[2]),
      reason: '$identifier usa uno stato non ammesso',
    );
    expect(row[3], isNotEmpty, reason: '$identifier deve avere evidence');
  }
}

Set<String> _referencedCommands(String evidence) {
  final result = <String>{};
  final references = RegExp(
    r'CMD-([A-Z]+[0-9]+(?:/[A-Z]+[0-9]+)*)',
  ).allMatches(evidence);
  for (final reference in references) {
    for (final shorthand in reference.group(1)!.split('/')) {
      result.add('CMD-$shorthand');
    }
  }
  return result;
}
