import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/tokens/app_breakpoints.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/design_system/widgets/storefront_cache_status.dart';
import '../../../app/design_system/widgets/storefront_empty_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/presentation/storefront_product_card.dart';
import '../../storefront/domain/storefront_failure.dart';
import '../../storefront/domain/storefront_models.dart';
import '../application/catalog_controller.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String?, double> _categoryOffsets = {};
  var _filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_requestNextPageNearEnd);
    _searchController.addListener(_handleSearchTextChanged);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_requestNextPageNearEnd)
      ..dispose();
    _searchController
      ..removeListener(_handleSearchTextChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchTextChanged() {
    if (mounted) setState(() {});
  }

  void _requestNextPageNearEnd() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 480) {
      return;
    }
    unawaited(ref.read(catalogControllerProvider.notifier).loadMore());
  }

  Future<void> _selectCategory(String? categorySlug) async {
    final current = ref.read(catalogControllerProvider).selectedCategorySlug;
    if (_scrollController.hasClients) {
      _categoryOffsets[current] = _scrollController.offset;
    }
    await ref
        .read(catalogControllerProvider.notifier)
        .selectCategory(categorySlug);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = math.min(
        _categoryOffsets[categorySlug] ?? 0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(target);
    });
  }

  Future<void> _clearSearch() async {
    _searchController.clear();
    await ref.read(catalogControllerProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogControllerProvider);
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final basePadding = constraints.maxWidth >= AppBreakpoints.wide
            ? AppSpacing.xxl
            : constraints.maxWidth <= AppBreakpoints.narrow
            ? AppSpacing.md
            : AppSpacing.lg;
        final horizontalPadding =
            basePadding +
            math.max(
              0,
              (constraints.maxWidth - AppSizes.catalogContentMaxWidth) / 2,
            );
        final contentWidth = math.max(
          1,
          constraints.maxWidth - horizontalPadding * 2,
        );
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final columns = textScale >= 1.7
            ? 1
            : contentWidth >= 1000
            ? 4
            : contentWidth >= 680
            ? 3
            : contentWidth >= 320
            ? 2
            : 1;
        final itemWidth =
            (contentWidth - AppSpacing.md * (columns - 1)) / columns;
        final cardTextHeight = textScale >= 1.7
            ? 500.0
            : textScale >= 1.3
            ? 340.0
            : 250.0;

        return RefreshIndicator.adaptive(
          onRefresh: ref.read(catalogControllerProvider.notifier).refresh,
          child: CustomScrollView(
            key: const PageStorageKey<String>('catalog-scroll'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                key: const ValueKey('catalog-sticky-search-header'),
                pinned: true,
                delegate: _CatalogSearchHeaderDelegate(
                  horizontalPadding: horizontalPadding,
                  child: _CatalogSearch(
                    l10n: l10n,
                    controller: _searchController,
                    onChanged: ref
                        .read(catalogControllerProvider.notifier)
                        .updateSearchQuery,
                    onSubmitted: (query) => unawaited(
                      ref
                          .read(catalogControllerProvider.notifier)
                          .submitSearch(query),
                    ),
                    onClear: () => unawaited(_clearSearch()),
                  ),
                ),
              ),
              if (state.isFromCache && state.cachedAt != null)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: StorefrontCacheStatus(
                      cachedAt: state.cachedAt!,
                      isStale: state.isStale,
                      isRefreshing: state.isRefreshing,
                    ),
                  ),
                ),
              if (state.categories.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.md,
                    horizontalPadding,
                    AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _CategorySelector(
                      categories: state.categories,
                      selectedSlug: state.selectedCategorySlug,
                      onSelected: (slug) => unawaited(_selectCategory(slug)),
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  AppSpacing.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: _CatalogControls(
                    l10n: l10n,
                    state: state,
                    expanded: _filtersExpanded,
                    onExpandedChanged: () =>
                        setState(() => _filtersExpanded = !_filtersExpanded),
                    onAvailabilitySelected: (availability) => unawaited(
                      ref
                          .read(catalogControllerProvider.notifier)
                          .selectAvailability(availability),
                    ),
                    onDiscountedChanged: (enabled) => unawaited(
                      ref
                          .read(catalogControllerProvider.notifier)
                          .setDiscountedOnly(enabled),
                    ),
                    onSortSelected: (sort) => unawaited(
                      ref
                          .read(catalogControllerProvider.notifier)
                          .selectSort(sort),
                    ),
                    onResetFilters: () => unawaited(
                      ref
                          .read(catalogControllerProvider.notifier)
                          .resetFilters(),
                    ),
                  ),
                ),
              ),
              ..._contentSlivers(
                state: state,
                l10n: l10n,
                horizontalPadding: horizontalPadding,
                columns: columns,
                mainAxisExtent:
                    itemWidth /
                        (itemWidth <= AppSizes.productCardCompactWidth
                            ? 1
                            : 16 / 10) +
                    cardTextHeight,
              ),
              SliverPadding(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  bottom: AppSpacing.xxl,
                ),
                sliver: SliverToBoxAdapter(
                  child: _CatalogFooter(
                    state: state,
                    onRetry: ref.read(catalogControllerProvider.notifier).retry,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _contentSlivers({
    required CatalogState state,
    required AppLocalizations l10n,
    required double horizontalPadding,
    required int columns,
    required double mainAxisExtent,
  }) {
    if (state.status == CatalogLoadStatus.data && state.items.isNotEmpty) {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            AppSpacing.lg,
          ),
          sliver: SliverGrid(
            key: const ValueKey('catalog-grid'),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              mainAxisExtent: mainAxisExtent,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = state.items[index];
              return StorefrontProductCard(
                key: ValueKey('catalog-product-${product.id}'),
                product: product,
              );
            }, childCount: state.items.length),
          ),
        ),
      ];
    }

    final presentation = switch (state.status) {
      CatalogLoadStatus.loading => (
        icon: Icons.cloud_sync_outlined,
        title: l10n.catalogConnectingTitle,
        message: l10n.catalogConnectingMessage,
        retryable: false,
        loading: true,
      ),
      CatalogLoadStatus.empty => (
        icon: Icons.inventory_2_outlined,
        title: l10n.catalogEmptyTitle,
        message: l10n.catalogEmptyMessage,
        retryable: false,
        loading: false,
      ),
      CatalogLoadStatus.offline => (
        icon: Icons.cloud_off_outlined,
        title: l10n.catalogOfflineTitle,
        message: l10n.catalogOfflineMessage,
        retryable: true,
        loading: false,
      ),
      CatalogLoadStatus.unavailable => (
        icon: Icons.cloud_queue_outlined,
        title: l10n.catalogUnavailableTitle,
        message: l10n.catalogUnavailableMessage,
        retryable: state.failure?.kind == StorefrontFailureKind.unavailable,
        loading: false,
      ),
      CatalogLoadStatus.failure => (
        icon: Icons.error_outline,
        title: l10n.catalogRetryTitle,
        message: l10n.catalogRetryMessage,
        retryable: true,
        loading: false,
      ),
      CatalogLoadStatus.data => throw StateError('catalog data without items'),
    };
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          AppSpacing.lg,
        ),
        sliver: SliverFillRemaining(
          hasScrollBody: false,
          child: StorefrontEmptyState(
            key: ValueKey('catalog-${state.status.name}'),
            icon: presentation.icon,
            title: presentation.title,
            message: presentation.message,
            actionLabel: presentation.retryable ? l10n.backendRetry : null,
            onAction: presentation.retryable
                ? ref.read(catalogControllerProvider.notifier).retry
                : null,
            actionKey: presentation.retryable
                ? const ValueKey('catalog-retry-action')
                : null,
            progress: presentation.loading,
          ),
        ),
      ),
    ];
  }
}

class _CatalogSearch extends StatelessWidget {
  const _CatalogSearch({
    required this.l10n,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final AppLocalizations l10n;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Semantics(
    textField: true,
    label: l10n.catalogSearchLabel,
    hint: l10n.catalogSearchMinimum,
    child: SearchBar(
      key: const ValueKey('catalog-search'),
      controller: controller,
      leading: const Icon(Icons.search),
      hintText: l10n.catalogSearchHint,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      trailing: controller.text.isNotEmpty
          ? [
              IconButton(
                key: const ValueKey('catalog-search-clear'),
                tooltip: l10n.catalogClearSearch,
                onPressed: onClear,
                icon: const Icon(Icons.clear),
              ),
            ]
          : null,
      constraints: const BoxConstraints.tightFor(height: 56),
      elevation: const WidgetStatePropertyAll(0),
      side: WidgetStatePropertyAll(
        BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
  );
}

class _CatalogSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _CatalogSearchHeaderDelegate({
    required this.horizontalPadding,
    required this.child,
  });

  final double horizontalPadding;
  final Widget child;

  @override
  double get minExtent => 80;

  @override
  double get maxExtent => 80;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Material(
    color: Theme.of(context).scaffoldBackgroundColor,
    elevation: overlapsContent ? 3 : 0,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.sm,
        horizontalPadding,
        AppSpacing.sm,
      ),
      child: child,
    ),
  );

  @override
  bool shouldRebuild(covariant _CatalogSearchHeaderDelegate oldDelegate) =>
      oldDelegate.horizontalPadding != horizontalPadding ||
      oldDelegate.child != child;
}

class _CatalogControls extends StatelessWidget {
  const _CatalogControls({
    required this.l10n,
    required this.state,
    required this.expanded,
    required this.onExpandedChanged,
    required this.onAvailabilitySelected,
    required this.onDiscountedChanged,
    required this.onSortSelected,
    required this.onResetFilters,
  });

  final AppLocalizations l10n;
  final CatalogState state;
  final bool expanded;
  final VoidCallback onExpandedChanged;
  final ValueChanged<StorefrontAvailability?> onAvailabilitySelected;
  final ValueChanged<bool> onDiscountedChanged;
  final ValueChanged<StorefrontCatalogSort> onSortSelected;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    final count = l10n.catalogLoadedCount(state.items.length);
    final filterLabel = expanded
        ? l10n.catalogHideFilters
        : l10n.catalogShowFilters;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final summary = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        count,
                        key: const ValueKey('catalog-result-count'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      l10n.catalogFiltersLabel,
                      key: const ValueKey('catalog-controls-explanation'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
                final button = FilledButton.tonalIcon(
                  key: const ValueKey('catalog-toggle-filters'),
                  onPressed: onExpandedChanged,
                  icon: Icon(expanded ? Icons.filter_alt_off : Icons.tune),
                  label: Text(filterLabel),
                );
                if (constraints.maxWidth < 480 ||
                    MediaQuery.textScalerOf(context).scale(1) >= 1.5) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      summary,
                      const SizedBox(height: AppSpacing.sm),
                      button,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: summary),
                    const SizedBox(width: AppSpacing.md),
                    button,
                  ],
                );
              },
            ),
            if (state.isSearchActive) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.catalogFiltersUnavailableDuringSearch,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            Offstage(
              key: const ValueKey('catalog-filter-panel'),
              offstage: !expanded,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.catalogAvailabilityLabel,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            key: const ValueKey('catalog-availability-all'),
                            label: Text(l10n.catalogAvailabilityAll),
                            selected: state.availabilityFilter == null,
                            onSelected: state.isSearchActive
                                ? null
                                : (_) => onAvailabilitySelected(null),
                          ),
                          for (final availability
                              in StorefrontAvailability.values) ...[
                            const SizedBox(width: AppSpacing.sm),
                            ChoiceChip(
                              key: ValueKey(
                                'catalog-availability-${availability.name}',
                              ),
                              label: Text(
                                _availabilityLabel(l10n, availability),
                              ),
                              selected:
                                  state.availabilityFilter == availability,
                              onSelected: state.isSearchActive
                                  ? null
                                  : (_) => onAvailabilitySelected(availability),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    KeyedSubtree(
                      key: ValueKey('catalog-sort-value-${state.sort.name}'),
                      child: DropdownButtonFormField<StorefrontCatalogSort>(
                        key: const ValueKey('catalog-sort'),
                        initialValue: state.sort,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.catalogSortLabel,
                          border: const OutlineInputBorder(),
                        ),
                        items: StorefrontCatalogSort.values
                            .map(
                              (sort) => DropdownMenuItem(
                                value: sort,
                                child: Text(_sortLabel(l10n, sort)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: state.isSearchActive
                            ? null
                            : (sort) {
                                if (sort != null) onSortSelected(sort);
                              },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilterChip(
                          key: const ValueKey('catalog-discounted-only'),
                          label: Text(l10n.catalogDiscountedOnly),
                          selected: state.discountedOnly,
                          onSelected: state.isSearchActive
                              ? null
                              : onDiscountedChanged,
                        ),
                        TextButton.icon(
                          key: const ValueKey('catalog-reset-filters'),
                          onPressed:
                              state.isSearchActive || !state.hasCatalogFilters
                              ? null
                              : onResetFilters,
                          icon: const Icon(Icons.restart_alt),
                          label: Text(l10n.catalogResetFilters),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _availabilityLabel(
    AppLocalizations strings,
    StorefrontAvailability availability,
  ) => switch (availability) {
    StorefrontAvailability.available => strings.catalogAvailabilityAvailable,
    StorefrontAvailability.lowStock => strings.catalogAvailabilityLowStock,
    StorefrontAvailability.unavailable =>
      strings.catalogAvailabilityUnavailable,
    StorefrontAvailability.reservationOnly =>
      strings.catalogAvailabilityReservationOnly,
    StorefrontAvailability.pickupOnly => strings.catalogAvailabilityPickupOnly,
    StorefrontAvailability.deliveryOnly =>
      strings.catalogAvailabilityDeliveryOnly,
  };

  String _sortLabel(
    AppLocalizations strings,
    StorefrontCatalogSort sort,
  ) => switch (sort) {
    StorefrontCatalogSort.catalog => strings.catalogSortCatalog,
    StorefrontCatalogSort.name => strings.catalogSortName,
    StorefrontCatalogSort.priceAscending => strings.catalogSortPriceAscending,
    StorefrontCatalogSort.priceDescending => strings.catalogSortPriceDescending,
  };
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.categories,
    required this.selectedSlug,
    required this.onSelected,
  });

  final List<StorefrontCategory> categories;
  final String? selectedSlug;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l10n.catalogCategoriesLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.catalogCategoriesLabel,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  key: const ValueKey('catalog-category-all'),
                  label: Text(l10n.catalogAllCategories),
                  selected: selectedSlug == null,
                  onSelected: (_) => onSelected(null),
                ),
                for (final category in categories) ...[
                  const SizedBox(width: AppSpacing.sm),
                  ChoiceChip(
                    key: ValueKey('catalog-category-${category.slug}'),
                    label: Text(category.name),
                    selected: selectedSlug == category.slug,
                    onSelected: (_) => onSelected(category.slug),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogFooter extends StatelessWidget {
  const _CatalogFooter({required this.state, required this.onRetry});

  final CatalogState state;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (state.isLoadingMore) {
      return Semantics(
        liveRegion: true,
        label: l10n.catalogLoadingMore,
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      );
    }
    if (state.loadMoreFailed) {
      return StorefrontEmptyState(
        key: const ValueKey('catalog-load-more-error'),
        icon: Icons.sync_problem_outlined,
        title: l10n.catalogLoadMoreError,
        message: l10n.catalogRetryMessage,
        actionLabel: l10n.backendRetry,
        onAction: onRetry,
        actionKey: const ValueKey('catalog-load-more-retry'),
      );
    }
    return const SizedBox.shrink();
  }
}
