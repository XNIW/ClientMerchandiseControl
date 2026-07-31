import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/widgets/storefront_empty_state.dart';
import '../../../app/design_system/widgets/storefront_page.dart';
import '../../../app/router/app_router.dart';
import '../../../l10n/generated/app_localizations.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return StorefrontPage(
      child: StorefrontEmptyState(
        icon: Icons.shopping_cart_outlined,
        title: l10n.cartEmptyTitle,
        message: l10n.cartEmptyMessage,
        actionLabel: l10n.cartExploreCatalog,
        actionKey: const ValueKey('cart-explore-catalog'),
        onAction: () => context.go(AppRoutes.catalogLocation),
      ),
    );
  }
}
