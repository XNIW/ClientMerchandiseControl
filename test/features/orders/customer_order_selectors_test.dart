import 'package:client_merchandise_control/features/orders/domain/customer_order_models.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_selectors.dart';
import 'package:flutter_test/flutter_test.dart';

import 'customer_order_test_support.dart';

void main() {
  test('seleziona ordine attivo con priorità commerciale deterministica', () {
    final orders = [
      _card('confirmed', CustomerOrderStatus.confirmed, version: 8),
      _card('preparing', CustomerOrderStatus.preparing, version: 7),
      _card('ready', CustomerOrderStatus.ready, version: 6),
      _card('delivery-old', CustomerOrderStatus.outForDelivery, version: 2),
      _card('delivery-new', CustomerOrderStatus.outForDelivery, version: 5),
      _card('completed', CustomerOrderStatus.completed, version: 9),
    ];

    expect(selectPrimaryActiveOrder(orders)?.id, 'delivery-new');
    expect(activeCustomerOrderCount(orders), 5);
  });

  test('filtri usano soltanto stati supportati dal contratto', () {
    final orders = [
      _card('active', CustomerOrderStatus.accepted),
      _card('completed', CustomerOrderStatus.completed),
      _card('cancelled', CustomerOrderStatus.cancelled),
      _card('rejected', CustomerOrderStatus.rejected),
    ];

    expect(
      filterCustomerOrders(
        orders,
        CustomerOrderListFilter.active,
      ).map((order) => order.id),
      ['active'],
    );
    expect(
      filterCustomerOrders(
        orders,
        CustomerOrderListFilter.completed,
      ).map((order) => order.id),
      ['completed'],
    );
    expect(
      filterCustomerOrders(
        orders,
        CustomerOrderListFilter.cancelled,
      ).map((order) => order.id),
      ['cancelled', 'rejected'],
    );
    expect(
      customerOrderListFilterFromName('unknown'),
      CustomerOrderListFilter.all,
    );
  });
}

CustomerOrderCard _card(
  String id,
  CustomerOrderStatus status, {
  int version = 1,
}) {
  return orderTestCard(
    id: id,
    code: 'MC-$id',
    status: status,
    version: version,
    placedAt: orderTestNow.subtract(Duration(minutes: 20 - version)),
  );
}
