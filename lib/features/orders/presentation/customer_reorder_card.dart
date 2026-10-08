import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/formatting/clp_currency_formatter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../cart/application/cart_controller.dart';
import '../application/customer_order_providers.dart';
import '../application/customer_reorder_attempt.dart';
import '../domain/customer_order_models.dart';

final class CustomerReorderCard extends ConsumerStatefulWidget {
  const CustomerReorderCard({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<CustomerReorderCard> createState() =>
      _CustomerReorderCardState();
}

final class _CustomerReorderCardState
    extends ConsumerState<CustomerReorderCard> {
  var _isLoading = false;
  late final CustomerReorderAttempt _attempt;

  @override
  void initState() {
    super.initState();
    _attempt = CustomerReorderAttempt(
      ref.read(customerOrderIdempotencyKeyFactoryProvider),
    );
  }

  Future<void> _open() async {
    if (_isLoading) return;
    final container = ProviderScope.containerOf(context);
    final owner = container.read(customerOrderIdentityProvider)?.subjectId;
    final shop = container.read(customerOrderShopSlugProvider);
    if (owner == null || shop == null) return;
    final scopeValid = ValueNotifier(true);
    final identitySubscription = container.listen(
      customerOrderIdentityProvider,
      (_, next) {
        if (next?.subjectId != owner) scopeValid.value = false;
      },
    );
    // Il listener diretto osserva anche A→B→A fra due frame, prima del mount.
    final authSubscription = container.exists(authControllerProvider)
        ? container.listen(authControllerProvider, (_, next) {
            final subject = switch (next) {
              AuthAuthenticated(:final customer) => customer.subjectId,
              _ => null,
            };
            if (subject != owner) scopeValid.value = false;
          })
        : null;
    final shopSubscription = container.listen(customerOrderShopSlugProvider, (
      _,
      next,
    ) {
      if (next != shop) scopeValid.value = false;
    });
    setState(() => _isLoading = true);
    try {
      final preview = await ref
          .read(customerOrderRepositoryProvider)
          .previewReorder(widget.orderId);
      if (!mounted || !scopeValid.value) return;
      final idempotencyKey = _attempt.begin();
      final navigator = Navigator.of(context);
      final route = ModalBottomSheetRoute<void>(
        capturedThemes: InheritedTheme.capture(
          from: context,
          to: navigator.context,
        ),
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) => ValueListenableBuilder<bool>(
          valueListenable: scopeValid,
          builder: (context, valid, _) {
            if (!valid) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!sheetContext.mounted) return;
                final route = ModalRoute.of(sheetContext);
                if (route != null && route.isActive) {
                  Navigator.of(sheetContext).removeRoute(route);
                }
              });
              return const SizedBox.shrink();
            }
            return _CustomerReorderSheet(
              preview: preview,
              idempotencyKey: idempotencyKey,
              scopeValid: scopeValid,
              onDefinitiveResult: () => _attempt.complete(idempotencyKey),
            );
          },
        ),
      );
      await Future.any([navigator.push(route), route.completed]);
    } on Object {
      if (!mounted || !scopeValid.value) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).ordersReorderFailure),
        ),
      );
    } finally {
      identitySubscription.close();
      authSubscription?.close();
      shopSubscription.close();
      scopeValid.dispose();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: FilledButton.icon(
          key: const ValueKey('customer-order-reorder'),
          onPressed: _isLoading ? null : _open,
          icon: _isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.replay_outlined),
          label: Text(l10n.ordersReorderAction),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSizes.minimumTouchTarget),
          ),
        ),
      ),
    );
  }
}

final class _CustomerReorderSheet extends ConsumerStatefulWidget {
  const _CustomerReorderSheet({
    required this.preview,
    required this.idempotencyKey,
    required this.scopeValid,
    required this.onDefinitiveResult,
  });

  final CustomerReorderPreview preview;
  final String idempotencyKey;
  final ValueNotifier<bool> scopeValid;
  final VoidCallback onDefinitiveResult;

  @override
  ConsumerState<_CustomerReorderSheet> createState() =>
      _CustomerReorderSheetState();
}

final class _CustomerReorderSheetState
    extends ConsumerState<_CustomerReorderSheet> {
  CustomerReorderResult? _result;
  var _isApplying = false;

  Future<void> _apply() async {
    if (_isApplying || !widget.scopeValid.value) return;
    setState(() => _isApplying = true);
    try {
      final result = await ref
          .read(customerOrderRepositoryProvider)
          .applyReorder(
            orderId: widget.preview.orderId,
            idempotencyKey: widget.idempotencyKey,
          );
      if (!mounted || !widget.scopeValid.value) return;
      widget.onDefinitiveResult();
      setState(() => _result = result);
      await ref.read(cartControllerProvider.notifier).refresh();
    } on Object {
      if (!mounted || !widget.scopeValid.value) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).ordersReorderFailure),
        ),
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formatter = ClpCurrencyFormatter();
    final result = _result;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.ordersReorderTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: result == null
                  ? widget.preview.items
                        .map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.name),
                            subtitle: Text(
                              item.availability ==
                                      CustomerReorderAvailability.unavailable
                                  ? l10n.ordersReorderUnavailable
                                  : '${l10n.ordersReorderCurrentPrice}: '
                                        '${formatter.format(item.currentPriceClp)}\n'
                                        '${l10n.ordersReorderHistoricalPrice}: '
                                        '${formatter.format(item.historicalPriceClp)}',
                            ),
                            trailing: Text('×${item.allowedQuantity}'),
                          ),
                        )
                        .toList(growable: false)
                  : [
                      _ReorderResultGroup(
                        title: l10n.ordersReorderResultAdded,
                        lines: result.added,
                      ),
                      _ReorderResultGroup(
                        title: l10n.ordersReorderResultSkipped,
                        lines: result.skipped,
                      ),
                    ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (result == null)
            FilledButton(
              key: const ValueKey('customer-order-reorder-apply'),
              onPressed:
                  _isApplying ||
                      !widget.preview.items.any(
                        (item) =>
                            item.availability ==
                            CustomerReorderAvailability.available,
                      )
                  ? null
                  : _apply,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSizes.minimumTouchTarget),
              ),
              child: Text(
                _isApplying
                    ? l10n.ordersReorderApplying
                    : l10n.ordersReorderApply,
              ),
            )
          else
            FilledButton(
              key: const ValueKey('customer-order-reorder-open-cart'),
              onPressed: () {
                if (!widget.scopeValid.value) return;
                Navigator.of(context).pop();
                context.go(AppRoutes.cartLocation);
              },
              child: Text(l10n.ordersReorderOpenCart),
            ),
        ],
      ),
    );
  }
}

final class _ReorderResultGroup extends StatelessWidget {
  const _ReorderResultGroup({required this.title, required this.lines});

  final String title;
  final List<CustomerReorderAppliedLine> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          ...lines.map(
            (line) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(line.name),
              trailing: line.quantity == null
                  ? null
                  : Text('×${line.quantity}'),
            ),
          ),
        ],
      ),
    );
  }
}
