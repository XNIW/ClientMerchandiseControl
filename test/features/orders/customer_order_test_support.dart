import 'package:client_merchandise_control/features/orders/data/supabase_customer_order_repository.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_failure.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_models.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_repository.dart';

const orderTestOwner = '10000000-0000-4000-8000-000000028001';
const orderTestShop = 'storefront-test';
const orderTestOrder = '88000000-0000-4000-8000-000000028101';
const orderTestOlderOrder = '88000000-0000-4000-8000-000000028102';
const orderTestPublication = '50000000-0000-4000-8000-000000028101';
const orderTestPoint = '51000000-0000-4000-8000-000000028101';
const orderTestSlot = '53000000-0000-4000-8000-000000028101';
const orderTestKey = '56000000-0000-4000-8000-000000028101';
const orderTestCode = 'MC-0123456789ABCDEF0123';
final orderTestNow = DateTime.utc(2026, 8, 3, 5);

CustomerOrderCard orderTestCard({
  String id = orderTestOrder,
  String code = orderTestCode,
  CustomerOrderStatus status = CustomerOrderStatus.confirmed,
  int version = 1,
  int totalClp = 2400,
  bool cancellationAllowed = true,
  DateTime? placedAt,
}) {
  final placed = placedAt ?? orderTestNow.subtract(const Duration(minutes: 2));
  return CustomerOrderCard(
    id: id,
    code: code,
    status: status,
    version: version,
    fulfillmentMode: CustomerOrderFulfillmentMode.pickup,
    totalClp: totalClp,
    itemCount: 1,
    primaryItemName: 'Café público',
    cancellationAllowed: cancellationAllowed,
    placedAt: placed,
    updatedAt: placed.add(Duration(seconds: version - 1)),
  );
}

CustomerOrderDetail orderTestDetail({
  String id = orderTestOrder,
  String code = orderTestCode,
  CustomerOrderStatus status = CustomerOrderStatus.confirmed,
  int version = 1,
  bool cancellationEnabled = true,
  bool cancellationAllowed = true,
  bool idempotent = false,
  DateTime? serverTime,
}) {
  final server = serverTime ?? orderTestNow;
  final placed = orderTestNow.subtract(const Duration(minutes: 2));
  final timeline = <CustomerOrderTimelineEvent>[
    CustomerOrderTimelineEvent(
      version: 1,
      status: CustomerOrderStatus.confirmed,
      actorKind: CustomerOrderActorKind.system,
      createdAt: placed,
    ),
    if (version == 2)
      CustomerOrderTimelineEvent(
        version: 2,
        status: status,
        actorKind: CustomerOrderActorKind.customer,
        createdAt: placed.add(const Duration(seconds: 1)),
      ),
  ];
  return CustomerOrderDetail(
    id: id,
    code: code,
    status: status,
    version: version,
    shopSlug: orderTestShop,
    fulfillment: CustomerOrderFulfillment(
      mode: CustomerOrderFulfillmentMode.pickup,
      destinationTitle: 'Tienda Centro',
      destinationLines: const ['Calle Pública 123', 'Santiago, RM'],
      slotLabel: 'Hoy 10:00–12:00',
      slotStartsAt: orderTestNow.add(const Duration(hours: 1)),
      slotEndsAt: orderTestNow.add(const Duration(hours: 3)),
    ),
    subtotalClp: 2400,
    deliveryFeeClp: 0,
    totalClp: 2400,
    items: const [
      CustomerOrderLine(
        publicationId: orderTestPublication,
        publicName: 'Café público',
        quantity: 2,
        unitPriceClp: 1200,
        compareAtPriceClp: 1500,
        lineTotalClp: 2400,
        promotionName: 'Oferta pública',
        promotionEndsAt: null,
      ),
    ],
    timeline: timeline,
    cancellation: CustomerOrderCancellation(
      enabled: cancellationEnabled,
      allowed: cancellationAllowed,
      deadline: orderTestNow.add(const Duration(minutes: 10)),
    ),
    placedAt: placed,
    updatedAt: placed.add(Duration(seconds: version - 1)),
    serverTime: server,
    idempotent: idempotent,
  );
}

CustomerOrderDetail orderTestCancelledDetail({bool idempotent = false}) =>
    orderTestDetail(
      status: CustomerOrderStatus.cancelled,
      version: 2,
      cancellationAllowed: false,
      idempotent: idempotent,
      serverTime: orderTestNow.add(const Duration(seconds: 2)),
    );

CustomerOrderPage orderTestPage({
  List<CustomerOrderCard>? orders,
  CustomerOrderCursor? nextCursor,
}) => CustomerOrderPage(
  shopSlug: orderTestShop,
  orders: orders ?? [orderTestCard()],
  nextCursor: nextCursor,
  serverTime: orderTestNow,
);

CustomerOrderCacheSnapshot orderTestCache({
  String ownerSubjectId = orderTestOwner,
  String shopSlug = orderTestShop,
  List<CustomerOrderCard>? orders,
  Map<String, CustomerOrderDetail>? details,
  CustomerOrderCursor? nextCursor,
  CustomerOrderPendingCancellation? pendingCancellation,
}) => CustomerOrderCacheSnapshot(
  ownerSubjectId: ownerSubjectId,
  shopSlug: shopSlug,
  orders: orders ?? [orderTestCard()],
  details: details ?? {orderTestOrder: orderTestDetail()},
  nextCursor: nextCursor,
  pendingCancellation: pendingCancellation,
  cachedAt: orderTestNow,
);

Map<String, Object?> orderTestListPayload({
  List<Map<String, Object?>>? orders,
  bool hasMore = false,
  String shopSlug = orderTestShop,
}) {
  final values = orders ?? [orderTestCardPayload()];
  return {
    'apiVersion': 'customer-order-list.v1',
    'status': 'ok',
    'shopSlug': shopSlug,
    'orders': values,
    'hasMore': hasMore,
    if (hasMore)
      'nextCursor': {
        'beforePlacedAt': values.last['placedAt'],
        'beforeOrderId': values.last['orderId'],
      },
    'serverTime': orderTestNow.toIso8601String(),
  };
}

Map<String, Object?> orderTestCardPayload({
  String id = orderTestOrder,
  String code = orderTestCode,
  DateTime? placedAt,
  String status = 'confirmed',
  int version = 1,
  bool cancellationAllowed = true,
}) {
  final placed = placedAt ?? orderTestNow.subtract(const Duration(minutes: 2));
  return {
    'orderId': id,
    'orderCode': code,
    'orderStatus': status,
    'orderVersion': version,
    'fulfillmentMode': 'pickup',
    'currencyCode': 'CLP',
    'totalClp': 2400,
    'itemCount': 1,
    'primaryItemName': 'Café público',
    'cancellationAllowed': cancellationAllowed,
    'placedAt': placed.toIso8601String(),
    'updatedAt': placed.add(Duration(seconds: version - 1)).toIso8601String(),
  };
}

Map<String, Object?> orderTestDetailPayload({
  String id = orderTestOrder,
  String shopSlug = orderTestShop,
  String status = 'confirmed',
  int version = 1,
  bool cancellationAllowed = true,
  bool idempotent = false,
}) {
  final placed = orderTestNow.subtract(const Duration(minutes: 2));
  return {
    'apiVersion': 'customer-order-detail.v1',
    'status': 'ok',
    'idempotent': idempotent,
    'orderId': id,
    'orderCode': orderTestCode,
    'orderStatus': status,
    'orderVersion': version,
    'shopSlug': shopSlug,
    'fulfillmentMode': 'pickup',
    'fulfillment': {
      'mode': 'pickup',
      'pickupPoint': {
        'id': orderTestPoint,
        'name': 'Tienda Centro',
        'addressLine1': 'Calle Pública 123',
        'addressLine2': null,
        'commune': 'Santiago',
        'region': 'RM',
        'instructions': null,
      },
      'slot': {
        'id': orderTestSlot,
        'label': 'Hoy 10:00–12:00',
        'startsAt': orderTestNow
            .add(const Duration(hours: 1))
            .toIso8601String(),
        'endsAt': orderTestNow.add(const Duration(hours: 3)).toIso8601String(),
      },
    },
    'currencyCode': 'CLP',
    'subtotalClp': 2400,
    'deliveryFeeClp': 0,
    'totalClp': 2400,
    'items': [
      {
        'publicationId': orderTestPublication,
        'publicName': 'Café público',
        'quantity': 2,
        'unitPriceClp': 1200,
        'compareAtPriceClp': 1500,
        'lineTotalClp': 2400,
        'promotionName': 'Oferta pública',
        'promotionEndsAt': null,
      },
    ],
    'timeline': [
      {
        'eventVersion': 1,
        'status': 'confirmed',
        'actorKind': 'system',
        'createdAt': placed.toIso8601String(),
      },
      if (version == 2)
        {
          'eventVersion': 2,
          'status': status,
          'actorKind': 'customer',
          'createdAt': placed.add(const Duration(seconds: 1)).toIso8601String(),
        },
    ],
    'cancellation': {
      'enabled': true,
      'allowed': cancellationAllowed,
      'deadline': orderTestNow
          .add(const Duration(minutes: 10))
          .toIso8601String(),
    },
    'placedAt': placed.toIso8601String(),
    'updatedAt': placed.add(Duration(seconds: version - 1)).toIso8601String(),
    'serverTime': orderTestNow
        .add(Duration(seconds: version - 1))
        .toIso8601String(),
  };
}

final class FakeCustomerOrderPort implements CustomerOrderPort {
  Object? response;
  Object? error;
  String? function;
  Map<String, Object?>? parameters;
  int calls = 0;

  @override
  Future<Object?> invoke(
    String function,
    Map<String, Object?> parameters,
  ) async {
    calls++;
    this.function = function;
    this.parameters = parameters;
    if (error case final Object value) throw value;
    return response;
  }
}

final class FakeCustomerOrderRepository implements CustomerOrderRepository {
  final List<Object> listOutcomes = [];
  final List<Object> detailOutcomes = [];
  final List<Object> cancelOutcomes = [];
  final List<({String shopSlug, CustomerOrderCursor? cursor, int limit})>
  listRequests = [];
  final List<({String shopSlug, String orderId})> detailRequests = [];
  final List<
    ({
      String shopSlug,
      String orderId,
      int expectedStatusVersion,
      String idempotencyKey,
    })
  >
  cancelRequests = [];

  @override
  Future<CustomerOrderPage> listOrders({
    required String shopSlug,
    CustomerOrderCursor? cursor,
    int limit = 20,
  }) async {
    listRequests.add((shopSlug: shopSlug, cursor: cursor, limit: limit));
    return _resolve(listOutcomes, orderTestPage());
  }

  @override
  Future<CustomerOrderDetail> loadOrder({
    required String shopSlug,
    required String orderId,
  }) async {
    detailRequests.add((shopSlug: shopSlug, orderId: orderId));
    return _resolve(detailOutcomes, orderTestDetail(id: orderId));
  }

  @override
  Future<CustomerOrderDetail> cancelOrder({
    required String shopSlug,
    required String orderId,
    required int expectedStatusVersion,
    required String idempotencyKey,
  }) async {
    cancelRequests.add((
      shopSlug: shopSlug,
      orderId: orderId,
      expectedStatusVersion: expectedStatusVersion,
      idempotencyKey: idempotencyKey,
    ));
    return _resolve(cancelOutcomes, orderTestCancelledDetail());
  }

  Future<T> _resolve<T extends Object>(
    List<Object> outcomes,
    T fallback,
  ) async {
    final Object outcome = outcomes.isEmpty ? fallback : outcomes.removeAt(0);
    if (outcome is Future<T>) return outcome;
    if (outcome is T) return outcome;
    throw outcome;
  }
}

final class MemoryCustomerOrderCacheStore implements CustomerOrderCacheStore {
  CustomerOrderCacheSnapshot? snapshot;
  Object? readError;
  Object? saveError;
  int readCalls = 0;
  int saveCalls = 0;
  int clearCalls = 0;

  @override
  Future<CustomerOrderCacheSnapshot?> read({
    required String ownerSubjectId,
    required String shopSlug,
  }) async {
    readCalls++;
    if (readError case final Object value) throw value;
    if (snapshot?.ownerSubjectId != ownerSubjectId ||
        snapshot?.shopSlug != shopSlug) {
      return null;
    }
    return snapshot;
  }

  @override
  Future<void> save(CustomerOrderCacheSnapshot snapshot) async {
    saveCalls++;
    if (saveError case final Object value) throw value;
    this.snapshot = snapshot;
  }

  @override
  Future<void> clear({
    required String ownerSubjectId,
    required String shopSlug,
  }) async {
    clearCalls++;
    if (snapshot?.ownerSubjectId == ownerSubjectId &&
        snapshot?.shopSlug == shopSlug) {
      snapshot = null;
    }
  }
}

const customerOrderOffline = CustomerOrderRepositoryException(
  CustomerOrderFailureKind.offline,
);
const customerOrderTimeout = CustomerOrderRepositoryException(
  CustomerOrderFailureKind.timeout,
);
