import 'dart:async';

import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/customer_notifications/application/customer_notification_inbox_controller.dart';
import 'package:client_merchandise_control/features/customer_notifications/application/customer_notification_providers.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_cache.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_failure.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_models.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  late _Repository repository;
  late _Cache cache;
  final identity = StateProvider<AuthenticatedCustomer?>(
    (ref) => AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: '00000000-0000-4000-8000-000000000001',
      email: null,
      metadata: const {},
    ),
  );
  setUp(() async {
    repository = _Repository();
    cache = _Cache();
    container = ProviderContainer(
      overrides: [
        customerNotificationIdentityProvider.overrideWith(
          (ref) => ref.watch(identity),
        ),
        customerNotificationShopSlugProvider.overrideWithValue(
          'storefront-test',
        ),
        customerNotificationRepositoryProvider.overrideWithValue(repository),
        customerNotificationCacheProvider.overrideWithValue(cache),
      ],
    );
    addTearDown(container.dispose);
    container.listen(customerNotificationInboxControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
  });

  test(
    'pagina tardiva non entra nel filtro selezionato successivamente',
    () async {
      final next = Completer<CustomerNotificationPage>();
      repository.next = next.future;
      final controller = container.read(
        customerNotificationInboxControllerProvider.notifier,
      );
      final operation = controller.loadMore();
      await controller.selectCategory(CustomerNotificationCategory.payment);
      next.complete(_page('old-order', CustomerNotificationCategory.order));
      await operation;
      final state = container.read(customerNotificationInboxControllerProvider);
      expect(state.items.map((item) => item.id), ['payment']);
      expect(state.category, CustomerNotificationCategory.payment);
    },
  );

  test(
    'mark-all tardivo dopo A-B-A non altera le notifiche della nuova sessione',
    () async {
      final barrier = Completer<int>();
      repository.markAll = barrier.future;
      final operation = container
          .read(customerNotificationInboxControllerProvider.notifier)
          .markAllRead();
      final owner = container.read(identity);
      container.read(identity.notifier).state = null;
      container.read(customerNotificationInboxControllerProvider);
      container.read(identity.notifier).state = owner;
      container.read(customerNotificationInboxControllerProvider);
      await Future<void>.delayed(Duration.zero);
      barrier.complete(1);
      await operation;
      expect(
        container.read(customerNotificationInboxControllerProvider).unreadCount,
        1,
      );
      expect(
        container
            .read(customerNotificationInboxControllerProvider)
            .items
            .single
            .isUnread,
        isTrue,
      );
    },
  );

  test('revoca autorizzazione rimuove notifiche da UI e cache', () async {
    repository.failure = CustomerNotificationFailureKind.unauthorized;
    await container
        .read(customerNotificationInboxControllerProvider.notifier)
        .refresh();
    final state = container.read(customerNotificationInboxControllerProvider);
    expect(state.items, isEmpty);
    expect(state.unreadCount, 0);
    expect(cache.items, isEmpty);
    expect(state.status, CustomerNotificationInboxStatus.failure);
  });

  test(
    'offline conserva la pagina leggibile senza dichiararla aggiornata',
    () async {
      repository.failure = CustomerNotificationFailureKind.offline;
      await container
          .read(customerNotificationInboxControllerProvider.notifier)
          .refresh();
      final state = container.read(customerNotificationInboxControllerProvider);
      expect(state.items, hasLength(1));
      expect(state.status, CustomerNotificationInboxStatus.offline);
    },
  );
}

CustomerNotificationPage _page(
  String id,
  CustomerNotificationCategory category,
) => CustomerNotificationPage(
  items: [
    CustomerNotification(
      id: id,
      shopSlug: 'storefront-test',
      category: category,
      event: 'order.confirmed',
      eventVersion: 1,
      titleKey: 'notification.order.confirmed.title',
      bodyKey: 'notification.order.confirmed.body',
      safeArguments: const {},
      destinationType: CustomerNotificationDestinationType.order,
      destinationId: null,
      createdAt: DateTime.utc(2026, 9, 1),
      readAt: null,
      expiresAt: null,
    ),
  ],
  unreadCount: 1,
  serverTime: DateTime.utc(2026, 9, 1),
  nextCursor: CustomerNotificationCursor(
    createdAt: DateTime.utc(2026, 9, 1),
    id: id,
  ),
);

class _Repository implements CustomerNotificationRepository {
  Future<CustomerNotificationPage>? next;
  Future<int>? markAll;
  CustomerNotificationFailureKind? failure;
  @override
  Future<CustomerNotificationPage> list({
    required String shopSlug,
    CustomerNotificationCategory? category,
    CustomerNotificationCursor? before,
    int pageSize = 25,
  }) async {
    if (failure != null) {
      throw CustomerNotificationRepositoryException(failure!);
    }
    if (before != null && next != null) return next!;
    return _page(
      category?.name ?? 'order',
      category ?? CustomerNotificationCategory.order,
    );
  }

  @override
  Future<int> markAllRead(String shopSlug) async => markAll ?? 1;
  @override
  Future<DateTime> markRead(String notificationId) async =>
      DateTime.utc(2026, 9, 1);
  @override
  Future<CustomerNotificationDestination> resolveRoute({
    required String shopSlug,
    required String routeToken,
  }) => throw UnimplementedError();
}

class _Cache implements CustomerNotificationCache {
  List<CustomerNotification> items = [];
  @override
  Future<List<CustomerNotification>> read({
    required String ownerSubjectId,
    required String shopSlug,
  }) async => items;
  @override
  Future<void> write({
    required String ownerSubjectId,
    required String shopSlug,
    required List<CustomerNotification> items,
  }) async {
    this.items = items;
  }

  @override
  Future<void> remove({
    required String ownerSubjectId,
    required String shopSlug,
  }) async {
    items = [];
  }
}
