import 'package:flutter/material.dart';

/// Centres content and caps its width so large screens stay readable while
/// phones fill the width. All screens are wrapped in this.
class AppContentFrame extends StatelessWidget {
  const AppContentFrame({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding:
              padding ??
              EdgeInsets.fromLTRB(20, safe.top + 16, 20, safe.bottom + 24),
          child: child,
        ),
      ),
    );
  }
}

/// Responsive grid helper that switches from a single column (mobile) to a
/// two-column layout (tablet/desktop) at the given breakpoint.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.gap = 16,
    this.minColumnWidth = 300,
    this.breakpoint = 600,
  });

  final List<Widget> children;
  final double gap;
  final double minColumnWidth;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < breakpoint) {
      return Column(
        children: <Widget>[
          for (var i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      );
    }

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: <Widget>[
        for (final child in children)
          SizedBox(width: (width / 2) - (gap / 2) - 40, child: child),
      ],
    );
  }
}