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
    this.compact = false,
    super.key,
  }) : assert((actionLabel == null) == (onAction == null));

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

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
          child: compact
              ? Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        icon,
                        size: AppSizes.iconStandard,
                        color: semanticColors.onInformationContainer,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ExcludeSemantics(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            message,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: semanticColors.onInformationContainer,
                                ),
                          ),
                        ),
                      ),
                    ),
                    if (actionLabel case final label?) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _BannerAction(
                        label: label,
                        onPressed: onAction!,
                        foregroundColor: semanticColors.onInformationContainer,
                        compact: true,
                      ),
                    ],
                  ],
                )
              : Column(
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
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color:
                                        semanticColors.onInformationContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (actionLabel case final label?)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _BannerAction(
                          label: label,
                          onPressed: onAction!,
                          foregroundColor:
                              semanticColors.onInformationContainer,
                          compact: false,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BannerAction extends StatelessWidget {
  const _BannerAction({
    required this.label,
    required this.onPressed,
    required this.foregroundColor,
    required this.compact,
  });

  final String label;
  final VoidCallback onPressed;
  final Color foregroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: compact
            ? IconButton(
                key: const ValueKey('storefront-status-action'),
                onPressed: onPressed,
                color: foregroundColor,
                tooltip: label,
                icon: const Icon(Icons.refresh),
              )
            : TextButton(
                key: const ValueKey('storefront-status-action'),
                onPressed: onPressed,
                style: TextButton.styleFrom(foregroundColor: foregroundColor),
                child: Text(label),
              ),
      ),
    );
  }
}
