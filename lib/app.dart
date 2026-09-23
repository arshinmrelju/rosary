import 'package:flutter/material.dart';

import 'core/di/app_scope.dart';
import 'core/router/app_router.dart';
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
        title: 'Rosary Break',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: AppRouter.instance,
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.4,
          child: child!,
        ),
      ),
    );
  }
}