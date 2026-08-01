import 'package:flutter/material.dart';

import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';

class StorefrontSearchLauncher extends StatelessWidget {
  const StorefrontSearchLauncher({
    required this.label,
    required this.hint,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String hint;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      hint: hint,
      onTap: onPressed,
      excludeSemantics: true,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.controlHeight),
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          foregroundColor: colorScheme.onSurface,
          backgroundColor: colorScheme.surfaceContainerLow,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            const Icon(Icons.search),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
