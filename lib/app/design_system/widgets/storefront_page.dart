import 'package:flutter/material.dart';

import '../tokens/app_breakpoints.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacing.dart';

class StorefrontPage extends StatelessWidget {
  const StorefrontPage({
    required this.child,
    super.key,
    this.maxWidth = AppSizes.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  static const scrollViewKey = ValueKey<String>('storefront-page-scroll');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= AppBreakpoints.wide
            ? AppSpacing.xxl
            : AppSpacing.lg;

        return SingleChildScrollView(
          key: scrollViewKey,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: AppSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        );
      },
    );
  }
}
