import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/cart/application/cart_controller.dart';
import 'package:client_merchandise_control/features/cart/application/cart_providers.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_failure.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_models.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_repository.dart';
import 'package:client_merchandise_control/features/cart/presentation/add_to_cart_button.dart';
import 'package:client_merchandise_control/features/reservations/application/reservation_hold_providers.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../reservations/reservation_hold_test_support.dart';

const publication = '50000000-0000-4000-8000-000000000001';
final identity = StateProvider<AuthenticatedCustomer?>((ref) => customer());
final shop = StateProvider<String>((ref) => 'storefront-test');

void main() {
  for (final status in [
    CartRemoteStatus.unavailable,
    CartRemoteStatus.limitReached,
  ]) {
    testWidgets('rifiuto ${status.name} non annuncia aggiunta', (tester) async {
      final remote = Remote([
        CartRemoteResponse(status: status, snapshot: snapshot()),
      ]);
      final container = await mount(tester, remote);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(AddToCartButton)),
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.text(l10n.cartAddedNotice), findsNothing);
      expect(
        find.text(
          status == CartRemoteStatus.unavailable
              ? l10n.cartProductUnavailable
              : l10n.cartLimitReached,
        ),
        findsOneWidget,
      );
      expect(container.read(cartControllerProvider).snapshot!.items, isEmpty);
    });
  }
  testWidgets('ACK perso conserva errore, nessun falso successo', (
    tester,
  ) async {
    final remote = Remote([
      const CartRepositoryException(CartFailureKind.timeout),
    ]);
    final container = await mount(tester, remote);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AddToCartButton)),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.cartAddedNotice), findsNothing);
    expect(find.text(l10n.cartTimeoutError), findsOneWidget);
    expect(container.read(cartControllerProvider).hasPendingRetry, isTrue);
  });
  testWidgets('successo richiede ACK account', (tester) async {
    final remote = Remote([
      CartRemoteResponse(
        status: CartRemoteStatus.ok,
        snapshot: snapshot(quantity: 1, version: 5),
      ),
    ]);
    await mount(tester, remote);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AddToCartButton)),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.cartAddedNotice), findsOneWidget);
    expect(remote.requests, hasLength(1));
  });
}

Future<ProviderContainer> mount(WidgetTester tester, Remote remote) async {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWith(
        (ref) => AppConfig.fromValues(
          appEnvironment: 'staging',
          supabaseUrl: 'https://staging.example.invalid',
          supabasePublishableKey: 'sb_publishable_staging',
          authRedirectUri: AppConfig.allowedAuthRedirectUri,
          googleAuthEnabled: 'false',
          storefrontShopSlug: ref.watch(shop),
        ),
      ),
      customerAccountIdentityProvider.overrideWith(
        (ref) => ref.watch(identity),
      ),
      guestCartStoreProvider.overrideWithValue(Guest()),
      customerCartRepositoryProvider.overrideWithValue(remote),
      customerIdempotencyKeyFactoryProvider.overrideWithValue(
        () => '60000000-0000-4000-8000-000000000001',
      ),
      reservationHoldLocalStoreProvider.overrideWithValue(
        MemoryReservationHoldStore(),
      ),
      reservationHoldRepositoryProvider.overrideWithValue(
        FakeReservationHoldRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('es', 'CL'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AddToCartButton(product: product())),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

AuthenticatedCustomer customer({String suffix = '1'}) =>
    AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: '10000000-0000-4000-8000-00000000000$suffix',
      email: 'customer@example.invalid',
      metadata: const {'name': 'Cliente'},
    );
CustomerCartSnapshot snapshot({
  int quantity = 0,
  int version = 4,
  String slug = 'storefront-test',
}) => CustomerCartSnapshot(
  shopSlug: slug,
  version: version,
  source: CartSource.account,
  quoteStatus: CartQuoteStatus.indicative,
  requiresCustomerReview: false,
  subtotalClp: quantity * 1200,
  idempotent: false,
  items: [
    if (quantity > 0)
      CartLine(
        publicationId: publication,
        publicName: 'Café público',
        quantity: quantity,
        priceClp: 1200,
        snapshotPriceClp: 1200,
        availability: StorefrontAvailability.available,
        status: CartLineStatus.available,
        changeType: CartLineChangeType.none,
        isGuest: false,
      ),
  ],
);
StorefrontProductSummary product() => StorefrontProductSummary(
  id: publication,
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

final class Remote implements CustomerCartRepository {
  Remote(this.outcomes);
  final List<Object> outcomes;
  final List<CartMutationRequest> requests = [];
  @override
  Future<CartRemoteResponse> read({required String shopSlug}) async =>
      CartRemoteResponse(
        status: CartRemoteStatus.ok,
        snapshot: snapshot(slug: shopSlug),
      );
  @override
  Future<CartRemoteResponse> mutate(CartMutationRequest request) async {
    requests.add(request);
    final outcome = outcomes.removeAt(0);
    if (outcome is CartRepositoryException) throw outcome;
    if (outcome is Future<CartRemoteResponse>) return outcome;
    return outcome as CartRemoteResponse;
  }

  @override
  Future<CartRemoteResponse> mergeGuest({
    required String shopSlug,
    required List<CartLine> guestItems,
    required int expectedVersion,
    required String idempotencyKey,
  }) async => throw UnimplementedError();
  @override
  Future<CartRemoteResponse> revalidate({
    required String shopSlug,
    required int expectedVersion,
    required String idempotencyKey,
  }) async => throw UnimplementedError();
}

final class Guest implements GuestCartStore {
  @override
  Future<CustomerCartSnapshot> read({required String shopSlug}) async =>
      CustomerCartSnapshot.empty(shopSlug: shopSlug, source: CartSource.guest);
  @override
  Future<CustomerCartSnapshot> setProduct({
    required String shopSlug,
    required StorefrontProductSummary product,
    required int quantity,
  }) async => throw UnimplementedError();
  @override
  Future<CustomerCartSnapshot> setQuantity({
    required String shopSlug,
    required String publicationId,
    required int quantity,
  }) async => throw UnimplementedError();
  @override
  Future<CustomerCartSnapshot> remove({
    required String shopSlug,
    required String publicationId,
  }) async => throw UnimplementedError();
  @override
  Future<CustomerCartSnapshot> clear({required String shopSlug}) async =>
      throw UnimplementedError();
  @override
  Future<CustomerCartSnapshot> retainOnly({
    required String shopSlug,
    required Set<String> publicationIds,
  }) async => throw UnimplementedError();
}
