import 'package:flutter/material.dart';

/// Responsive grid helper: single column on phones, evenly spaced columns on
/// wider screens. Used together with [AppContentFrame].
class AppGrid extends StatelessWidget {
  const AppGrid({
    super.key,
    required this.children,
    this.columns = 2,
    this.gap = 16,
  });

  final List<Widget> children;
  final int columns;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth < 600 ? 1 : columns;
        final tileWidth =
            (constraints.maxWidth - (gap * (columnCount - 1))) / columnCount;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}