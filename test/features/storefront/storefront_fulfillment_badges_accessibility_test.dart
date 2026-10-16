import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/features/storefront/presentation/storefront_product_metadata.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in const [
    Locale('es', 'CL'),
    Locale('it'),
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('fulfillment320/200% ${locale.toLanguageTag()} dark=$dark', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark() : AppTheme.light(),
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: const Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(24),
                  child: StorefrontFulfillmentBadges(
                    fulfillment: StorefrontFulfillment(
                      pickup: true,
                      delivery: true,
                      reservation: true,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final l10n = AppLocalizations.of(
            tester.element(find.byType(StorefrontFulfillmentBadges)),
          );
          for (final label in [
            l10n.productDetailPickup,
            l10n.productDetailDelivery,
            l10n.productDetailReservation,
          ]) {
            final text = find.text(label);
            expect(text, findsOneWidget);
            expect(
              tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
              isFalse,
            );
          }
          expect(
            tester.getSemantics(find.byType(StorefrontFulfillmentBadges)).label,
            contains(l10n.productDetailDelivery),
          );
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      });
    }
  }
}
