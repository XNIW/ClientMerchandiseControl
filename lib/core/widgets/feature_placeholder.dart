import 'package:flutter/material.dart';

import 'responsive_content.dart';

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

    return ResponsiveContent(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: Icon(icon, size: 36)),
              const SizedBox(height: 20),
              Semantics(
                header: true,
                child: Text(title, style: textTheme.headlineSmall),
              ),
              const SizedBox(height: 12),
              Text(message, style: textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
