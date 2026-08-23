import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/theme/storefront_semantic_colors.dart';
import '../../../app/design_system/tokens/app_radii.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/design_system/widgets/storefront_empty_state.dart';
import '../../../app/design_system/widgets/storefront_page.dart';
import '../../../app/design_system/widgets/storefront_section.dart';
import '../../../app/design_system/widgets/storefront_status_banner.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/formatting/clp_currency_formatter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/presentation/storefront_product_card.dart';
import '../../home/application/home_controller.dart';
import '../../account/application/customer_account_controller.dart';
import '../../account/domain/customer_account_models.dart';
import '../../delivery_context/domain/delivery_context_models.dart';
import '../../reservations/presentation/reservation_hold_panel.dart';
import '../../storefront/domain/storefront_models.dart';
import '../../storefront/presentation/storefront_product_metadata.dart';
import '../application/cart_controller.dart';
import '../application/cart_providers.dart';
import '../application/cart_state.dart';
import '../domain/cart_failure.dart';
import '../domain/cart_models.dart';
import 'cart_messages.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(cartControllerProvider);
    ref.listen<CartState>(cartControllerProvider, (previous, next) {
      final notice = next.notice;
      if (notice == null || previous?.notice == notice) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(cartNoticeMessage(l10n, notice))),
        );
      ref.read(cartControllerProvider.notifier).clearNotice();
    });
    final snapshot = state.snapshot;
    final hasItems = snapshot != null && snapshot.items.isNotEmpty;
    return SafeArea(
      top: false,
      bottom: false,
      child: hasItems
          ? Column(
              children: [
                Expanded(
                  child: _CartBody(
                    state: state,
                    onClear: state.isBusy
                        ? null
                        : () => _confirmClear(context, ref),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.62,
                  ),
                  child: _CartSummary(state: state),
                ),
              ],
            )
          : _CartBody(state: state),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.cartClearTitle),
        content: Text(l10n.cartClearMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.customerDialogCancel),
          ),
          FilledButton(
            key: const ValueKey('cart-clear-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.cartClearAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(cartControllerProvider.notifier).clear();
    }
  }
}

class _CartBody extends ConsumerWidget {
  const _CartBody({required this.state, this.onClear});

  final CartState state;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final snapshot = state.snapshot;
    if (state.status == CartViewStatus.loading && snapshot == null) {
      return const StorefrontPage(
        child: Center(
          child: CircularProgressIndicator(key: ValueKey('cart-loading')),
        ),
      );
    }
    if (snapshot == null) {
      final isUnconfigured = state.failureKind == CartFailureKind.invalidInput;
      return StorefrontPage(
        child: StorefrontEmptyState(
          icon: isUnconfigured
              ? Icons.shopping_cart_outlined
              : Icons.cloud_off_outlined,
          title: isUnconfigured ? l10n.cartEmptyTitle : l10n.cartTitle,
          message: isUnconfigured
              ? l10n.cartEmptyMessage
              : cartFailureMessage(
                  l10n,
                  state.failureKind ?? CartFailureKind.unexpected,
                ),
          actionLabel: isUnconfigured
              ? l10n.cartExploreCatalog
              : l10n.cartRetryAction,
          actionKey: ValueKey(
            isUnconfigured ? 'cart-explore-catalog' : 'cart-retry',
          ),
          onAction: isUnconfigured
              ? () => context.go(AppRoutes.catalogLocation)
              : ref.read(cartControllerProvider.notifier).retry,
        ),
      );
    }
    if (snapshot.items.isEmpty) {
      return _EmptyCartContent(
        featured: ref.watch(homeControllerProvider).data?.featured ?? const [],
      );
    }
    return RefreshIndicator.adaptive(
      onRefresh: ref.read(cartControllerProvider.notifier).refresh,
      child: ListView(
        key: const ValueKey('cart-items'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
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
                  _CartContextHeader(
                    contextValue: ref
                        .watch(cartDeliveryContextStateProvider)
                        .context,
                    address: _selectedAddress(
                      ref.watch(customerAccountControllerProvider),
                      ref.watch(cartDeliveryContextStateProvider).context,
                    ),
                    fulfillment: ref
                        .watch(homeControllerProvider)
                        .data
                        ?.settings
                        .fulfillment,
                    onClear: onClear,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StorefrontStatusBanner(
                    message: state.isAuthenticated
                        ? l10n.cartAccountSyncMessage
                        : l10n.cartGuestSyncMessage,
                    icon: state.isAuthenticated
                        ? Icons.cloud_done_outlined
                        : Icons.offline_bolt_outlined,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.cartPriceDisclaimer,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (state.failureKind case final failure?) ...[
                    const SizedBox(height: AppSpacing.sm),
                    StorefrontStatusBanner(
                      message: [
                        cartFailureMessage(l10n, failure),
                        if (state.hasPendingRetry) l10n.cartPendingRetry,
                      ].join(' '),
                      icon: Icons.warning_amber_outlined,
                      actionLabel: l10n.cartRetryAction,
                      onAction: ref.read(cartControllerProvider.notifier).retry,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  for (
                    var index = 0;
                    index < snapshot.items.length;
                    index++
                  ) ...[
                    _CartLineCard(line: snapshot.items[index]),
                    if (index != snapshot.items.length - 1)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCartContent extends StatelessWidget {
  const _EmptyCartContent({required this.featured});

  final List<StorefrontProductSummary> featured;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StorefrontPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StorefrontEmptyState(
            icon: Icons.shopping_cart_outlined,
            title: l10n.cartEmptyTitle,
            message: l10n.cartEmptyMessage,
            actionLabel: l10n.cartExploreCatalog,
            actionKey: const ValueKey('cart-explore-catalog'),
            onAction: () => context.go(AppRoutes.catalogLocation),
          ),
          if (featured.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            StorefrontSection(
              title: l10n.homeFeaturedTitle,
              actionLabel: l10n.homeExploreCatalog,
              onAction: () => context.go(AppRoutes.catalogLocation),
              child: StorefrontProductCollection(
                products: featured.take(6).toList(growable: false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CartContextHeader extends StatelessWidget {
  const _CartContextHeader({
    required this.contextValue,
    required this.address,
    required this.fulfillment,
    required this.onClear,
  });

  final CustomerDeliveryContext? contextValue;
  final CustomerAddress? address;
  final StorefrontFulfillment? fulfillment;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modes = <String>[
      if (fulfillment?.pickup == true) l10n.checkoutModePickup,
      if (fulfillment?.delivery == true) l10n.checkoutModeDelivery,
    ];
    final pickup = contextValue?.mode == CustomerDeliveryMode.pickup;
    final destination = pickup
        ? contextValue?.pickupPointName
        : address == null
        ? null
        : '${address!.label} · ${address!.commune}';
    final status = switch (contextValue?.serviceabilityStatus) {
      DeliveryServiceabilityStatus.serviceable =>
        l10n.deliveryContextServiceable,
      DeliveryServiceabilityStatus.unsupported =>
        l10n.deliveryContextUnsupported,
      DeliveryServiceabilityStatus.invalid => l10n.deliveryContextInvalid,
      DeliveryServiceabilityStatus.temporarilyUnavailable =>
        l10n.deliveryContextTemporarilyUnavailable,
      null => l10n.deliveryContextInvalid,
    };
    final fee = contextValue?.estimatedFeeClp;
    final slotStart = contextValue?.earliestSlotStartsAt;
    final slotEnd = contextValue?.earliestSlotEndsAt;
    final detail = slotStart == null || slotEnd == null
        ? status
        : '$status · '
              '${MaterialLocalizations.of(context).formatShortDate(slotStart.toLocal())} '
              '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(slotStart.toLocal()))}'
              '–${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(slotEnd.toLocal()))}'
              '${fee == null ? '' : ' · ${ClpCurrencyFormatter().format(fee)}'}';
    return Card.outlined(
      key: const ValueKey('cart-store-context'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Icon(
                pickup
                    ? Icons.storefront_outlined
                    : Icons.local_shipping_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    pickup
                        ? l10n.deliveryContextPickup
                        : l10n.deliveryContextDelivery,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    destination ??
                        (modes.isEmpty
                            ? l10n.homeStoreContextFallback
                            : modes.join(' · ')),
                  ),
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      TextButton.icon(
                        key: const ValueKey('cart-change-delivery-context'),
                        onPressed: () =>
                            context.push(AppRoutes.deliveryContextLocation),
                        icon: const Icon(Icons.edit_location_alt_outlined),
                        label: Text(l10n.cartModifyContext),
                      ),
                      IconButton(
                        key: const ValueKey('cart-clear'),
                        tooltip: l10n.cartClearAction,
                        onPressed: onClear,
                        icon: const Icon(Icons.delete_sweep_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLineCard extends ConsumerWidget {
  _CartLineCard({required this.line});

  final CartLine line;
  final ClpCurrencyFormatter _formatter = ClpCurrencyFormatter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(cartControllerProvider);
    final busy = state.busyPublicationIds.contains(line.publicationId);
    final price = _formatter.format(line.priceClp);
    final semanticLabel = l10n.cartLineSemantics(
      line.publicName,
      line.quantity,
      price,
    );
    final issue = switch (line.changeType) {
      CartLineChangeType.priceChanged => l10n.cartPriceChangedLine,
      CartLineChangeType.promotionChanged => l10n.cartPromotionChangedLine,
      CartLineChangeType.unavailable => l10n.cartUnavailableLine,
      CartLineChangeType.none => null,
    };
    return Semantics(
      container: true,
      label: [semanticLabel, ?issue].join('. '),
      explicitChildNodes: true,
      child: Card(
        key: ValueKey('cart-line-${line.publicationId}'),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: SizedBox.square(
                  dimension: 72,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.surface),
                    child: StorefrontProductImage(
                      productId: line.publicationId,
                      name: line.publicName,
                      uri: line.imageUrl,
                      sha256Digest: null,
                      cacheWidth: 264,
                      keyPrefix: 'cart-image',
                      compactPlaceholder: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.publicName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      price,
                      key: ValueKey('cart-price-${line.publicationId}'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: StorefrontSemanticColors.of(context).price,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    StorefrontAvailabilityBadge(
                      availability: line.availability,
                      compact: true,
                    ),
                    if (issue != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        issue,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    ReservationHoldPanel(
                      key: ValueKey('cart-reservation-${line.publicationId}'),
                      publicationId: line.publicationId,
                      quantity: line.quantity,
                      canCreate: false,
                      compact: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _QuantityButton(
                          key: ValueKey('cart-decrease-${line.publicationId}'),
                          label: l10n.cartDecreaseQuantity,
                          icon: Icons.remove,
                          onPressed: busy || line.quantity <= 1
                              ? null
                              : () => ref
                                    .read(cartControllerProvider.notifier)
                                    .setQuantity(
                                      line.publicationId,
                                      line.quantity - 1,
                                    ),
                        ),
                        SizedBox(
                          height: AppSizes.minimumTouchTarget,
                          child: Center(
                            child: Text(
                              l10n.cartQuantityLabel(line.quantity),
                              key: ValueKey(
                                'cart-quantity-${line.publicationId}',
                              ),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                        _QuantityButton(
                          key: ValueKey('cart-increase-${line.publicationId}'),
                          label: l10n.cartIncreaseQuantity,
                          icon: Icons.add,
                          onPressed:
                              busy ||
                                  !line.isAvailable ||
                                  line.quantity >= customerCartMaximumQuantity
                              ? null
                              : () => ref
                                    .read(cartControllerProvider.notifier)
                                    .setQuantity(
                                      line.publicationId,
                                      line.quantity + 1,
                                    ),
                        ),
                        TextButton.icon(
                          key: ValueKey('cart-remove-${line.publicationId}'),
                          onPressed: busy
                              ? null
                              : () => ref
                                    .read(cartControllerProvider.notifier)
                                    .remove(line.publicationId),
                          icon: const Icon(Icons.delete_outline),
                          label: Text(l10n.cartRemoveAction),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(
                              AppSizes.minimumTouchTarget,
                              AppSizes.minimumTouchTarget,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: label,
    onTap: onPressed,
    excludeSemantics: true,
    child: SizedBox.square(
      dimension: AppSizes.minimumTouchTarget,
      child: IconButton.outlined(
        tooltip: label,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    ),
  );
}

class _CartSummary extends ConsumerWidget {
  _CartSummary({required this.state});

  final CartState state;
  final ClpCurrencyFormatter _formatter = ClpCurrencyFormatter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final snapshot = state.snapshot!;
    final deliveryContext = ref.watch(cartDeliveryContextStateProvider).context;
    final contextReady = deliveryContext?.isCheckoutReady ?? false;
    final feeClp = deliveryContext?.estimatedFeeClp;
    final savingsClp = snapshot.items.fold<int>(0, (total, line) {
      final compareAt = line.compareAtPriceClp;
      return total +
          (compareAt != null && compareAt > line.priceClp
              ? (compareAt - line.priceClp) * line.quantity
              : 0);
    });
    final subtotal = _formatter.format(snapshot.subtotalClp);
    final label = snapshot.quoteStatus == CartQuoteStatus.confirmed
        ? l10n.cartConfirmedSubtotal(subtotal)
        : l10n.cartIndicativeSubtotal(subtotal);
    final statusLabel = snapshot.quoteStatus == CartQuoteStatus.confirmed
        ? l10n.cartValidatedLabel
        : l10n.cartEstimatedLabel;
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            key: const ValueKey('cart-subtotal'),
                            label: label,
                            excludeSemantics: true,
                            child: Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  subtotal,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  avatar: Icon(
                                    snapshot.quoteStatus ==
                                            CartQuoteStatus.confirmed
                                        ? Icons.verified_outlined
                                        : Icons.info_outline,
                                    size: 18,
                                  ),
                                  label: Text(statusLabel),
                                ),
                                if (state.isAuthenticated)
                                  TextButton.icon(
                                    key: const ValueKey('cart-revalidate'),
                                    onPressed: state.isBusy
                                        ? null
                                        : ref
                                              .read(
                                                cartControllerProvider.notifier,
                                              )
                                              .revalidate,
                                    icon: const Icon(Icons.verified_outlined),
                                    label: Text(l10n.cartRevalidateAction),
                                  ),
                              ],
                            ),
                          ),
                          if (savingsClp > 0)
                            _CartMoneyRow(
                              label: l10n.cartSavingsLabel,
                              value: _formatter.format(savingsClp),
                            ),
                          _CartMoneyRow(
                            label: l10n.checkoutDeliveryFeeLabel,
                            value: feeClp == null
                                ? '—'
                                : _formatter.format(feeClp),
                          ),
                          _CartMoneyRow(
                            label: l10n.checkoutEstimatedTotalLabel,
                            value: contextReady
                                ? _formatter.format(
                                    snapshot.subtotalClp + (feeClp ?? 0),
                                  )
                                : '—',
                            emphasized: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    key: const ValueKey('cart-checkout'),
                    onPressed: state.isBusy
                        ? null
                        : contextReady
                        ? () => context.push(AppRoutes.checkoutLocation)
                        : () => context.push(AppRoutes.deliveryContextLocation),
                    icon: state.isGlobalBusy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.shopping_bag_outlined),
                    label: Text(
                      !contextReady
                          ? l10n.cartChooseDelivery
                          : state.isAuthenticated
                          ? l10n.cartCheckoutAction
                          : l10n.cartSignInCheckoutAction,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        AppSizes.minimumTouchTarget,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

CustomerAddress? _selectedAddress(
  CustomerAccountState account,
  CustomerDeliveryContext? context,
) {
  final id = context?.addressId;
  if (id == null) return null;
  return account.snapshot?.addresses
      .where((address) => address.id == id)
      .firstOrNull;
}

class _CartMoneyRow extends StatelessWidget {
  const _CartMoneyRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
