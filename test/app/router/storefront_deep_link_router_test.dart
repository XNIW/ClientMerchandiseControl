import 'dart:async';

import 'package:client_merchandise_control/app/router/app_router.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/auth/application/auth_controller.dart';
import 'package:client_merchandise_control/features/auth/application/auth_providers.dart';
import 'package:client_merchandise_control/features/auth/data/auth_callback_source.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_repository.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_state.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/catalog/application/catalog_controller.dart';
import 'package:client_merchandise_control/features/customer_notifications/application/customer_notification_providers.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_failure.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_models.dart';
import 'package:client_merchandise_control/features/customer_notifications/domain/customer_notification_repository.dart';
import 'package:client_merchandise_control/features/orders/application/customer_order_providers.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_repository.dart';
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
import '../../features/orders/customer_order_test_support.dart';

const _publicationId = '50000000-0000-4000-8000-000000000001';
const _productLink =
    'com.xniw.clientmerchandisecontrol://storefront/'
    'storefront-test/product/$_publicationId';
const _categoryLink =
    'com.xniw.clientmerchandisecontrol://storefront/'
    'storefront-test/category/bebidas';
const _orderId = '88000000-0000-4000-8000-000000028101';
const _orderIdB = '88000000-0000-4000-8000-000000028102';
const _orderLink =
    'com.xniw.clientmerchandisecontrol://storefront/'
    'storefront-test/order/$_orderId';
const _notificationRouteA = 'f1000000-0000-4000-8000-000000031001';
const _notificationRouteB = 'f1000000-0000-4000-8000-000000031002';
const _notificationLinkA =
    'com.xniw.clientmerchandisecontrol://storefront/'
    'storefront-test/notification/$_notificationRouteA';
const _notificationLinkB =
    'com.xniw.clientmerchandisecontrol://storefront/'
    'storefront-test/notification/$_notificationRouteB';

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

  testWidgets(
    'ordine guest attende Auth e riprende il dettaglio dopo callback Google',
    (tester) async {
      final gateway = _FakeAppLinksGateway(initial: Uri.parse(_orderLink));
      final source = AppLinksAuthCallbackSource(gateway: gateway);
      final authRepository = _RouterAuthRepository();
      final container = _container(
        source,
        googleAuthEnabled: true,
        authRepository: authRepository,
      );
      addTearDown(() async {
        container.dispose();
        await source.dispose();
        await gateway.dispose();
        await authRepository.dispose();
      });

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(_app(container, router));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.accountLocation);

      gateway.emit(
        Uri.parse('${AppConfig.allowedAuthRedirectUri}?code=order-code'),
      );
      for (
        var attempt = 0;
        attempt < 50 && authRepository.exchangeCalls == 0;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      for (
        var attempt = 0;
        attempt < 100 &&
            router.state.uri.path != AppRoutes.orderLocation(_orderId);
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 10));
      }

      expect(authRepository.exchangeCalls, 1);
      expect(router.state.uri.path, AppRoutes.orderLocation(_orderId));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'notifica cold guest risolve la route opaca solo dopo autenticazione',
    (tester) async {
      final gateway = _FakeAppLinksGateway(
        initial: Uri.parse(_notificationLinkA),
      );
      final source = AppLinksAuthCallbackSource(gateway: gateway);
      final authRepository = _RouterAuthRepository();
      final notificationRepository = _NotificationRepository()
        ..outcomes[_notificationRouteA] = Future.value(
          const CustomerNotificationOrderDestination(
            orderId: _orderId,
            event: CustomerNotificationEvent.ready,
            eventVersion: 4,
          ),
        );
      final orderRepository = FakeCustomerOrderRepository();
      final container = _container(
        source,
        googleAuthEnabled: true,
        authRepository: authRepository,
        notificationRepository: notificationRepository,
        customerOrderRepository: orderRepository,
      );
      addTearDown(() async {
        container.dispose();
        await source.dispose();
        await gateway.dispose();
        await authRepository.dispose();
      });

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(_app(container, router));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.accountLocation);
      expect(notificationRepository.calls, isEmpty);

      gateway.emit(
        Uri.parse('${AppConfig.allowedAuthRedirectUri}?code=notification-code'),
      );
      for (
        var attempt = 0;
        attempt < 100 &&
            router.state.uri.path != AppRoutes.orderLocation(_orderId);
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 10));
      }

      expect(notificationRepository.calls, [_notificationRouteA]);
      expect(router.state.uri.path, AppRoutes.orderLocation(_orderId));
      expect(
        orderRepository.detailRequests,
        contains((shopSlug: orderTestShop, orderId: _orderId)),
      );
      expect(router.state.uri.toString(), isNot(contains(_notificationRouteA)));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'notifiche warm duplicate e fuori ordine navigano una volta alla più recente',
    (tester) async {
      final gateway = _FakeAppLinksGateway();
      final source = AppLinksAuthCallbackSource(gateway: gateway);
      final authRepository = _RouterAuthRepository(authenticated: true);
      final first = Completer<CustomerNotificationDestination>();
      final second = Completer<CustomerNotificationDestination>();
      final notificationRepository = _NotificationRepository()
        ..outcomes[_notificationRouteA] = first.future
        ..outcomes[_notificationRouteB] = second.future;
      final container = _container(
        source,
        googleAuthEnabled: true,
        authRepository: authRepository,
        notificationRepository: notificationRepository,
      );
      addTearDown(() async {
        container.dispose();
        await source.dispose();
        await gateway.dispose();
        await authRepository.dispose();
      });

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(_app(container, router));
      for (
        var attempt = 0;
        attempt < 100 &&
            container.read(authControllerProvider) is! AuthAuthenticated;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(container.read(authControllerProvider), isA<AuthAuthenticated>());

      gateway.emit(Uri.parse(_notificationLinkA));
      gateway.emit(Uri.parse(_notificationLinkA));
      await tester.pump();
      gateway.emit(Uri.parse(_notificationLinkB));
      await tester.pump();
      expect(notificationRepository.calls, [
        _notificationRouteA,
        _notificationRouteB,
      ]);

      second.complete(
        const CustomerNotificationOrderDestination(
          orderId: _orderIdB,
          event: CustomerNotificationEvent.completed,
          eventVersion: 2,
        ),
      );
      for (
        var attempt = 0;
        attempt < 100 &&
            router.state.uri.path != AppRoutes.orderLocation(_orderIdB);
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(router.state.uri.path, AppRoutes.orderLocation(_orderIdB));

      first.complete(
        const CustomerNotificationOrderDestination(
          orderId: _orderId,
          event: CustomerNotificationEvent.preparing,
          eventVersion: 2,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(router.state.uri.path, AppRoutes.orderLocation(_orderIdB));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('notifica offline non naviga e non causa crash', (tester) async {
    final gateway = _FakeAppLinksGateway();
    final source = AppLinksAuthCallbackSource(gateway: gateway);
    final authRepository = _RouterAuthRepository(authenticated: true);
    final notificationRepository = _NotificationRepository()
      ..errors[_notificationRouteA] =
          const CustomerNotificationRepositoryException(
            CustomerNotificationFailureKind.offline,
          );
    final container = _container(
      source,
      googleAuthEnabled: true,
      authRepository: authRepository,
      notificationRepository: notificationRepository,
    );
    addTearDown(() async {
      container.dispose();
      await source.dispose();
      await gateway.dispose();
      await authRepository.dispose();
    });

    final router = container.read(appRouterProvider);
    await tester.pumpWidget(_app(container, router));
    for (
      var attempt = 0;
      attempt < 100 &&
          container.read(authControllerProvider) is! AuthAuthenticated;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    gateway.emit(Uri.parse(_notificationLinkA));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.homeLocation);
    expect(notificationRepository.calls, [_notificationRouteA]);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(ProviderContainer container, GoRouter router) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: const Locale('es', 'CL'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

ProviderContainer _container(
  AuthCallbackSource source, {
  _DeepLinkStorefrontRepository? repository,
  bool googleAuthEnabled = false,
  AuthRepository? authRepository,
  CustomerNotificationRepository? notificationRepository,
  CustomerOrderRepository? customerOrderRepository,
}) => ProviderContainer(
  overrides: [
    appConfigProvider.overrideWithValue(
      AppConfig.fromValues(
        appEnvironment: 'staging',
        supabaseUrl: 'https://staging.example.invalid',
        supabasePublishableKey: 'sb_publishable_staging',
        authRedirectUri: AppConfig.allowedAuthRedirectUri,
        googleAuthEnabled: '$googleAuthEnabled',
        storefrontShopSlug: 'storefront-test',
      ),
    ),
    authCallbackSourceProvider.overrideWithValue(source),
    if (authRepository != null)
      authRepositoryFactoryProvider.overrideWithValue(
        (config) async => authRepository,
      ),
    backendReadinessRepositoryProvider.overrideWithValue(
      const _ReadyRepository(),
    ),
    storefrontRepositoryProvider.overrideWithValue(
      repository ?? _DeepLinkStorefrontRepository(),
    ),
    storefrontCacheRepositoryProvider.overrideWithValue(
      const DisabledStorefrontCacheRepository(),
    ),
    customerOrderRepositoryProvider.overrideWithValue(
      customerOrderRepository ?? FakeCustomerOrderRepository(),
    ),
    customerOrderCacheStoreProvider.overrideWithValue(
      MemoryCustomerOrderCacheStore(),
    ),
    customerOrderClockProvider.overrideWithValue(() => orderTestNow),
    if (notificationRepository != null)
      customerNotificationRepositoryProvider.overrideWithValue(
        notificationRepository,
      ),
  ],
);

final class _RouterAuthRepository implements AuthRepository {
  _RouterAuthRepository({bool authenticated = false}) {
    if (authenticated) {
      currentCustomer = AuthenticatedCustomer.fromUntrustedIdentity(
        subjectId: orderTestOwner,
        email: 'customer@example.invalid',
        metadata: const {'name': 'Order Customer'},
      );
    }
  }

  final StreamController<AuthSessionEvent> _events =
      StreamController<AuthSessionEvent>.broadcast();

  @override
  AuthenticatedCustomer? currentCustomer;
  int exchangeCalls = 0;

  @override
  Stream<AuthSessionEvent> get sessionChanges => _events.stream;

  @override
  Future<void> clearPendingOAuth() async {}

  @override
  Future<AuthenticatedCustomer> exchangeCodeForSession(String code) async {
    exchangeCalls++;
    currentCustomer = AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: orderTestOwner,
      email: 'customer@example.invalid',
      metadata: const {'name': 'Order Customer'},
    );
    return currentCustomer!;
  }

  @override
  Future<bool> launchGoogleSignIn() async => true;

  @override
  Future<void> signOutLocal() async {
    currentCustomer = null;
  }

  Future<void> dispose() => _events.close();
}

final class _NotificationRepository implements CustomerNotificationRepository {
  final Map<String, Future<CustomerNotificationDestination>> outcomes = {};
  final Map<String, CustomerNotificationRepositoryException> errors = {};
  final List<String> calls = [];

  @override
  Future<CustomerNotificationDestination> resolveRoute({
    required String shopSlug,
    required String routeToken,
  }) {
    calls.add(routeToken);
    final error = errors[routeToken];
    if (error != null) return Future.error(error);
    return outcomes[routeToken] ??
        Future.error(
          const CustomerNotificationRepositoryException(
            CustomerNotificationFailureKind.notFound,
          ),
        );
  }
}

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
