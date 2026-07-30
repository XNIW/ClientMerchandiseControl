import 'package:flutter/material.dart';

import '../theme/storefront_semantic_colors.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';

class StorefrontStatusBanner extends StatelessWidget {
  const StorefrontStatusBanner({
    required this.message,
    required this.icon,
    super.key,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final semanticColors = StorefrontSemanticColors.of(context);

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: Material(
          color: semanticColors.informationContainer,
          borderRadius: BorderRadius.circular(AppRadii.surface),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: AppSizes.iconStandard,
                  color: semanticColors.onInformationContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: semanticColors.onInformationContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
