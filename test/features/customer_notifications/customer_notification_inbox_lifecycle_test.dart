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

  for (final purgeFails in [false, true]) {
    test('revoca durante paginazione, purgeFails=$purgeFails', () async {
      cache.failRemove = purgeFails;
      final page = Completer<CustomerNotificationPage>();
      repository.next = page.future;
      final controller = container.read(
        customerNotificationInboxControllerProvider.notifier,
      );
      final pagination = controller.loadMore();
      final mutationBarrier = Completer<int>();
      repository.markAll = mutationBarrier.future;
      final mutation = controller.markAllRead();
      mutationBarrier.completeError(
        const CustomerNotificationRepositoryException(
          CustomerNotificationFailureKind.unauthorized,
        ),
      );
      await mutation;
      expect(
        container.read(customerNotificationInboxControllerProvider).items,
        isEmpty,
      );
      final writes = cache.writes;
      page.complete(
        _page('old-sensitive-order', CustomerNotificationCategory.order),
      );
      await pagination;
      final state = container.read(customerNotificationInboxControllerProvider);
      expect(
        state.items,
        isEmpty,
        reason: 'authoritative denial must invalidate older successful page',
      );
      expect(cache.writes, writes);
      if (!purgeFails) expect(cache.items, isEmpty);
      expect(state.status, CustomerNotificationInboxStatus.failure);
      expect(state.failure, CustomerNotificationFailureKind.unauthorized);
    });
  }

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

  for (final markAll in [true, false]) {
    test(
      'pagina precedente non ripristina unread dopo lettura all=$markAll',
      () async {
        final page = Completer<CustomerNotificationPage>();
        repository.next = page.future;
        final controller = container.read(
          customerNotificationInboxControllerProvider.notifier,
        );
        controller.selectUnreadOnly(true);
        final pagination = controller.loadMore();
        if (markAll) {
          await controller.markAllRead();
        } else {
          await controller.markRead('order');
        }
        final writes = cache.writes;
        page.complete(_page('order', CustomerNotificationCategory.order));
        await pagination;
        final state = container.read(
          customerNotificationInboxControllerProvider,
        );
        expect(state.visibleItems, isEmpty);
        expect(state.unreadCount, 0);
        expect(state.isLoadingMore, isFalse);
        expect(state.hasMore, isTrue);
        expect(cache.writes, writes);
        expect(cache.items.single.isUnread, isFalse);
        repository.next = Future.value(
          _page('fresh-event', CustomerNotificationCategory.order),
        );
        await controller.loadMore();
        expect(
          container
              .read(customerNotificationInboxControllerProvider)
              .visibleItems
              .single
              .id,
          'fresh-event',
          reason: 'Nuovi eventi autorevoli conservano unread',
        );
        expect(cache.items.last.isUnread, isTrue);
      },
    );
    test(
      'lettura in volo non avvia refresh o altre pagine all=$markAll',
      () async {
        final controller = container.read(
          customerNotificationInboxControllerProvider.notifier,
        );
        final barrier = Completer<int>();
        final singleBarrier = Completer<DateTime>();
        repository.markAll = barrier.future;
        repository.markSingle = singleBarrier.future;
        final mutation = markAll
            ? controller.markAllRead()
            : controller.markRead('order');
        final calls = repository.listCalls;
        await controller.refresh();
        await controller.loadMore();
        expect(repository.listCalls, calls);
        expect(
          container
              .read(customerNotificationInboxControllerProvider)
              .isMutating,
          isTrue,
        );
        barrier.complete(1);
        singleBarrier.complete(DateTime.utc(2026, 9, 1));
        await mutation;
        expect(
          container
              .read(customerNotificationInboxControllerProvider)
              .items
              .single
              .isUnread,
          isFalse,
        );
        expect(
          container.read(customerNotificationInboxControllerProvider).hasMore,
          isTrue,
        );
      },
    );
    test(
      'lettura fallita conserva cursor e pagina ritentabile all=$markAll',
      () async {
        final controller = container.read(
          customerNotificationInboxControllerProvider.notifier,
        );
        final page = Completer<CustomerNotificationPage>();
        repository.next = page.future;
        final pagination = controller.loadMore();
        if (markAll) {
          repository.markAll = Future.error(
            const CustomerNotificationRepositoryException(
              CustomerNotificationFailureKind.offline,
            ),
          );
          await controller.markAllRead();
        } else {
          repository.markSingle = Future.error(
            const CustomerNotificationRepositoryException(
              CustomerNotificationFailureKind.offline,
            ),
          );
          await controller.markRead('order');
        }
        page.complete(_page('stale-event', CustomerNotificationCategory.order));
        await pagination;
        final state = container.read(
          customerNotificationInboxControllerProvider,
        );
        expect(state.items.map((item) => item.id), ['order']);
        expect(state.unreadCount, 1);
        expect(state.hasMore, isTrue);
        expect(state.isLoadingMore, isFalse);
        repository.next = Future.value(
          _page('next-event', CustomerNotificationCategory.order),
        );
        await controller.loadMore();
        expect(
          container
              .read(customerNotificationInboxControllerProvider)
              .items
              .map((item) => item.id),
          ['order', 'next-event'],
        );
      },
    );
  }

  test(
    'mark-all durante categoria loading non annulla il caricamento',
    () async {
      final controller = container.read(
        customerNotificationInboxControllerProvider.notifier,
      );
      final page = Completer<CustomerNotificationPage>();
      repository.categoryPage = page.future;
      final change = controller.selectCategory(
        CustomerNotificationCategory.payment,
      );
      expect(
        container.read(customerNotificationInboxControllerProvider).status,
        CustomerNotificationInboxStatus.loading,
      );
      await controller.markAllRead();
      page.complete(_page('payment', CustomerNotificationCategory.payment));
      await change;
      final state = container.read(customerNotificationInboxControllerProvider);
      expect(state.status, CustomerNotificationInboxStatus.ready);
      expect(state.isRefreshing, isFalse);
      expect(state.isMutating, isFalse);
      expect(state.category, CustomerNotificationCategory.payment);
      expect(state.items.single.id, 'payment');
      expect(state.items.single.isUnread, isTrue);
      await controller.markAllRead();
      expect(
        container
            .read(customerNotificationInboxControllerProvider)
            .items
            .single
            .isUnread,
        isFalse,
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
  Future<CustomerNotificationPage>? categoryPage;
  Future<int>? markAll;
  Future<DateTime>? markSingle;
  int listCalls = 0;
  CustomerNotificationFailureKind? failure;
  @override
  Future<CustomerNotificationPage> list({
    required String shopSlug,
    CustomerNotificationCategory? category,
    CustomerNotificationCursor? before,
    int pageSize = 25,
  }) async {
    listCalls++;
    if (failure != null) {
      throw CustomerNotificationRepositoryException(failure!);
    }
    if (before != null && next != null) return next!;
    if (category != null && categoryPage != null) return categoryPage!;
    return _page(
      category?.name ?? 'order',
      category ?? CustomerNotificationCategory.order,
    );
  }

  @override
  Future<int> markAllRead(String shopSlug) async => markAll ?? 1;
  @override
  Future<DateTime> markRead(String notificationId) async =>
      markSingle ?? DateTime.utc(2026, 9, 1);
  @override
  Future<CustomerNotificationDestination> resolveRoute({
    required String shopSlug,
    required String routeToken,
  }) => throw UnimplementedError();
}

class _Cache implements CustomerNotificationCache {
  List<CustomerNotification> items = [];
  bool failRemove = false;
  int writes = 0;
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
    writes++;
    this.items = items;
  }

  @override
  Future<void> remove({
    required String ownerSubjectId,
    required String shopSlug,
  }) async {
    if (failRemove) throw StateError('fixture_cache_failure');
    items = [];
  }
}
