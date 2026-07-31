import 'package:flutter/material.dart';

import '../theme/storefront_semantic_colors.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';

class StorefrontStatusBanner extends StatelessWidget {
  const StorefrontStatusBanner({
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert((actionLabel == null) == (onAction == null));

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final semanticColors = StorefrontSemanticColors.of(context);

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      explicitChildNodes: true,
      child: Material(
        color: semanticColors.informationContainer,
        borderRadius: BorderRadius.circular(AppRadii.surface),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
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
              if (actionLabel case final label?)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Semantics(
                    button: true,
                    label: label,
                    child: TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        foregroundColor: semanticColors.onInformationContainer,
                      ),
                      child: Text(label),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
