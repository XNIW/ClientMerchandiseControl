import 'package:client_merchandise_control/core/formatting/shop_date_time_formatter.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('valida IANA bounded e rifiuta input ignoto o ambiguo', () {
    expect(ShopDateTimeFormatter.supports('America/Santiago'), isTrue);
    expect(ShopDateTimeFormatter.supports('UTC'), isTrue);
    expect(ShopDateTimeFormatter.supports('Mars/Olympus'), isFalse);
    expect(ShopDateTimeFormatter.supports(' America/Santiago'), isFalse);
    expect(ShopDateTimeFormatter.supports('A' * 65), isFalse);
  });

  test('converte America/Santiago rispettando DST, non la timezone device', () {
    final summer = ShopDateTimeFormatter.inTimeZone(
      DateTime.utc(2026, 1, 15, 15),
      timeZone: 'America/Santiago',
    );
    final winter = ShopDateTimeFormatter.inTimeZone(
      DateTime.utc(2026, 7, 15, 15),
      timeZone: 'America/Santiago',
    );

    expect(
      (summer.hour, summer.timeZoneOffset),
      (12, const Duration(hours: -3)),
    );
    expect(
      (winter.hour, winter.timeZoneOffset),
      (11, const Duration(hours: -4)),
    );
  });

  for (final locale in const [
    Locale('es', 'CL'),
    Locale('it'),
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ]) {
    testWidgets('formatta e associa esplicitamente la zona in $locale', (
      tester,
    ) async {
      late String formatted;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              formatted = ShopDateTimeFormatter.format(
                context,
                DateTime.utc(2026, 1, 15, 15),
                timeZone: 'America/Santiago',
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(formatted, contains('12:00'));
      expect(formatted, endsWith('America/Santiago'));
    });
  }
}
