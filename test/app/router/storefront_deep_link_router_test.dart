import 'dart:async';

import 'package:client_merchandise_control/app/router/app_router.dart';
import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/auth/application/auth_providers.dart';
import 'package:client_merchandise_control/features/auth/data/auth_callback_source.dart';
import 'package:client_merchandise_control/features/catalog/application/catalog_controller.dart';
import 'package:client_merchandise_control/features/storefront/application/storefront_providers.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_repository.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../features/storefront/storefront_test_fixture.dart';

const _publicationId = '50000000-0000-4000-8000-000000000001';
const _productLink =
    'com.xniw.clientmerchandisecontrol://storefront/'
    'storefront-test/product/$_publicationId';
const _categoryLink =
    'com.xniw.clientmerchandisecontrol://storefront/'
    'storefront-test/category/bebidas';

void main() {
  testWidgets(
    'cold prodotto e warm categoria condividono un solo source nativo',
    (tester) async {
      final gateway = _FakeAppLinksGateway(initial: Uri.parse(_productLink));
      final source = AppLinksAuthCallbackSource(gateway: gateway);
      final repository = _DeepLinkStorefrontRepository();
      final container = _container(source, repository: repository);
      addTearDown(() async {
        container.dispose();
        await source.dispose();
        await gateway.dispose();
      });

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(_app(container, router));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.productLocation(_publicationId));
      expect(gateway.initialReads, 1);
      expect(gateway.warmListeners, 1);

      gateway.emit(Uri.parse(_categoryLink));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.catalogLocation);
      expect(
        container.read(catalogControllerProvider).selectedCategorySlug,
        'bebidas',
      );
      expect(repository.catalogCalls, 1);
      gateway.emit(Uri.parse(_categoryLink));
      await tester.pumpAndSettle();
      expect(repository.catalogCalls, 1);
      expect(gateway.warmListeners, 1);
    },
  );

  testWidgets(
    'callback OAuth e link altro shop non cambiano route Storefront',
    (tester) async {
      final gateway = _FakeAppLinksGateway();
      final source = AppLinksAuthCallbackSource(gateway: gateway);
      final container = _container(source);
      addTearDown(() async {
        container.dispose();
        await source.dispose();
        await gateway.dispose();
      });

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(_app(container, router));
      await tester.pumpAndSettle();
      gateway.emit(
        Uri.parse('${AppConfig.allowedAuthRedirectUri}?code=oauth-private'),
      );
      gateway.emit(
        Uri.parse(
          'com.xniw.clientmerchandisecontrol://storefront/'
          'other-shop/product/$_publicationId',
        ),
      );
      await tester.pumpAndSettle();

      expect(router.state.uri.path, AppRoutes.homeLocation);
      expect(gateway.warmListeners, 1);
    },
  );
}

Widget _app(ProviderContainer container, GoRouter router) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('es', 'CL'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

ProviderContainer _container(
  AuthCallbackSource source, {
  _DeepLinkStorefrontRepository? repository,
}) => ProviderContainer(
  overrides: [
    appConfigProvider.overrideWithValue(
      AppConfig.fromValues(
        appEnvironment: 'staging',
        supabaseUrl: 'https://staging.example.invalid',
        supabasePublishableKey: 'sb_publishable_staging',
        authRedirectUri: AppConfig.allowedAuthRedirectUri,
        googleAuthEnabled: 'false',
        storefrontShopSlug: 'storefront-test',
      ),
    ),
    authCallbackSourceProvider.overrideWithValue(source),
    backendReadinessRepositoryProvider.overrideWithValue(
      const _ReadyRepository(),
    ),
    storefrontRepositoryProvider.overrideWithValue(
      repository ?? _DeepLinkStorefrontRepository(),
    ),
    storefrontCacheRepositoryProvider.overrideWithValue(
      const DisabledStorefrontCacheRepository(),
    ),
  ],
);

final class _FakeAppLinksGateway implements AppLinksGateway {
  _FakeAppLinksGateway({this.initial}) {
    _warm = StreamController<Uri>.broadcast(onListen: () => warmListeners++);
  }

  final Uri? initial;
  late final StreamController<Uri> _warm;
  var initialReads = 0;
  var warmListeners = 0;

  @override
  Future<Uri?> getInitialLink() async {
    initialReads++;
    return initial;
  }

  @override
  Stream<Uri> get uriLinkStream => _warm.stream;

  void emit(Uri uri) => _warm.add(uri);

  Future<void> dispose() => _warm.close();
}

final class _ReadyRepository implements BackendReadinessRepository {
  const _ReadyRepository();

  @override
  BackendReadinessState get initialState => BackendReadinessState.ready;

  @override
  bool get canCheck => false;

  @override
  Future<BackendReadinessState> check({
    required BackendProbeCancellation cancellation,
  }) async => BackendReadinessState.ready;
}

final class _DeepLinkStorefrontRepository implements StorefrontRepository {
  var catalogCalls = 0;

  @override
  Future<StorefrontCategoriesPage> fetchCategories({
    required String shopSlug,
    required String? cursor,
    required int limit,
    required StorefrontRequestCancellation cancellation,
  }) async => StorefrontCategoriesPage(
    catalogVersion: 7,
    categories: [
      StorefrontCategory(
        id: '40000000-0000-4000-8000-000000000001',
        slug: 'bebidas',
        name: 'Bebidas',
        sortRank: 1,
      ),
    ],
    nextCursor: null,
  );

  @override
  Future<StorefrontCatalogPage> fetchCatalog({
    required String shopSlug,
    required String? cursor,
    required int limit,
    required String? categorySlug,
    required StorefrontCatalogSort sort,
    StorefrontAvailability? availability,
    bool? discounted,
    required StorefrontRequestCancellation cancellation,
  }) async {
    catalogCalls++;
    return StorefrontCatalogPage(
      catalogVersion: 7,
      items: const [],
      nextCursor: null,
      sort: sort,
    );
  }

  @override
  Future<StorefrontHomeData> fetchHome({
    required String shopSlug,
    required StorefrontRequestCancellation cancellation,
  }) async => validStorefrontHomeData();

  @override
  Future<StorefrontProductSummary> fetchProductDetail({
    required String shopSlug,
    required String publicationId,
    required StorefrontRequestCancellation cancellation,
  }) async => StorefrontProductSummary(
    id: publicationId,
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

  @override
  Future<StorefrontSearchPage> fetchSearch({
    required String shopSlug,
    required String query,
    required String? cursor,
    required int limit,
    required String? categorySlug,
    required StorefrontRequestCancellation cancellation,
  }) => throw UnsupportedError('outside deep-link test');
}
