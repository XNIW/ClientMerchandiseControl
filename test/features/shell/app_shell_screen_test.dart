import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp() {
    return ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(AppConfig.fromValues())],
      child: const ClientMerchandiseControlApp(locale: Locale('es')),
    );
  }

  testWidgets('presenta le quattro destinazioni localizzate', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Carrito'), findsOneWidget);
    expect(find.text('Cuenta'), findsOneWidget);
  });

  testWidgets('naviga tra catalogo e account mantenendo la shell', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-catalog')));
    await tester.pumpAndSettle();
    expect(find.text('Catálogo'), findsWidgets);
    expect(
      find.text(
        'El catálogo todavía no está conectado. '
        'Aquí se mostrarán solo productos publicados.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('nav-account')));
    await tester.pumpAndSettle();
    expect(find.text('Cuenta'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
