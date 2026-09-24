import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Small friendly strip shown while the device has no connectivity.
///
/// Copy is deliberately encouraging: the Rosary experience keeps working and
/// progress syncs later. Reads its own state via [offline], so it stays a pure
/// widget (the controller decides when to show it).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.offline = true});

  final bool offline;

  @override
  Widget build(BuildContext context) {
    if (!offline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1D6),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: const Color(0xFFF0D9A8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.wifi_off_outlined, size: 18, color: Color(0xFF8A6D1F)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "You're offline.",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF6B5418),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your prayer experience still works. Progress will sync when '
                  'you\'re connected.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF7A6223),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}