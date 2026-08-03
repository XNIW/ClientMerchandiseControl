import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/theme/storefront_semantic_colors.dart';
import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/design_system/widgets/storefront_empty_state.dart';
import '../../../app/design_system/widgets/storefront_page.dart';
import '../../../app/design_system/widgets/storefront_status_banner.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/formatting/clp_currency_formatter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../account/domain/customer_account_models.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../application/checkout_controller.dart';
import '../application/checkout_state.dart';
import '../domain/checkout_failure.dart';
import '../domain/checkout_models.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(checkoutControllerProvider);
    ref.listen<CheckoutState>(checkoutControllerProvider, (previous, next) {
      if (next.notice == null || next.notice == previous?.notice) return;
      final message = switch (next.notice!) {
        CheckoutNoticeKind.restored => l10n.checkoutRestoredNotice,
        CheckoutNoticeKind.quoteChanged => l10n.checkoutQuoteChangedNotice,
        CheckoutNoticeKind.confirmed => l10n.checkoutConfirmedNotice,
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      ref.read(checkoutControllerProvider.notifier).clearNotice();
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.checkoutTitle),
        leading: IconButton(
          key: const ValueKey('checkout-close'),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: state.isBusy
              ? null
              : () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.cartLocation),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: switch (state.status) {
        CheckoutViewStatus.authRequired => const _CheckoutAuthGate(),
        CheckoutViewStatus.loading => const Center(
          child: CircularProgressIndicator(key: ValueKey('checkout-loading')),
        ),
        CheckoutViewStatus.failure => _CheckoutFailureView(state: state),
        CheckoutViewStatus.ready => _CheckoutFlow(state: state),
      },
    );
  }
}

class _CheckoutAuthGate extends ConsumerWidget {
  const _CheckoutAuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final busy = auth.isBusy;
    final canAuthenticate = switch (auth) {
      AuthGuest(:final canAuthenticate) => canAuthenticate,
      AuthCancelled() || AuthRecoverableError() => true,
      _ => false,
    };
    return StorefrontPage(
      maxWidth: AppSizes.accountContentMaxWidth,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ExcludeSemantics(
                child: Icon(Icons.lock_person_outlined, size: 48),
              ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                header: true,
                child: Text(
                  l10n.checkoutAuthTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.checkoutAuthMessage, textAlign: TextAlign.center),
              if (busy) ...[
                const SizedBox(height: AppSpacing.lg),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.accountSigningInMessage, textAlign: TextAlign.center),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                key: const ValueKey('checkout-google-sign-in'),
                onPressed: canAuthenticate
                    ? controller.startGoogleSignIn
                    : null,
                icon: const Icon(Icons.login),
                label: Text(l10n.accountContinueWithGoogle),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                    AppSizes.minimumTouchTarget,
                  ),
                ),
              ),
              if (auth is AuthAuthenticating) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  key: const ValueKey('checkout-cancel-sign-in'),
                  onPressed: controller.cancelGoogleSignIn,
                  child: Text(l10n.accountCancelSignIn),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                key: const ValueKey('checkout-continue-browsing'),
                onPressed: () => context.go(AppRoutes.cartLocation),
                child: Text(l10n.checkoutContinueBrowsing),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutFailureView extends ConsumerWidget {
  const _CheckoutFailureView({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return StorefrontPage(
      maxWidth: AppSizes.accountContentMaxWidth,
      child: StorefrontEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: l10n.checkoutUnavailableTitle,
        message: checkoutFailureMessage(
          l10n,
          state.failureKind ?? CheckoutFailureKind.unexpected,
        ),
        actionLabel: state.cart?.isEmpty ?? true
            ? l10n.cartExploreCatalog
            : l10n.checkoutRetryAction,
        actionKey: const ValueKey('checkout-failure-action'),
        onAction: state.cart?.isEmpty ?? true
            ? () => context.go(AppRoutes.catalogLocation)
            : ref.read(checkoutControllerProvider.notifier).retry,
      ),
    );
  }
}

class _CheckoutFlow extends ConsumerWidget {
  const _CheckoutFlow({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(checkoutControllerProvider.notifier);
    return PopScope<void>(
      canPop: state.step == CheckoutStep.mode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !state.isBusy) controller.previousStep();
      },
      child: Column(
        children: [
          Expanded(
            child: StorefrontPage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CheckoutProgress(step: state.step),
                  if (state.failureKind case final failure?) ...[
                    const SizedBox(height: AppSpacing.md),
                    StorefrontStatusBanner(
                      key: const ValueKey('checkout-failure-banner'),
                      message: checkoutFailureMessage(
                        AppLocalizations.of(context),
                        failure,
                      ),
                      icon: Icons.warning_amber_outlined,
                      actionLabel: state.hasPendingRetry
                          ? AppLocalizations.of(context).checkoutRetryAction
                          : null,
                      onAction: state.hasPendingRetry ? controller.retry : null,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  switch (state.step) {
                    CheckoutStep.mode => _ModeStep(state: state),
                    CheckoutStep.destination => _DestinationStep(state: state),
                    CheckoutStep.slot => _SlotStep(state: state),
                    CheckoutStep.review => _ReviewStep(state: state),
                    CheckoutStep.confirmation => _ConfirmationStep(
                      state: state,
                    ),
                  },
                ],
              ),
            ),
          ),
          _CheckoutActions(state: state),
        ],
      ),
    );
  }
}

class _CheckoutProgress extends StatelessWidget {
  const _CheckoutProgress({required this.step});

  final CheckoutStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = checkoutStepTitle(l10n, step);
    final current = step.index + 1;
    return Semantics(
      container: true,
      label: l10n.checkoutStepProgress(
        current,
        CheckoutStep.values.length,
        title,
      ),
      value: '$current/${CheckoutStep.values.length}',
      child: ExcludeSemantics(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.checkoutStepProgress(
                    current,
                    CheckoutStep.values.length,
                    title,
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(
                  value: current / CheckoutStep.values.length,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeStep extends ConsumerWidget {
  const _ModeStep({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final modes = state.options!.modes.where((mode) => mode.enabled).toList();
    return _StepSection(
      title: l10n.checkoutModeTitle,
      message: l10n.checkoutModeMessage,
      child: RadioGroup<CheckoutFulfillmentMode>(
        groupValue: state.selection.mode,
        onChanged: (mode) {
          if (mode != null) {
            ref.read(checkoutControllerProvider.notifier).selectMode(mode);
          }
        },
        child: Column(
          children: [
            for (final option in modes)
              Card(
                key: ValueKey('checkout-mode-${option.mode.name}'),
                clipBehavior: Clip.antiAlias,
                child: RadioListTile<CheckoutFulfillmentMode>(
                  value: option.mode,
                  secondary: Icon(checkoutModeIcon(option.mode)),
                  title: Text(checkoutModeTitle(l10n, option.mode)),
                  subtitle: Text(checkoutModeDescription(l10n, option.mode)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DestinationStep extends ConsumerWidget {
  const _DestinationStep({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = state.selection.mode!;
    if (mode == CheckoutFulfillmentMode.delivery) {
      return _StepSection(
        title: l10n.checkoutDeliveryAddressTitle,
        message: l10n.checkoutDeliveryAddressMessage,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.addresses.isEmpty)
              StorefrontStatusBanner(
                message: l10n.checkoutNoAddresses,
                icon: Icons.location_off_outlined,
                actionLabel: l10n.checkoutManageAddresses,
                onAction: () => context.push(AppRoutes.accountLocation),
              )
            else
              RadioGroup<String>(
                groupValue: state.selection.addressId,
                onChanged: (addressId) {
                  if (addressId != null) {
                    ref
                        .read(checkoutControllerProvider.notifier)
                        .selectAddress(addressId);
                  }
                },
                child: Column(
                  children: [
                    for (final address in state.addresses)
                      _AddressChoice(
                        address: address,
                        enabled: state.options!.deliveryZones.any(
                          (zone) => zone.supports(address),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              key: const ValueKey('checkout-manage-addresses'),
              onPressed: () => context.push(AppRoutes.accountLocation),
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: Text(l10n.checkoutManageAddresses),
            ),
          ],
        ),
      );
    }
    return _StepSection(
      title: l10n.checkoutPickupPointTitle,
      message: l10n.checkoutPickupPointMessage,
      child: RadioGroup<String>(
        groupValue: state.selection.pickupPointId,
        onChanged: (pointId) {
          if (pointId != null) {
            ref
                .read(checkoutControllerProvider.notifier)
                .selectPickupPoint(pointId);
          }
        },
        child: Column(
          children: [
            for (final point in state.options!.pickupPoints)
              Card(
                key: ValueKey('checkout-pickup-${point.id}'),
                clipBehavior: Clip.antiAlias,
                child: RadioListTile<String>(
                  value: point.id,
                  secondary: const Icon(Icons.storefront_outlined),
                  title: Text(point.name),
                  subtitle: Text(
                    [
                      point.addressLine1,
                      if (point.addressLine2 != null) point.addressLine2!,
                      point.commune,
                    ].join(' · '),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddressChoice extends StatelessWidget {
  const _AddressChoice({required this.address, required this.enabled});

  final CustomerAddress address;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      key: ValueKey('checkout-address-${address.id}'),
      clipBehavior: Clip.antiAlias,
      child: RadioListTile<String>(
        value: address.id,
        enabled: enabled,
        secondary: Icon(
          enabled ? Icons.location_on_outlined : Icons.location_off_outlined,
        ),
        title: Text(address.label),
        subtitle: Text(
          [
            address.addressLine1,
            address.commune,
            if (!enabled) l10n.checkoutUnsupportedAddress,
          ].join(' · '),
        ),
      ),
    );
  }
}

class _SlotStep extends ConsumerWidget {
  const _SlotStep({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final slots = state.selectableSlots;
    return _StepSection(
      title: l10n.checkoutSlotTitle,
      message: l10n.checkoutSlotMessage,
      child: slots.isEmpty
          ? StorefrontStatusBanner(
              message: l10n.checkoutNoSlots,
              icon: Icons.event_busy_outlined,
            )
          : RadioGroup<String>(
              groupValue: state.selection.slotId,
              onChanged: (slotId) {
                if (slotId != null) {
                  ref
                      .read(checkoutControllerProvider.notifier)
                      .selectSlot(slotId);
                }
              },
              child: Column(
                children: [
                  for (final slot in slots)
                    Card(
                      key: ValueKey('checkout-slot-${slot.id}'),
                      clipBehavior: Clip.antiAlias,
                      child: RadioListTile<String>(
                        value: slot.id,
                        secondary: const Icon(Icons.schedule_outlined),
                        title: Text(slot.label),
                        subtitle: Text(slotWindow(context, slot)),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formatter = ClpCurrencyFormatter();
    final cart = state.cart!;
    final slot = state.selectedSlot!;
    final fee = state.options!.deliveryZone(slot.deliveryZoneId)?.feeClp ?? 0;
    return _StepSection(
      title: l10n.checkoutReviewTitle,
      message: l10n.checkoutReviewMessage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StorefrontStatusBanner(
            message: l10n.checkoutServerValidationNotice,
            icon: Icons.verified_user_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          _SelectionSummary(state: state),
          const SizedBox(height: AppSpacing.md),
          for (final item in cart.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.publicName),
              subtitle: Text(l10n.cartQuantityLabel(item.quantity)),
              trailing: Text(
                formatter.format(item.lineSubtotalClp),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          const Divider(),
          _MoneyRow(
            label: l10n.checkoutSubtotalLabel,
            value: formatter.format(cart.subtotalClp),
          ),
          _MoneyRow(
            label: l10n.checkoutDeliveryFeeLabel,
            value: formatter.format(fee),
          ),
          _MoneyRow(
            label: l10n.checkoutEstimatedTotalLabel,
            value: formatter.format(cart.subtotalClp + fee),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _ConfirmationStep extends StatelessWidget {
  const _ConfirmationStep({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formatter = ClpCurrencyFormatter();
    final quote = state.quote;
    if (quote == null) {
      return StorefrontStatusBanner(
        message: checkoutFailureMessage(
          l10n,
          state.failureKind ?? CheckoutFailureKind.unexpected,
        ),
        icon: Icons.warning_amber_outlined,
      );
    }
    final statusMessage = quote.isConfirmed
        ? l10n.checkoutConfirmedMessage
        : quote.isExpired
        ? l10n.checkoutExpiredMessage
        : quote.requiresCustomerReview
        ? l10n.checkoutReviewChangesMessage
        : l10n.checkoutQuoteReadyMessage;
    return _StepSection(
      title: l10n.checkoutConfirmationTitle,
      message: statusMessage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StorefrontStatusBanner(
            key: const ValueKey('checkout-quote-status'),
            message: quote.isConfirmed
                ? l10n.checkoutConfirmedMessage
                : l10n.checkoutQuoteRemaining(
                    _durationLabel(quote.remainingSeconds),
                  ),
            icon: quote.isConfirmed
                ? Icons.verified_outlined
                : Icons.timer_outlined,
          ),
          if (quote.changes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              header: true,
              child: Text(
                l10n.checkoutChangesTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (final change in quote.changes)
              ListTile(
                key: ValueKey(
                  'checkout-change-${change.publicationId}-${change.type.name}',
                ),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.change_circle_outlined),
                title: Text(checkoutChangeMessage(l10n, change)),
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
          for (final item in quote.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.publicName),
              subtitle: Text(l10n.cartQuantityLabel(item.quantity)),
              trailing: Text(
                formatter.format(item.lineTotalClp),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          const Divider(),
          _MoneyRow(
            label: l10n.checkoutSubtotalLabel,
            value: formatter.format(quote.subtotalClp),
          ),
          _MoneyRow(
            label: l10n.checkoutDeliveryFeeLabel,
            value: formatter.format(quote.deliveryFeeClp),
          ),
          _MoneyRow(
            key: const ValueKey('checkout-authoritative-total'),
            label: l10n.checkoutAuthoritativeTotalLabel,
            value: formatter.format(quote.totalClp),
            emphasized: true,
          ),
          if (quote.isConfirmed) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.checkoutOrderDeferredNotice,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mode = state.selection.mode!;
    final destination = mode == CheckoutFulfillmentMode.delivery
        ? '${state.selectedAddress!.label} · ${state.selectedAddress!.commune}'
        : state.selectedPickupPoint!.name;
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              checkoutModeTitle(l10n, mode),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(destination),
            const SizedBox(height: AppSpacing.xs),
            Text(state.selectedSlot!.label),
          ],
        ),
      ),
    );
  }
}

class _StepSection extends StatelessWidget {
  const _StepSection({
    required this.title,
    required this.message,
    required this.child,
  });

  final String title;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        child,
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleLarge?.copyWith(
            color: StorefrontSemanticColors.of(context).price,
            fontWeight: FontWeight.w800,
          )
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: AppSpacing.md),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _CheckoutActions extends ConsumerWidget {
  const _CheckoutActions({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(checkoutControllerProvider.notifier);
    final quote = state.quote;
    final primary = switch (state.step) {
      CheckoutStep.mode => (
        key: 'checkout-next-mode',
        label: l10n.checkoutContinueAction,
        enabled: state.selection.mode != null,
        action: controller.nextStep,
      ),
      CheckoutStep.destination => (
        key: 'checkout-next-destination',
        label: l10n.checkoutContinueAction,
        enabled: state.selection.mode == CheckoutFulfillmentMode.delivery
            ? state.selection.addressId != null &&
                  state.supportedDeliveryZones.isNotEmpty
            : state.selection.pickupPointId != null,
        action: controller.nextStep,
      ),
      CheckoutStep.slot => (
        key: 'checkout-next-slot',
        label: l10n.checkoutContinueAction,
        enabled: state.selection.slotId != null,
        action: controller.nextStep,
      ),
      CheckoutStep.review => (
        key: 'checkout-create-quote',
        label: l10n.checkoutValidateAction,
        enabled: true,
        action: controller.createQuote,
      ),
      CheckoutStep.confirmation when quote?.isConfirmed ?? false => (
        key: 'checkout-back-to-cart',
        label: l10n.checkoutBackToCart,
        enabled: true,
        action: () async => context.go(AppRoutes.cartLocation),
      ),
      CheckoutStep.confirmation when quote?.isExpired ?? true => (
        key: 'checkout-restart',
        label: l10n.checkoutRestartAction,
        enabled: true,
        action: controller.restart,
      ),
      CheckoutStep.confirmation => (
        key: 'checkout-confirm-quote',
        label: quote?.requiresCustomerReview ?? false
            ? l10n.checkoutAcceptChangesAction
            : l10n.checkoutConfirmAction,
        enabled: quote != null,
        action: controller.confirmQuote,
      ),
    };
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.isBusy)
                    const LinearProgressIndicator(
                      key: ValueKey('checkout-action-progress'),
                    ),
                  if (state.isBusy) const SizedBox(height: AppSpacing.sm),
                  FilledButton(
                    key: ValueKey(primary.key),
                    onPressed: !state.isBusy && primary.enabled
                        ? primary.action
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        AppSizes.minimumTouchTarget,
                      ),
                    ),
                    child: Text(primary.label),
                  ),
                  if (state.step != CheckoutStep.mode &&
                      !(quote?.isConfirmed ?? false)) ...[
                    const SizedBox(height: AppSpacing.xs),
                    TextButton(
                      key: const ValueKey('checkout-back-step'),
                      onPressed: state.isBusy ? null : controller.previousStep,
                      child: Text(l10n.checkoutBackAction),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String checkoutStepTitle(AppLocalizations l10n, CheckoutStep step) =>
    switch (step) {
      CheckoutStep.mode => l10n.checkoutStepMode,
      CheckoutStep.destination => l10n.checkoutStepDestination,
      CheckoutStep.slot => l10n.checkoutStepSlot,
      CheckoutStep.review => l10n.checkoutStepReview,
      CheckoutStep.confirmation => l10n.checkoutStepConfirmation,
    };

String checkoutModeTitle(AppLocalizations l10n, CheckoutFulfillmentMode mode) =>
    switch (mode) {
      CheckoutFulfillmentMode.pickup => l10n.checkoutModePickup,
      CheckoutFulfillmentMode.reservation => l10n.checkoutModeReservation,
      CheckoutFulfillmentMode.delivery => l10n.checkoutModeDelivery,
    };

String checkoutModeDescription(
  AppLocalizations l10n,
  CheckoutFulfillmentMode mode,
) => switch (mode) {
  CheckoutFulfillmentMode.pickup => l10n.checkoutModePickupDescription,
  CheckoutFulfillmentMode.reservation =>
    l10n.checkoutModeReservationDescription,
  CheckoutFulfillmentMode.delivery => l10n.checkoutModeDeliveryDescription,
};

IconData checkoutModeIcon(CheckoutFulfillmentMode mode) => switch (mode) {
  CheckoutFulfillmentMode.pickup => Icons.storefront_outlined,
  CheckoutFulfillmentMode.reservation => Icons.inventory_2_outlined,
  CheckoutFulfillmentMode.delivery => Icons.local_shipping_outlined,
};

String checkoutFailureMessage(
  AppLocalizations l10n,
  CheckoutFailureKind kind,
) => switch (kind) {
  CheckoutFailureKind.offline => l10n.checkoutOfflineError,
  CheckoutFailureKind.timeout => l10n.checkoutTimeoutError,
  CheckoutFailureKind.unauthorized => l10n.checkoutUnauthorizedError,
  CheckoutFailureKind.invalidInput => l10n.checkoutInvalidError,
  CheckoutFailureKind.unavailable => l10n.checkoutUnavailableError,
  CheckoutFailureKind.conflict => l10n.checkoutConflictError,
  CheckoutFailureKind.staleCart => l10n.checkoutStaleCartError,
  CheckoutFailureKind.invalidAddress => l10n.checkoutInvalidAddressError,
  CheckoutFailureKind.unsupportedZone => l10n.checkoutUnsupportedZoneError,
  CheckoutFailureKind.slotUnavailable => l10n.checkoutSlotUnavailableError,
  CheckoutFailureKind.cartUnavailable => l10n.checkoutCartUnavailableError,
  CheckoutFailureKind.expired => l10n.checkoutExpiredError,
  CheckoutFailureKind.notFound => l10n.checkoutNotFoundError,
  CheckoutFailureKind.unexpected => l10n.checkoutUnexpectedError,
};

String checkoutChangeMessage(
  AppLocalizations l10n,
  CheckoutQuoteChange change,
) => switch (change.type) {
  CheckoutChangeType.priceChanged => l10n.checkoutPriceChanged,
  CheckoutChangeType.promotionChanged => l10n.checkoutPromotionChanged,
  CheckoutChangeType.unavailable => l10n.checkoutProductUnavailable,
  CheckoutChangeType.holdRequired => l10n.checkoutHoldRequired,
};

String slotWindow(BuildContext context, CheckoutFulfillmentSlot slot) {
  final localizations = MaterialLocalizations.of(context);
  final start = slot.startsAt.toLocal();
  final end = slot.endsAt.toLocal();
  final date = localizations.formatMediumDate(start);
  final startTime = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(start),
  );
  final endTime = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(end));
  return '$date · $startTime–$endTime';
}

String _durationLabel(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}
