import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder.dart';
import '../../../l10n/generated/app_localizations.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FeaturePlaceholder(
      icon: Icons.shopping_bag_outlined,
      title: l10n.cartTitle,
      message: l10n.cartFoundationMessage,
    );
  }
}
