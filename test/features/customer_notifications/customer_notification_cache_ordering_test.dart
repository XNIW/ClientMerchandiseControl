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

// Verifica ordering del port async, non riordino osservato di SharedPreferences OS.
const _owner = '90000000-0000-4000-8000-000000000002';
const _notification = '90000000-0000-4000-8000-000000000001';

void main() {
  late ProviderContainer container;
  late _Repository repository;
  late _BarrierCache cache;
  late CustomerNotificationInboxController controller;

  setUp(() async {
    repository = _Repository();
    cache = _BarrierCache();
    container = ProviderContainer(
      overrides: [
        customerNotificationIdentityProvider.overrideWithValue(
          AuthenticatedCustomer.fromUntrustedIdentity(
            subjectId: _owner,
            email: null,
            metadata: const {},
          ),
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
    controller = container.read(
      customerNotificationInboxControllerProvider.notifier,
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(customerNotificationInboxControllerProvider).status,
      CustomerNotificationInboxStatus.ready,
    );
    expect(cache.items.single.isUnread, isTrue);
  });

  test(
    'cache write iniziata prima di mark-all non ripristina unread dopo success',
    () async {
      cache.blockNextWrite = true;
      final earlierPage = controller.loadMore();
      await cache.blockedWriteStarted.future;
      expect(
        container
            .read(customerNotificationInboxControllerProvider)
            .isLoadingMore,
        isFalse,
      );

      // Il controller può pubblicare success prima che il vecchio save termini.
      // Non attendere mutation qui: una coda corretta attende old write, poi salva.
      final mutation = controller.markAllRead();
      await Future<void>.delayed(Duration.zero);
      expect(
        container
            .read(customerNotificationInboxControllerProvider)
            .items
            .single
            .isUnread,
        isFalse,
      );
      expect(
        container.read(customerNotificationInboxControllerProvider).unreadCount,
        0,
      );

      cache.releaseBlockedWrite.complete();
      await Future.wait([earlierPage, mutation]);

      expect(
        cache.items.single.isUnread,
        isFalse,
        reason:
            'cache finale deve riflettere mark-all, anche se una write old era già iniziata',
      );
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
    'cache write iniziata prima del diniego non ripubblica dati dopo purge',
    () async {
      cache.blockNextWrite = true;
      final earlierPage = controller.loadMore();
      await cache.blockedWriteStarted.future;

      final deniedMutation = Completer<int>();
      repository.markAll = deniedMutation.future;
      final mutation = controller.markAllRead();
      deniedMutation.completeError(
        const CustomerNotificationRepositoryException(
          CustomerNotificationFailureKind.unauthorized,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(customerNotificationInboxControllerProvider).items,
        isEmpty,
      );
      expect(
        container.read(customerNotificationInboxControllerProvider).failure,
        CustomerNotificationFailureKind.unauthorized,
      );

      // Una coda corretta esegue remove dopo il vecchio write, anche se la UI è
      // stata svuotata immediatamente. Non richiedere purge completato prima.
      cache.releaseBlockedWrite.complete();
      await Future.wait([earlierPage, mutation]);

      expect(
        cache.items,
        isEmpty,
        reason: 'nessuna write pre-denial può restare persistita dopo il purge',
      );
      expect(cache.removes, 1);
      expect(
        container.read(customerNotificationInboxControllerProvider).items,
        isEmpty,
      );
      expect(
        container.read(customerNotificationInboxControllerProvider).hasMore,
        isFalse,
      );
    },
  );
}

CustomerNotificationPage _page() => CustomerNotificationPage(
  items: [
    CustomerNotification(
      id: _notification,
      shopSlug: 'storefront-test',
      category: CustomerNotificationCategory.order,
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
    id: _notification,
  ),
);

class _Repository implements CustomerNotificationRepository {
  Future<int>? markAll;

  @override
  Future<CustomerNotificationPage> list({
    required String shopSlug,
    CustomerNotificationCategory? category,
    CustomerNotificationCursor? before,
    int pageSize = 25,
  }) async => _page();

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

class _BarrierCache implements CustomerNotificationCache {
  List<CustomerNotification> items = [];
  bool blockNextWrite = false;
  final blockedWriteStarted = Completer<void>();
  final releaseBlockedWrite = Completer<void>();
  int removes = 0;

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
    // Snapshot per invocazione: due Future indipendenti possono terminare in
    // ordine inverso anche se chiamati old prima di new.
    final snapshot = List<CustomerNotification>.unmodifiable(items);
    if (blockNextWrite) {
      blockNextWrite = false;
      blockedWriteStarted.complete();
      await releaseBlockedWrite.future;
    }
    this.items = snapshot;
  }

  @override
  Future<void> remove({
    required String ownerSubjectId,
    required String shopSlug,
  }) async {
    removes++;
    items = [];
  }
}
