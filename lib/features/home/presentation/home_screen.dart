import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_content_frame.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../today/presentation/today_controller.dart';
import '../../today/presentation/widgets/break_schedule_list.dart';
import 'widgets/community_card.dart';
import 'widgets/home_header.dart';
import 'widgets/intention_card.dart';
import 'widgets/progress_hero_card.dart';
import 'widgets/reflection_card.dart';

/// Landing screen: today's progress, next break, PRAY NOW and the daily
/// intention/reflection/community cards.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TodayController? _controller;
  bool _wired = false;

  Future<void> _openDecade(int decadeNumber, TodayController c) async {
    if (decadeNumber <= 0) return;
    await context.push(AppRoutes.decadeFor(decadeNumber));
    // Refresh progress in case the decade was completed while praying.
    await c.load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    _controller ??= TodayController(deps);
    if (!_wired) {
      _wired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller!.load());
    }

    return ListenableBuilder(
      listenable: _controller!,
      builder: (context, _) {
        final c = _controller!;

        if (c.isLoading) return const AppLoadingView(message: 'Preparing your Rosary…');
        if (c.error != null) {
          return AppErrorView(message: c.error!, onRetry: () {
            _wired = false;
            setState(() => _controller!.load());
          });
        }

        final today = c.now;
        return SafeArea(
          child: AppContentFrame(
            child: RefreshIndicator(
              onRefresh: _controller!.load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    HomeHeader(today: today),
                    const SizedBox(height: AppSpacing.xl),

                    ProgressHeroCard(
                      completedCount: c.completedCount,
                      nextBreak: c.nextBreak,
                      content: c.content,
                      onPrayNow: () => _openDecade(c.nextDecadeNumber, c),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    _EmptyTodayWarning(show: c.content == null),
                    if (c.content != null) ...<Widget>[
                      IntentionCard(intention: c.content!.intention),
                      const SizedBox(height: AppSpacing.lg),
                      if (c.content!.reflection != null) ...<Widget>[
                        ReflectionCard(reflection: c.content!.reflection),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ],

                    CommunityCard(stats: c.stats),
                    const SizedBox(height: AppSpacing.xxl),

                    const AppSectionHeader(
                      overline: 'College day',
                      title: 'Your five breaks',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (c.schedule != null)
                      BreakScheduleList(
                        slots: c.schedule!.slots,
                        now: c.now,
                        onOpen: (n) => _openDecade(n, c),
                      ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shown only when today's content is not published yet (e.g. Firebase has no
/// document for today).
class _EmptyTodayWarning extends StatelessWidget {
  const _EmptyTodayWarning({required this.show});

  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: const AppCard(
        color: Color(0xFFFFF8E6),
        child: Text(
          'Today\'s content has not been published yet. Schedule and '
          'participation still work.',
          style: TextStyle(color: Color(0xFF8A6D1F)),
        ),
      ),
    );
  }
}