import 'dart:async';

import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/customer_notifications/presentation/customer_notification_inbox_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:client_merchandise_control/features/customer_notifications/application/customer_notification_providers.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_models.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/commerce_surface_fixtures.dart';

void main() {
  testWidgets(
    'mark-all disabilitato in categoria loading, riabilitato dopo pagina',
    (tester) async {
      final fixture = Task054VisualFixtures();
      final repository = _DeferredCategoryRepository(fixture.inbox);
      await tester.pumpWidget(
        fixture.wrap(
          MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('es', 'CL'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const CustomerNotificationInboxScreen(),
          ),
          additionalOverrides: [
            customerNotificationRepositoryProvider.overrideWithValue(
              repository,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final action = find.byKey(const ValueKey('notifications-mark-all-read'));
      expect(tester.widget<IconButton>(action).onPressed, isNotNull);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(CustomerNotificationInboxScreen)),
      );
      await tester.tap(find.text(l10n.notificationsPayments));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<IconButton>(action).onPressed, isNull);
      await tester.tap(action);
      await tester.pump();
      expect(repository.markAllCalls, 0);
      repository.page.complete(
        await fixture.inbox.list(
          shopSlug: 'storefront-test',
          category: CustomerNotificationCategory.payment,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.widget<IconButton>(action).onPressed, isNotNull);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(repository.markAllCalls, 1);
      expect(tester.widget<IconButton>(action).onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in const [
    Locale('es', 'CL'),
    Locale('it'),
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ]) {
    testWidgets(
      'inbox titolo e azione accessibili compact 200% ${locale.toLanguageTag()}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final semantics = tester.ensureSemantics();
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
              home: const CustomerNotificationInboxScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(CustomerNotificationInboxScreen)),
        );
        final title = tester.renderObject<RenderParagraph>(
          find.text(l10n.notificationsTitle),
        );
        expect(title.size.width, greaterThan(0));
        expect(title.didExceedMaxLines, isFalse);
        expect(find.byTooltip(l10n.notificationsMarkAllRead), findsOneWidget);
        final action = find.byKey(
          const ValueKey('notifications-mark-all-read'),
        );
        final size = tester.getSize(action);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(
          tester.getSemantics(action).getSemanticsData().tooltip,
          contains(l10n.notificationsMarkAllRead),
        );
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(tester.widget<IconButton>(action).onPressed, isNull);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}

class _DeferredCategoryRepository implements CustomerNotificationRepository {
  _DeferredCategoryRepository(this.delegate);
  final CustomerNotificationRepository delegate;
  final page = Completer<CustomerNotificationPage>();
  var markAllCalls = 0;

  @override
  Future<CustomerNotificationPage> list({
    required String shopSlug,
    CustomerNotificationCategory? category,
    CustomerNotificationCursor? before,
    int pageSize = 25,
  }) => category == null
      ? delegate.list(
          shopSlug: shopSlug,
          category: category,
          before: before,
          pageSize: pageSize,
        )
      : page.future;
  @override
  Future<int> markAllRead(String shopSlug) {
    markAllCalls++;
    return delegate.markAllRead(shopSlug);
  }

  @override
  Future<DateTime> markRead(String notificationId) =>
      delegate.markRead(notificationId);
  @override
  Future<CustomerNotificationDestination> resolveRoute({
    required String shopSlug,
    required String routeToken,
  }) => delegate.resolveRoute(shopSlug: shopSlug, routeToken: routeToken);
}
