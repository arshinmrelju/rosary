import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_content_frame.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../today/presentation/today_controller.dart';

/// Today's Reflection — the day's mystery, scripture, reflection and shared
/// intention in one calm, readable screen.
class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  TodayController? _controller;
  bool _wired = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openDecade(int decadeNumber) async {
    await context.push(AppRoutes.decadeFor(decadeNumber));
    await _controller?.load();
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

        if (c.isLoading) {
          return const AppLoadingView(message: 'Preparing today\'s reflection…');
        }
        if (c.error != null) {
          return AppErrorView(message: c.error!, onRetry: c.load);
        }

        final content = c.content;
        if (content == null) {
          return SafeArea(
            child: AppContentFrame(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  Text(
                    "Today's Reflection",
                    style: context.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    friendlyMonthDay(c.now),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const AppEmptyView(
                    icon: Icons.auto_stories_outlined,
                    message:
                        'Today\'s content hasn\'t been published yet.\n\n'
                        'Please check again soon.',
                  ),
                ],
              ),
            ),
          );
        }

        String? scripture;
        final topScripture = content.scripture?.trim();
        final firstDecadeScripture = content.decades.isEmpty
            ? null
            : content.decades.first.scripture?.trim();
        if (topScripture != null && topScripture.isNotEmpty) {
          scripture = topScripture;
        } else if (firstDecadeScripture != null &&
            firstDecadeScripture.isNotEmpty) {
          scripture = firstDecadeScripture;
        }
        final reflection = content.reflection?.trim().isNotEmpty == true
            ? content.reflection!
            : 'Take a quiet moment today. Even one decade, prayed with your '
                  'whole heart, is a gift to the world.';
        final nextDecade = c.nextDecadeNumber > 0 ? c.nextDecadeNumber : 1;

        return SafeArea(
          child: AppContentFrame(
            child: RefreshIndicator(
              onRefresh: c.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  Text(
                    "Today's Reflection",
                    style: context.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    friendlyMonthDay(c.now),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _MysteryHeader(
                    mystery: content.mysterySetTitle,
                    theme: content.theme,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (scripture != null) ...<Widget>[
                    AppCard(
                      color: AppColors.marianBlueSoft.withValues(alpha: 0.5),
                      child: Text(
                        scripture,
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                          color: AppColors.marianBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  _Section(title: 'Reflection', child: Text(
                    reflection,
                    style: context.textTheme.bodyLarge?.copyWith(height: 1.65),
                  )),
                  const SizedBox(height: AppSpacing.lg),

                  AppCard(
                    color: const Color(0xFFFAF3DE),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('🙏', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "Today's Intention",
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: AppColors.goldDark,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                content.intention,
                                style: context.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  AppPrimaryButton(
                    label: "PRAY TODAY'S DECADE",
                    icon: Icons.self_improvement,
                    onPressed: () => _openDecade(nextDecade),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MysteryHeader extends StatelessWidget {
  const _MysteryHeader({required this.mystery, this.theme});

  final String mystery;
  final String? theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'MYSTERY',
            style: context.textTheme.labelSmall?.copyWith(
              color: const Color(0xFFB9C8EC),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            mystery,
            style: context.textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          if (theme != null && theme!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              theme!,
              style: context.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFDDE6F8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.goldDark,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}