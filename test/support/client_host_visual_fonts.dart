import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Font già presenti sulla superficie host; nessuna installazione o download.
/// Il record distingue un frame leggibile da glifi sostitutivi del renderer.
Future<void> loadClientHostVisualFonts() async {
  final root = Platform.environment['FLUTTER_ROOT']!;
  final fonts = <String, String>{
    'Roboto': '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
    'MaterialIcons':
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final path in const [
    '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',
    '/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc',
    '/usr/share/fonts/truetype/noto/NotoSansSC-Regular.ttf',
  ]) {
    if (File(path).existsSync()) {
      fonts['CmcCjkFixture'] = path;
      break;
    }
  }
  final hashes = <String, String>{};
  for (final entry in fonts.entries) {
    final bytes = await File(entry.value).readAsBytes();
    hashes[entry.key] = sha256.convert(bytes).toString();
    await (FontLoader(
      entry.key,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
  final directory = Platform.environment['CMC_CLIENT_CAPTURE_DIR'];
  if (directory != null) {
    await Directory(directory).create(recursive: true);
    await File('$directory/host-fonts.json').writeAsString(
      jsonEncode({
        'cjkAvailable': fonts.containsKey('CmcCjkFixture'),
        'sha256': hashes,
        'scope': 'widget_host_existing_fonts_not_native_platform',
      }),
    );
  }
}

ThemeData clientHostVisualTheme(ThemeData theme) => theme.copyWith(
  textTheme: theme.textTheme.apply(fontFamilyFallback: const ['CmcCjkFixture']),
  primaryTextTheme: theme.primaryTextTheme.apply(
    fontFamilyFallback: const ['CmcCjkFixture'],
  ),
);
