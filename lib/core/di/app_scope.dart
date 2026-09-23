import 'package:flutter/widgets.dart';

import '../../data/dependencies.dart';

/// Exposes [AppDependencies] to the whole widget tree.
///
/// Access via `AppScope.of(context)`. Keeps screens decoupled from services
/// while avoiding a full DI package.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.dependencies, required super.child});

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing from the widget tree.');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}