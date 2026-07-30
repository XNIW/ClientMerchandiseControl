import 'package:flutter/material.dart';

import '../../app/design_system/tokens/app_sizes.dart';
import '../../app/design_system/tokens/app_spacing.dart';
import '../../app/design_system/widgets/storefront_page.dart';

class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return StorefrontPage(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: Icon(icon, size: AppSizes.iconEmphasis)),
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                header: true,
                child: Text(title, style: textTheme.headlineSmall),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(message, style: textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
