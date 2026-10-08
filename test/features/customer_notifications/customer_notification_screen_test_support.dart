import 'dart:async';

import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/customer_notifications/application/customer_notification_providers.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_cache.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_models.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_repository.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final inboxTestIdentityProvider = StateProvider<AuthenticatedCustomer?>(
  (ref) => inboxTestCustomer('owner-a'),
);
final inboxTestShopProvider = StateProvider<String>((ref) => 'storefront-test');

AuthenticatedCustomer inboxTestCustomer(String subject) =>
    AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: subject,
      email: null,
      metadata: const {},
    );

ProviderContainer inboxTestContainer(PagedInboxTestRepository repository) =>
    ProviderContainer(
      overrides: [
        customerNotificationIdentityProvider.overrideWith(
          (ref) => ref.watch(inboxTestIdentityProvider),
        ),
        customerNotificationShopSlugProvider.overrideWith(
          (ref) => ref.watch(inboxTestShopProvider),
        ),
        customerNotificationRepositoryProvider.overrideWithValue(repository),
        customerNotificationCacheProvider.overrideWithValue(_InboxCache()),
      ],
    );

Widget inboxTestApp(Widget home) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('es', 'CL'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

class PagedInboxTestRepository implements CustomerNotificationRepository {
  PagedInboxTestRepository({
    this.totalItems = 1,
    this.destination = CustomerNotificationDestinationType.order,
  });

  final int totalItems;
  final CustomerNotificationDestinationType destination;
  final now = DateTime.utc(2026, 10, 8, 12);
  final listCalls = <String>[];
  var markReadCalls = 0;
  Completer<DateTime>? markReadBarrier;

  @override
  Future<CustomerNotificationPage> list({
    required String shopSlug,
    CustomerNotificationCategory? category,
    CustomerNotificationCursor? before,
    int pageSize = 25,
  }) async {
    listCalls.add('$shopSlug:${before?.id ?? "first"}');
    final start = before == null ? 0 : int.parse(before.id) + 1;
    final end = (start + pageSize).clamp(0, totalItems);
    return CustomerNotificationPage(
      items: [
        for (var index = start; index < end; index++)
          CustomerNotification(
            id: '$index',
            shopSlug: shopSlug,
            category: CustomerNotificationCategory.order,
            event: 'confirmed',
            eventVersion: 1,
            titleKey: 'notificationOrderTitle',
            bodyKey: 'notificationOrderBody',
            safeArguments: {'orderCode': 'TEST-$index'},
            destinationType: destination,
            destinationId: 'resource-$index',
            createdAt: now.subtract(Duration(minutes: index)),
            readAt: null,
            expiresAt: null,
          ),
      ],
      unreadCount: totalItems,
      serverTime: now,
      nextCursor: end == totalItems
          ? null
          : CustomerNotificationCursor(createdAt: now, id: '${end - 1}'),
    );
  }

  @override
  Future<DateTime> markRead(String notificationId) async {
    markReadCalls++;
    return markReadBarrier?.future ?? now;
  }

  @override
  Future<int> markAllRead(String shopSlug) async => totalItems;

  @override
  Future<CustomerNotificationDestination> resolveRoute({
    required String shopSlug,
    required String routeToken,
  }) async => const CustomerNotificationOrderDestination(
    orderId: 'resource-0',
    event: CustomerNotificationEvent.confirmed,
    eventVersion: 1,
  );
}

class _InboxCache implements CustomerNotificationCache {
  final itemsByScope = <String, List<CustomerNotification>>{};

  @override
  Future<List<CustomerNotification>> read({
    required String ownerSubjectId,
    required String shopSlug,
  }) async => itemsByScope['$ownerSubjectId:$shopSlug'] ?? [];

  @override
  Future<void> write({
    required String ownerSubjectId,
    required String shopSlug,
    required List<CustomerNotification> items,
  }) async {
    itemsByScope['$ownerSubjectId:$shopSlug'] = List.of(items);
  }

  @override
  Future<void> remove({
    required String ownerSubjectId,
    required String shopSlug,
  }) async {
    itemsByScope.remove('$ownerSubjectId:$shopSlug');
  }
}
