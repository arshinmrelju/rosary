import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'admin_badge_controller.dart';

/// Branded sign-in screen shown at `/admin/login` and by the gate.
class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).adminSession;
    final isFirebase = AppScope.of(context).isUsingFirebase.value;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const AdminSidebarBrand(),
                const SizedBox(height: 8),
                Text(
                  'ADMIN SIGN IN',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.goldDark,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 28),
                if (!isFirebase)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.marianBlueSoft,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      'Demo mode is active — you will be signed in as the '
                      'Super Admin so the dashboard can be previewed without '
                      'Firebase.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (!isFirebase) const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.marianBlue,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  onPressed: session.isBusy
                      ? null
                      : () => _signIn(context, session),
                  icon: session.isBusy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.login, size: 20),
                  label: Text(
                    isFirebase
                        ? 'Continue with Google'
                        : 'Continue as demo Super Admin',
                  ),
                ),
                if (session.error != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    session.error!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn(BuildContext context, dynamic session) async {
    final ok = await session.signInWithGoogle();
    if (!context.mounted) return;
    if (session.signedInButNotAdmin) {
      // The gate's denial page is rendered automatically once the state
      // change reaches it; nothing else to do here.
      return;
    }
    if (ok) {
      final badges = AdminBadgeScope.maybeOf(context);
      badges?.refresh();
      context.go(AppRoutes.adminDashboard);
    }
  }
}