import 'customer_order_models.dart';

enum CustomerOrderListFilter { all, active, completed, cancelled }

CustomerOrderListFilter customerOrderListFilterFromName(String? name) {
  return CustomerOrderListFilter.values.firstWhere(
    (value) => value.name == name,
    orElse: () => CustomerOrderListFilter.all,
  );
}

const _activeOrderPriority = <CustomerOrderStatus, int>{
  CustomerOrderStatus.outForDelivery: 0,
  CustomerOrderStatus.ready: 1,
  CustomerOrderStatus.preparing: 2,
  CustomerOrderStatus.accepted: 3,
  CustomerOrderStatus.confirmed: 4,
};

bool isActiveCustomerOrderStatus(CustomerOrderStatus status) {
  return _activeOrderPriority.containsKey(status);
}

List<CustomerOrderCard> filterCustomerOrders(
  Iterable<CustomerOrderCard> orders,
  CustomerOrderListFilter filter,
) {
  return List.unmodifiable(
    orders.where((order) {
      return switch (filter) {
        CustomerOrderListFilter.all => true,
        CustomerOrderListFilter.active => isActiveCustomerOrderStatus(
          order.status,
        ),
        CustomerOrderListFilter.completed =>
          order.status == CustomerOrderStatus.completed,
        CustomerOrderListFilter.cancelled =>
          order.status == CustomerOrderStatus.cancelled ||
              order.status == CustomerOrderStatus.rejected,
      };
    }),
  );
}

CustomerOrderCard? selectPrimaryActiveOrder(
  Iterable<CustomerOrderCard> orders,
) {
  final candidates = orders
      .where((order) => isActiveCustomerOrderStatus(order.status))
      .toList();
  if (candidates.isEmpty) return null;
  candidates.sort((left, right) {
    final byPriority = _activeOrderPriority[left.status]!.compareTo(
      _activeOrderPriority[right.status]!,
    );
    if (byPriority != 0) return byPriority;
    final byUpdate = right.updatedAt.compareTo(left.updatedAt);
    if (byUpdate != 0) return byUpdate;
    return left.id.compareTo(right.id);
  });
  return candidates.first;
}

int activeCustomerOrderCount(Iterable<CustomerOrderCard> orders) {
  return orders
      .where((order) => isActiveCustomerOrderStatus(order.status))
      .length;
}

int? completeActiveCustomerOrderCount(
  Iterable<CustomerOrderCard> orders, {
  required bool hasMore,
}) {
  if (hasMore) return null;
  return activeCustomerOrderCount(orders);
}
