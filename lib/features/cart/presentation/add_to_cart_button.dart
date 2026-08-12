import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../storefront/domain/storefront_models.dart';
import '../application/cart_controller.dart';
import '../domain/cart_failure.dart';
import 'cart_messages.dart';

class AddToCartButton extends ConsumerWidget {
  const AddToCartButton({
    required this.product,
    this.expanded = false,
    super.key,
  });

  final StorefrontProductSummary product;
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cart = ref.watch(cartControllerProvider);
    final busy = cart.busyPublicationIds.contains(product.id);
    final unavailable =
        product.availability == StorefrontAvailability.unavailable;
    final button = FilledButton.icon(
      key: ValueKey('add-to-cart-${product.id}'),
      onPressed: unavailable || busy ? null : () => _add(context, ref, l10n),
      icon: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_shopping_cart_outlined),
      label: Text(l10n.cartAddAction),
      style: FilledButton.styleFrom(
        minimumSize: Size(
          expanded ? double.infinity : AppSizes.minimumTouchTarget,
          AppSizes.minimumTouchTarget,
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: !unavailable && !busy,
      label: '${l10n.cartAddAction}: ${product.name}',
      onTap: unavailable || busy ? null : () => _add(context, ref, l10n),
      excludeSemantics: true,
      child: expanded
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    try {
      await ref.read(cartControllerProvider.notifier).addProduct(product);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.cartAddedNotice)));
      ref.read(cartControllerProvider.notifier).clearNotice();
    } on CartRepositoryException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(cartFailureMessage(l10n, error.kind))),
        );
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.cartUnavailableError)));
    }
  }
}
