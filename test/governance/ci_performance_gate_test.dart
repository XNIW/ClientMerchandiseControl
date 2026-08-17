import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
}
