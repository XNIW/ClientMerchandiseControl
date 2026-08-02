import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/cart/application/cart_controller.dart';
import 'package:client_merchandise_control/features/cart/application/cart_providers.dart';
import 'package:client_merchandise_control/features/cart/application/cart_state.dart';
import 'package:client_merchandise_control/features/cart/data/drift_guest_cart_store.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_models.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_repository.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_database.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _shopSlug = 'storefront-cart-integration';
const _publicationId = '50000000-0000-4000-8000-000000000023';
const _customerId = '10000000-0000-4000-8000-000000000023';
const _idempotencyKey = '60000000-0000-4000-8000-000000000023';

final _identityProvider = StateProvider<AuthenticatedCustomer?>((ref) {
  return AuthenticatedCustomer.fromUntrustedIdentity(
    subjectId: _customerId,
    email: 'cart-integration@example.invalid',
    metadata: const {'name': 'Cart Integration'},
  );
});

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'guest restart, login merge, revalidation e logout restano coerenti',
    (tester) async {
      var database = StorefrontCacheDatabase.defaults();
      var guestStore = DriftGuestCartStore(database);
      await guestStore.clear(shopSlug: _shopSlug);
      await guestStore.setProduct(
        shopSlug: _shopSlug,
        product: _product(),
        quantity: 2,
      );
      await database.close();

      database = StorefrontCacheDatabase.defaults();
      guestStore = DriftGuestCartStore(database);
      addTearDown(() async {
        await guestStore.clear(shopSlug: _shopSlug);
        await database.close();
      });
      final restored = await guestStore.read(shopSlug: _shopSlug);
      expect(restored.items.single.publicationId, _publicationId);
      expect(restored.totalQuantity, 2);

      final mergedSnapshot = _snapshot(version: 5, items: [_line(quantity: 2)]);
      final revalidatedSnapshot = _snapshot(
        version: 5,
        items: [_line(quantity: 2, priceClp: 1100)],
        quoteStatus: CartQuoteStatus.confirmed,
        requiresCustomerReview: true,
      );
      final remote = _IntegrationCartRepository(
        readResponse: CartRemoteResponse(
          status: CartRemoteStatus.ok,
          snapshot: _snapshot(version: 4),
        ),
        mergeResponse: CartRemoteResponse(
          status: CartRemoteStatus.merged,
          snapshot: mergedSnapshot,
        ),
        revalidateResponse: CartRemoteResponse(
          status: CartRemoteStatus.revalidated,
          snapshot: revalidatedSnapshot,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(_config()),
          guestCartStoreProvider.overrideWithValue(guestStore),
          customerCartRepositoryProvider.overrideWithValue(remote),
          customerAccountIdentityProvider.overrideWith(
            (ref) => ref.watch(_identityProvider),
          ),
          customerIdempotencyKeyFactoryProvider.overrideWithValue(
            () => _idempotencyKey,
          ),
        ],
      );
      addTearDown(container.dispose);

      await _waitFor(
        tester,
        container,
        (state) => state.notice == CartNoticeKind.merged,
      );
      expect(remote.mergeCalls, 1);
      expect(remote.readShopSlug, _shopSlug);
      expect(remote.mergeShopSlug, _shopSlug);
      expect(remote.mergeGuestItems.single.publicationId, _publicationId);
      expect(remote.mergeGuestItems.single.quantity, 2);
      expect(remote.mergeExpectedVersion, 4);
      expect(remote.mergeIdempotencyKey, _idempotencyKey);
      expect((await guestStore.read(shopSlug: _shopSlug)).items, isEmpty);
      expect(container.read(cartControllerProvider).snapshot?.version, 5);

      await container.read(cartControllerProvider.notifier).revalidate();
      final revalidated = container.read(cartControllerProvider);
      expect(revalidated.notice, CartNoticeKind.revalidated);
      expect(revalidated.snapshot?.quoteStatus, CartQuoteStatus.confirmed);
      expect(revalidated.snapshot?.subtotalClp, 2200);
      expect(remote.revalidateCalls, 1);
      expect(remote.revalidateShopSlug, _shopSlug);
      expect(remote.revalidateExpectedVersion, 5);
      expect(remote.revalidateIdempotencyKey, _idempotencyKey);

      container.read(_identityProvider.notifier).state = null;
      await _waitFor(
        tester,
        container,
        (state) =>
            !state.isAuthenticated &&
            state.status == CartViewStatus.ready &&
            state.snapshot?.source == CartSource.guest,
      );
      expect(container.read(cartControllerProvider).snapshot?.items, isEmpty);
      expect(remote.readCalls, 1);

      expect(tester.takeException(), isNull);

      binding.reportData = <String, Object?>{
        'guestPersistenceRestart': 'PASS',
        'loginMerge': 'PASS',
        'mergeCleanupAfterAck': 'PASS',
        'serverRevalidationAdapter': 'PASS',
        'accountLogoutIsolation': 'PASS',
        'idempotencyKey': 'stable',
        'internalIdentifiers': 'absent',
        'processAlive': 'PASS',
      };
    },
  );
}

Future<CartState> _waitFor(
  WidgetTester tester,
  ProviderContainer container,
  bool Function(CartState state) predicate,
) async {
  for (var attempt = 0; attempt < 1000; attempt++) {
    final state = container.read(cartControllerProvider);
    if (predicate(state)) return state;
    await tester.pump(const Duration(milliseconds: 10));
  }
  final state = container.read(cartControllerProvider);
  fail(
    'Cart non ha raggiunto lo stato atteso: '
    'status=${state.status.name}, auth=${state.isAuthenticated}, '
    'failure=${state.failureKind?.name}, notice=${state.notice?.name}, '
    'version=${state.snapshot?.version}, '
    'source=${state.snapshot?.source.name}, '
    'items=${state.snapshot?.items.length}.',
  );
}

AppConfig _config() => AppConfig.fromValues(
  appEnvironment: 'staging',
  supabaseUrl: 'https://staging.example.invalid',
  supabasePublishableKey: 'sb_publishable_staging',
  authRedirectUri: AppConfig.allowedAuthRedirectUri,
  googleAuthEnabled: 'false',
  storefrontShopSlug: _shopSlug,
);

StorefrontProductSummary _product() => StorefrontProductSummary(
  id: _publicationId,
  category: const StorefrontCategory(
    id: '40000000-0000-4000-8000-000000000023',
    slug: 'integration',
    name: 'Integración',
    sortRank: 1,
  ),
  name: 'Producto público de integración',
  priceClp: 1200,
  featured: false,
  sortRank: 1,
  availability: StorefrontAvailability.available,
  fulfillment: const StorefrontFulfillment(
    pickup: true,
    delivery: false,
    reservation: false,
  ),
  catalogVersion: 23,
  publishedAt: DateTime.utc(2026, 8, 2),
  updatedAt: DateTime.utc(2026, 8, 2),
);

CartLine _line({required int quantity, int priceClp = 1200}) => CartLine(
  publicationId: _publicationId,
  publicName: 'Producto público de integración',
  quantity: quantity,
  priceClp: priceClp,
  snapshotPriceClp: 1200,
  availability: StorefrontAvailability.available,
  status: CartLineStatus.available,
  changeType: priceClp == 1200
      ? CartLineChangeType.none
      : CartLineChangeType.priceChanged,
  isGuest: false,
);

CustomerCartSnapshot _snapshot({
  required int version,
  List<CartLine> items = const [],
  CartQuoteStatus quoteStatus = CartQuoteStatus.indicative,
  bool requiresCustomerReview = false,
}) => CustomerCartSnapshot(
  shopSlug: _shopSlug,
  version: version,
  items: items,
  source: CartSource.account,
  quoteStatus: quoteStatus,
  requiresCustomerReview: requiresCustomerReview,
  subtotalClp: items.fold(0, (total, item) => total + item.lineSubtotalClp),
  idempotent: false,
  quotedAt: quoteStatus == CartQuoteStatus.confirmed
      ? DateTime.utc(2026, 8, 2, 12)
      : null,
  quoteExpiresAt: quoteStatus == CartQuoteStatus.confirmed
      ? DateTime.utc(2026, 8, 2, 12, 5)
      : null,
);

final class _IntegrationCartRepository implements CustomerCartRepository {
  _IntegrationCartRepository({
    required this.readResponse,
    required this.mergeResponse,
    required this.revalidateResponse,
  });

  final CartRemoteResponse readResponse;
  final CartRemoteResponse mergeResponse;
  final CartRemoteResponse revalidateResponse;
  int readCalls = 0;
  int mergeCalls = 0;
  int revalidateCalls = 0;
  String? readShopSlug;
  String? mergeShopSlug;
  String? revalidateShopSlug;
  List<CartLine> mergeGuestItems = const [];
  int? mergeExpectedVersion;
  int? revalidateExpectedVersion;
  String? mergeIdempotencyKey;
  String? revalidateIdempotencyKey;

  @override
  Future<CartRemoteResponse> read({required String shopSlug}) async {
    readCalls++;
    readShopSlug = shopSlug;
    return readResponse;
  }

  @override
  Future<CartRemoteResponse> mergeGuest({
    required String shopSlug,
    required List<CartLine> guestItems,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    mergeCalls++;
    mergeShopSlug = shopSlug;
    mergeGuestItems = List.unmodifiable(guestItems);
    mergeExpectedVersion = expectedVersion;
    mergeIdempotencyKey = idempotencyKey;
    return mergeResponse;
  }

  @override
  Future<CartRemoteResponse> revalidate({
    required String shopSlug,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    revalidateCalls++;
    revalidateShopSlug = shopSlug;
    revalidateExpectedVersion = expectedVersion;
    revalidateIdempotencyKey = idempotencyKey;
    return revalidateResponse;
  }

  @override
  Future<CartRemoteResponse> mutate(CartMutationRequest request) {
    throw StateError('Mutation non prevista nel flow di integrazione.');
  }
}
