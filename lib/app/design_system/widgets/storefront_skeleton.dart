import 'package:flutter/material.dart';

import '../tokens/app_radii.dart';
import '../tokens/app_spacing.dart';

class StorefrontSkeleton extends StatelessWidget {
  const StorefrontSkeleton({required this.semanticLabel, super.key});

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Column(
          key: const ValueKey('storefront-skeleton'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SkeletonBlock(height: 64, color: color),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                for (var index = 0; index < 3; index++) ...[
                  if (index > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _SkeletonBlock(height: 40, color: color)),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _SkeletonBlock(height: 20, widthFactor: 0.42, color: color),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < 2; index++) ...[
                  if (index > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SkeletonBlock(height: 132, color: color),
                        const SizedBox(height: AppSpacing.sm),
                        _SkeletonBlock(height: 18, color: color),
                        const SizedBox(height: AppSpacing.xs),
                        _SkeletonBlock(
                          height: 18,
                          widthFactor: 0.64,
                          color: color,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.height,
    required this.color,
    this.widthFactor = 1,
  });

  final double height;
  final Color color;
  final double widthFactor;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    alignment: AlignmentDirectional.centerStart,
    widthFactor: widthFactor,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.surface),
      ),
      child: SizedBox(height: height),
    ),
  );
}
