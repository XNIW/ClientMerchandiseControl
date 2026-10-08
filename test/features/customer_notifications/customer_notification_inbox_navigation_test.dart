import 'dart:async';

import 'package:client_merchandise_control/app/router/app_routes.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/customer_notifications/application/customer_notification_inbox_controller.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_failure.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_models.dart';
import 'package:client_merchandise_control/features/customer_notifications/presentation/customer_notification_inbox_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'customer_notification_screen_test_support.dart';

void main() {
  for (final destination in [
    CustomerNotificationDestinationType.order,
    CustomerNotificationDestinationType.afterSales,
    CustomerNotificationDestinationType.product,
  ]) {
    testWidgets('tap apre $destination anche con markRead lento', (
      tester,
    ) async {
      final repository = PagedInboxTestRepository(destination: destination);
      final barrier = repository.markReadBarrier = Completer<DateTime>();
      final container = inboxTestContainer(repository);
      final router = _router();
      addTearDown(container.dispose);
      addTearDown(router.dispose);
      await _pumpInbox(tester, container, router);

      await tester.tap(find.byKey(const ValueKey('notification-0')));
      await tester.pumpAndSettle();
      expect(repository.markReadCalls, 1);
      expect(barrier.isCompleted, isFalse);
      expect(find.text('destination-resource-0'), findsOneWidget);
      barrier.complete(repository.now);
      await tester.pumpAndSettle();
      expect(find.text('destination-resource-0'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(CustomerNotificationInboxScreen), findsOneWidget);
      expect(router.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  for (final transition in ['account', 'shop', 'A-B-A', 'logout']) {
    testWidgets('ACK tardivo dopo $transition non apre destinazione vecchia', (
      tester,
    ) async {
      final repository = PagedInboxTestRepository();
      final barrier = repository.markReadBarrier = Completer<DateTime>();
      final container = inboxTestContainer(repository);
      final router = _router();
      addTearDown(container.dispose);
      addTearDown(router.dispose);
      await _pumpInbox(tester, container, router);
      await tester.tap(find.byKey(const ValueKey('notification-0')));
      await tester.pumpAndSettle();
      router.go(AppRoutes.notificationsLocation);
      await tester.pumpAndSettle();

      if (transition == 'shop') {
        container.read(inboxTestShopProvider.notifier).state = 'other-test';
      } else {
        container.read(inboxTestIdentityProvider.notifier).state =
            transition == 'logout' ? null : inboxTestCustomer('owner-b');
      }
      // Riconcilia prima del prossimo frame: la UI può mantenere lo stesso
      // elemento inbox mentre una nuova sessione ha già caricato la pagina.
      container.read(customerNotificationInboxControllerProvider);
      await tester.pump();
      if (transition == 'A-B-A') {
        container.read(inboxTestIdentityProvider.notifier).state =
            inboxTestCustomer('owner-a');
        container.read(customerNotificationInboxControllerProvider);
      }
      await tester.pumpAndSettle();
      barrier.complete(repository.now);
      await tester.pumpAndSettle();

      expect(find.text('destination-resource-0'), findsNothing);
      expect(find.byType(CustomerNotificationInboxScreen), findsOneWidget);
      expect(router.canPop(), isFalse);
      final state = container.read(customerNotificationInboxControllerProvider);
      if (transition == 'logout') {
        expect(state.items, isEmpty);
      } else {
        expect(state.items.single.isUnread, isTrue);
        expect(state.unreadCount, 1);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('errore markRead tardivo non riapre la destinazione', (
    tester,
  ) async {
    final repository = PagedInboxTestRepository();
    final barrier = repository.markReadBarrier = Completer<DateTime>();
    final container = inboxTestContainer(repository);
    final router = _router();
    addTearDown(container.dispose);
    addTearDown(router.dispose);
    await _pumpInbox(tester, container, router);
    await tester.tap(find.byKey(const ValueKey('notification-0')));
    await tester.pumpAndSettle();
    router.go(AppRoutes.notificationsLocation);
    await tester.pumpAndSettle();
    barrier.completeError(
      const CustomerNotificationRepositoryException(
        CustomerNotificationFailureKind.offline,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('destination-resource-0'), findsNothing);
    expect(
      find.byKey(const ValueKey('notifications-update-failed')),
      findsOneWidget,
    );
    expect(
      container
          .read(customerNotificationInboxControllerProvider)
          .items
          .single
          .isUnread,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}

GoRouter _router() => GoRouter(
  initialLocation: AppRoutes.notificationsLocation,
  routes: [
    GoRoute(
      path: AppRoutes.notificationsLocation,
      builder: (_, _) => const CustomerNotificationInboxScreen(),
    ),
    for (final path in [
      AppRoutes.orderPattern,
      AppRoutes.afterSalesPattern,
      AppRoutes.productPattern,
    ])
      GoRoute(
        path: path,
        builder: (_, state) => Scaffold(
          body: Text('destination-${state.pathParameters.values.single}'),
        ),
      ),
  ],
);

Future<void> _pumpInbox(
  WidgetTester tester,
  ProviderContainer container,
  GoRouter router,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('es', 'CL'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
