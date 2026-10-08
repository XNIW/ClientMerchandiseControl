import 'dart:async';

import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/customer_notifications/application/customer_notification_inbox_controller.dart';
import 'package:client_merchandise_control/features/customer_notifications/application/customer_notification_providers.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_failure.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_models.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_repository.dart';
import 'package:client_merchandise_control/features/customer_notifications/presentation/customer_notification_inbox_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/commerce_surface_fixtures.dart';

void main() {
  for (final locale in const [
    Locale('es', 'CL'),
    Locale('it'),
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ]) {
    testWidgets('non lette vuote con altre pagine ${locale.toLanguageTag()}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _PagedInbox();
      final fixture = Task054VisualFixtures();
      await _mount(tester, fixture, repository, locale: locale);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(CustomerNotificationInboxScreen)),
      );
      await tester.tap(find.byKey(const ValueKey('notifications-unread-only')));
      await tester.pumpAndSettle();
      // Il server dichiara una non letta in una pagina ancora da caricare.
      expect(find.text(l10n.notificationsEmptyTitle), findsNothing);
      expect(
        find.text(l10n.notificationsUnreadPartialEmptyTitle),
        findsOneWidget,
      );
      expect(find.text(l10n.notificationsUnreadPageHint), findsOneWidget);
      final more = find.byKey(const ValueKey('notifications-load-more'));
      await tester.scrollUntilVisible(
        more,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(more), alignment: 0.5);
      await tester.pumpAndSettle();
      expect(more.hitTestable(), findsOneWidget);
      await tester.tap(more);
      await tester.pump();
      expect(repository.cursors, hasLength(1));
      expect(repository.cursors.single?.id, 'read-first');
      expect(tester.widget<OutlinedButton>(more).onPressed, isNull);
      repository.next.complete(repository.olderPage);
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CustomerNotificationInboxScreen)),
      );
      final state = container.read(customerNotificationInboxControllerProvider);
      expect(state.visibleItems.single.id, 'unread-older');
      expect(state.items.map((item) => item.id), [
        'read-first',
        'unread-older',
      ]);
      expect(state.hasMore, isFalse);
      expect(fixture.notificationCache.items, hasLength(2));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('notifications-unread-only')),
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const ValueKey('notifications-unread-only'))),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('notifications-unread-only')));
      await tester.pumpAndSettle();
      expect(
        container
            .read(customerNotificationInboxControllerProvider)
            .visibleItems,
        hasLength(2),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('non lette esaurite distingue filtro da inbox senza notifiche', (
    tester,
  ) async {
    final fixture = Task054VisualFixtures();
    fixture.inbox.read = true;
    await _mount(tester, fixture, fixture.inbox);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CustomerNotificationInboxScreen)),
    );
    await tester.tap(find.byKey(const ValueKey('notifications-unread-only')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.notificationsEmptyTitle), findsNothing);
    expect(find.text(l10n.notificationsUnreadEmptyTitle), findsOneWidget);
    expect(find.text(l10n.notificationsUnreadEmptyMessage), findsOneWidget);
    expect(find.byKey(const ValueKey('notifications-load-more')), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CustomerNotificationInboxScreen)),
    );
    expect(
      container.read(customerNotificationInboxControllerProvider).items,
      hasLength(4),
    );
  });

  testWidgets('cache offline letta non dichiara inbox globale vuota', (
    tester,
  ) async {
    final fixture = Task054VisualFixtures();
    final repository = _PagedInbox()..offline = true;
    fixture.notificationCache.items = [repository.readItem];
    await _mount(tester, fixture, repository);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CustomerNotificationInboxScreen)),
    );
    await tester.tap(find.byKey(const ValueKey('notifications-unread-only')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.notificationsEmptyTitle), findsNothing);
    expect(
      find.text(l10n.notificationsUnreadPartialEmptyTitle),
      findsOneWidget,
    );
    expect(
      find.text(l10n.notificationsUnreadCachedEmptyMessage),
      findsOneWidget,
    );
    expect(find.text(l10n.notificationsOffline), findsOneWidget);
    expect(fixture.notificationCache.items.single.id, 'read-first');
  });

  testWidgets('pagina fallita conserva filtro e offre feedback con retry', (
    tester,
  ) async {
    final fixture = Task054VisualFixtures();
    final repository = _PagedInbox()..failNextPage = true;
    await _mount(tester, fixture, repository);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CustomerNotificationInboxScreen)),
    );
    final controller = container.read(
      customerNotificationInboxControllerProvider.notifier,
    );
    controller.selectUnreadOnly(true);
    await controller.loadMore();
    await tester.pumpAndSettle();
    final state = container.read(customerNotificationInboxControllerProvider);
    expect(state.unreadOnly, isTrue);
    expect(state.items.single.id, 'read-first');
    expect(state.nextCursor?.id, 'read-first');
    expect(state.failure, CustomerNotificationFailureKind.offline);
    expect(
      find.byKey(const ValueKey('notifications-update-failed')),
      findsOneWidget,
    );
    repository.failNextPage = false;
    repository.next.complete(repository.olderPage);
    final more = find.byKey(const ValueKey('notifications-load-more'));
    await tester.scrollUntilVisible(
      more,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(more), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(more);
    await tester.pumpAndSettle();
    final recovered = container.read(
      customerNotificationInboxControllerProvider,
    );
    expect(recovered.visibleItems.single.id, 'unread-older');
    expect(recovered.failure, isNull);
    expect(repository.cursors.map((cursor) => cursor?.id), [
      'read-first',
      'read-first',
    ]);
    expect(
      find.byKey(const ValueKey('notifications-update-failed')),
      findsNothing,
    );
  });

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

Future<void> _mount(
  WidgetTester tester,
  Task054VisualFixtures fixture,
  CustomerNotificationRepository repository, {
  Locale locale = const Locale('it'),
}) async {
  await tester.pumpWidget(
    fixture.wrap(
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
      additionalOverrides: [
        customerNotificationRepositoryProvider.overrideWithValue(repository),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

class _PagedInbox implements CustomerNotificationRepository {
  final next = Completer<CustomerNotificationPage>();
  final cursors = <CustomerNotificationCursor?>[];
  bool offline = false;
  bool failNextPage = false;

  CustomerNotification get readItem => _item('read-first', read: true);
  CustomerNotificationPage get olderPage => CustomerNotificationPage(
    items: [readItem, _item('unread-older', read: false)],
    unreadCount: 1,
    serverTime: task054VisualNow,
    nextCursor: null,
  );

  @override
  Future<CustomerNotificationPage> list({
    required String shopSlug,
    CustomerNotificationCategory? category,
    CustomerNotificationCursor? before,
    int pageSize = 25,
  }) async {
    if (offline) {
      throw const CustomerNotificationRepositoryException(
        CustomerNotificationFailureKind.offline,
      );
    }
    if (before != null) {
      cursors.add(before);
      if (failNextPage) {
        throw const CustomerNotificationRepositoryException(
          CustomerNotificationFailureKind.offline,
        );
      }
      return next.future;
    }
    return CustomerNotificationPage(
      items: [readItem],
      unreadCount: 1,
      serverTime: task054VisualNow,
      nextCursor: CustomerNotificationCursor(
        createdAt: readItem.createdAt,
        id: readItem.id,
      ),
    );
  }

  @override
  Future<DateTime> markRead(String notificationId) async => task054VisualNow;
  @override
  Future<int> markAllRead(String shopSlug) async => 1;
  @override
  Future<CustomerNotificationDestination> resolveRoute({
    required String shopSlug,
    required String routeToken,
  }) async => const CustomerNotificationCartDestination(
    event: CustomerNotificationEvent.confirmed,
    eventVersion: 1,
  );

  CustomerNotification _item(String id, {required bool read}) =>
      CustomerNotification(
        id: id,
        shopSlug: 'storefront-test',
        category: CustomerNotificationCategory.order,
        event: 'order.confirmed',
        eventVersion: 1,
        titleKey: 'notification.order.confirmed.title',
        bodyKey: 'notification.order.confirmed.body',
        safeArguments: const {},
        destinationType: CustomerNotificationDestinationType.notifications,
        destinationId: null,
        createdAt: task054VisualNow,
        readAt: read ? task054VisualNow : null,
        expiresAt: null,
      );
}
