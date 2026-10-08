import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Il riquadro compatto occupa solo parte del display nativo: gli inset devono
/// descrivere l'intersezione con quel riquadro, non l'intero display.
class Task054CompactViewport extends StatelessWidget {
  const Task054CompactViewport({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final parent = MediaQuery.of(context);
      final size = Size(
        math.min(320, constraints.maxWidth),
        math.min(568, constraints.maxHeight),
      );
      final rect = Rect.fromLTWH(
        (constraints.maxWidth - size.width) / 2,
        (constraints.maxHeight - size.height) / 2,
        size.width,
        size.height,
      );
      final insets = _projectEdges(parent.viewInsets, rect, parent.size);
      final viewPadding = _projectEdges(parent.viewPadding, rect, parent.size);
      final padding = EdgeInsets.fromLTRB(
        math.max(0, viewPadding.left - insets.left),
        math.max(0, viewPadding.top - insets.top),
        math.max(0, viewPadding.right - insets.right),
        math.max(0, viewPadding.bottom - insets.bottom),
      );
      return Center(
        child: SizedBox(
          key: const ValueKey('task054-compact-viewport'),
          width: size.width,
          height: size.height,
          child: MediaQuery(
            data: parent.copyWith(
              size: size,
              textScaler: TextScaler.linear(2),
              viewInsets: insets,
              viewPadding: viewPadding,
              padding: padding,
            ),
            child: child,
          ),
        ),
      );
    },
  );
}

EdgeInsets _projectEdges(EdgeInsets edges, Rect rect, Size parent) =>
    EdgeInsets.fromLTRB(
      (edges.left - rect.left).clamp(0.0, rect.width),
      (edges.top - rect.top).clamp(0.0, rect.height),
      (rect.right - (parent.width - edges.right)).clamp(0.0, rect.width),
      (rect.bottom - (parent.height - edges.bottom)).clamp(0.0, rect.height),
    );
