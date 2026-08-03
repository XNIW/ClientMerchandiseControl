import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/cart/application/cart_controller.dart';
import 'package:client_merchandise_control/features/cart/application/cart_providers.dart';
import 'package:client_merchandise_control/features/cart/application/cart_state.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_failure.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_models.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_repository.dart';
import 'package:client_merchandise_control/features/reservations/application/reservation_hold_providers.dart';
import 'package:client_merchandise_control/features/reservations/domain/reservation_hold_models.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../reservations/reservation_hold_test_support.dart';

const _publicationId = '50000000-0000-4000-8000-000000000001';
const _rejectedId = '50000000-0000-4000-8000-000000000002';

final _identityProvider = StateProvider<AuthenticatedCustomer?>((ref) => null);

void main() {
  test('guest add persiste localmente e sopravvive al lifecycle', () async {
    final guest = _FakeGuestStore();
    var container = _container(guest: guest);
    await _waitFor(container, (state) => state.status == CartViewStatus.ready);

    await container
        .read(cartControllerProvider.notifier)
        .addProduct(_product());
    expect(container.read(cartControllerProvider).snapshot?.totalQuantity, 1);
    expect(guest.setProductCalls, 1);
    container.dispose();

    container = _container(guest: guest);
    addTearDown(container.dispose);
    await _waitFor(container, (state) => state.snapshot?.totalQuantity == 1);
    expect(
      container.read(cartControllerProvider).snapshot?.source,
      CartSource.guest,
    );
  });

  test('login merge elimina solo gli item accettati dopo ack', () async {
    final guest = _FakeGuestStore(
      snapshot: _snapshot(
        source: CartSource.guest,
        items: [
          _line(_publicationId, isGuest: true),
          _line(_rejectedId, isGuest: true),
        ],
      ),
    );
    final remote = _FakeRemoteRepository(
      readResponse: CartRemoteResponse(
        status: CartRemoteStatus.ok,
        snapshot: _snapshot(source: CartSource.account, version: 4),
      ),
      mergeOutcomes: [
        CartRemoteResponse(
          status: CartRemoteStatus.partial,
          snapshot: _snapshot(
            source: CartSource.account,
            version: 5,
            items: [_line(_publicationId)],
          ),
          rejectedPublicationIds: const [_rejectedId],
        ),
      ],
    );
    final container = _container(
      guest: guest,
      remote: remote,
      identity: _identity(),
    );
    addTearDown(container.dispose);

    await _waitFor(
      container,
      (state) => state.notice == CartNoticeKind.partialMerge,
    );

    expect(guest.retainedIds, {_rejectedId});
    expect(guest.snapshot.items.map((item) => item.publicationId), [
      _rejectedId,
    ]);
    final visible = container.read(cartControllerProvider).snapshot!.items;
    expect(visible, hasLength(2));
    expect(
      visible
          .singleWhere((item) => item.publicationId == _rejectedId)
          .isAvailable,
      isFalse,
    );
  });

  test(
    'timeout merge mantiene guest e riusa la stessa idempotency key',
    () async {
      final guest = _FakeGuestStore(
        snapshot: _snapshot(
          source: CartSource.guest,
          items: [_line(_publicationId, isGuest: true)],
        ),
      );
      final merged = CartRemoteResponse(
        status: CartRemoteStatus.merged,
        snapshot: _snapshot(
          source: CartSource.account,
          version: 5,
          items: [_line(_publicationId)],
        ),
      );
      final remote = _FakeRemoteRepository(
        readResponse: CartRemoteResponse(
          status: CartRemoteStatus.ok,
          snapshot: _snapshot(source: CartSource.account, version: 4),
        ),
        mergeOutcomes: [
          const CartRepositoryException(CartFailureKind.timeout),
          merged,
        ],
      );
      final keys = <String>[
        '60000000-0000-4000-8000-000000000001',
        '60000000-0000-4000-8000-000000000002',
      ];
      final container = _container(
        guest: guest,
        remote: remote,
        identity: _identity(),
        keyFactory: () => keys.removeAt(0),
      );
      addTearDown(container.dispose);
      await _waitFor(
        container,
        (state) => state.failureKind == CartFailureKind.timeout,
      );
      expect(guest.snapshot.items, isNotEmpty);

      await container.read(cartControllerProvider.notifier).retry();

      expect(remote.mergeKeys, hasLength(2));
      expect(remote.mergeKeys.toSet(), hasLength(1));
      expect(guest.snapshot.items, isEmpty);
      expect(
        container.read(cartControllerProvider).status,
        CartViewStatus.ready,
      );
    },
  );

  test(
    'version conflict effettua un solo retry con nuova chiave/versione',
    () async {
      final guest = _FakeGuestStore(
        snapshot: _snapshot(
          source: CartSource.guest,
          items: [_line(_publicationId, isGuest: true)],
        ),
      );
      final remote = _FakeRemoteRepository(
        readResponse: CartRemoteResponse(
          status: CartRemoteStatus.ok,
          snapshot: _snapshot(source: CartSource.account, version: 4),
        ),
        mergeOutcomes: [
          CartRemoteResponse(
            status: CartRemoteStatus.versionConflict,
            snapshot: _snapshot(source: CartSource.account, version: 7),
          ),
          CartRemoteResponse(
            status: CartRemoteStatus.merged,
            snapshot: _snapshot(
              source: CartSource.account,
              version: 8,
              items: [_line(_publicationId)],
            ),
          ),
        ],
      );
      final keys = <String>[
        '60000000-0000-4000-8000-000000000001',
        '60000000-0000-4000-8000-000000000002',
      ];
      final container = _container(
        guest: guest,
        remote: remote,
        identity: _identity(),
        keyFactory: () => keys.removeAt(0),
      );
      addTearDown(container.dispose);

      await _waitFor(
        container,
        (state) => state.notice == CartNoticeKind.merged,
      );

      expect(remote.mergeVersions, [4, 7]);
      expect(remote.mergeKeys.toSet(), hasLength(2));
      expect(remote.mergeCalls, 2);
    },
  );

  test(
    'timeout mutation preserva intent e riusa chiave/versione al retry',
    () async {
      final guest = _FakeGuestStore();
      final remote = _FakeRemoteRepository(
        readResponse: CartRemoteResponse(
          status: CartRemoteStatus.ok,
          snapshot: _snapshot(source: CartSource.account, version: 4),
        ),
        mutationOutcomes: [
          const CartRepositoryException(CartFailureKind.timeout),
          CartRemoteResponse(
            status: CartRemoteStatus.ok,
            snapshot: _snapshot(
              source: CartSource.account,
              version: 5,
              items: [_line(_publicationId)],
            ),
          ),
        ],
      );
      const key = '60000000-0000-4000-8000-000000000001';
      final container = _container(
        guest: guest,
        remote: remote,
        identity: _identity(),
        keyFactory: () => key,
      );
      addTearDown(container.dispose);
      await _waitFor(
        container,
        (state) => state.status == CartViewStatus.ready,
      );

      await container
          .read(cartControllerProvider.notifier)
          .addProduct(_product());

      expect(
        container.read(cartControllerProvider).failureKind,
        CartFailureKind.timeout,
      );
      expect(container.read(cartControllerProvider).hasPendingRetry, isTrue);
      expect(container.read(cartControllerProvider).snapshot?.version, 4);

      await container.read(cartControllerProvider.notifier).retry();

      expect(remote.mutationRequests, hasLength(2));
      expect(remote.mutationRequests.map((request) => request.idempotencyKey), [
        key,
        key,
      ]);
      expect(
        remote.mutationRequests.map((request) => request.expectedVersion),
        [4, 4],
      );
      expect(container.read(cartControllerProvider).snapshot?.version, 5);
      expect(container.read(cartControllerProvider).snapshot?.totalQuantity, 1);
      expect(container.read(cartControllerProvider).hasPendingRetry, isFalse);
    },
  );

  test(
    'account switch ricostruisce lo stato senza copiare account in guest',
    () async {
      final guest = _FakeGuestStore();
      final remote = _FakeRemoteRepository(
        readResponse: CartRemoteResponse(
          status: CartRemoteStatus.ok,
          snapshot: _snapshot(
            source: CartSource.account,
            version: 2,
            items: [_line(_publicationId)],
          ),
        ),
      );
      final container = _container(guest: guest, remote: remote);
      addTearDown(container.dispose);
      await _waitFor(
        container,
        (state) => state.status == CartViewStatus.ready,
      );

      container.read(_identityProvider.notifier).state = _identity();
      await _waitFor(
        container,
        (state) => state.isAuthenticated && state.snapshot?.version == 2,
      );
      container.read(_identityProvider.notifier).state = null;
      await _waitFor(
        container,
        (state) =>
            !state.isAuthenticated && state.status == CartViewStatus.ready,
      );

      expect(container.read(cartControllerProvider).snapshot?.items, isEmpty);
      expect(guest.setProductCalls, 0);
    },
  );

  test('mutation account rilascia la reservation hold correlata', () async {
    final guest = _FakeGuestStore();
    final remote = _FakeRemoteRepository(
      readResponse: CartRemoteResponse(
        status: CartRemoteStatus.ok,
        snapshot: _snapshot(
          source: CartSource.account,
          version: 4,
          items: [_line(_publicationId)],
        ),
      ),
      mutationOutcomes: [
        CartRemoteResponse(
          status: CartRemoteStatus.ok,
          snapshot: _snapshot(
            source: CartSource.account,
            version: 5,
            items: [
              CartLine(
                publicationId: _publicationId,
                publicName: 'Café público',
                quantity: 2,
                priceClp: 1200,
                snapshotPriceClp: 1200,
                availability: StorefrontAvailability.available,
                status: CartLineStatus.available,
                changeType: CartLineChangeType.none,
                isGuest: false,
              ),
            ],
          ),
        ),
      ],
    );
    final reservationStore = MemoryReservationHoldStore();
    await reservationStore.saveEntry(
      reservationEntry(hold: reservationSnapshot(quantity: 1)),
    );
    final reservationRepository = FakeReservationHoldRepository();
    reservationRepository.releaseOutcomes.add(
      reservationResponse(
        status: ReservationHoldRemoteStatus.terminal,
        hold: reservationSnapshot(
          quantity: 1,
          status: ReservationHoldServerStatus.released,
        ),
      ),
    );
    final container = _container(
      guest: guest,
      remote: remote,
      identity: _identity(),
      reservationStore: reservationStore,
      reservationRepository: reservationRepository,
    );
    addTearDown(container.dispose);
    await _waitFor(container, (state) => state.status == CartViewStatus.ready);

    await container
        .read(cartControllerProvider.notifier)
        .setQuantity(_publicationId, 2);

    expect(reservationRepository.releaseCalls, hasLength(1));
    expect(remote.mutationRequests.single.quantity, 2);
    final released = await reservationStore.readEntry(
      ownerSubjectId: reservationTestOwner,
      shopSlug: reservationTestShop,
      publicationId: reservationTestPublication,
    );
    expect(released?.hold?.status, ReservationHoldServerStatus.released);
  });
}

ProviderContainer _container({
  required _FakeGuestStore guest,
  _FakeRemoteRepository? remote,
  AuthenticatedCustomer? identity,
  String Function()? keyFactory,
  MemoryReservationHoldStore? reservationStore,
  FakeReservationHoldRepository? reservationRepository,
}) {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(_config()),
      guestCartStoreProvider.overrideWithValue(guest),
      customerCartRepositoryProvider.overrideWithValue(
        remote ??
            _FakeRemoteRepository(
              readResponse: CartRemoteResponse(
                status: CartRemoteStatus.ok,
                snapshot: _snapshot(source: CartSource.account),
              ),
            ),
      ),
      customerAccountIdentityProvider.overrideWith(
        (ref) => ref.watch(_identityProvider),
      ),
      customerIdempotencyKeyFactoryProvider.overrideWithValue(
        keyFactory ?? () => '60000000-0000-4000-8000-000000000001',
      ),
      reservationHoldLocalStoreProvider.overrideWithValue(
        reservationStore ?? MemoryReservationHoldStore(),
      ),
      reservationHoldRepositoryProvider.overrideWithValue(
        reservationRepository ?? FakeReservationHoldRepository(),
      ),
    ],
  );
  if (identity != null) {
    container.read(_identityProvider.notifier).state = identity;
  }
  return container;
}

Future<CartState> _waitFor(
  ProviderContainer container,
  bool Function(CartState state) predicate,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    final state = container.read(cartControllerProvider);
    if (predicate(state)) return state;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  throw TestFailure(
    'Cart state non raggiunto: ${container.read(cartControllerProvider).status}',
  );
}

AppConfig _config() => AppConfig.fromValues(
  appEnvironment: 'staging',
  supabaseUrl: 'https://staging.example.invalid',
  supabasePublishableKey: 'sb_publishable_staging',
  authRedirectUri: AppConfig.allowedAuthRedirectUri,
  googleAuthEnabled: 'false',
  storefrontShopSlug: 'storefront-test',
);

AuthenticatedCustomer _identity() =>
    AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: '10000000-0000-4000-8000-000000000001',
      email: 'customer@example.invalid',
      metadata: const {'name': 'Cliente'},
    );

CustomerCartSnapshot _snapshot({
  required CartSource source,
  int version = 0,
  List<CartLine> items = const [],
}) => CustomerCartSnapshot(
  shopSlug: 'storefront-test',
  version: version,
  items: items,
  source: source,
  quoteStatus: CartQuoteStatus.indicative,
  requiresCustomerReview: false,
  subtotalClp: items.fold(0, (total, item) => total + item.lineSubtotalClp),
  idempotent: false,
);

CartLine _line(String id, {bool isGuest = false}) => CartLine(
  publicationId: id,
  publicName: id == _publicationId ? 'Café público' : 'Té no disponible',
  quantity: 1,
  priceClp: 1200,
  snapshotPriceClp: 1200,
  availability: StorefrontAvailability.available,
  status: CartLineStatus.available,
  changeType: CartLineChangeType.none,
  isGuest: isGuest,
);

StorefrontProductSummary _product() => StorefrontProductSummary(
  id: _publicationId,
  category: const StorefrontCategory(
    id: '40000000-0000-4000-8000-000000000001',
    slug: 'bebidas',
    name: 'Bebidas',
    sortRank: 1,
  ),
  name: 'Café público',
  priceClp: 1200,
  featured: false,
  sortRank: 1,
  availability: StorefrontAvailability.available,
  fulfillment: const StorefrontFulfillment(
    pickup: true,
    delivery: true,
    reservation: false,
  ),
  catalogVersion: 7,
  publishedAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
);

final class _FakeGuestStore implements GuestCartStore {
  _FakeGuestStore({CustomerCartSnapshot? snapshot})
    : snapshot = snapshot ?? _snapshot(source: CartSource.guest);

  CustomerCartSnapshot snapshot;
  int setProductCalls = 0;
  Set<String>? retainedIds;

  @override
  Future<CustomerCartSnapshot> read({required String shopSlug}) async =>
      snapshot;

  @override
  Future<CustomerCartSnapshot> setProduct({
    required String shopSlug,
    required StorefrontProductSummary product,
    required int quantity,
  }) async {
    setProductCalls++;
    final existing = snapshot.items.where(
      (item) => item.publicationId != product.id,
    );
    snapshot = _snapshot(
      source: CartSource.guest,
      items: [
        ...existing,
        CartLine(
          publicationId: product.id,
          publicName: product.name,
          quantity: quantity,
          priceClp: product.priceClp,
          snapshotPriceClp: product.priceClp,
          availability: product.availability,
          status: CartLineStatus.available,
          changeType: CartLineChangeType.none,
          isGuest: true,
        ),
      ],
    );
    return snapshot;
  }

  @override
  Future<CustomerCartSnapshot> setQuantity({
    required String shopSlug,
    required String publicationId,
    required int quantity,
  }) async {
    snapshot = _snapshot(
      source: CartSource.guest,
      items: snapshot.items
          .map(
            (item) => item.publicationId == publicationId
                ? item.copyWith(quantity: quantity)
                : item,
          )
          .toList(),
    );
    return snapshot;
  }

  @override
  Future<CustomerCartSnapshot> remove({
    required String shopSlug,
    required String publicationId,
  }) async {
    snapshot = _snapshot(
      source: CartSource.guest,
      items: snapshot.items
          .where((item) => item.publicationId != publicationId)
          .toList(),
    );
    return snapshot;
  }

  @override
  Future<CustomerCartSnapshot> clear({required String shopSlug}) async {
    snapshot = _snapshot(source: CartSource.guest);
    return snapshot;
  }

  @override
  Future<CustomerCartSnapshot> retainOnly({
    required String shopSlug,
    required Set<String> publicationIds,
  }) async {
    retainedIds = publicationIds;
    snapshot = _snapshot(
      source: CartSource.guest,
      items: snapshot.items
          .where((item) => publicationIds.contains(item.publicationId))
          .toList(),
    );
    return snapshot;
  }
}

final class _FakeRemoteRepository implements CustomerCartRepository {
  _FakeRemoteRepository({
    required this.readResponse,
    List<Object> mergeOutcomes = const [],
    List<Object> mutationOutcomes = const [],
    List<Object> revalidationOutcomes = const [],
  }) : mergeOutcomes = [...mergeOutcomes],
       mutationOutcomes = [...mutationOutcomes],
       revalidationOutcomes = [...revalidationOutcomes];

  CartRemoteResponse readResponse;
  final List<Object> mergeOutcomes;
  final List<Object> mutationOutcomes;
  final List<Object> revalidationOutcomes;
  final List<String> mergeKeys = [];
  final List<int> mergeVersions = [];
  final List<CartMutationRequest> mutationRequests = [];
  int mergeCalls = 0;

  @override
  Future<CartRemoteResponse> read({required String shopSlug}) async =>
      readResponse;

  @override
  Future<CartRemoteResponse> mergeGuest({
    required String shopSlug,
    required List<CartLine> guestItems,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    mergeCalls++;
    mergeKeys.add(idempotencyKey);
    mergeVersions.add(expectedVersion);
    return _outcome(mergeOutcomes);
  }

  @override
  Future<CartRemoteResponse> mutate(CartMutationRequest request) async {
    mutationRequests.add(request);
    return _outcome(mutationOutcomes);
  }

  @override
  Future<CartRemoteResponse> revalidate({
    required String shopSlug,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    return _outcome(revalidationOutcomes);
  }

  CartRemoteResponse _outcome(List<Object> outcomes) {
    if (outcomes.isEmpty) throw StateError('missing fake outcome');
    final outcome = outcomes.removeAt(0);
    if (outcome is CartRepositoryException) throw outcome;
    return outcome as CartRemoteResponse;
  }
}
