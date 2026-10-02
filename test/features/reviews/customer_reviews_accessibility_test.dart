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
    testWidgets('recensioni pubbliche compact 200% ${locale.toLanguageTag()}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();

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
            home: const Scaffold(
              body: SingleChildScrollView(
                child: StorefrontProductReviewsSection(
                  publicationId: task054VisualPublication,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(StorefrontProductReviewsSection)),
      );
      expect(find.text(l10n.reviewsCount(24)), findsOneWidget);
      expect(find.text(l10n.reviewsVerified), findsOneWidget);
      expect(
        tester
            .renderObject<RenderParagraph>(find.text(l10n.reviewsVerified))
            .didExceedMaxLines,
        isFalse,
        reason: 'Badge leggibile per intero',
      );
      final cardRight = tester
          .getRect(find.byKey(const ValueKey('product-reviews')))
          .right;
      expect(
        tester.getRect(find.text(l10n.reviewsVerified)).right,
        lessThanOrEqualTo(cardRight),
      );
      await tester.ensureVisible(find.text(l10n.reviewsVerified));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(l10n.reviewsRating))),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
