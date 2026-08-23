import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/design_system/widgets/storefront_empty_state.dart';
import '../../../app/design_system/widgets/storefront_page.dart';
import '../../../app/design_system/widgets/storefront_status_banner.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/formatting/clp_currency_formatter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/checkout_controller.dart';
import '../application/checkout_state.dart';
import '../domain/checkout_models.dart';
import 'checkout_screen.dart';

class CheckoutPaymentScreen extends ConsumerWidget {
  const CheckoutPaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(checkoutControllerProvider);
    ref.listen<CheckoutState>(checkoutControllerProvider, (previous, next) {
      if (previous?.order == null && next.order != null) {
        scheduleMicrotask(() {
          if (context.mounted) context.go(AppRoutes.checkoutLocation);
        });
      }
    });
    final quote = state.quote;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.checkoutPaymentScreenTitle),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: state.isBusy ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: quote == null || !quote.isConfirmed
          ? StorefrontPage(
              maxWidth: AppSizes.accountContentMaxWidth,
              child: StorefrontEmptyState(
                icon: Icons.receipt_long_outlined,
                title: l10n.checkoutUnavailableTitle,
                message: l10n.checkoutExpiredMessage,
                actionLabel: l10n.checkoutBackAction,
                onAction: () => context.go(AppRoutes.checkoutLocation),
              ),
            )
          : _PaymentBody(state: state),
    );
  }
}

class _PaymentBody extends ConsumerWidget {
  const _PaymentBody({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final quote = state.quote!;
    final formatter = ClpCurrencyFormatter();
    final destination = state.selection.mode == CheckoutFulfillmentMode.delivery
        ? state.selectedAddress == null
              ? l10n.deliveryContextInvalid
              : '${state.selectedAddress!.label} · '
                    '${state.selectedAddress!.commune}'
        : state.selectedPickupPoint?.name ?? l10n.deliveryContextInvalid;
    final methods = state.compatiblePaymentOptions;
    final online = state.paymentOptions?.option(
      CheckoutPaymentMethod.onlinePayment,
    );
    final pending =
        state.pendingOperation?.kind == CheckoutPendingOperationKind.order;
    return Column(
      children: [
        Expanded(
          child: StorefrontPage(
            maxWidth: AppSizes.accountContentMaxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.checkoutPaymentTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          checkoutModeTitle(l10n, state.selection.mode!),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(destination),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          formatter.format(quote.totalClp),
                          key: const ValueKey('payment-authoritative-total'),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(l10n.checkoutAuthoritativeTotalLabel),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (state.failureKind != null)
                  StorefrontStatusBanner(
                    message: checkoutFailureMessage(l10n, state.failureKind!),
                    icon: Icons.warning_amber_outlined,
                    actionLabel: pending ? l10n.checkoutRetryAction : null,
                    onAction: pending
                        ? ref.read(checkoutControllerProvider.notifier).retry
                        : null,
                  ),
                if (pending) ...[
                  const SizedBox(height: AppSpacing.sm),
                  StorefrontStatusBanner(
                    message: l10n.checkoutPaymentProcessing,
                    icon: Icons.sync_outlined,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                RadioGroup<CheckoutPaymentMethod>(
                  groupValue: state.selection.paymentMethod,
                  onChanged: (method) {
                    if (!state.isBusy && method != null) {
                      ref
                          .read(checkoutControllerProvider.notifier)
                          .selectPaymentMethod(method);
                    }
                  },
                  child: Column(
                    children: [
                      for (final option in methods)
                        Card(
                          key: ValueKey('payment-method-${option.method.name}'),
                          child: RadioListTile<CheckoutPaymentMethod>(
                            value: option.method,
                            secondary: Icon(checkoutPaymentIcon(option.method)),
                            title: Text(
                              checkoutPaymentMethodTitle(l10n, option.method),
                            ),
                            subtitle: Text(
                              checkoutPaymentMethodDescription(
                                l10n,
                                option.method,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (online == null || !online.enabled)
                  ListTile(
                    key: const ValueKey('payment-online-not-configured'),
                    enabled: false,
                    minTileHeight: AppSizes.minimumTouchTarget,
                    leading: const Icon(Icons.lock_outline),
                    title: Text(l10n.checkoutPaymentOnline),
                    subtitle: Text(l10n.checkoutPaymentOnlineUnavailable),
                  ),
              ],
            ),
          ),
        ),
        Material(
          elevation: 8,
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: FilledButton(
                key: const ValueKey('payment-confirm-order'),
                onPressed:
                    state.isBusy || !state.hasValidPaymentSelection || pending
                    ? null
                    : ref.read(checkoutControllerProvider.notifier).createOrder,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                    AppSizes.minimumTouchTarget,
                  ),
                ),
                child: state.isBusy
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        state.selection.paymentMethod ==
                                CheckoutPaymentMethod.onlinePayment
                            ? l10n.checkoutContinueOnlineAction
                            : l10n.checkoutConfirmOrderAction,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
