import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/backend_readiness_controller.dart';
import '../../../core/backend/backend_readiness_state.dart';
import '../../../core/config/app_config.dart';
import '../../storefront/application/storefront_providers.dart';
import '../../storefront/cache/storefront_cache_repository.dart';
import '../../storefront/domain/storefront_failure.dart';
import '../../storefront/domain/storefront_models.dart';
import '../../storefront/domain/storefront_repository.dart';

const _criteriaUnset = Object();

enum CatalogLoadStatus { loading, data, empty, offline, unavailable, failure }

class CatalogState {
  const CatalogState({
    required this.status,
    this.categories = const [],
    this.items = const [],
    this.selectedCategorySlug,
    this.searchQuery,
    this.availabilityFilter,
    this.discountedOnly = false,
    this.sort = StorefrontCatalogSort.catalog,
    this.catalogVersion,
    this.nextCursor,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.isFromCache = false,
    this.isStale = false,
    this.cachedAt,
    this.failure,
  });

  final CatalogLoadStatus status;
  final List<StorefrontCategory> categories;
  final List<StorefrontProductSummary> items;
  final String? selectedCategorySlug;
  final String? searchQuery;
  final StorefrontAvailability? availabilityFilter;
  final bool discountedOnly;
  final StorefrontCatalogSort sort;
  final int? catalogVersion;
  final String? nextCursor;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final bool isFromCache;
  final bool isStale;
  final DateTime? cachedAt;
  final StorefrontFailure? failure;

  bool get isSearchActive => searchQuery != null;
  bool get hasCatalogFilters =>
      availabilityFilter != null ||
      discountedOnly ||
      sort != StorefrontCatalogSort.catalog;
  bool get canLoadMore =>
      status == CatalogLoadStatus.data &&
      nextCursor != null &&
      !isRefreshing &&
      !isLoadingMore &&
      !loadMoreFailed;
}

final catalogControllerProvider =
    NotifierProvider<CatalogController, CatalogState>(CatalogController.new);

class CatalogController extends Notifier<CatalogState> {
  static const categoryPageSize = 100;
  static const catalogPageSize = 24;
  static const searchDebounce = Duration(milliseconds: 300);

  StorefrontRequestCancellation? _cancellation;
  Timer? _searchTimer;
  var _generation = 0;
  var _disposed = false;

  @override
  CatalogState build() {
    _disposed = false;
    final readiness = ref.read(backendReadinessControllerProvider);
    ref.listen(
      backendReadinessControllerProvider,
      (_, next) => _handleReadinessChange(next),
    );
    ref.onDispose(_dispose);
    return _initialState(readiness);
  }

  Future<void> retry() {
    final readiness = ref.read(backendReadinessControllerProvider);
    if (readiness != BackendReadinessState.ready) {
      return ref.read(backendReadinessControllerProvider.notifier).retry();
    }
    if (state.loadMoreFailed && state.items.isNotEmpty) {
      return _loadMore(retryFailedPage: true);
    }
    return _loadFirstPage(
      criteria: _criteriaFromState(),
      reloadCategories: state.categories.isEmpty,
    );
  }

  Future<void> refresh() => _loadFirstPage(
    criteria: _criteriaFromState(),
    reloadCategories: true,
    preserveItems: state.items.isNotEmpty,
  );

  Future<void> selectCategory(String? categorySlug) {
    if (categorySlug == state.selectedCategorySlug) return Future<void>.value();
    if (categorySlug != null &&
        !state.categories.any((category) => category.slug == categorySlug)) {
      return Future<void>.value();
    }
    return _loadFirstPage(
      criteria: _criteriaFromState(categorySlug: categorySlug),
      reloadCategories: false,
    );
  }

  Future<void> openCategoryFromDeepLink(String categorySlug) {
    if (!RegExp(r'^[a-z0-9][a-z0-9-]{1,62}$').hasMatch(categorySlug)) {
      return Future<void>.value();
    }
    final readiness = ref.read(backendReadinessControllerProvider);
    final criteria = _CatalogCriteria(categorySlug: categorySlug);
    if (readiness == BackendReadinessState.ready ||
        readiness == BackendReadinessState.offline) {
      return _loadFirstPage(
        criteria: criteria,
        reloadCategories: true,
        cacheOnly: readiness == BackendReadinessState.offline,
      );
    }
    _searchTimer?.cancel();
    _cancelCurrentRequest();
    state = _stateForReadiness(readiness, criteria);
    return Future<void>.value();
  }

  void updateSearchQuery(String rawQuery) {
    final query = _normalizeQuery(rawQuery);
    _searchTimer?.cancel();
    if (query.length < 2) {
      if (state.searchQuery != null) {
        unawaited(clearSearch());
      }
      return;
    }
    _cancelCurrentRequest();
    final criteria = _CatalogCriteria(
      categorySlug: state.selectedCategorySlug,
      searchQuery: query,
      availability: null,
      discountedOnly: false,
      sort: StorefrontCatalogSort.catalog,
    );
    state = _loadingState(
      criteria,
      categories: state.categories,
      catalogVersion: state.catalogVersion,
    );
    _searchTimer = Timer(searchDebounce, () {
      if (!_disposed) {
        unawaited(_loadFirstPage(criteria: criteria, reloadCategories: false));
      }
    });
  }

  Future<void> submitSearch(String rawQuery) {
    final query = _normalizeQuery(rawQuery);
    if (query.length < 2) return clearSearch();
    _searchTimer?.cancel();
    return _loadFirstPage(
      criteria: _CatalogCriteria(
        categorySlug: state.selectedCategorySlug,
        searchQuery: query,
        availability: null,
        discountedOnly: false,
        sort: StorefrontCatalogSort.catalog,
      ),
      reloadCategories: false,
    );
  }

  Future<void> clearSearch() {
    _searchTimer?.cancel();
    if (state.searchQuery == null) return Future<void>.value();
    return _loadFirstPage(
      criteria: _CatalogCriteria(
        categorySlug: state.selectedCategorySlug,
        searchQuery: null,
        availability: null,
        discountedOnly: false,
        sort: StorefrontCatalogSort.catalog,
      ),
      reloadCategories: false,
    );
  }

  Future<void> selectAvailability(StorefrontAvailability? availability) {
    if (state.isSearchActive || availability == state.availabilityFilter) {
      return Future<void>.value();
    }
    return _loadFirstPage(
      criteria: _criteriaFromState(availability: availability),
      reloadCategories: false,
    );
  }

  Future<void> setDiscountedOnly(bool enabled) {
    if (state.isSearchActive || enabled == state.discountedOnly) {
      return Future<void>.value();
    }
    return _loadFirstPage(
      criteria: _criteriaFromState(discountedOnly: enabled),
      reloadCategories: false,
    );
  }

  Future<void> selectSort(StorefrontCatalogSort sort) {
    if (state.isSearchActive || sort == state.sort) return Future<void>.value();
    return _loadFirstPage(
      criteria: _criteriaFromState(sort: sort),
      reloadCategories: false,
    );
  }

  Future<void> resetFilters() {
    if (state.isSearchActive || !state.hasCatalogFilters) {
      return Future<void>.value();
    }
    return _loadFirstPage(
      criteria: _CatalogCriteria(categorySlug: state.selectedCategorySlug),
      reloadCategories: false,
    );
  }

  Future<void> loadMore() => _loadMore();

  Future<void> _loadMore({bool retryFailedPage = false}) async {
    final cursor = state.nextCursor;
    final currentVersion = state.catalogVersion;
    final canRetryFailedPage =
        retryFailedPage &&
        state.status == CatalogLoadStatus.data &&
        state.loadMoreFailed &&
        !state.isRefreshing &&
        !state.isLoadingMore;
    if ((!state.canLoadMore && !canRetryFailedPage) ||
        cursor == null ||
        currentVersion == null) {
      return;
    }
    final config = ref.read(appConfigProvider);
    final shopSlug = config.storefrontShopSlug;
    if (_disposed || shopSlug == null) return;

    final criteria = _criteriaFromState();
    final fromCache = state.isFromCache;
    final cacheIsStale = state.isStale;
    final cachedAt = state.cachedAt;
    final generation = _generation;
    _cancellation?.cancel();
    final cancellation = StorefrontRequestCancellation();
    _cancellation = cancellation;
    state = CatalogState(
      status: CatalogLoadStatus.data,
      categories: state.categories,
      items: state.items,
      selectedCategorySlug: criteria.categorySlug,
      searchQuery: criteria.searchQuery,
      availabilityFilter: criteria.availability,
      discountedOnly: criteria.discountedOnly,
      sort: criteria.sort,
      catalogVersion: currentVersion,
      nextCursor: cursor,
      isLoadingMore: true,
      isFromCache: fromCache,
      isStale: cacheIsStale,
      cachedAt: cachedAt,
    );
    try {
      final page = fromCache
          ? await _fetchCachedPage(
              shopSlug: shopSlug,
              criteria: criteria,
              cursor: cursor,
            )
          : await _fetchPage(
              shopSlug: shopSlug,
              criteria: criteria,
              cursor: cursor,
              cancellation: cancellation,
            );
      if (page == null) {
        throw const StorefrontFailure(
          StorefrontFailureKind.offline,
          code: 'cache_page_missing',
        );
      }
      if (_isStale(generation, cancellation)) return;
      if (page.catalogVersion != currentVersion) {
        throw const StorefrontFailure(
          StorefrontFailureKind.catalogChanged,
          code: 'catalog_version_changed',
        );
      }
      final existingIds = state.items.map((item) => item.id).toSet();
      if (page.items.any((item) => existingIds.contains(item.id))) {
        throw const StorefrontFailure(
          StorefrontFailureKind.invalidPayload,
          code: 'duplicate_page_item',
        );
      }
      if (!fromCache) {
        await _persistPage(shopSlug, criteria, page);
        if (_isStale(generation, cancellation)) return;
      }
      state = CatalogState(
        status: CatalogLoadStatus.data,
        categories: state.categories,
        items: List.unmodifiable([...state.items, ...page.items]),
        selectedCategorySlug: criteria.categorySlug,
        searchQuery: criteria.searchQuery,
        availabilityFilter: criteria.availability,
        discountedOnly: criteria.discountedOnly,
        sort: criteria.sort,
        catalogVersion: currentVersion,
        nextCursor: page.nextCursor,
        isFromCache: fromCache,
        isStale: cacheIsStale,
        cachedAt: cachedAt,
      );
    } on StorefrontFailure catch (failure) {
      if (_isStale(generation, cancellation)) return;
      if (failure.kind == StorefrontFailureKind.catalogChanged) {
        await _loadFirstPage(
          criteria: criteria,
          reloadCategories: true,
          preserveItems: true,
          allowCatalogRetry: false,
        );
        return;
      }
      if (_requiresCacheInvalidation(failure)) {
        await _invalidateCache(shopSlug);
        if (_isStale(generation, cancellation)) return;
        state = CatalogState(
          status: _statusForFailure(failure),
          selectedCategorySlug: criteria.categorySlug,
          searchQuery: criteria.searchQuery,
          availabilityFilter: criteria.availability,
          discountedOnly: criteria.discountedOnly,
          sort: criteria.sort,
          failure: failure,
        );
        return;
      }
      state = CatalogState(
        status: CatalogLoadStatus.data,
        categories: state.categories,
        items: state.items,
        selectedCategorySlug: criteria.categorySlug,
        searchQuery: criteria.searchQuery,
        availabilityFilter: criteria.availability,
        discountedOnly: criteria.discountedOnly,
        sort: criteria.sort,
        catalogVersion: currentVersion,
        nextCursor: cursor,
        loadMoreFailed: true,
        isFromCache: fromCache,
        isStale: cacheIsStale,
        cachedAt: cachedAt,
        failure: failure,
      );
    }
  }

  CatalogState _initialState(BackendReadinessState readiness) {
    const criteria = _CatalogCriteria();
    if (readiness == BackendReadinessState.ready ||
        readiness == BackendReadinessState.offline) {
      scheduleMicrotask(() {
        if (!_disposed) {
          final effectiveCriteria = _criteriaFromState();
          unawaited(
            _loadFirstPage(
              criteria: effectiveCriteria,
              reloadCategories: true,
              cacheOnly: readiness == BackendReadinessState.offline,
            ),
          );
        }
      });
    }
    return _stateForReadiness(readiness, criteria);
  }

  void _handleReadinessChange(BackendReadinessState readiness) {
    if (_disposed) return;
    final criteria = _criteriaFromState();
    if (readiness == BackendReadinessState.ready) {
      unawaited(_loadFirstPage(criteria: criteria, reloadCategories: true));
      return;
    }
    if (readiness == BackendReadinessState.offline) {
      _searchTimer?.cancel();
      _cancelCurrentRequest();
      unawaited(
        _loadFirstPage(
          criteria: criteria,
          reloadCategories: true,
          cacheOnly: true,
        ),
      );
      return;
    }
    _searchTimer?.cancel();
    _cancelCurrentRequest();
    state = _stateForReadiness(readiness, criteria);
  }

  CatalogState _stateForReadiness(
    BackendReadinessState readiness,
    _CatalogCriteria criteria,
  ) => switch (readiness) {
    BackendReadinessState.ready ||
    BackendReadinessState.initializing => _loadingState(criteria),
    BackendReadinessState.offline => CatalogState(
      status: CatalogLoadStatus.offline,
      selectedCategorySlug: criteria.categorySlug,
      searchQuery: criteria.searchQuery,
      availabilityFilter: criteria.availability,
      discountedOnly: criteria.discountedOnly,
      sort: criteria.sort,
    ),
    BackendReadinessState.unconfigured => CatalogState(
      status: CatalogLoadStatus.empty,
      selectedCategorySlug: criteria.categorySlug,
      searchQuery: criteria.searchQuery,
      availabilityFilter: criteria.availability,
      discountedOnly: criteria.discountedOnly,
      sort: criteria.sort,
    ),
    BackendReadinessState.misconfigured ||
    BackendReadinessState.authenticationRequired => CatalogState(
      status: CatalogLoadStatus.unavailable,
      selectedCategorySlug: criteria.categorySlug,
      searchQuery: criteria.searchQuery,
      availabilityFilter: criteria.availability,
      discountedOnly: criteria.discountedOnly,
      sort: criteria.sort,
    ),
    BackendReadinessState.recoverableError => CatalogState(
      status: CatalogLoadStatus.failure,
      selectedCategorySlug: criteria.categorySlug,
      searchQuery: criteria.searchQuery,
      availabilityFilter: criteria.availability,
      discountedOnly: criteria.discountedOnly,
      sort: criteria.sort,
      failure: const StorefrontFailure(
        StorefrontFailureKind.unavailable,
        code: 'backend_recoverable',
      ),
    ),
  };

  Future<void> _loadFirstPage({
    required _CatalogCriteria criteria,
    required bool reloadCategories,
    bool preserveItems = false,
    bool allowCatalogRetry = true,
    bool cacheOnly = false,
  }) async {
    _searchTimer?.cancel();
    final config = ref.read(appConfigProvider);
    final shopSlug = config.storefrontShopSlug;
    if (_disposed || shopSlug == null) {
      if (!_disposed) {
        state = CatalogState(
          status: CatalogLoadStatus.unavailable,
          selectedCategorySlug: criteria.categorySlug,
          searchQuery: criteria.searchQuery,
          availabilityFilter: criteria.availability,
          discountedOnly: criteria.discountedOnly,
          sort: criteria.sort,
        );
      }
      return;
    }
    final previous = state;
    final generation = ++_generation;
    _cancellation?.cancel();
    final cancellation = StorefrontRequestCancellation();
    _cancellation = cancellation;
    state = preserveItems
        ? CatalogState(
            status: previous.status,
            categories: previous.categories,
            items: previous.items,
            selectedCategorySlug: criteria.categorySlug,
            searchQuery: criteria.searchQuery,
            availabilityFilter: criteria.availability,
            discountedOnly: criteria.discountedOnly,
            sort: criteria.sort,
            catalogVersion: previous.catalogVersion,
            nextCursor: previous.nextCursor,
            isRefreshing: true,
            isFromCache: previous.isFromCache,
            isStale: previous.isStale,
            cachedAt: previous.cachedAt,
          )
        : _loadingState(
            criteria,
            categories: previous.categories,
            catalogVersion: previous.catalogVersion,
          );
    var cachedApplied = false;
    if (!preserveItems) {
      try {
        final cachedResults = await Future.wait<Object?>([
          ref
              .read(storefrontCacheRepositoryProvider)
              .readCategories(shopSlug: shopSlug),
          _readCachedPage(shopSlug: shopSlug, criteria: criteria, cursor: null),
        ]);
        if (_isStale(generation, cancellation)) return;
        final categoriesSnapshot =
            cachedResults[0]
                as StorefrontCacheSnapshot<StorefrontCategoriesPage>?;
        final pageSnapshot =
            cachedResults[1] as StorefrontCacheSnapshot<_DiscoveryPage>?;
        if (categoriesSnapshot != null &&
            pageSnapshot != null &&
            categoriesSnapshot.value.catalogVersion ==
                pageSnapshot.value.catalogVersion &&
            (criteria.categorySlug == null ||
                categoriesSnapshot.value.categories.any(
                  (category) => category.slug == criteria.categorySlug,
                ))) {
          final cachedAt =
              categoriesSnapshot.refreshedAt.isBefore(pageSnapshot.refreshedAt)
              ? categoriesSnapshot.refreshedAt
              : pageSnapshot.refreshedAt;
          final fresh =
              categoriesSnapshot.isFreshAt(DateTime.now()) &&
              pageSnapshot.isFreshAt(DateTime.now());
          final page = pageSnapshot.value;
          state = CatalogState(
            status: page.items.isEmpty
                ? CatalogLoadStatus.empty
                : CatalogLoadStatus.data,
            categories: categoriesSnapshot.value.categories,
            items: page.items,
            selectedCategorySlug: criteria.categorySlug,
            searchQuery: criteria.searchQuery,
            availabilityFilter: criteria.availability,
            discountedOnly: criteria.discountedOnly,
            sort: criteria.sort,
            catalogVersion: page.catalogVersion,
            nextCursor: page.nextCursor,
            isRefreshing: !cacheOnly,
            isFromCache: true,
            isStale: !fresh,
            cachedAt: cachedAt,
          );
          cachedApplied = true;
        }
      } on Object {
        cachedApplied = false;
      }
    }
    if (cacheOnly) {
      if (!cachedApplied) {
        state = CatalogState(
          status: CatalogLoadStatus.offline,
          selectedCategorySlug: criteria.categorySlug,
          searchQuery: criteria.searchQuery,
          availabilityFilter: criteria.availability,
          discountedOnly: criteria.discountedOnly,
          sort: criteria.sort,
        );
      }
      return;
    }
    try {
      final repository = ref.read(storefrontRepositoryProvider);
      final categoriesOperation = reloadCategories
          ? repository.fetchCategories(
              shopSlug: shopSlug,
              cursor: null,
              limit: categoryPageSize,
              cancellation: cancellation,
            )
          : Future.value(
              StorefrontCategoriesPage(
                catalogVersion: previous.catalogVersion ?? 0,
                categories: previous.categories,
                nextCursor: null,
              ),
            );
      final results = await Future.wait<Object>([
        categoriesOperation,
        _fetchPage(
          shopSlug: shopSlug,
          criteria: criteria,
          cursor: null,
          cancellation: cancellation,
        ),
      ]);
      final categoriesPage = results[0] as StorefrontCategoriesPage;
      final page = results[1] as _DiscoveryPage;
      if (_isStale(generation, cancellation)) return;
      if (categoriesPage.catalogVersion != page.catalogVersion) {
        throw const StorefrontFailure(
          StorefrontFailureKind.catalogChanged,
          code: 'catalog_version_changed',
        );
      }
      if (criteria.categorySlug != null &&
          !categoriesPage.categories.any(
            (category) => category.slug == criteria.categorySlug,
          )) {
        final fallback = criteria.copyWith(clearCategory: true);
        state = _loadingState(
          fallback,
          categories: categoriesPage.categories,
          catalogVersion: categoriesPage.catalogVersion,
        );
        await _loadFirstPage(
          criteria: fallback,
          reloadCategories: false,
          allowCatalogRetry: false,
        );
        return;
      }
      await _persistFirstPage(
        shopSlug: shopSlug,
        categoriesPage: categoriesPage,
        page: page,
        criteria: criteria,
        writeCategories: reloadCategories,
      );
      if (_isStale(generation, cancellation)) return;
      state = CatalogState(
        status: page.items.isEmpty
            ? CatalogLoadStatus.empty
            : CatalogLoadStatus.data,
        categories: categoriesPage.categories,
        items: page.items,
        selectedCategorySlug: criteria.categorySlug,
        searchQuery: criteria.searchQuery,
        availabilityFilter: criteria.availability,
        discountedOnly: criteria.discountedOnly,
        sort: criteria.sort,
        catalogVersion: page.catalogVersion,
        nextCursor: page.nextCursor,
      );
    } on StorefrontFailure catch (failure) {
      if (_isStale(generation, cancellation)) return;
      if (failure.kind == StorefrontFailureKind.catalogChanged &&
          allowCatalogRetry) {
        await _loadFirstPage(
          criteria: criteria,
          reloadCategories: true,
          preserveItems: preserveItems,
          allowCatalogRetry: false,
        );
        return;
      }
      if ((cachedApplied || (preserveItems && previous.items.isNotEmpty)) &&
          (failure.kind == StorefrontFailureKind.offline ||
              failure.kind == StorefrontFailureKind.timeout)) {
        final visible = cachedApplied ? state : previous;
        state = CatalogState(
          status: visible.items.isEmpty
              ? CatalogLoadStatus.empty
              : CatalogLoadStatus.data,
          categories: visible.categories,
          items: visible.items,
          selectedCategorySlug: criteria.categorySlug,
          searchQuery: criteria.searchQuery,
          availabilityFilter: criteria.availability,
          discountedOnly: criteria.discountedOnly,
          sort: criteria.sort,
          catalogVersion: visible.catalogVersion,
          nextCursor: visible.nextCursor,
          isFromCache: visible.isFromCache,
          isStale: true,
          cachedAt: visible.cachedAt,
          failure: failure,
        );
        return;
      }
      if (_requiresCacheInvalidation(failure)) {
        await _invalidateCache(shopSlug);
        if (_isStale(generation, cancellation)) return;
      }
      state = CatalogState(
        status: _statusForFailure(failure),
        categories: state.categories,
        items: preserveItems ? previous.items : const [],
        selectedCategorySlug: criteria.categorySlug,
        searchQuery: criteria.searchQuery,
        availabilityFilter: criteria.availability,
        discountedOnly: criteria.discountedOnly,
        sort: criteria.sort,
        catalogVersion: previous.catalogVersion,
        nextCursor: preserveItems ? previous.nextCursor : null,
        failure: failure,
      );
    }
  }

  Future<StorefrontCacheSnapshot<_DiscoveryPage>?> _readCachedPage({
    required String shopSlug,
    required _CatalogCriteria criteria,
    required String? cursor,
  }) async {
    final cache = ref.read(storefrontCacheRepositoryProvider);
    final query = criteria.searchQuery;
    if (query != null) {
      final snapshot = await cache.readSearch(
        shopSlug: shopSlug,
        query: query,
        cursor: cursor,
        limit: catalogPageSize,
        categorySlug: criteria.categorySlug,
      );
      if (snapshot == null) return null;
      return StorefrontCacheSnapshot(
        value: (
          catalogVersion: snapshot.value.catalogVersion,
          items: snapshot.value.items,
          nextCursor: snapshot.value.nextCursor,
        ),
        refreshedAt: snapshot.refreshedAt,
      );
    }
    final snapshot = await cache.readCatalog(
      shopSlug: shopSlug,
      cursor: cursor,
      limit: catalogPageSize,
      categorySlug: criteria.categorySlug,
      availability: criteria.availability,
      discounted: criteria.discountedOnly ? true : null,
      sort: criteria.sort,
    );
    if (snapshot == null) return null;
    return StorefrontCacheSnapshot(
      value: (
        catalogVersion: snapshot.value.catalogVersion,
        items: snapshot.value.items,
        nextCursor: snapshot.value.nextCursor,
      ),
      refreshedAt: snapshot.refreshedAt,
    );
  }

  Future<_DiscoveryPage?> _fetchCachedPage({
    required String shopSlug,
    required _CatalogCriteria criteria,
    required String? cursor,
  }) async => (await _readCachedPage(
    shopSlug: shopSlug,
    criteria: criteria,
    cursor: cursor,
  ))?.value;

  Future<void> _persistFirstPage({
    required String shopSlug,
    required StorefrontCategoriesPage categoriesPage,
    required _DiscoveryPage page,
    required _CatalogCriteria criteria,
    required bool writeCategories,
  }) async {
    try {
      final cache = ref.read(storefrontCacheRepositoryProvider);
      if (writeCategories) {
        await cache.writeCategories(shopSlug: shopSlug, page: categoriesPage);
      }
      await _writePageToCache(cache, shopSlug, criteria, page);
      await cache.cleanup(shopSlug: shopSlug);
    } on Object {
      // Una cache parziale resta un miss: i dati live validi hanno precedenza.
    }
  }

  Future<void> _persistPage(
    String shopSlug,
    _CatalogCriteria criteria,
    _DiscoveryPage page,
  ) async {
    try {
      final cache = ref.read(storefrontCacheRepositoryProvider);
      await _writePageToCache(cache, shopSlug, criteria, page);
      await cache.cleanup(shopSlug: shopSlug);
    } on Object {
      // La persistenza locale è best-effort e sempre ricostruibile.
    }
  }

  Future<void> _writePageToCache(
    StorefrontCacheRepository cache,
    String shopSlug,
    _CatalogCriteria criteria,
    _DiscoveryPage page,
  ) {
    final query = criteria.searchQuery;
    if (query != null) {
      return cache.writeSearch(
        shopSlug: shopSlug,
        page: StorefrontSearchPage(
          catalogVersion: page.catalogVersion,
          query: query,
          items: page.items,
          nextCursor: page.nextCursor,
        ),
        categorySlug: criteria.categorySlug,
      );
    }
    return cache.writeCatalog(
      shopSlug: shopSlug,
      page: StorefrontCatalogPage(
        catalogVersion: page.catalogVersion,
        items: page.items,
        nextCursor: page.nextCursor,
        sort: criteria.sort,
      ),
      categorySlug: criteria.categorySlug,
      availability: criteria.availability,
      discounted: criteria.discountedOnly ? true : null,
    );
  }

  bool _requiresCacheInvalidation(StorefrontFailure failure) =>
      failure.kind == StorefrontFailureKind.invalidConfiguration ||
      failure.kind == StorefrontFailureKind.unauthorized ||
      failure.kind == StorefrontFailureKind.unavailable ||
      failure.kind == StorefrontFailureKind.invalidPayload;

  Future<void> _invalidateCache(String shopSlug) async {
    try {
      await ref
          .read(storefrontCacheRepositoryProvider)
          .clearShop(shopSlug: shopSlug);
    } on Object {
      // I dati cached non vengono mostrati dopo un failure autoritativo.
    }
  }

  Future<_DiscoveryPage> _fetchPage({
    required String shopSlug,
    required _CatalogCriteria criteria,
    required String? cursor,
    required StorefrontRequestCancellation cancellation,
  }) async {
    final repository = ref.read(storefrontRepositoryProvider);
    final query = criteria.searchQuery;
    if (query != null) {
      final page = await repository.fetchSearch(
        shopSlug: shopSlug,
        query: query,
        cursor: cursor,
        limit: catalogPageSize,
        categorySlug: criteria.categorySlug,
        cancellation: cancellation,
      );
      if (page.query != query) {
        throw const StorefrontFailure(
          StorefrontFailureKind.invalidPayload,
          code: 'search_query_mismatch',
        );
      }
      return (
        catalogVersion: page.catalogVersion,
        items: page.items,
        nextCursor: page.nextCursor,
      );
    }
    final page = await repository.fetchCatalog(
      shopSlug: shopSlug,
      cursor: cursor,
      limit: catalogPageSize,
      categorySlug: criteria.categorySlug,
      availability: criteria.availability,
      discounted: criteria.discountedOnly ? true : null,
      sort: criteria.sort,
      cancellation: cancellation,
    );
    if (page.sort != criteria.sort) {
      throw const StorefrontFailure(
        StorefrontFailureKind.invalidPayload,
        code: 'catalog_sort_mismatch',
      );
    }
    return (
      catalogVersion: page.catalogVersion,
      items: page.items,
      nextCursor: page.nextCursor,
    );
  }

  CatalogState _loadingState(
    _CatalogCriteria criteria, {
    List<StorefrontCategory> categories = const [],
    int? catalogVersion,
  }) => CatalogState(
    status: CatalogLoadStatus.loading,
    categories: categories,
    selectedCategorySlug: criteria.categorySlug,
    searchQuery: criteria.searchQuery,
    availabilityFilter: criteria.availability,
    discountedOnly: criteria.discountedOnly,
    sort: criteria.sort,
    catalogVersion: catalogVersion,
  );

  CatalogLoadStatus _statusForFailure(StorefrontFailure failure) =>
      switch (failure.kind) {
        StorefrontFailureKind.cancelled => state.status,
        StorefrontFailureKind.offline ||
        StorefrontFailureKind.timeout => CatalogLoadStatus.offline,
        StorefrontFailureKind.invalidConfiguration ||
        StorefrontFailureKind.unauthorized ||
        StorefrontFailureKind.unavailable => CatalogLoadStatus.unavailable,
        StorefrontFailureKind.catalogChanged ||
        StorefrontFailureKind.invalidPayload ||
        StorefrontFailureKind.unknown => CatalogLoadStatus.failure,
      };

  _CatalogCriteria _criteriaFromState({
    Object? categorySlug = _criteriaUnset,
    Object? availability = _criteriaUnset,
    bool? discountedOnly,
    StorefrontCatalogSort? sort,
  }) => _CatalogCriteria(
    categorySlug: identical(categorySlug, _criteriaUnset)
        ? state.selectedCategorySlug
        : categorySlug as String?,
    searchQuery: state.searchQuery,
    availability: identical(availability, _criteriaUnset)
        ? state.availabilityFilter
        : availability as StorefrontAvailability?,
    discountedOnly: discountedOnly ?? state.discountedOnly,
    sort: sort ?? state.sort,
  );

  String _normalizeQuery(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  void _cancelCurrentRequest() {
    _generation += 1;
    _cancellation?.cancel();
  }

  bool _isStale(int generation, StorefrontRequestCancellation cancellation) =>
      _disposed || cancellation.isCancelled || generation != _generation;

  void _dispose() {
    _disposed = true;
    _searchTimer?.cancel();
    _cancelCurrentRequest();
  }
}

typedef _DiscoveryPage = ({
  int catalogVersion,
  List<StorefrontProductSummary> items,
  String? nextCursor,
});

class _CatalogCriteria {
  const _CatalogCriteria({
    this.categorySlug,
    this.searchQuery,
    this.availability,
    this.discountedOnly = false,
    this.sort = StorefrontCatalogSort.catalog,
  });

  final String? categorySlug;
  final String? searchQuery;
  final StorefrontAvailability? availability;
  final bool discountedOnly;
  final StorefrontCatalogSort sort;

  _CatalogCriteria copyWith({bool clearCategory = false}) => _CatalogCriteria(
    categorySlug: clearCategory ? null : categorySlug,
    searchQuery: searchQuery,
    availability: availability,
    discountedOnly: discountedOnly,
    sort: sort,
  );
}
