import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Five dots mapping to the five decades.
///
/// Completed → gold, active/next → Marian blue, remaining → muted outline.
class DecadeDots extends StatelessWidget {
  const DecadeDots({
    super.key,
    required this.completedCount,
    this.nextDecade,
    this.size = 18,
  });

  final int completedCount;
  final int? nextDecade;
  final double size;

  @override
  Widget build(BuildContext context) {
    final count = completedCount.clamp(0, 5);
    return Semantics(
      label: '$count of 5 decades completed',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var i = 1; i <= 5; i++) ...<Widget>[
            if (i > 1) const SizedBox(width: 8),
            _Dot(
              size: size,
              color: i <= count
                  ? AppColors.dotCompleted
                  : i == nextDecade
                  ? AppColors.dotActive
                  : AppColors.dotUpcoming,
              filled: i <= count || i == nextDecade,
            ),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color, required this.filled});

  final double size;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : Colors.transparent,
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}