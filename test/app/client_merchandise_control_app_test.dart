import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('si avvia senza backend e mostra la localizzazione spagnola', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.fromValues()),
        ],
        child: const ClientMerchandiseControlApp(locale: Locale('es')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsWidgets);
    expect(
      find.text('Backend no configurado: modo de desarrollo sin conexión.'),
      findsOneWidget,
    );
    expect(find.text('0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('usa lo spagnolo come fallback per una lingua non supportata', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.fromValues()),
        ],
        child: const ClientMerchandiseControlApp(locale: Locale('de')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsWidgets);
  });
}
