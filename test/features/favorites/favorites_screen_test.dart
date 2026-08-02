import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/cart/application/cart_providers.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_models.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_repository.dart';
import 'package:client_merchandise_control/features/favorites/presentation/favorites_screen.dart';
import 'package:client_merchandise_control/features/storefront/application/storefront_providers.dart';
import 'package:client_merchandise_control/features/storefront/cache/drift_storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_database.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _publicationId = '50000000-0000-4000-8000-000000000001';

void main() {
  testWidgets('lista favorite mostra dati pubblici e rimozione accessibile', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final fixture = await _favoriteFixture();
    final guest = _FavoriteGuestCartStore();
    addTearDown(fixture.database.close);
    await tester.pumpWidget(_app(fixture.cache, guestCartStore: guest));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('favorites-list')), findsOneWidget);
    expect(find.text('Café favorito'), findsOneWidget);
    expect(find.text('Bebidas'), findsOneWidget);
    expect(find.textContaining(_publicationId), findsNothing);
    expect(find.textContaining('supplier'), findsNothing);
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('remove-favorite-$_publicationId')),
          )
          .label,
      contains('Quitar de favoritos'),
    );

    await tester.tap(find.byKey(ValueKey('add-to-cart-$_publicationId')));
    await tester.pumpAndSettle();
    expect(guest.setCalls, 1);

    await tester.tap(
      find.byKey(const ValueKey('remove-favorite-$_publicationId')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes favoritos'), findsOneWidget);
    expect(find.text('Café favorito'), findsNothing);
    semantics.dispose();
  });

  testWidgets('orphan/unpublished resta generico e non espone ID tecnico', (
    tester,
  ) async {
    final fixture = await _favoriteFixture();
    addTearDown(fixture.database.close);
    await fixture.cache.clearShop(shopSlug: 'storefront-test');

    await tester.pumpWidget(_app(fixture.cache));
    await tester.pumpAndSettle();

    expect(find.text('Producto no disponible'), findsOneWidget);
    expect(
      find.text('Puedes conservar este favorito o quitarlo de la lista.'),
      findsOneWidget,
    );
    expect(find.textContaining(_publicationId), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failure locale mostra errore recuperabile senza dettagli driver',
    (tester) async {
      final database = StorefrontCacheDatabase(NativeDatabase.memory());
      final cache = DriftStorefrontCacheRepository(database);
      await database.customSelect('SELECT 1').get();
      await database.close();

      await tester.pumpWidget(_app(cache));
      await tester.pumpAndSettle();

      expect(find.text('No pudimos abrir tus favoritos'), findsOneWidget);
      expect(find.textContaining('Bad state'), findsNothing);
      expect(find.textContaining('sqlite'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rifluisce a 200% in dark compact per quattro locale', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final locale in const [
      Locale('es', 'CL'),
      Locale('it'),
      Locale('en'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    ]) {
      final fixture = await _favoriteFixture();
      await tester.binding.setSurfaceSize(const Size(360, 320));
      await tester.pumpWidget(
        _app(
          fixture.cache,
          locale: locale,
          themeMode: ThemeMode.dark,
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('favorites-list')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: locale.toLanguageTag());
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await fixture.database.close();
    }
  });
}

Widget _app(
  DriftStorefrontCacheRepository cache, {
  GuestCartStore? guestCartStore,
  Locale locale = const Locale('es', 'CL'),
  ThemeMode themeMode = ThemeMode.light,
  TextScaler textScaler = TextScaler.noScaling,
}) => ProviderScope(
  overrides: [
    appConfigProvider.overrideWithValue(_config()),
    storefrontCacheRepositoryProvider.overrideWithValue(cache),
    customerAccountIdentityProvider.overrideWithValue(null),
    guestCartStoreProvider.overrideWithValue(
      guestCartStore ?? _FavoriteGuestCartStore(),
    ),
  ],
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: themeMode,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: const FavoritesScreen(),
  ),
);

Future<
  ({StorefrontCacheDatabase database, DriftStorefrontCacheRepository cache})
>
_favoriteFixture() async {
  final database = StorefrontCacheDatabase(NativeDatabase.memory());
  final cache = DriftStorefrontCacheRepository(database);
  await cache.writeProductDetail(
    shopSlug: 'storefront-test',
    product: _product(),
  );
  await cache.toggleFavorite(
    shopSlug: 'storefront-test',
    publicationId: _publicationId,
  );
  return (database: database, cache: cache);
}

AppConfig _config() => AppConfig.fromValues(
  appEnvironment: 'staging',
  supabaseUrl: 'https://staging.example.invalid',
  supabasePublishableKey: 'sb_publishable_staging',
  authRedirectUri: AppConfig.allowedAuthRedirectUri,
  googleAuthEnabled: 'false',
  storefrontShopSlug: 'storefront-test',
);

StorefrontProductSummary _product() => StorefrontProductSummary(
  id: _publicationId,
  category: const StorefrontCategory(
    id: '40000000-0000-4000-8000-000000000001',
    slug: 'bebidas',
    name: 'Bebidas',
    sortRank: 1,
  ),
  name: 'Café favorito',
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

final class _FavoriteGuestCartStore implements GuestCartStore {
  CustomerCartSnapshot snapshot = CustomerCartSnapshot.empty(
    shopSlug: 'storefront-test',
    source: CartSource.guest,
  );
  int setCalls = 0;

  @override
  Future<CustomerCartSnapshot> read({required String shopSlug}) async =>
      snapshot;

  @override
  Future<CustomerCartSnapshot> setProduct({
    required String shopSlug,
    required StorefrontProductSummary product,
    required int quantity,
  }) async {
    setCalls++;
    final line = CartLine(
      publicationId: product.id,
      publicName: product.name,
      quantity: quantity,
      priceClp: product.priceClp,
      snapshotPriceClp: product.priceClp,
      availability: product.availability,
      status: CartLineStatus.available,
      changeType: CartLineChangeType.none,
      isGuest: true,
    );
    snapshot = CustomerCartSnapshot(
      shopSlug: shopSlug,
      version: 0,
      items: [line],
      source: CartSource.guest,
      quoteStatus: CartQuoteStatus.indicative,
      requiresCustomerReview: false,
      subtotalClp: line.lineSubtotalClp,
      idempotent: true,
    );
    return snapshot;
  }

  @override
  Future<CustomerCartSnapshot> setQuantity({
    required String shopSlug,
    required String publicationId,
    required int quantity,
  }) async => snapshot;

  @override
  Future<CustomerCartSnapshot> remove({
    required String shopSlug,
    required String publicationId,
  }) async => snapshot;

  @override
  Future<CustomerCartSnapshot> clear({required String shopSlug}) async =>
      snapshot;

  @override
  Future<CustomerCartSnapshot> retainOnly({
    required String shopSlug,
    required Set<String> publicationIds,
  }) async => snapshot;
}
