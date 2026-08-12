import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/tokens/app_sizes.dart';
import '../../../app/design_system/tokens/app_spacing.dart';
import '../../../app/router/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';

class CustomerOrdersAccountEntry extends StatelessWidget {
  const CustomerOrdersAccountEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Card.outlined(
        key: const ValueKey('customer-orders-account-entry'),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          label:
              '${l10n.ordersAccountTitle}. '
              '${l10n.ordersAccountDescription}',
          excludeSemantics: true,
          child: InkWell(
            onTap: () => context.push(AppRoutes.ordersLocation),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 32),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.ordersAccountTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.ordersAccountDescription,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const SizedBox.square(
                    dimension: AppSizes.minimumTouchTarget,
                    child: Icon(Icons.chevron_right),
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
