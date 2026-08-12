import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/theme/storefront_semantic_colors.dart';
import '../../../app/design_system/tokens/app_radii.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/design_system/widgets/storefront_empty_state.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/formatting/clp_currency_formatter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/customer_order_controller.dart';
import '../domain/customer_order_failure.dart';
import '../domain/customer_order_models.dart';
import 'customer_order_presentation.dart';
import 'orders_screen.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    scheduleMicrotask(
      () => ref
          .read(customerOrderControllerProvider.notifier)
          .openOrder(widget.orderId),
    );
  }

  @override
  void didUpdateWidget(covariant OrderDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      scheduleMicrotask(
        () => ref
            .read(customerOrderControllerProvider.notifier)
            .openOrder(widget.orderId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(customerOrderControllerProvider);
    final controller = ref.read(customerOrderControllerProvider.notifier);
    ref.listen<CustomerOrdersState>(customerOrderControllerProvider, (
      previous,
      next,
    ) {
      if (next.notice == null ||
          next.noticeRevision == previous?.noticeRevision) {
        return;
      }
      final message = switch (next.notice!) {
        CustomerOrdersNotice.cancelled => l10n.ordersCancelSuccess,
        CustomerOrdersNotice.cancellationFailed
            when next.failure == CustomerOrderFailureKind.offline ||
                next.failure == CustomerOrderFailureKind.timeout =>
          l10n.ordersCancelAmbiguous,
        CustomerOrdersNotice.cancellationFailed => customerOrderFailureMessage(
          l10n,
          next.failure,
        ),
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      controller.clearNotice();
    });
    final selectedMatches = state.selectedOrderId == widget.orderId;
    final detail = selectedMatches ? state.selectedOrder : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ordersDetailTitle),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.ordersLocation),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            key: const ValueKey('order-detail-refresh'),
            tooltip: l10n.ordersDetailRefresh,
            onPressed: state.isDetailLoading || state.isCancelling
                ? null
                : () =>
                      controller.openOrder(widget.orderId, forceRefresh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: detail == null
            ? _OrderDetailUnavailable(
                isLoading: !selectedMatches || state.isDetailLoading,
                state: state,
                onRetry: () =>
                    controller.openOrder(widget.orderId, forceRefresh: true),
              )
            : _OrderDetailBody(detail: detail, state: state),
      ),
    );
  }
}

class _OrderDetailUnavailable extends StatelessWidget {
  const _OrderDetailUnavailable({
    required this.isLoading,
    required this.state,
    required this.onRetry,
  });

  final bool isLoading;
  final CustomerOrdersState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (isLoading) {
      return Center(
        child: Semantics(
          liveRegion: true,
          label: l10n.ordersLoading,
          child: const CircularProgressIndicator(
            key: ValueKey('order-detail-loading'),
          ),
        ),
      );
    }
    return StorefrontEmptyState(
      icon: Icons.receipt_long_outlined,
      title: state.failure == CustomerOrderFailureKind.notFound
          ? l10n.ordersNotFound
          : l10n.ordersError,
      message: customerOrderFailureMessage(l10n, state.failure),
      actionLabel: l10n.ordersRetry,
      actionKey: const ValueKey('order-detail-retry'),
      onAction: onRetry,
    );
  }
}

class _OrderDetailBody extends ConsumerWidget {
  const _OrderDetailBody({required this.detail, required this.state});

  final CustomerOrderDetail detail;
  final CustomerOrdersState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(customerOrderControllerProvider.notifier);
    return RefreshIndicator.adaptive(
      onRefresh: () => controller.openOrder(detail.id, forceRefresh: true),
      child: ListView(
        key: const ValueKey('order-detail-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.status == CustomerOrdersStatus.offline) ...[
                    _DetailBanner(
                      key: const ValueKey('order-detail-offline'),
                      icon: Icons.cloud_off_outlined,
                      message: l10n.ordersOffline,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (state.failure != null) ...[
                    _DetailBanner(
                      key: const ValueKey('order-detail-error'),
                      icon: Icons.error_outline,
                      message: customerOrderFailureMessage(l10n, state.failure),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _OrderHeader(detail: detail),
                  const SizedBox(height: AppSpacing.md),
                  _OrderItems(detail: detail),
                  const SizedBox(height: AppSpacing.md),
                  _FulfillmentCard(detail: detail),
                  const SizedBox(height: AppSpacing.md),
                  _TimelineCard(detail: detail),
                  if (detail.cancellation.allowed) ...[
                    const SizedBox(height: AppSpacing.md),
                    _CancellationCard(
                      detail: detail,
                      isBusy: state.isCancelling,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  TextButton.icon(
                    key: const ValueKey('order-back-to-list'),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.ordersLocation),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.ordersBackToOrders),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        AppSizes.minimumTouchTarget,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.detail});

  final CustomerOrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formatter = ClpCurrencyFormatter();
    return Card(
      key: const ValueKey('order-detail-header'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      detail.code,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                    ),
                  ),
                ),
                CustomerOrderStatusChip(status: detail.status),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.ordersPlacedAt(
                      customerOrderDate(context, detail.placedAt),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.ordersTotalLabel,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      formatter.format(detail.totalClp),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItems extends StatelessWidget {
  const _OrderItems({required this.detail});

  final CustomerOrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formatter = ClpCurrencyFormatter();
    return Card(
      key: const ValueKey('order-detail-items'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(
              icon: Icons.inventory_2_outlined,
              title: l10n.ordersProductsTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            for (var index = 0; index < detail.items.length; index++) ...[
              if (index > 0) const Divider(height: AppSpacing.xl),
              _OrderLineRow(
                line: detail.items[index],
                formattedTotal: formatter.format(
                  detail.items[index].lineTotalClp,
                ),
              ),
            ],
            const Divider(height: AppSpacing.xl),
            _MoneyRow(
              label: l10n.checkoutSubtotalLabel,
              amount: formatter.format(detail.subtotalClp),
            ),
            if (detail.deliveryFeeClp > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              _MoneyRow(
                label: l10n.checkoutDeliveryFeeLabel,
                amount: formatter.format(detail.deliveryFeeClp),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            _MoneyRow(
              label: l10n.ordersTotalLabel,
              amount: formatter.format(detail.totalClp),
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderLineRow extends StatelessWidget {
  const _OrderLineRow({required this.line, required this.formattedTotal});

  final CustomerOrderLine line;
  final String formattedTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Container(
            width: AppSizes.minimumTouchTarget,
            height: AppSizes.minimumTouchTarget,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadii.surface),
            ),
            child: const Icon(Icons.inventory_2_outlined),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.publicName,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${line.quantity} × '
                '${ClpCurrencyFormatter().format(line.unitPriceClp)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (line.promotionName != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  line.promotionName!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: StorefrontSemanticColors.of(context).promotion,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          formattedTotal,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.amount,
    this.emphasized = false,
  });

  final String label;
  final String amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(amount, style: style),
      ],
    );
  }
}

class _FulfillmentCard extends StatelessWidget {
  const _FulfillmentCard({required this.detail});

  final CustomerOrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fulfillment = detail.fulfillment;
    return Card(
      key: const ValueKey('order-detail-fulfillment'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(
              icon: customerOrderModeIcon(fulfillment.mode),
              title: l10n.ordersFulfillmentTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              customerOrderModeLabel(l10n, fulfillment.mode),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              fulfillment.destinationTitle,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            for (final line in fulfillment.destinationLines)
              Text(
                line,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadii.surface),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_outlined),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fulfillment.slotLabel,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(
                            customerOrderDate(
                              context,
                              fulfillment.slotStartsAt,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
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
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.detail});

  final CustomerOrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      key: const ValueKey('order-detail-timeline'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(
              icon: Icons.route_outlined,
              title: l10n.ordersTimelineTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            for (var index = 0; index < detail.timeline.length; index++)
              _TimelineEventRow(
                event: detail.timeline[index],
                isLast: index == detail.timeline.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineEventRow extends StatelessWidget {
  const _TimelineEventRow({required this.event, required this.isLast});

  final CustomerOrderTimelineEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final label = customerOrderStatusLabel(
      AppLocalizations.of(context),
      event.status,
    );
    final color = customerOrderStatusColor(context, event.status);
    return Semantics(
      label: '$label. ${customerOrderDate(context, event.createdAt)}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isLast ? color : color.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 44,
                    color: color.withValues(alpha: 0.4),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: isLast ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    customerOrderDate(context, event.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancellationCard extends ConsumerWidget {
  const _CancellationCard({required this.detail, required this.isBusy});

  final CustomerOrderDetail detail;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Card.outlined(
      key: const ValueKey('order-cancellation-card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.ordersCancellationDeadline(
                customerOrderDate(context, detail.cancellation.deadline),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              key: const ValueKey('order-cancel-button'),
              onPressed: isBusy ? null : () => _confirm(context, ref),
              icon: isBusy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: Text(l10n.ordersCancelAction),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSizes.minimumTouchTarget),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ordersCancelConfirmTitle),
        content: Text(l10n.ordersCancelConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            key: const ValueKey('order-cancel-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.ordersCancelAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(customerOrderControllerProvider.notifier)
          .cancelSelectedOrder();
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailBanner extends StatelessWidget {
  const _DetailBanner({required this.icon, required this.message, super.key});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
