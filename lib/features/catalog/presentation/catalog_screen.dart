import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/tokens/app_breakpoints.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
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
  final Map<String?, double> _categoryOffsets = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_requestNextPageNearEnd);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_requestNextPageNearEnd)
      ..dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogControllerProvider);
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final basePadding = constraints.maxWidth >= AppBreakpoints.wide
            ? AppSpacing.xxl
            : AppSpacing.lg;
        final horizontalPadding =
            basePadding +
            math.max(0, (constraints.maxWidth - AppSizes.contentMaxWidth) / 2);
        final contentWidth = math.max(
          1,
          constraints.maxWidth - horizontalPadding * 2,
        );
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final columns = textScale >= 1.7
            ? 1
            : contentWidth >= 840
            ? 3
            : contentWidth >= 520
            ? 2
            : 1;
        final itemWidth =
            (contentWidth - AppSpacing.md * (columns - 1)) / columns;
        final cardTextHeight = textScale >= 1.7
            ? 300.0
            : textScale >= 1.3
            ? 235.0
            : 190.0;

        return RefreshIndicator.adaptive(
          onRefresh: ref.read(catalogControllerProvider.notifier).refresh,
          child: CustomScrollView(
            key: const PageStorageKey<String>('catalog-scroll'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.xl,
                  horizontalPadding,
                  AppSpacing.md,
                ),
                sliver: SliverToBoxAdapter(child: _CatalogControls(l10n: l10n)),
              ),
              if (state.categories.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.sm,
                    horizontalPadding,
                    AppSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _CategorySelector(
                      categories: state.categories,
                      selectedSlug: state.selectedCategorySlug,
                      onSelected: (slug) => unawaited(_selectCategory(slug)),
                    ),
                  ),
                ),
              ..._contentSlivers(
                state: state,
                l10n: l10n,
                horizontalPadding: horizontalPadding,
                columns: columns,
                mainAxisExtent: itemWidth * 0.75 + cardTextHeight,
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

class _CatalogControls extends StatelessWidget {
  const _CatalogControls({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              textField: true,
              enabled: false,
              label: l10n.catalogSearchLabel,
              hint: l10n.catalogSearchHint,
              child: ExcludeSemantics(
                child: SearchBar(
                  key: const ValueKey('catalog-search'),
                  enabled: false,
                  leading: const Icon(Icons.search),
                  hintText: l10n.catalogSearchHint,
                  constraints: const BoxConstraints(
                    minHeight: AppSizes.minimumTouchTarget,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.catalogControlsUnavailable,
              key: const ValueKey('catalog-controls-explanation'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.catalogCategoriesLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
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
        ),
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
