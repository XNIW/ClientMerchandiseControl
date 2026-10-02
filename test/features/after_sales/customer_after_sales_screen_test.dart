import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/after_sales/presentation/customer_after_sales_screen.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_models.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/commerce_surface_fixtures.dart';

void main() {
  for (final locale in const [
    Locale('es', 'CL'),
    Locale('it'),
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ]) {
    testWidgets(
      'motivo, eleggibilità e validazione compact 200% ${locale.toLanguageTag()}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final fixtures = Task054VisualFixtures();
        await tester.pumpWidget(
          fixtures.wrap(
            MaterialApp(
              theme: AppTheme.light(),
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: const CustomerAfterSalesScreen(orderId: task054VisualOrder),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(CustomerAfterSalesScreen)),
        );
        final reason = tester
            .widget<DropdownButtonFormField<CustomerAfterSalesReason>>(
              find.byType(DropdownButtonFormField<CustomerAfterSalesReason>),
            );
        expect(reason.decoration.labelText, l10n.afterSalesReason);
        await tester.scrollUntilVisible(
          find.text('Producto sintético de prueba con descripción larga'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        final checks = tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .toList();
        expect(checks.first.onChanged, isNotNull);
        final ineligible = find.text(
          'Producto sintético sin unidades elegibles',
        );
        await tester.scrollUntilVisible(
          ineligible,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        final row = find.ancestor(
          of: ineligible,
          matching: find.byType(ListTile),
        );
        expect(
          tester
              .widget<Checkbox>(
                find.descendant(of: row, matching: find.byType(Checkbox)),
              )
              .onChanged,
          isNull,
        );
        final submit = find.byKey(const ValueKey('after-sales-submit'));
        await tester.scrollUntilVisible(
          submit,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(submit);
        await tester.pumpAndSettle();
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(fixtures.afterSales.createCalls, 0);
        expect(find.text(l10n.afterSalesSelectItem), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
