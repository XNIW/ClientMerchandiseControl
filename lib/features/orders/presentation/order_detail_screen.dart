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
import '../../delivery_tracking/application/delivery_tracking_controller.dart';
import '../../delivery_tracking/application/delivery_tracking_providers.dart';
import '../../delivery_tracking/domain/delivery_tracking_models.dart';
import '../../delivery_tracking/presentation/delivery_live_map.dart';
import '../../delivery_tracking/presentation/google_delivery_map_adapter.dart';
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

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen>
    with WidgetsBindingObserver {
  String? _trackingOpenOrderId;
  late final CustomerOrderController _orderController;
  late final DeliveryTrackingController _trackingController;

  @override
  void initState() {
    super.initState();
    _orderController = ref.read(customerOrderControllerProvider.notifier);
    _trackingController = ref.read(deliveryTrackingControllerProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
    scheduleMicrotask(() => _orderController.openOrder(widget.orderId));
  }

  @override
  void didUpdateWidget(covariant OrderDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      _trackingOpenOrderId = null;
      scheduleMicrotask(() async {
        await _trackingController.close();
        if (mounted) await _orderController.openOrder(widget.orderId);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(
      _trackingController.setForeground(state == AppLifecycleState.resumed),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_trackingController.close());
    super.dispose();
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
    if (detail?.fulfillment.mode == CustomerOrderFulfillmentMode.delivery) {
      final terminal = _isTerminalCustomerOrderStatus(detail!.status);
      final trackingKey = terminal ? 'terminal:${detail.id}' : detail.id;
      if (_trackingOpenOrderId != trackingKey) {
        _trackingOpenOrderId = trackingKey;
        scheduleMicrotask(() {
          if (!mounted) return;
          unawaited(
            terminal
                ? _trackingController.close(clearCache: true)
                : _trackingController.open(detail.id),
          );
        });
      }
    }
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
                : () => unawaited(
                    Future.wait([
                      controller.openOrder(widget.orderId, forceRefresh: true),
                      ref
                          .read(deliveryTrackingControllerProvider.notifier)
                          .refresh(),
                    ]),
                  ),
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
      onRefresh: () => Future.wait([
        controller.openOrder(detail.id, forceRefresh: true),
        ref.read(deliveryTrackingControllerProvider.notifier).refresh(),
      ]),
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
                  if (detail.fulfillment.mode ==
                          CustomerOrderFulfillmentMode.delivery &&
                      !_isTerminalCustomerOrderStatus(detail.status)) ...[
                    _DeliveryTrackingSection(detail: detail),
                    const SizedBox(height: AppSpacing.md),
                  ],
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

class _DeliveryTrackingSection extends ConsumerWidget {
  const _DeliveryTrackingSection({required this.detail});

  final CustomerOrderDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deliveryTrackingControllerProvider);
    final ownerAuthenticated =
        ref.watch(deliveryTrackingIdentityProvider) != null;
    return _DeliveryTrackingCard(
      detail: detail,
      state: state,
      ownerAuthenticated: ownerAuthenticated,
      onRetry: () =>
          ref.read(deliveryTrackingControllerProvider.notifier).refresh(),
    );
  }
}

bool _isTerminalCustomerOrderStatus(CustomerOrderStatus status) =>
    status == CustomerOrderStatus.completed ||
    status == CustomerOrderStatus.cancelled ||
    status == CustomerOrderStatus.rejected;

bool _isPreDeliveryCustomerOrderStatus(CustomerOrderStatus status) =>
    status == CustomerOrderStatus.confirmed ||
    status == CustomerOrderStatus.accepted ||
    status == CustomerOrderStatus.preparing ||
    status == CustomerOrderStatus.ready;

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

class _DeliveryTrackingCard extends StatelessWidget {
  const _DeliveryTrackingCard({
    required this.detail,
    required this.state,
    required this.ownerAuthenticated,
    required this.onRetry,
  });

  final CustomerOrderDetail detail;
  final DeliveryTrackingViewState state;
  final bool ownerAuthenticated;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snapshot = state.orderId == detail.id ? state.snapshot : null;
    if (snapshot == null) {
      return Card(
        key: const ValueKey('delivery-tracking-card'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 152),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child:
                state.status == DeliveryTrackingStatus.loading ||
                    state.orderId != detail.id
                ? Semantics(
                    liveRegion: true,
                    label: l10n.deliveryTrackingLoading,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionTitle(
                          icon: Icons.local_shipping_outlined,
                          title: l10n.deliveryTrackingTitle,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const LinearProgressIndicator(
                          key: ValueKey('delivery-tracking-loading'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionTitle(
                        icon: Icons.local_shipping_outlined,
                        title: l10n.deliveryTrackingTitle,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(l10n.deliveryTrackingUnavailable),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton.icon(
                        key: const ValueKey('delivery-tracking-retry'),
                        onPressed: () => unawaited(onRetry()),
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.deliveryTrackingRetry),
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
      );
    }

    final modeLabel = switch (snapshot.trackingMode) {
      DeliveryTrackingMode.statusOnly => l10n.deliveryTrackingModeStatusOnly,
      DeliveryTrackingMode.externalCarrier =>
        l10n.deliveryTrackingModeExternalCarrier,
      DeliveryTrackingMode.liveCourier => l10n.deliveryTrackingModeLiveCourier,
    };
    final freshnessLabel =
        _isPreDeliveryCustomerOrderStatus(detail.status) &&
            snapshot.trackingMode == DeliveryTrackingMode.liveCourier
        ? l10n.deliveryTrackingLiveWaiting
        : switch (snapshot.freshness) {
            DeliveryTrackingFreshness.fresh => l10n.deliveryTrackingFresh,
            DeliveryTrackingFreshness.stale => l10n.deliveryTrackingStale,
            DeliveryTrackingFreshness.ended => l10n.deliveryTrackingEnded,
            DeliveryTrackingFreshness.unavailable
                when snapshot.trackingMode ==
                    DeliveryTrackingMode.liveCourier =>
              l10n.deliveryTrackingLiveWaiting,
            DeliveryTrackingFreshness.unavailable =>
              l10n.deliveryTrackingModeStatusOnly,
          };
    final semanticLabel = [
      l10n.deliveryTrackingTitle,
      modeLabel,
      customerOrderStatusLabel(l10n, detail.status),
      freshnessLabel,
    ].join('. ');
    final lastUpdatedLabel = snapshot.observedAt == null
        ? freshnessLabel
        : l10n.deliveryTrackingLastUpdated(
            customerOrderDate(context, snapshot.observedAt!),
          );

    return Semantics(
      key: const ValueKey('delivery-tracking-card'),
      container: true,
      label: semanticLabel,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitle(
                icon: snapshot.isTerminal
                    ? Icons.task_alt_outlined
                    : Icons.local_shipping_outlined,
                title: l10n.deliveryTrackingTitle,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    snapshot.freshness == DeliveryTrackingFreshness.stale
                        ? Icons.location_off_outlined
                        : Icons.location_on_outlined,
                    color: snapshot.freshness == DeliveryTrackingFreshness.stale
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          modeLabel,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(freshnessLabel),
                      ],
                    ),
                  ),
                ],
              ),
              if (snapshot.etaStartsAt != null &&
                  snapshot.etaEndsAt != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.deliveryTrackingWindow(
                    customerOrderDate(context, snapshot.etaStartsAt!),
                    customerOrderDate(context, snapshot.etaEndsAt!),
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
              DeliveryLiveMap(
                snapshot: snapshot,
                ownerAuthenticated: ownerAuthenticated,
                orderStatusCompatible:
                    detail.status == CustomerOrderStatus.outForDelivery,
                semanticsLabel: l10n.deliveryTrackingMapSemantics(
                  customerOrderStatusLabel(l10n, detail.status),
                  lastUpdatedLabel,
                ),
                recenterLabel: l10n.deliveryTrackingMapRecenter,
                loadingLabel: l10n.deliveryTrackingMapLoading,
                markerLabels: DeliveryMapMarkerLabels(
                  store: l10n.deliveryTrackingMapStoreMarker,
                  destination: l10n.deliveryTrackingMapDestinationMarker,
                  courier: l10n.deliveryTrackingMapCourierMarker,
                ),
              ),
              if (snapshot.courierPublicLabel != null &&
                  !snapshot.isTerminal) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.deliveryTrackingCourierLabel(
                    snapshot.courierPublicLabel!,
                  ),
                ),
              ],
              if (snapshot.trackingMode ==
                      DeliveryTrackingMode.externalCarrier &&
                  snapshot.externalCarrier != null &&
                  !snapshot.isTerminal) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  snapshot.externalCarrier!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (snapshot.externalTrackingCodeMasked != null)
                  Text(
                    l10n.deliveryTrackingExternalCode(
                      snapshot.externalTrackingCodeMasked!,
                    ),
                  ),
              ],
              if (snapshot.observedAt != null && !snapshot.isTerminal) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.deliveryTrackingLastUpdated(
                    customerOrderDate(context, snapshot.observedAt!),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (state.isPollingFallback) ...[
                const SizedBox(height: AppSpacing.md),
                _DetailBanner(
                  icon: Icons.sync_problem_outlined,
                  message: l10n.deliveryTrackingPollingFallback,
                ),
              ] else if (state.status == DeliveryTrackingStatus.offline) ...[
                const SizedBox(height: AppSpacing.md),
                _DetailBanner(
                  icon: Icons.lock_outline,
                  message: l10n.deliveryTrackingOfflineCached,
                ),
              ],
            ],
          ),
        ),
      ),
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
