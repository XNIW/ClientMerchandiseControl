import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_context_models.dart';
import 'package:client_merchandise_control/features/delivery_context/presentation/delivery_context_screen.dart';
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
    testWidgets('scelta consegna compact 200% ${locale.toLanguageTag()}', (
      tester,
    ) async {
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
            home: const DeliveryContextScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final selector = find.byType(SegmentedButton<CustomerDeliveryMode>);
      expect(
        tester
            .widget<SegmentedButton<CustomerDeliveryMode>>(selector)
            .direction,
        Axis.vertical,
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(DeliveryContextScreen)),
      );
      await tester.tap(find.text(l10n.deliveryContextPickup));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SegmentedButton<CustomerDeliveryMode>>(selector).selected,
        {CustomerDeliveryMode.pickup},
      );
    });
  }
}
