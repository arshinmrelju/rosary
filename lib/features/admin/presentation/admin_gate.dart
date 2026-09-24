import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import 'admin_login_screen.dart';

/// Decides what an `/admin/*` visitor sees.
///
/// * Not a signed-in admin  → sign-in screen.
/// * Signed in via Google but no `admins/{uid}` doc → a denial page.
/// * Signed-in admin        → the admin dashboard (the child).
class AdminGate extends StatefulWidget {
  const AdminGate({super.key, required this.child});

  final Widget child;

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  @override
  void initState() {
    super.initState();
    final session = AppScope.of(context).adminSession;
    if (!session.isInitialized && !session.isBusy) {
      // Restore before the router paints the dashboard so the first frame
      // already knows the admin's identity.
      Future.microtask(session.restore);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).adminSession;

    if (!session.isInitialized || session.isBusy) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (session.isAdmin) return widget.child;

    if (session.signedInButNotAdmin) {
      return const _NotAdminScreen();
    }

    return const AdminLoginScreen();
  }
}

class _NotAdminScreen extends StatelessWidget {
  const _NotAdminScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.verified_user_outlined,
                    size: 56, color: Color(0xFF8A93A6)),
                const SizedBox(height: 20),
                Text(
                  'Not an administrator',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You are signed in, but this Google account does not hold a '
                  'role on this project. Contact a Super Admin if you expected '
                  'access.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final session = AppScope.of(context).adminSession;
                    await session.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Switch account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}