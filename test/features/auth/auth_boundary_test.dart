import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current;

  test('widget e presentation non importano Supabase', () {
    final presentationFiles = root
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.contains('/lib/features/') &&
              file.path.contains('/presentation/') &&
              file.path.endsWith('.dart'),
        );

    for (final file in presentationFiles) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('package:supabase')), reason: file.path);
    }
  });

  test('Auth non introduce SDK Google nativo o accessi dati', () {
    final pubspec = File('${root.path}/pubspec.yaml').readAsStringSync();
    final authSource = Directory('${root.path}/lib/features/auth')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    expect(pubspec, isNot(contains('google_sign_in:')));
    expect(authSource, isNot(contains('.from(')));
    expect(authSource, isNot(contains('.rpc(')));
    expect(authSource, isNot(contains('.storage.')));
    expect(authSource, isNot(contains('service_role')));
  });

  test('Auth e Account non registrano callback, token o oggetti SDK', () {
    final files = <File>[
      ...Directory(
        '${root.path}/lib/features/auth',
      ).listSync(recursive: true).whereType<File>(),
      File(
        '${root.path}/lib/features/account/presentation/account_screen.dart',
      ),
    ].where((file) => file.path.endsWith('.dart'));

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(
        RegExp(r'\bdebugPrint\s*\(').hasMatch(source),
        isFalse,
        reason: file.path,
      );
      expect(
        RegExp(r'(^|[^\w])print\s*\(').hasMatch(source),
        isFalse,
        reason: file.path,
      );
      expect(source, isNot(contains('NetworkImage(')), reason: file.path);
      expect(source, isNot(contains('Image.network(')), reason: file.path);
    }
  });
}
