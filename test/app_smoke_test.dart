import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rosary_break/app.dart';
import 'package:rosary_break/data/dependencies.dart';
import 'package:rosary_break/features/home/presentation/widgets/break_smart_card.dart';

void main() {
  testWidgets('Home screen renders in mock mode', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final deps = await AppDependencies.create();
    await tester.pumpWidget(RosaryBreakApp(dependencies: deps));
    // Let the post-frame load complete and rebuild.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(BreakSmartCard), findsOneWidget);
    expect(find.text("TODAY'S MYSTERY"), findsOneWidget);
    expect(find.textContaining('/ 5 Decades'), findsOneWidget);

    // Unmount to dispose controllers and their timers.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('bottom navigation switches to Today', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final deps = await AppDependencies.create();
    await tester.pumpWidget(RosaryBreakApp(dependencies: deps));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(find.text('Your five breaks'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}