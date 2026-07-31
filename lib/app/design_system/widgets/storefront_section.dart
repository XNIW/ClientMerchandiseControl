import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

class StorefrontSection extends StatelessWidget {
  const StorefrontSection({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}
