import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/customer_notifications/application/customer_notification_inbox_controller.dart';
import 'package:client_merchandise_control/features/customer_notifications/presentation/customer_notification_inbox_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/commerce_surface_fixtures.dart';

void main() {
  testWidgets('non lette reagisce alle letture senza eliminare la cache', (
    tester,
  ) async {
    final fixture = Task054VisualFixtures();
    await tester.pumpWidget(
      fixture.wrap(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CustomerNotificationInboxScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CustomerNotificationInboxScreen)),
    );
    final controller = container.read(
      customerNotificationInboxControllerProvider.notifier,
    );
    final filter = find.byKey(const ValueKey('notifications-unread-only'));
    await tester.tap(filter);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(filter).value, isTrue);
    final first = container.read(customerNotificationInboxControllerProvider);
    expect(first.visibleItems, hasLength(4));
    await controller.markRead(first.items.first.id);
    await tester.pumpAndSettle();
    expect(
      container.read(customerNotificationInboxControllerProvider).visibleItems,
      hasLength(3),
    );
    expect(
      container.read(customerNotificationInboxControllerProvider).items,
      hasLength(4),
    );
    await controller.markAllRead();
    await tester.pumpAndSettle();
    expect(
      container.read(customerNotificationInboxControllerProvider).visibleItems,
      isEmpty,
    );
    await tester.tap(filter);
    await tester.pumpAndSettle();
    expect(
      container.read(customerNotificationInboxControllerProvider).visibleItems,
      hasLength(4),
    );
    expect(fixture.inbox.markAllCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
