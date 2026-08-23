import 'package:client_merchandise_control/features/customer_notifications/data/supabase_customer_notification_repository.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_failure.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _notification = '65000000-0000-4000-8000-000000000001';
const _order = '57000000-0000-4000-8000-000000000001';
const _shopId = '45000000-0000-4000-8000-000000000001';

void main() {
  test('inbox valida destinazione sicura, unread e cursor composto', () async {
    final port = _Port()..response = _page();
    final page = await SupabaseCustomerNotificationRepository(port: port).list(
      shopSlug: 'storefront-test',
      category: CustomerNotificationCategory.order,
      pageSize: 1,
    );

    expect(page.items.single.destinationId, _order);
    expect(page.unreadCount, 1);
    expect(page.nextCursor?.id, _notification);
    expect(port.parameters, containsPair('p_category', 'order'));
  });

  test('URL arbitrario e destinazione non correlata sono negati', () async {
    final port = _Port()
      ..response = _page(
        itemOverride: {
          'destinationType': 'notifications',
          'destinationId': 'https://example.invalid',
        },
      );
    await expectLater(
      SupabaseCustomerNotificationRepository(
        port: port,
      ).list(shopSlug: 'storefront-test'),
      throwsA(isA<CustomerNotificationRepositoryException>()),
    );
  });

  test(
    'destinazione inbox accetta soltanto lo shop UUID del contract',
    () async {
      final port = _Port()
        ..response = _page(
          itemOverride: const {
            'category': 'system',
            'event': 'reservation_hold',
            'titleKey': 'notification.reservation.title',
            'bodyKey': 'notification.reservation.body',
            'safeArguments': <String, String>{},
            'destinationType': 'notifications',
            'destinationId': _shopId,
          },
        );

      final page = await SupabaseCustomerNotificationRepository(
        port: port,
      ).list(shopSlug: 'storefront-test');

      expect(
        page.items.single.destinationType,
        CustomerNotificationDestinationType.notifications,
      );
      expect(page.items.single.destinationId, _shopId);
    },
  );

  test('mark read e mark all usano solo identifier owner-scoped', () async {
    final port = _Port()
      ..responses['customer_notification_mark_read_v1'] = {
        'apiVersion': 'customer-notifications.v1',
        'status': 'ok',
        'readAt': '2026-08-23T13:00:00Z',
      }
      ..responses['customer_notifications_mark_all_read_v1'] = {
        'apiVersion': 'customer-notifications.v1',
        'status': 'ok',
        'updatedCount': 3,
      };
    final repository = SupabaseCustomerNotificationRepository(port: port);
    expect(
      await repository.markRead(_notification),
      DateTime.utc(2026, 8, 23, 13),
    );
    expect(await repository.markAllRead('storefront-test'), 3);
  });
}

Map<String, Object?> _page({Map<String, Object?> itemOverride = const {}}) => {
  'apiVersion': 'customer-notifications.v1',
  'status': 'ok',
  'unreadCount': 1,
  'serverTime': '2026-08-23T12:00:00Z',
  'items': [
    {
      'id': _notification,
      'shopSlug': 'storefront-test',
      'category': 'order',
      'event': 'order.confirmed',
      'eventVersion': 1,
      'titleKey': 'notification.order.confirmed.title',
      'bodyKey': 'notification.order.confirmed.body',
      'safeArguments': {'orderCode': 'MC-1234'},
      'destinationType': 'order',
      'destinationId': _order,
      'createdAt': '2026-08-23T12:00:00Z',
      'readAt': null,
      'expiresAt': null,
      ...itemOverride,
    },
  ],
};

final class _Port implements CustomerNotificationPort {
  Object? response;
  final Map<String, Object?> responses = {};
  Map<String, Object?>? parameters;

  @override
  Future<Object?> invoke(
    String function,
    Map<String, Object?> parameters,
  ) async {
    this.parameters = parameters;
    return responses[function] ?? response;
  }
}
