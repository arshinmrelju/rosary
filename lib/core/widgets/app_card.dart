import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A rounded white surface card used across every screen.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.color,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: const Color(0xFFE9EDF4)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A1C3D8A),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      // A transparent Material so inner ink splashes (ListTile, InkWell,
      // FilledButton) paint on top of the card colour instead of being hidden.
      child: Material(type: MaterialType.transparency, child: child),
    );

    if (onTap == null) {
      return margin == null ? card : Padding(padding: margin!, child: card);
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Padding(
        padding: margin ?? EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg),
          child: card,
        ),
      ),
    );
  }
}