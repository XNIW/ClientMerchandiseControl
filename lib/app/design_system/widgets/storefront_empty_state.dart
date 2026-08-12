import 'package:flutter/material.dart';

import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';

class StorefrontEmptyState extends StatelessWidget {
  const StorefrontEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    this.progress = false,
  }) : assert((actionLabel == null) == (onAction == null));

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;
  final bool progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ExcludeSemantics(
                  child: progress
                      ? const SizedBox.square(
                          dimension: AppSizes.iconEmphasis,
                          child: CircularProgressIndicator(
                            strokeWidth: AppSizes.progressIndicatorStroke,
                          ),
                        )
                      : Icon(icon, size: AppSizes.iconEmphasis),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(message, style: Theme.of(context).textTheme.bodyLarge),
              if (actionLabel case final label?) ...[
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton(
                    key: actionKey,
                    onPressed: onAction,
                    child: Text(label),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
