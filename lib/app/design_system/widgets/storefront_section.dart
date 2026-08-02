import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

class StorefrontSection extends StatelessWidget {
  const StorefrontSection({
    required this.title,
    required this.child,
    super.key,
    this.actionLabel,
    this.onAction,
  }) : assert((actionLabel == null) == (onAction == null));

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final heading = Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackHeading =
            constraints.maxWidth < 480 ||
            MediaQuery.textScalerOf(context).scale(1) >= 1.3;
        final action = actionLabel == null
            ? null
            : TextButton(
                onPressed: onAction,
                child: Text(actionLabel!, textAlign: TextAlign.end),
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (stackHeading) ...[
              heading,
              if (action != null) Row(children: [Expanded(child: action)]),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: heading),
                  if (action != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(child: action),
                  ],
                ],
              ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        );
      },
    );
  }
}
