import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/after_sales/presentation/customer_after_sales_screen.dart';
import 'package:client_merchandise_control/features/reviews/presentation/customer_reviews.dart';
import 'package:client_merchandise_control/features/customer_notifications/presentation/customer_notification_inbox_screen.dart';
import 'package:client_merchandise_control/features/delivery_context/presentation/delivery_context_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/commerce_surface_fixtures.dart';
import 'support/visual_capture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final scale in [1.0, 2.0]) {
    for (final entry in <String, Widget>{
      'assistance-form': const CustomerAfterSalesScreen(
        orderId: task054VisualOrder,
      ),
      'reviews-account': const CustomerReviewsScreen(),
      'reviews-product': const Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: StorefrontProductReviewsSection(
              publicationId: task054VisualPublication,
            ),
          ),
        ),
      ),
      'inbox': const CustomerNotificationInboxScreen(),
      'delivery-provider-off': const DeliveryContextScreen(),
    }.entries) {
      testWidgets('${entry.key} scale$scale con fixture sintetiche', (
        tester,
      ) async {
        final fixtures = Task054VisualFixtures();
        await tester.pumpWidget(
          fixtures.wrap(
            MaterialApp(
              theme: AppTheme.light(),
              locale: const Locale('es', 'CL'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: entry.value,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await captureVisual(tester, '${entry.key}-scale${scale.toInt()}');
        if (entry.key == 'delivery-provider-off') {
          final l10n = AppLocalizations.of(
            tester.element(find.byType(DeliveryContextScreen)),
          );
          await tester.tap(find.text(l10n.deliveryContextPickup));
          await tester.pumpAndSettle();
          await captureVisual(tester, 'pickup-options-scale${scale.toInt()}');
        }
        expect(tester.takeException(), isNull, reason: 'Reflow senza overflow');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }
  for (final state in [
    Task054VisualState.empty,
    Task054VisualState.error,
    Task054VisualState.loading,
  ]) {
    for (final entry in <String, Widget>{
      'assistance-list': const CustomerAfterSalesScreen(),
      'reviews-account': const CustomerReviewsScreen(),
      'reviews-product': const Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: StorefrontProductReviewsSection(
              publicationId: task054VisualPublication,
            ),
          ),
        ),
      ),
      'inbox': const CustomerNotificationInboxScreen(),
    }.entries) {
      testWidgets('${entry.key} ${state.name} sintetico', (tester) async {
        final fixture = Task054VisualFixtures(state: state);
        await tester.pumpWidget(
          fixture.wrap(
            MaterialApp(
              theme: AppTheme.light(),
              locale: const Locale('es', 'CL'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: entry.value,
            ),
          ),
        );
        final loading = state == Task054VisualState.loading;
        if (loading) {
          await tester.pump(const Duration(milliseconds: 100));
        } else {
          await tester.pumpAndSettle();
        }
        await captureVisual(
          tester,
          '${entry.key}-${state.name}',
          settle: !loading,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }
}
