import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

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
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../reservations/reservation_hold_test_support.dart';
import '../../support/client_host_visual_fonts.dart';

const publication = '50000000-0000-4000-8000-000000000001';
final identity = StateProvider<AuthenticatedCustomer?>((ref) => customer());
final shop = StateProvider<String>((ref) => 'storefront-test');

void main() {
  setUpAll(loadClientHostVisualFonts);
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
  testWidgets('guest conferma salvataggio locale distinto da ACK server', (
    tester,
  ) async {
    final remote = Remote([]);
    final container = await mount(tester, remote, guest: true);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AddToCartButton)),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.cartLocalSavedNotice), findsOneWidget);
    expect(find.text(l10n.cartAddedNotice), findsNothing);
    expect(remote.requests, isEmpty);
    expect(container.read(cartControllerProvider).snapshot!.totalQuantity, 1);
  });
  testWidgets('due tap nello stesso frame inviano una sola richiesta', (
    tester,
  ) async {
    final barrier = Completer<CartRemoteResponse>();
    final remote = Remote([barrier.future]);
    await mount(tester, remote);
    await tester.tap(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(remote.requests, hasLength(1));
    barrier.complete(
      CartRemoteResponse(
        status: CartRemoteStatus.ok,
        snapshot: snapshot(quantity: 1, version: 5),
      ),
    );
    await tester.pumpAndSettle();
    expect(remote.requests, hasLength(1));
  });
  for (final change in ['account', 'shop']) {
    testWidgets('ACK tardivo dopo cambio $change non annuncia successo', (
      tester,
    ) async {
      final barrier = Completer<CartRemoteResponse>();
      final remote = Remote([barrier.future]);
      final container = await mount(tester, remote);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(AddToCartButton)),
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(remote.requests, hasLength(1));
      if (change == 'account') {
        container.read(identity.notifier).state = customer(suffix: '2');
      } else {
        container.read(shop.notifier).state = 'other-store';
      }
      await tester.pumpAndSettle();
      barrier.complete(
        CartRemoteResponse(
          status: CartRemoteStatus.ok,
          snapshot: snapshot(quantity: 1, version: 5),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text(l10n.cartAddedNotice), findsNothing);
      expect(container.read(cartControllerProvider).snapshot!.items, isEmpty);
    });
  }
  testWidgets(
    'timeout poi add non sostituisce intent; retry riconcilia lo stesso ACK',
    (tester) async {
      final remote = Remote([
        const CartRepositoryException(CartFailureKind.timeout),
        CartRemoteResponse(
          status: CartRemoteStatus.ok,
          snapshot: snapshot(quantity: 1, version: 5),
        ),
      ]);
      final container = await mount(tester, remote);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(AddToCartButton)),
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(remote.requests, hasLength(1));
      expect(find.text(l10n.cartAddedNotice), findsNothing);
      await tester.runAsync(
        () => container.read(cartControllerProvider.notifier).retry(),
      );
      await tester.pumpAndSettle();
      expect(remote.requests, hasLength(2));
      expect(
        remote.requests[1].idempotencyKey,
        remote.requests[0].idempotencyKey,
      );
      expect(remote.requests[1].quantity, remote.requests[0].quantity);
      expect(
        remote.requests[1].expectedVersion,
        remote.requests[0].expectedVersion,
      );
      expect(container.read(cartControllerProvider).snapshot!.totalQuantity, 1);
      expect(container.read(cartControllerProvider).hasPendingRetry, isFalse);
    },
  );
  testWidgets(
    'clearNotice di altro listener non converte un rifiuto in successo',
    (tester) async {
      final remote = Remote([
        CartRemoteResponse(
          status: CartRemoteStatus.unavailable,
          snapshot: snapshot(),
        ),
      ]);
      final container = await mount(tester, remote);
      container.listen(cartControllerProvider, (previous, next) {
        if (next.notice != null) {
          container.read(cartControllerProvider.notifier).clearNotice();
        }
      });
      final l10n = AppLocalizations.of(
        tester.element(find.byType(AddToCartButton)),
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.text(l10n.cartProductUnavailable), findsOneWidget);
      expect(find.text(l10n.cartAddedNotice), findsNothing);
    },
  );
  for (final locale in const [Locale('es', 'CL'), Locale('it'), Locale('en'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')]) {
    for (final dark in [false, true]) {
      testWidgets('feedback pending ${locale.toLanguageTag()} dark=$dark testo200 e semantics', (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final semantics = tester.ensureSemantics();
        addTearDown(semantics.dispose);
        await mount(tester, Remote([const CartRepositoryException(CartFailureKind.timeout)]),
            locale: locale, dark: dark, scaled: true);
        final l10n = AppLocalizations.of(tester.element(find.byType(AddToCartButton)));
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(find.text(l10n.cartPendingConfirmationNotice), findsOneWidget);
        expect(find.text(l10n.cartAddedNotice), findsNothing);
        expect(tester.getSemantics(find.text(l10n.cartPendingConfirmationNotice)).getSemanticsData().label,
            contains(l10n.cartPendingConfirmationNotice));
        expect(tester.takeException(), isNull);
        final path = Platform.environment['CMC_CLIENT_CAPTURE_DIR'];
        if (path != null) {
          await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('cart-feedback-frame')));
          final frame = await boundary.toImage();
          final data = await frame.toByteData(format: ui.ImageByteFormat.png);
          await File('$path/cart-pending-${locale.toLanguageTag()}-${dark ? 'dark' : 'light'}-200.png')
              .writeAsBytes(data!.buffer.asUint8List());
          frame.dispose();
          });
        }
      });
    }
  }

}

Future<ProviderContainer> mount(
  WidgetTester tester,
  Remote remote, {
  bool guest = false,
  Locale locale = const Locale('es', 'CL'),
  bool dark = false,
  bool scaled = false,
}) async {
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
  if (guest) container.read(identity.notifier).state = null;
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        theme: clientHostVisualTheme(AppTheme.light()),
        darkTheme: clientHostVisualTheme(AppTheme.dark()),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) => RepaintBoundary(key: const ValueKey('cart-feedback-frame'),
          child: MediaQuery(data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scaled ? 2 : 1), disableAnimations: true), child: child!)),
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
  CustomerCartSnapshot? current;
  @override
  Future<CartRemoteResponse> read({required String shopSlug}) async =>
      CartRemoteResponse(
        status: CartRemoteStatus.ok,
        snapshot: current?.shopSlug == shopSlug ? current : snapshot(slug: shopSlug),
      );
  @override
  Future<CartRemoteResponse> mutate(CartMutationRequest request) async {
    requests.add(request);
    final outcome = outcomes.removeAt(0);
    if (outcome is CartRepositoryException) throw outcome;
    if (outcome is Future<CartRemoteResponse>) return outcome;
    final response = outcome as CartRemoteResponse;
    if (response.status == CartRemoteStatus.ok) current = response.snapshot;
    return response;
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
  CustomerCartSnapshot? saved;
  @override
  Future<CustomerCartSnapshot> read({required String shopSlug}) async =>
      saved ??
      CustomerCartSnapshot.empty(shopSlug: shopSlug, source: CartSource.guest);
  @override
  Future<CustomerCartSnapshot> setProduct({
    required String shopSlug,
    required StorefrontProductSummary product,
    required int quantity,
  }) async {
    final account = snapshot(quantity: quantity, version: 0, slug: shopSlug);
    saved = CustomerCartSnapshot(
      shopSlug: shopSlug,
      version: 0,
      source: CartSource.guest,
      quoteStatus: CartQuoteStatus.indicative,
      requiresCustomerReview: false,
      subtotalClp: account.subtotalClp,
      idempotent: true,
      items: account.items.map((line) => line.copyWith(isGuest: true)).toList(),
    );
    return saved!;
  }

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
