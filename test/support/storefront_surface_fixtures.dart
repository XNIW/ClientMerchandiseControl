import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/features/cart/application/cart_providers.dart';
import 'package:client_merchandise_control/features/cart/data/drift_guest_cart_store.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_failure.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_models.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_repository.dart';
import 'package:client_merchandise_control/features/catalog/application/search_assist_controller.dart';
import 'package:client_merchandise_control/features/catalog/domain/search_assist_models.dart';
import 'package:client_merchandise_control/features/catalog/domain/search_assist_repository.dart';
import 'package:client_merchandise_control/features/orders/application/customer_order_providers.dart';
import 'package:client_merchandise_control/features/storefront/application/storefront_providers.dart';
import 'package:client_merchandise_control/features/storefront/cache/drift_storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_database.dart';
import 'package:client_merchandise_control/features/storefront/data/supabase_storefront_repository.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_failure.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';

import '../features/storefront/storefront_test_fixture.dart';
import 'commerce_surface_fixtures.dart';

enum Task054StorefrontState { loaded, empty, offline, error }

final class Task054StorefrontFixtures {
  Task054StorefrontFixtures._(this.state, this.database)
    : commerce = Task054VisualFixtures(
        authenticated: false,
        state: state == Task054StorefrontState.empty
            ? Task054VisualState.empty
            : state == Task054StorefrontState.offline ||
                  state == Task054StorefrontState.error
            ? Task054VisualState.error
            : Task054VisualState.loaded,
      ),
      transport = Task054StorefrontRpcFixture(state),
      search = Task054SearchFixture(state);

  final Task054StorefrontState state;
  final StorefrontCacheDatabase database;
  final Task054VisualFixtures commerce;
  final Task054StorefrontRpcFixture transport;
  final Task054SearchFixture search;
  late final DriftStorefrontCacheRepository cache;
  late final Task054GuestStoreFailurePort cart;

  static Future<Task054StorefrontFixtures> create({
    Task054StorefrontState state = Task054StorefrontState.loaded,
    bool offlineCache = true,
  }) async {
    final value = Task054StorefrontFixtures._(
      state,
      StorefrontCacheDatabase(NativeDatabase.memory()),
    );
    final now = DateTime.now().toUtc();
    var clock = state == Task054StorefrontState.offline
        ? now.subtract(const Duration(hours: 1))
        : now;
    value.cache = DriftStorefrontCacheRepository(
      value.database,
      clock: () => clock,
    );
    value.cart = Task054GuestStoreFailurePort(
      DriftGuestCartStore(value.database),
    );
    final home = validStorefrontHomeData(); // già privo di immagini remote
    final products = [...home.featured, ...home.offers];
    if (state == Task054StorefrontState.offline && offlineCache) {
      await value.cache.writeHome(shopSlug: 'storefront-test', data: home);
      await value.cache.writeCategories(
        shopSlug: 'storefront-test',
        page: StorefrontCategoriesPage(
          catalogVersion: home.catalogVersion,
          categories: home.categories,
          nextCursor: null,
        ),
      );
      await value.cache.writeCatalog(
        shopSlug: 'storefront-test',
        page: StorefrontCatalogPage(
          catalogVersion: home.catalogVersion,
          items: products,
          nextCursor: null,
          sort: StorefrontCatalogSort.catalog,
        ),
        categorySlug: null,
        availability: null,
        discounted: null,
      );
      for (final product in products) {
        await value.cache.writeProductDetail(
          shopSlug: 'storefront-test',
          product: product,
        );
      }
    }
    clock = now;
    if (state != Task054StorefrontState.empty) {
      await value.cart.delegate.setProduct(
        shopSlug: 'storefront-test',
        product: products.first,
        quantity: 2,
      );
      await value.cart.delegate.setProduct(
        shopSlug: 'storefront-test',
        product: products.last,
        quantity: 1,
      );
    }
    return value;
  }

  Widget wrap(Widget child) => commerce.wrap(
    child,
    additionalOverrides: [
      backendReadinessRepositoryProvider.overrideWithValue(
        const Task054ReadyRepository(),
      ),
      // Repository concreto di produzione, con invoker locale: tutti i DTO,
      // cancellation e validatori reali restano esercitati.
      storefrontRepositoryProvider.overrideWithValue(
        SupabaseStorefrontRepository(invoke: transport.call),
      ),
      storefrontCacheDatabaseProvider.overrideWithValue(database),
      storefrontCacheRepositoryProvider.overrideWithValue(cache),
      guestCartStoreProvider.overrideWithValue(cart),
      customerOrderIdentityProvider.overrideWithValue(null),
      searchAssistRepositoryProvider.overrideWithValue(search),
      searchHistoryStoreProvider.overrideWithValue(search),
    ],
  );

  Future<void> dispose() => database.close();
}

final class Task054StorefrontRpcFixture {
  Task054StorefrontRpcFixture(this.state);
  Task054StorefrontState state;
  final List<String> calls = [];

  Future<Object?> call(String function, Map<String, Object?> parameters) async {
    calls.add(function);
    if (state == Task054StorefrontState.offline) {
      throw const StorefrontFailure(
        StorefrontFailureKind.offline,
        code: 'fixture_offline',
      );
    }
    if (state == Task054StorefrontState.error) {
      throw const StorefrontFailure(
        StorefrontFailureKind.unavailable,
        code: 'fixture_unavailable',
      );
    }
    final home = validStorefrontHomePayload(withImages: false);
    final empty = state == Task054StorefrontState.empty;
    if (function == 'storefront_home_v1') {
      if (empty) {
        home['categories'] = [];
        home['featured'] = [];
        home['offers'] = [];
      }
      return home;
    }
    if (function == 'storefront_categories_v1') {
      return {
        'status': 'ok',
        'apiVersion': 'storefront.v1',
        'catalogVersion': 7,
        'categories': empty ? [] : home['categories'],
        'nextCursor': null,
      };
    }
    final products = <Map<String, Object?>>[
      ...(home['featured'] as List).cast<Map<String, Object?>>(),
      ...(home['offers'] as List).cast<Map<String, Object?>>(),
    ];
    if (function == 'storefront_product_detail_v1') {
      final id = parameters['p_publication_id'];
      final matches = products.where((product) => product['id'] == id);
      if (empty || matches.isEmpty) {
        // ProductDetail non ha stato empty: il prodotto assente è unavailable.
        throw const StorefrontFailure(
          StorefrontFailureKind.unavailable,
          code: 'fixture_product_absent',
        );
      }
      return {
        'status': 'ok',
        'apiVersion': 'storefront.v1',
        'catalogVersion': 7,
        'item': matches.single,
      };
    }
    var selected = empty ? <Map<String, Object?>>[] : products;
    final category = parameters['p_category_slug'];
    if (category != null) {
      selected = selected
          .where((p) => (p['category'] as Map)['slug'] == category)
          .toList();
    }
    if (parameters['p_discounted'] == true) {
      selected = selected.where((p) => p['discountBps'] != null).toList();
    }
    final availability = parameters['p_availability'];
    if (availability != null) {
      selected = selected
          .where((p) => p['availability'] == availability)
          .toList();
    }
    if (function == 'storefront_search_v1') {
      final query = (parameters['p_query'] as String).toLowerCase();
      selected = selected
          .where((p) => (p['name'] as String).toLowerCase().contains(query))
          .toList();
      return {
        'status': 'ok',
        'apiVersion': 'storefront.v1',
        'catalogVersion': 7,
        'query': parameters['p_query'],
        'items': selected,
        'nextCursor': null,
      };
    }
    if (function == 'storefront_catalog_v1') {
      final sort = parameters['p_sort'] as String;
      if (sort == 'name') {
        selected.sort(
          (a, b) => (a['name'] as String).compareTo(b['name'] as String),
        );
      } else if (sort == 'price_asc' || sort == 'price_desc') {
        selected.sort(
          (a, b) => sort == 'price_asc'
              ? (a['priceClp'] as int).compareTo(b['priceClp'] as int)
              : (b['priceClp'] as int).compareTo(a['priceClp'] as int),
        );
      }
      return {
        'status': 'ok',
        'apiVersion': 'storefront.v1',
        'catalogVersion': 7,
        'items': selected,
        'nextCursor': null,
        'sort': sort,
      };
    }
    throw StateError('unexpected fixture RPC $function');
  }
}

final class Task054ReadyRepository implements BackendReadinessRepository {
  const Task054ReadyRepository();
  @override
  BackendReadinessState get initialState => BackendReadinessState.ready;
  @override
  bool get canCheck => true;
  @override
  Future<BackendReadinessState> check({
    required BackendProbeCancellation cancellation,
  }) async => BackendReadinessState.ready;
}

final class Task054SearchFixture
    implements SearchAssistRepository, SearchHistoryStore {
  Task054SearchFixture(this.state);
  final Task054StorefrontState state;
  List<String> history = [];
  @override
  Future<List<String>> read(String shopSlug) async => history;
  @override
  Future<void> write(String shopSlug, List<String> values) async {
    history = values;
  }

  @override
  Future<List<StorefrontSearchSuggestion>> suggestions({
    required String shopSlug,
    required String query,
  }) async {
    if (state != Task054StorefrontState.loaded) return [];
    return const [
          StorefrontSearchSuggestion(
            value: 'Café destacado',
            kind: StorefrontSearchSuggestionKind.product,
          ),
        ]
        .where((p) => p.value.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

// Offline con dati Cart si ottiene DOPO il read locale riuscito:
// fixture.cart.offlineMutations = true; tap cart-increase-<publicationId>.
// CartController reale conserva i dati e pubblica la failure osservata.
// Per Cart offline senza dati: fixture.cart.readFailure=CartFailureKind.offline
// prima del mount. Default: mutazioni Drift reali e nessun errore simulato.
final class Task054GuestStoreFailurePort implements GuestCartStore {
  Task054GuestStoreFailurePort(this.delegate);
  final DriftGuestCartStore delegate;
  bool offlineMutations = false;
  CartFailureKind? readFailure;
  void _check() {
    if (offlineMutations) {
      throw const CartRepositoryException(CartFailureKind.offline);
    }
  }

  @override
  Future<CustomerCartSnapshot> read({required String shopSlug}) async {
    if (readFailure case final failure?) throw CartRepositoryException(failure);
    return delegate.read(shopSlug: shopSlug);
  }

  @override
  Future<CustomerCartSnapshot> setProduct({
    required String shopSlug,
    required StorefrontProductSummary product,
    required int quantity,
  }) async {
    _check();
    return delegate.setProduct(
      shopSlug: shopSlug,
      product: product,
      quantity: quantity,
    );
  }

  @override
  Future<CustomerCartSnapshot> setQuantity({
    required String shopSlug,
    required String publicationId,
    required int quantity,
  }) async {
    _check();
    return delegate.setQuantity(
      shopSlug: shopSlug,
      publicationId: publicationId,
      quantity: quantity,
    );
  }

  @override
  Future<CustomerCartSnapshot> remove({
    required String shopSlug,
    required String publicationId,
  }) async {
    _check();
    return delegate.remove(shopSlug: shopSlug, publicationId: publicationId);
  }

  @override
  Future<CustomerCartSnapshot> clear({required String shopSlug}) async {
    _check();
    return delegate.clear(shopSlug: shopSlug);
  }

  @override
  Future<CustomerCartSnapshot> retainOnly({
    required String shopSlug,
    required Set<String> publicationIds,
  }) async {
    _check();
    return delegate.retainOnly(
      shopSlug: shopSlug,
      publicationIds: publicationIds,
    );
  }
}
