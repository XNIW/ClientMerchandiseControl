import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/backend_readiness_controller.dart';
import '../../../core/backend/backend_readiness_state.dart';
import '../../../core/config/app_config.dart';
import '../../storefront/application/storefront_providers.dart';
import '../../storefront/domain/storefront_failure.dart';
import '../../storefront/domain/storefront_models.dart';
import '../../storefront/domain/storefront_repository.dart';

enum CatalogLoadStatus { loading, data, empty, offline, unavailable, failure }

class CatalogState {
  const CatalogState({
    required this.status,
    this.categories = const [],
    this.items = const [],
    this.selectedCategorySlug,
    this.catalogVersion,
    this.nextCursor,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.failure,
  });

  final CatalogLoadStatus status;
  final List<StorefrontCategory> categories;
  final List<StorefrontProductSummary> items;
  final String? selectedCategorySlug;
  final int? catalogVersion;
  final String? nextCursor;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final StorefrontFailure? failure;

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

  StorefrontRequestCancellation? _cancellation;
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
      categorySlug: state.selectedCategorySlug,
      reloadCategories: state.categories.isEmpty,
    );
  }

  Future<void> refresh() => _loadFirstPage(
    categorySlug: state.selectedCategorySlug,
    reloadCategories: true,
    preserveItems: state.items.isNotEmpty,
  );

  Future<void> selectCategory(String? categorySlug) {
    if (categorySlug == state.selectedCategorySlug) return Future<void>.value();
    if (categorySlug != null &&
        !state.categories.any((category) => category.slug == categorySlug)) {
      return Future<void>.value();
    }
    return _loadFirstPage(categorySlug: categorySlug, reloadCategories: false);
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

    final generation = _generation;
    _cancellation?.cancel();
    final cancellation = StorefrontRequestCancellation();
    _cancellation = cancellation;
    state = CatalogState(
      status: CatalogLoadStatus.data,
      categories: state.categories,
      items: state.items,
      selectedCategorySlug: state.selectedCategorySlug,
      catalogVersion: currentVersion,
      nextCursor: cursor,
      isLoadingMore: true,
    );
    try {
      final page = await ref
          .read(storefrontRepositoryProvider)
          .fetchCatalog(
            shopSlug: shopSlug,
            cursor: cursor,
            limit: catalogPageSize,
            categorySlug: state.selectedCategorySlug,
            sort: StorefrontCatalogSort.catalog,
            cancellation: cancellation,
          );
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
      state = CatalogState(
        status: CatalogLoadStatus.data,
        categories: state.categories,
        items: List.unmodifiable([...state.items, ...page.items]),
        selectedCategorySlug: state.selectedCategorySlug,
        catalogVersion: currentVersion,
        nextCursor: page.nextCursor,
      );
    } on StorefrontFailure catch (failure) {
      if (_isStale(generation, cancellation)) return;
      if (failure.kind == StorefrontFailureKind.catalogChanged) {
        await _loadFirstPage(
          categorySlug: state.selectedCategorySlug,
          reloadCategories: true,
          preserveItems: true,
          allowCatalogRetry: false,
        );
        return;
      }
      state = CatalogState(
        status: CatalogLoadStatus.data,
        categories: state.categories,
        items: state.items,
        selectedCategorySlug: state.selectedCategorySlug,
        catalogVersion: currentVersion,
        nextCursor: cursor,
        loadMoreFailed: true,
        failure: failure,
      );
    }
  }

  CatalogState _initialState(BackendReadinessState readiness) {
    if (readiness == BackendReadinessState.ready) {
      scheduleMicrotask(() {
        if (!_disposed) {
          unawaited(_loadFirstPage(categorySlug: null, reloadCategories: true));
        }
      });
    }
    return _stateForReadiness(readiness);
  }

  void _handleReadinessChange(BackendReadinessState readiness) {
    if (_disposed) return;
    if (readiness == BackendReadinessState.ready) {
      unawaited(
        _loadFirstPage(
          categorySlug: state.selectedCategorySlug,
          reloadCategories: true,
        ),
      );
      return;
    }
    _generation += 1;
    _cancellation?.cancel();
    state = _stateForReadiness(readiness);
  }

  CatalogState _stateForReadiness(BackendReadinessState readiness) =>
      switch (readiness) {
        BackendReadinessState.ready || BackendReadinessState.initializing =>
          const CatalogState(status: CatalogLoadStatus.loading),
        BackendReadinessState.offline => const CatalogState(
          status: CatalogLoadStatus.offline,
        ),
        BackendReadinessState.unconfigured => const CatalogState(
          status: CatalogLoadStatus.empty,
        ),
        BackendReadinessState.misconfigured ||
        BackendReadinessState.authenticationRequired => const CatalogState(
          status: CatalogLoadStatus.unavailable,
        ),
        BackendReadinessState.recoverableError => CatalogState(
          status: CatalogLoadStatus.failure,
          failure: const StorefrontFailure(
            StorefrontFailureKind.unavailable,
            code: 'backend_recoverable',
          ),
        ),
      };

  Future<void> _loadFirstPage({
    required String? categorySlug,
    required bool reloadCategories,
    bool preserveItems = false,
    bool allowCatalogRetry = true,
  }) async {
    final config = ref.read(appConfigProvider);
    final shopSlug = config.storefrontShopSlug;
    if (_disposed || shopSlug == null) {
      if (!_disposed) {
        state = const CatalogState(status: CatalogLoadStatus.unavailable);
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
            selectedCategorySlug: categorySlug,
            catalogVersion: previous.catalogVersion,
            nextCursor: previous.nextCursor,
            isRefreshing: true,
          )
        : CatalogState(
            status: CatalogLoadStatus.loading,
            categories: previous.categories,
            selectedCategorySlug: categorySlug,
          );
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
      final catalogOperation = repository.fetchCatalog(
        shopSlug: shopSlug,
        cursor: null,
        limit: catalogPageSize,
        categorySlug: categorySlug,
        sort: StorefrontCatalogSort.catalog,
        cancellation: cancellation,
      );
      final results = await Future.wait<Object>([
        categoriesOperation,
        catalogOperation,
      ]);
      final categoriesPage = results[0] as StorefrontCategoriesPage;
      final catalogPage = results[1] as StorefrontCatalogPage;
      if (_isStale(generation, cancellation)) return;
      if (reloadCategories &&
          categoriesPage.catalogVersion != catalogPage.catalogVersion) {
        throw const StorefrontFailure(
          StorefrontFailureKind.catalogChanged,
          code: 'catalog_version_changed',
        );
      }
      if (categorySlug != null &&
          !categoriesPage.categories.any(
            (category) => category.slug == categorySlug,
          )) {
        state = CatalogState(
          status: CatalogLoadStatus.loading,
          categories: categoriesPage.categories,
        );
        await _loadFirstPage(
          categorySlug: null,
          reloadCategories: false,
          allowCatalogRetry: false,
        );
        return;
      }
      state = CatalogState(
        status: catalogPage.items.isEmpty
            ? CatalogLoadStatus.empty
            : CatalogLoadStatus.data,
        categories: categoriesPage.categories,
        items: catalogPage.items,
        selectedCategorySlug: categorySlug,
        catalogVersion: catalogPage.catalogVersion,
        nextCursor: catalogPage.nextCursor,
      );
    } on StorefrontFailure catch (failure) {
      if (_isStale(generation, cancellation)) return;
      if (failure.kind == StorefrontFailureKind.catalogChanged &&
          allowCatalogRetry) {
        await _loadFirstPage(
          categorySlug: categorySlug,
          reloadCategories: true,
          preserveItems: preserveItems,
          allowCatalogRetry: false,
        );
        return;
      }
      state = CatalogState(
        status: switch (failure.kind) {
          StorefrontFailureKind.cancelled => state.status,
          StorefrontFailureKind.offline ||
          StorefrontFailureKind.timeout => CatalogLoadStatus.offline,
          StorefrontFailureKind.invalidConfiguration ||
          StorefrontFailureKind.unauthorized ||
          StorefrontFailureKind.unavailable => CatalogLoadStatus.unavailable,
          StorefrontFailureKind.catalogChanged ||
          StorefrontFailureKind.invalidPayload ||
          StorefrontFailureKind.unknown => CatalogLoadStatus.failure,
        },
        categories: state.categories,
        items: preserveItems ? previous.items : const [],
        selectedCategorySlug: categorySlug,
        catalogVersion: preserveItems ? previous.catalogVersion : null,
        nextCursor: preserveItems ? previous.nextCursor : null,
        failure: failure,
      );
    }
  }

  bool _isStale(int generation, StorefrontRequestCancellation cancellation) =>
      _disposed || cancellation.isCancelled || generation != _generation;

  void _dispose() {
    _disposed = true;
    _generation += 1;
    _cancellation?.cancel();
  }
}
