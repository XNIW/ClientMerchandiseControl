import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/reviews/presentation/customer_reviews.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/commerce_surface_fixtures.dart';

void main() {
  for (final locale in const [
    Locale('es', 'CL'),
    Locale('it'),
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ]) {
    for (final orderCard in [false, true]) {
      testWidgets(
        'prodotto eleggibile CTA sotto dettagli order=$orderCard ${locale.toLanguageTag()}',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 568));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            Task054VisualFixtures().wrap(
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
                home: orderCard
                    ? const Scaffold(
                        body: SingleChildScrollView(
                          child: CustomerOrderReviewsCard(
                            orderId: task054VisualOrder,
                          ),
                        ),
                      )
                    : const CustomerReviewsScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final title = find.text(
            'Producto sintético de prueba con descripción larga',
          );
          final titleRect = tester.getRect(title);
          final l10n = AppLocalizations.of(tester.element(title));
          final button = find.ancestor(
            of: find.text(l10n.reviewsLeave),
            matching: find.byWidgetPredicate(
              (widget) => widget is ButtonStyleButton,
            ),
          );
          expect(
            tester.getRect(button).top,
            greaterThanOrEqualTo(titleRect.bottom),
            reason: 'La CTA lascia tutta la riga al nome lungo',
          );
          expect(
            tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
            isFalse,
          );
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
