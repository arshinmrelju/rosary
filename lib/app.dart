import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/di/app_scope.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/dependencies.dart';

/// Root widget: wires the app scope and router.
class RosaryBreakApp extends StatelessWidget {
  const RosaryBreakApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: dependencies,
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.instance,
        builder: (context, child) => _NotificationTapHandler(
          dependencies: dependencies,
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: 0.9,
            maxScaleFactor: 1.4,
            child: child!,
          ),
        ),
      ),
    );
  }
}

/// Responds to a reminder being tapped (including on cold start) by opening
/// the decade it pointed to. Uses the single router, so navigation works the
/// same whether the app was already open or launched from the lock screen.
class _NotificationTapHandler extends StatefulWidget {
  const _NotificationTapHandler({
    required this.dependencies,
    required this.child,
  });

  final AppDependencies dependencies;
  final Widget child;

  @override
  State<_NotificationTapHandler> createState() => _NotificationTapHandlerState();
}

class _NotificationTapHandlerState extends State<_NotificationTapHandler> {
  @override
  void initState() {
    super.initState();
    widget.dependencies.notificationService.pendingDecade
        .addListener(_onPending);
    // A cold-start launch can set the pending decade during `initialize()`,
    // before this listener existed — pick it up now if so.
    if (widget.dependencies.notificationService.pendingDecade.value != null) {
      _onPending();
    }
  }

  @override
  void didUpdateWidget(covariant _NotificationTapHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dependencies != widget.dependencies) {
      oldWidget.dependencies.notificationService.pendingDecade
          .removeListener(_onPending);
      widget.dependencies.notificationService.pendingDecade.addListener(_onPending);
    }
  }

  void _onPending() {
    final decade =
        widget.dependencies.notificationService.consumePendingDecade();
    if (decade == null) return;
    // A short delay lets the router settle after a cold start.
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      AppRouter.instance.push(AppRoutes.decadeFor(decade));
    });
  }

  @override
  void dispose() {
    widget.dependencies.notificationService.pendingDecade
        .removeListener(_onPending);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}