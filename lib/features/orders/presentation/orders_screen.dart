import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/tokens/app_radii.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/design_system/widgets/storefront_empty_state.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/formatting/clp_currency_formatter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/customer_order_controller.dart';
import '../domain/customer_order_models.dart';
import '../domain/customer_order_selectors.dart';
import 'customer_order_presentation.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({
    this.initialFilter = CustomerOrderListFilter.all,
    super.key,
  });

  final CustomerOrderListFilter initialFilter;

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  late CustomerOrderListFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  void didUpdateWidget(covariant OrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      _filter = widget.initialFilter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(customerOrderControllerProvider);
    final controller = ref.read(customerOrderControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ordersTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            key: const ValueKey('orders-refresh'),
            tooltip: l10n.ordersRefreshTooltip,
            onPressed: state.isRefreshing ? null : controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _OrdersBody(
          state: state,
          filter: _filter,
          onFilterChanged: (filter) => setState(() => _filter = filter),
        ),
      ),
    );
  }
}

class _OrdersBody extends ConsumerWidget {
  const _OrdersBody({
    required this.state,
    required this.filter,
    required this.onFilterChanged,
  });

  final CustomerOrdersState state;
  final CustomerOrderListFilter filter;
  final ValueChanged<CustomerOrderListFilter> onFilterChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(customerOrderControllerProvider.notifier);
    if (state.status == CustomerOrdersStatus.loading && state.orders.isEmpty) {
      return Center(
        child: Semantics(
          liveRegion: true,
          label: l10n.ordersLoading,
          child: const CircularProgressIndicator(
            key: ValueKey('orders-loading'),
          ),
        ),
      );
    }
    if (state.status == CustomerOrdersStatus.failure && state.orders.isEmpty) {
      return StorefrontEmptyState(
        icon: Icons.receipt_long_outlined,
        title: l10n.ordersError,
        message: customerOrderFailureMessage(l10n, state.failure),
        actionLabel: l10n.ordersRetry,
        actionKey: const ValueKey('orders-retry'),
        onAction: controller.retry,
      );
    }
    if (state.orders.isEmpty) {
      return RefreshIndicator.adaptive(
        onRefresh: controller.refresh,
        child: ListView(
          key: const ValueKey('orders-empty-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.65,
              child: StorefrontEmptyState(
                icon: Icons.receipt_long_outlined,
                title: l10n.ordersEmptyTitle,
                message: l10n.ordersEmptyMessage,
              ),
            ),
          ],
        ),
      );
    }
    final filtered = filterCustomerOrders(state.orders, filter).toList();
    final primaryActive = selectPrimaryActiveOrder(filtered);
    if (primaryActive != null) {
      filtered
        ..removeWhere((order) => order.id == primaryActive.id)
        ..insert(0, primaryActive);
    }
    final displayCount = filtered.isEmpty ? 1 : filtered.length;
    return RefreshIndicator.adaptive(
      onRefresh: controller.refresh,
      child: ListView.separated(
        key: const ValueKey('orders-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        itemCount: displayCount + 3,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.contentMaxWidth,
                ),
                child: _OrdersFilterBar(
                  filter: filter,
                  onChanged: onFilterChanged,
                ),
              ),
            );
          }
          if (index == 1) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.contentMaxWidth,
                ),
                child: _OrdersStatus(state: state),
              ),
            );
          }
          if (index == displayCount + 2) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.contentMaxWidth,
                ),
                child: state.hasMore
                    ? OutlinedButton.icon(
                        key: const ValueKey('orders-load-more'),
                        onPressed: state.isLoadingMore
                            ? null
                            : controller.loadMore,
                        icon: state.isLoadingMore
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.expand_more),
                        label: Text(l10n.ordersLoadMore),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            AppSizes.minimumTouchTarget,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }
          if (filtered.isEmpty) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.contentMaxWidth,
                ),
                child: StorefrontEmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title: l10n.ordersFilterEmptyTitle,
                  message: l10n.ordersFilterEmptyMessage,
                ),
              ),
            );
          }
          final order = filtered[index - 2];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth,
              ),
              child: _OrderCard(
                order: order,
                highlighted: order.id == primaryActive?.id,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrdersFilterBar extends StatelessWidget {
  const _OrdersFilterBar({required this.filter, required this.onChanged});

  final CustomerOrderListFilter filter;
  final ValueChanged<CustomerOrderListFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = <CustomerOrderListFilter, String>{
      CustomerOrderListFilter.all: l10n.ordersFilterAll,
      CustomerOrderListFilter.active: l10n.ordersFilterActive,
      CustomerOrderListFilter.completed: l10n.ordersFilterCompleted,
      CustomerOrderListFilter.cancelled: l10n.ordersFilterCancelled,
    };
    return Semantics(
      container: true,
      label: l10n.ordersFiltersLabel,
      child: SingleChildScrollView(
        key: const ValueKey('orders-filters'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            for (final entry in labels.entries) ...[
              FilterChip(
                key: ValueKey('orders-filter-${entry.key.name}'),
                label: Text(entry.value),
                selected: filter == entry.key,
                onSelected: (_) => onChanged(entry.key),
              ),
              if (entry.key != CustomerOrderListFilter.cancelled)
                const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrdersStatus extends StatelessWidget {
  const _OrdersStatus({required this.state});

  final CustomerOrdersState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (state.status == CustomerOrdersStatus.offline) {
      return _StatusBanner(
        key: const ValueKey('orders-offline-banner'),
        icon: Icons.cloud_off_outlined,
        message: l10n.ordersOffline,
      );
    }
    if (state.failure != null) {
      return _StatusBanner(
        key: const ValueKey('orders-error-banner'),
        icon: Icons.error_outline,
        message: customerOrderFailureMessage(l10n, state.failure),
      );
    }
    if (state.cachedAt != null) {
      return Text(
        l10n.ordersCachedAt(customerOrderDate(context, state.cachedAt!)),
        key: const ValueKey('orders-cached-at'),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.icon, required this.message, super.key});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: message,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadii.surface),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.highlighted});

  final CustomerOrderCard order;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formatter = ClpCurrencyFormatter();
    final status = customerOrderStatusLabel(l10n, order.status);
    final total = formatter.format(order.totalClp);
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final code = Text(
      order.code,
      maxLines: stacked ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
    final statusChip = _StatusChip(status: order.status);
    return Semantics(
      button: true,
      label: l10n.ordersCardSemantics(order.code, status, total),
      excludeSemantics: true,
      child: Card(
        key: ValueKey('order-card-${order.id}'),
        clipBehavior: Clip.antiAlias,
        shape: highlighted
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.surface),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              )
            : null,
        child: InkWell(
          onTap: () => context.push(AppRoutes.orderLocation(order.id)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (highlighted) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          l10n.ordersActiveOrder,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (stacked)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      code,
                      const SizedBox(height: AppSpacing.sm),
                      statusChip,
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(child: code),
                      statusChip,
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  order.primaryItemName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      customerOrderModeIcon(order.fulfillmentMode),
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '${customerOrderModeLabel(l10n, order.fulfillmentMode)} · '
                        '${l10n.ordersItemCount(order.itemCount)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (stacked) ...[
                  Text(
                    l10n.ordersPlacedAt(
                      customerOrderDate(context, order.placedAt),
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.ordersTotalLabel,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              total,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.ordersPlacedAt(
                            customerOrderDate(context, order.placedAt),
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            l10n.ordersTotalLabel,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Text(
                            total,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final CustomerOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final label = customerOrderStatusLabel(
      AppLocalizations.of(context),
      status,
    );
    final color = customerOrderStatusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class CustomerOrderStatusChip extends StatelessWidget {
  const CustomerOrderStatusChip({required this.status, super.key});

  final CustomerOrderStatus status;

  @override
  Widget build(BuildContext context) => _StatusChip(status: status);
}
