import 'dart:async';
import 'dart:io';

import 'package:client_merchandise_control/features/checkout/data/supabase_checkout_repository.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_failure.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _publicationId = '50000000-0000-4000-8000-000000000001';
const _pointId = '51000000-0000-4000-8000-000000000001';
const _zoneId = '52000000-0000-4000-8000-000000000001';
const _pickupSlotId = '53000000-0000-4000-8000-000000000001';
const _deliverySlotId = '53000000-0000-4000-8000-000000000002';
const _quoteId = '54000000-0000-4000-8000-000000000001';
const _orderId = '57000000-0000-4000-8000-000000000001';
const _addressId = '55000000-0000-4000-8000-000000000001';
const _idempotencyId = '56000000-0000-4000-8000-000000000001';
final _now = DateTime.utc(2026, 8, 3, 3);

void main() {
  late _FakeCheckoutPort port;
  late SupabaseCheckoutRepository repository;

  setUp(() {
    port = _FakeCheckoutPort()..response = _optionsPayload();
    repository = SupabaseCheckoutRepository(port: port);
  });

  test('options usa solo slug pubblico e valida riferimenti slot', () async {
    final options = await repository.loadOptions(shopSlug: 'storefront-test');

    expect(port.function, 'storefront_fulfillment_options_v1');
    expect(port.parameters, {'p_shop_slug': 'storefront-test'});
    expect(options.currencyCode, 'CLP');
    expect(options.modes, hasLength(3));
    expect(options.pickupPoint(_pointId)?.name, 'Tienda Centro');
    expect(options.deliveryZone(_zoneId)?.feeClp, 2500);
    expect(options.slots, hasLength(2));
  });

  test('payment options sono mode-scoped e online resta fail-closed', () async {
    port.response = _paymentOptionsPayload();

    final options = await repository.loadPaymentOptions(
      shopSlug: 'storefront-test',
    );

    expect(port.function, 'storefront_payment_options_v1');
    expect(port.parameters, {'p_shop_slug': 'storefront-test'});
    expect(
      options.isEnabled(
        CheckoutPaymentMethod.payAtPickup,
        CheckoutFulfillmentMode.pickup,
      ),
      isTrue,
    );
    expect(
      options.isEnabled(
        CheckoutPaymentMethod.cashOnDelivery,
        CheckoutFulfillmentMode.pickup,
      ),
      isFalse,
    );
    expect(options.option(CheckoutPaymentMethod.onlinePayment)?.enabled, false);
  });

  test(
    'payment options manipolate o con metadata interno falliscono chiuso',
    () async {
      final base = _paymentOptionsPayload();
      final methods = (base['methods']! as List<Object?>)
          .map((value) => Map<String, Object?>.from(value! as Map))
          .toList();
      for (final payload in [
        {
          ...base,
          'methods': [
            methods[0],
            methods[1],
            {...methods[2], 'enabled': true},
          ],
        },
        {...base, 'providerKey': 'internal-provider'},
      ]) {
        port.response = payload;
        await expectLater(
          repository.loadPaymentOptions(shopSlug: 'storefront-test'),
          throwsA(
            isA<CheckoutRepositoryException>().having(
              (error) => error.kind,
              'kind',
              CheckoutFailureKind.unexpected,
            ),
          ),
        );
      }
    },
  );

  test(
    'create invia selezione e idempotency senza prezzo o totale client',
    () async {
      port.response = _quotePayload();

      final response = await repository.createQuote(
        const CheckoutQuoteCreateRequest(
          shopSlug: 'storefront-test',
          cartVersion: 7,
          selection: CheckoutSelection(
            mode: CheckoutFulfillmentMode.pickup,
            pickupPointId: _pointId,
            slotId: _pickupSlotId,
          ),
          idempotencyKey: _idempotencyId,
        ),
      );

      expect(response.status, CheckoutRemoteStatus.quoted);
      expect(response.quote?.totalClp, 2400);
      expect(port.function, 'customer_checkout_quote_create_v1');
      expect(port.parameters, {
        'p_shop_slug': 'storefront-test',
        'p_cart_version': 7,
        'p_fulfillment_mode': 'pickup',
        'p_address_id': null,
        'p_pickup_point_id': _pointId,
        'p_slot_id': _pickupSlotId,
        'p_idempotency_key': _idempotencyId,
      });
      expect(
        port.parameters!.keys,
        isNot(
          contains(
            anyOf(
              'totalClp',
              'subtotalClp',
              'deliveryFeeClp',
              'priceClp',
              'discountClp',
              'shopId',
              'cartId',
            ),
          ),
        ),
      );
    },
  );

  test(
    'delivery richiede address, esclude pickup e accetta fee server',
    () async {
      port.response = _quotePayload(
        mode: 'delivery',
        addressId: _addressId,
        pickupPointId: null,
        deliveryZoneId: _zoneId,
        slotId: _deliverySlotId,
        deliveryFeeClp: 2500,
      );

      final response = await repository.createQuote(
        const CheckoutQuoteCreateRequest(
          shopSlug: 'storefront-test',
          cartVersion: 7,
          selection: CheckoutSelection(
            mode: CheckoutFulfillmentMode.delivery,
            addressId: _addressId,
            slotId: _deliverySlotId,
          ),
          idempotencyKey: _idempotencyId,
        ),
      );

      expect(response.quote?.deliveryFeeClp, 2500);
      expect(response.quote?.totalClp, 4900);
      expect(port.parameters?['p_address_id'], _addressId);
      expect(port.parameters?['p_pickup_point_id'], isNull);
    },
  );

  test('confirm usa versione attesa e stessa chiave idempotente', () async {
    port.response = _quotePayload(
      status: 'confirmed',
      quoteStatus: 'confirmed',
      confirmedAt: _now.add(const Duration(seconds: 20)),
    );

    final response = await repository.confirmQuote(
      shopSlug: 'storefront-test',
      cartVersion: 7,
      quoteId: _quoteId,
      expectedQuoteVersion: 2,
      idempotencyKey: _idempotencyId,
    );

    expect(response.quote?.isConfirmed, isTrue);
    expect(port.function, 'customer_checkout_quote_confirm_v1');
    expect(port.parameters, {
      'p_quote_id': _quoteId,
      'p_expected_quote_version': 2,
      'p_idempotency_key': _idempotencyId,
    });
  });

  test(
    'create order invia solo quote, versione e idempotency e valida receipt',
    () async {
      port.response = _orderPayload();

      final response = await repository.createOrder(
        shopSlug: 'storefront-test',
        cartVersion: 7,
        quoteId: _quoteId,
        expectedQuoteVersion: 2,
        paymentMethod: CheckoutPaymentMethod.payAtPickup,
        idempotencyKey: _idempotencyId,
      );

      expect(response.status, CheckoutOrderRemoteStatus.ok);
      expect(response.order?.id, _orderId);
      expect(response.order?.code, 'MC-0123456789ABCDEF0123');
      expect(response.order?.totalClp, 2400);
      expect(response.order?.items.single.publicName, 'Café público');
      expect(response.order?.payment.method, CheckoutPaymentMethod.payAtPickup);
      expect(
        response.order?.payment.status,
        CheckoutPaymentStatus.dueAtFulfillment,
      );
      expect(port.function, 'customer_order_create_v2');
      expect(port.parameters, {
        'p_quote_id': _quoteId,
        'p_expected_quote_version': 2,
        'p_payment_method': 'pay_at_pickup',
        'p_idempotency_key': _idempotencyId,
      });
      expect(
        port.parameters!.keys,
        isNot(
          contains(
            anyOf(
              'totalClp',
              'subtotalClp',
              'deliveryFeeClp',
              'priceClp',
              'discountClp',
              'shopId',
              'userId',
            ),
          ),
        ),
      );
    },
  );

  test('read order usa solo ID owner-scoped e accetta replay', () async {
    port.response = _orderPayload(idempotent: true);

    final response = await repository.readOrder(
      shopSlug: 'storefront-test',
      orderId: _orderId,
    );

    expect(response.order?.idempotent, isTrue);
    expect(port.function, 'customer_order_read_v2');
    expect(port.parameters, {'p_order_id': _orderId});
  });

  test('order minimale mappa conflitto e requires-review', () async {
    for (final entry in const {
      'requires_review': CheckoutOrderRemoteStatus.requiresReview,
      'quote_version_conflict': CheckoutOrderRemoteStatus.quoteVersionConflict,
      'idempotency_conflict': CheckoutOrderRemoteStatus.idempotencyConflict,
      'payment_method_unavailable':
          CheckoutOrderRemoteStatus.paymentMethodUnavailable,
      'payment_method_conflict':
          CheckoutOrderRemoteStatus.paymentMethodConflict,
      'online_payment_unavailable':
          CheckoutOrderRemoteStatus.onlinePaymentUnavailable,
      'not_found': CheckoutOrderRemoteStatus.notFound,
    }.entries) {
      port.response = {
        'apiVersion': 'customer-order.v2',
        'status': entry.key,
        'idempotent': false,
        'serverTime': _now.toIso8601String(),
      };
      final response = await repository.readOrder(
        shopSlug: 'storefront-test',
        orderId: _orderId,
      );
      expect(response.status, entry.value, reason: entry.key);
    }
  });

  test('order manipolato o con dato interno fallisce chiuso', () async {
    for (final payload in [
      {..._orderPayload(), 'totalClp': 1},
      {..._orderPayload(), 'sourceProductId': _publicationId},
      _orderPayload(
        items: [
          {..._orderItem(), 'sourceProductId': _publicationId},
        ],
      ),
      {
        ..._orderPayload(),
        'fulfillment': {
          ...(_orderPayload()['fulfillment']! as Map<String, Object?>),
          'shopId': _pointId,
        },
      },
      {
        ..._orderPayload(),
        'payment': {
          ...(_orderPayload()['payment']! as Map<String, Object?>),
          'amountClp': 1,
        },
      },
      {
        ..._orderPayload(),
        'payment': {
          ...(_orderPayload()['payment']! as Map<String, Object?>),
          'providerReference': 'secret-provider-reference',
        },
      },
    ]) {
      port.response = payload;
      await expectLater(
        repository.readOrder(shopSlug: 'storefront-test', orderId: _orderId),
        throwsA(
          isA<CheckoutRepositoryException>().having(
            (error) => error.kind,
            'kind',
            CheckoutFailureKind.unexpected,
          ),
        ),
      );
    }
  });

  test('risposta minimale mappa gli errori di dominio', () async {
    for (final entry in const {
      'cart_version_conflict': CheckoutRemoteStatus.cartVersionConflict,
      'invalid_address': CheckoutRemoteStatus.invalidAddress,
      'unsupported_zone': CheckoutRemoteStatus.unsupportedZone,
      'slot_unavailable': CheckoutRemoteStatus.slotUnavailable,
      'idempotency_conflict': CheckoutRemoteStatus.idempotencyConflict,
    }.entries) {
      port.response = {
        'apiVersion': 'customer-checkout.v1',
        'status': entry.key,
        'idempotent': false,
        'serverTime': _now.toIso8601String(),
      };
      final response = await repository.readQuote(
        shopSlug: 'storefront-test',
        cartVersion: 7,
        quoteId: _quoteId,
      );
      expect(response.status, entry.value, reason: entry.key);
    }
  });

  test(
    'payload con totale manipolato o dato interno fallisce chiuso',
    () async {
      for (final payload in [
        {..._quotePayload(), 'totalClp': 1},
        {..._quotePayload(), 'sourceProductId': _publicationId},
        _quotePayload(
          items: [
            {..._quoteItem(), 'unitPriceClp': 1},
          ],
        ),
      ]) {
        port.response = payload;
        await expectLater(
          repository.readQuote(
            shopSlug: 'storefront-test',
            cartVersion: 7,
            quoteId: _quoteId,
          ),
          throwsA(
            isA<CheckoutRepositoryException>().having(
              (error) => error.kind,
              'kind',
              CheckoutFailureKind.unexpected,
            ),
          ),
        );
      }
    },
  );

  test('input invalido non raggiunge la porta', () async {
    await expectLater(
      repository.createQuote(
        const CheckoutQuoteCreateRequest(
          shopSlug: 'storefront-test',
          cartVersion: 7,
          selection: CheckoutSelection(
            mode: CheckoutFulfillmentMode.delivery,
            pickupPointId: _pointId,
            slotId: _deliverySlotId,
          ),
          idempotencyKey: _idempotencyId,
        ),
      ),
      throwsA(
        isA<CheckoutRepositoryException>().having(
          (error) => error.kind,
          'kind',
          CheckoutFailureKind.invalidInput,
        ),
      ),
    );
    expect(port.function, isNull);
  });

  test('offline e timeout restano errori sanitizzati', () async {
    port.error = const SocketException('private staging endpoint');
    await expectLater(
      repository.loadOptions(shopSlug: 'storefront-test'),
      throwsA(
        isA<CheckoutRepositoryException>().having(
          (error) => error.kind,
          'kind',
          CheckoutFailureKind.offline,
        ),
      ),
    );

    port.error = null;
    port.barrier = Completer<void>();
    repository = SupabaseCheckoutRepository(
      port: port,
      requestTimeout: const Duration(milliseconds: 1),
    );
    await expectLater(
      repository.loadOptions(shopSlug: 'storefront-test'),
      throwsA(
        isA<CheckoutRepositoryException>().having(
          (error) => error.kind,
          'kind',
          CheckoutFailureKind.timeout,
        ),
      ),
    );
  });
}

Map<String, Object?> _optionsPayload() => {
  'apiVersion': 'storefront-fulfillment.v1',
  'status': 'ok',
  'shopSlug': 'storefront-test',
  'currencyCode': 'CLP',
  'modes': const [
    {'mode': 'pickup', 'enabled': true},
    {'mode': 'reservation', 'enabled': true},
    {'mode': 'delivery', 'enabled': true},
  ],
  'pickupPoints': const [
    {
      'id': _pointId,
      'name': 'Tienda Centro',
      'addressLine1': 'Avenida Uno 123',
      'addressLine2': null,
      'commune': 'Santiago',
      'region': 'Metropolitana',
      'instructions': 'Retiro en mesón',
    },
  ],
  'deliveryZones': const [
    {
      'id': _zoneId,
      'name': 'Santiago centro',
      'region': 'Metropolitana',
      'communes': ['Santiago'],
      'feeClp': 2500,
    },
  ],
  'slots': [
    {
      'id': _pickupSlotId,
      'mode': 'pickup',
      'pickupPointId': _pointId,
      'deliveryZoneId': null,
      'label': 'Hoy 16:00–18:00',
      'startsAt': _now.add(const Duration(hours: 1)).toIso8601String(),
      'endsAt': _now.add(const Duration(hours: 3)).toIso8601String(),
      'status': 'available',
    },
    {
      'id': _deliverySlotId,
      'mode': 'delivery',
      'pickupPointId': null,
      'deliveryZoneId': _zoneId,
      'label': 'Mañana 10:00–12:00',
      'startsAt': _now.add(const Duration(days: 1)).toIso8601String(),
      'endsAt': _now.add(const Duration(days: 1, hours: 2)).toIso8601String(),
      'status': 'available',
    },
  ],
  'serverTime': _now.toIso8601String(),
};

Map<String, Object?> _paymentOptionsPayload() => {
  'apiVersion': 'storefront-payment-options.v1',
  'status': 'ok',
  'shopSlug': 'storefront-test',
  'currencyCode': 'CLP',
  'methods': const [
    {
      'method': 'pay_at_pickup',
      'enabled': true,
      'fulfillmentModes': ['pickup', 'reservation'],
    },
    {
      'method': 'cash_on_delivery',
      'enabled': true,
      'fulfillmentModes': ['delivery'],
    },
    {
      'method': 'online_payment',
      'enabled': false,
      'fulfillmentModes': <String>[],
    },
  ],
  'onlineConfiguration': 'not_configured',
  'serverTime': _now.toIso8601String(),
};

Map<String, Object?> _quotePayload({
  String status = 'quoted',
  String quoteStatus = 'quoted',
  String mode = 'pickup',
  String? addressId,
  String? pickupPointId = _pointId,
  String? deliveryZoneId,
  String slotId = _pickupSlotId,
  int deliveryFeeClp = 0,
  DateTime? confirmedAt,
  List<Map<String, Object?>>? items,
}) {
  final quoteItems = items ?? [_quoteItem()];
  final subtotal = quoteItems.fold<int>(
    0,
    (sum, item) => sum + (item['lineTotalClp']! as int),
  );
  return {
    'apiVersion': 'customer-checkout.v1',
    'status': status,
    'idempotent': false,
    'quoteId': _quoteId,
    'shopSlug': 'storefront-test',
    'cartVersion': 7,
    'quoteVersion': 2,
    'quoteStatus': quoteStatus,
    'fulfillmentMode': mode,
    'addressId': addressId,
    'pickupPointId': pickupPointId,
    'deliveryZoneId': deliveryZoneId,
    'slotId': slotId,
    'currencyCode': 'CLP',
    'subtotalClp': subtotal,
    'deliveryFeeClp': deliveryFeeClp,
    'totalClp': subtotal + deliveryFeeClp,
    'items': quoteItems,
    'changes': const <Object?>[],
    'requiresCustomerReview': quoteStatus == 'requires_review',
    'quotedAt': _now.toIso8601String(),
    'expiresAt': _now.add(const Duration(minutes: 5)).toIso8601String(),
    'confirmedAt': confirmedAt?.toIso8601String(),
    'serverTime': _now.add(const Duration(seconds: 10)).toIso8601String(),
    'remainingSeconds': 290,
  };
}

Map<String, Object?> _quoteItem() => const {
  'publicationId': _publicationId,
  'publicName': 'Café público',
  'quantity': 2,
  'unitPriceClp': 1200,
  'compareAtPriceClp': 1500,
  'lineTotalClp': 2400,
  'promotionId': null,
  'promotionName': null,
  'promotionEndsAt': null,
  'holdId': null,
};

Map<String, Object?> _orderPayload({
  bool idempotent = false,
  List<Map<String, Object?>>? items,
}) {
  final orderItems = items ?? [_orderItem()];
  final subtotal = orderItems.fold<int>(
    0,
    (sum, item) => sum + (item['lineTotalClp']! as int),
  );
  final placedAt = _now.add(const Duration(seconds: 30));
  return {
    'apiVersion': 'customer-order.v2',
    'status': 'ok',
    'idempotent': idempotent,
    'orderId': _orderId,
    'orderCode': 'MC-0123456789ABCDEF0123',
    'orderStatus': 'confirmed',
    'orderVersion': 1,
    'shopSlug': 'storefront-test',
    'fulfillmentMode': 'pickup',
    'fulfillment': {
      'mode': 'pickup',
      'pickupPoint': {
        'id': _pointId,
        'name': 'Tienda Centro',
        'addressLine1': 'Avenida Uno 123',
        'commune': 'Santiago',
        'region': 'Metropolitana',
        'instructions': 'Retiro en mesón',
      },
      'slot': {
        'id': _pickupSlotId,
        'label': 'Hoy 16:00–18:00',
        'startsAt': _now.add(const Duration(hours: 1)).toIso8601String(),
        'endsAt': _now.add(const Duration(hours: 3)).toIso8601String(),
      },
    },
    'currencyCode': 'CLP',
    'subtotalClp': subtotal,
    'deliveryFeeClp': 0,
    'totalClp': subtotal,
    'items': orderItems,
    'payment': {
      'method': 'pay_at_pickup',
      'status': 'due_at_fulfillment',
      'amountClp': subtotal,
      'currencyCode': 'CLP',
      'version': 1,
      'createdAt': placedAt.toIso8601String(),
      'updatedAt': placedAt.toIso8601String(),
    },
    'placedAt': placedAt.toIso8601String(),
    'serverTime': placedAt.toIso8601String(),
  };
}

Map<String, Object?> _orderItem() => const {
  'publicationId': _publicationId,
  'publicName': 'Café público',
  'quantity': 2,
  'unitPriceClp': 1200,
  'compareAtPriceClp': 1500,
  'lineTotalClp': 2400,
};

final class _FakeCheckoutPort implements CheckoutPort {
  Object? response;
  Object? error;
  Completer<void>? barrier;
  String? function;
  Map<String, Object?>? parameters;

  @override
  Future<Object?> invoke(
    String function,
    Map<String, Object?> parameters,
  ) async {
    this.function = function;
    this.parameters = parameters;
    await barrier?.future;
    if (error case final failure?) throw failure;
    return response;
  }
}
