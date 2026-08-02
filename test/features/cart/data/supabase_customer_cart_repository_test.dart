import 'dart:async';
import 'dart:io';

import 'package:client_merchandise_control/features/cart/data/supabase_customer_cart_repository.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_failure.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_models.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _publicationId = '50000000-0000-4000-8000-000000000001';
const _rejectedId = '50000000-0000-4000-8000-000000000002';
const _idempotencyId = '60000000-0000-4000-8000-000000000001';

void main() {
  late _FakePort port;
  late SupabaseCustomerCartRepository repository;

  setUp(() {
    port = _FakePort()..response = _fullPayload();
    repository = SupabaseCustomerCartRepository(port: port);
  });

  test('read usa solo slug pubblico e valida il totale ricostruito', () async {
    final response = await repository.read(shopSlug: 'storefront-test');

    expect(port.function, 'customer_cart_read_v1');
    expect(port.parameters, {'p_shop_slug': 'storefront-test'});
    expect(response.snapshot?.items.single.publicationId, _publicationId);
    expect(response.snapshot?.subtotalClp, 2400);
    expect(response.snapshot?.requiresCustomerReview, isTrue);
    expect(response.snapshot?.items.single.priceChanged, isTrue);
  });

  test(
    'mutate invia expectedVersion e idempotency senza prezzi client',
    () async {
      final response = await repository.mutate(
        const CartMutationRequest(
          shopSlug: 'storefront-test',
          operation: CartMutationOperation.set,
          publicationId: _publicationId,
          quantity: 2,
          expectedVersion: 4,
          idempotencyKey: _idempotencyId,
        ),
      );

      expect(response.status, CartRemoteStatus.ok);
      expect(port.function, 'customer_cart_mutate_v1');
      expect(port.parameters, {
        'p_shop_slug': 'storefront-test',
        'p_operation': 'set',
        'p_publication_id': _publicationId,
        'p_quantity': 2,
        'p_expected_version': 4,
        'p_idempotency_key': _idempotencyId,
      });
      expect(
        port.parameters!.keys,
        isNot(contains(anyOf('priceClp', 'subtotalClp', 'shopId', 'cartId'))),
      );
    },
  );

  test(
    'merge canonicalizza max quantity e invia solo publicationId/quantity',
    () async {
      port.response = _fullPayload(
        status: 'partial',
        extra: {
          'mergeStatus': 'partial',
          'acceptedCount': 1,
          'rejectedPublicationIds': [_rejectedId],
        },
      );
      final guest = [
        _line(publicationId: _publicationId, quantity: 1),
        _line(publicationId: _publicationId, quantity: 3),
        _line(publicationId: _rejectedId, quantity: 2),
      ];

      final response = await repository.mergeGuest(
        shopSlug: 'storefront-test',
        guestItems: guest,
        expectedVersion: 4,
        idempotencyKey: _idempotencyId,
      );

      expect(response.status, CartRemoteStatus.partial);
      expect(response.rejectedPublicationIds, [_rejectedId]);
      expect(port.function, 'customer_cart_merge_guest_v1');
      expect(port.parameters, {
        'p_shop_slug': 'storefront-test',
        'p_guest_items': [
          {'publicationId': _publicationId, 'quantity': 3},
          {'publicationId': _rejectedId, 'quantity': 2},
        ],
        'p_expected_version': 4,
        'p_idempotency_key': _idempotencyId,
      });
    },
  );

  test('revalidate accetta quote confermata bounded', () async {
    final quotedAt = DateTime.utc(2026, 8, 2, 12);
    port.response = _fullPayload(
      status: 'revalidated',
      quoteStatus: 'confirmed',
      quotedAt: quotedAt,
      quoteExpiresAt: quotedAt.add(const Duration(minutes: 5)),
    );

    final response = await repository.revalidate(
      shopSlug: 'storefront-test',
      expectedVersion: 4,
      idempotencyKey: _idempotencyId,
    );

    expect(response.status, CartRemoteStatus.revalidated);
    expect(response.snapshot?.quoteStatus, CartQuoteStatus.confirmed);
    expect(port.parameters, {
      'p_shop_slug': 'storefront-test',
      'p_expected_version': 4,
      'p_idempotency_key': _idempotencyId,
    });
  });

  test(
    'payload con ID interni, totale o UUID incoerente fallisce chiuso',
    () async {
      for (final payload in [
        {..._fullPayload(), 'cartId': _idempotencyId},
        {..._fullPayload(), 'subtotalClp': 1},
        _fullPayload(
          items: [
            {..._item(), 'publicationId': '../inventory'},
          ],
        ),
      ]) {
        port.response = payload;
        await expectLater(
          repository.read(shopSlug: 'storefront-test'),
          throwsA(
            isA<CartRepositoryException>().having(
              (error) => error.kind,
              'kind',
              CartFailureKind.unexpected,
            ),
          ),
        );
      }
    },
  );

  test('minimal invalid e idempotency conflict sono tipizzati', () async {
    for (final entry in const {
      'invalid': CartFailureKind.invalidInput,
      'idempotency_conflict': CartFailureKind.conflict,
    }.entries) {
      port.response = {'apiVersion': 'customer-cart.v1', 'status': entry.key};
      await expectLater(
        repository.read(shopSlug: 'storefront-test'),
        throwsA(
          isA<CartRepositoryException>().having(
            (error) => error.kind,
            'kind',
            entry.value,
          ),
        ),
      );
    }
  });

  test('offline e timeout non espongono dettagli di trasporto', () async {
    port.error = const SocketException('private endpoint');
    await expectLater(
      repository.read(shopSlug: 'storefront-test'),
      throwsA(
        isA<CartRepositoryException>().having(
          (error) => error.kind,
          'kind',
          CartFailureKind.offline,
        ),
      ),
    );

    port.error = null;
    port.barrier = Completer<void>();
    repository = SupabaseCustomerCartRepository(
      port: port,
      requestTimeout: const Duration(milliseconds: 1),
    );
    await expectLater(
      repository.read(shopSlug: 'storefront-test'),
      throwsA(
        isA<CartRepositoryException>().having(
          (error) => error.kind,
          'kind',
          CartFailureKind.timeout,
        ),
      ),
    );
  });

  test('input invalido non raggiunge la porta', () async {
    await expectLater(
      repository.read(shopSlug: '../private'),
      throwsA(
        isA<CartRepositoryException>().having(
          (error) => error.kind,
          'kind',
          CartFailureKind.invalidInput,
        ),
      ),
    );
    expect(port.function, isNull);
  });
}

Map<String, Object?> _fullPayload({
  String status = 'ok',
  String quoteStatus = 'indicative',
  DateTime? quotedAt,
  DateTime? quoteExpiresAt,
  List<Map<String, Object?>>? items,
  Map<String, Object?> extra = const {},
}) {
  final lines = items ?? [_item()];
  final subtotal = lines.fold<int>(0, (total, item) {
    return total +
        (item['status'] == 'available'
            ? (item['priceClp']! as int) * (item['quantity']! as int)
            : 0);
  });
  return {
    'apiVersion': 'customer-cart.v1',
    'status': status,
    'idempotent': false,
    'shopSlug': 'storefront-test',
    'cartVersion': 4,
    'currencyCode': 'CLP',
    'quoteStatus': quoteStatus,
    'quotedAt': quotedAt?.toIso8601String(),
    'quoteExpiresAt': quoteExpiresAt?.toIso8601String(),
    'requiresCustomerReview': lines.any((item) => item['changeType'] != 'none'),
    'itemCount': lines.length,
    'totalQuantity': lines.fold<int>(
      0,
      (total, item) => total + (item['quantity']! as int),
    ),
    'unavailableItemCount': lines
        .where((item) => item['status'] == 'unavailable')
        .length,
    'subtotalClp': subtotal,
    'items': lines,
    ...extra,
  };
}

Map<String, Object?> _item() => {
  'publicationId': _publicationId,
  'quantity': 2,
  'publicName': 'Café público',
  'imageUrl':
      'https://example.invalid/storage/v1/object/public/storefront-product-images/public/thumb.webp',
  'status': 'available',
  'availabilityMode': 'low_stock',
  'snapshotPriceClp': 1300,
  'priceClp': 1200,
  'compareAtPriceClp': 1500,
  'promotionId': null,
  'promotionName': null,
  'promotionEndsAt': null,
  'changeType': 'price_changed',
};

CartLine _line({required String publicationId, required int quantity}) {
  return CartLine(
    publicationId: publicationId,
    publicName: 'Producto público',
    quantity: quantity,
    priceClp: 1200,
    snapshotPriceClp: 1200,
    availability: StorefrontAvailability.available,
    status: CartLineStatus.available,
    changeType: CartLineChangeType.none,
    isGuest: true,
  );
}

final class _FakePort implements CustomerCartPort {
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
