import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_content_frame.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../domain/models/decade.dart';
import 'decade_controller.dart';
import 'prayer_flow_view.dart';

/// The guided experience for one decade (the "Today's Decade" journey).
///
/// Two views live in one route so going "back" from the prayer flow never
/// loses the user's in-progress session:
///   0 → intro (mystery, scripture, intention, reflection, START DECADE)
///   1 → focused prayer flow (Our Father … Fatima … completion)
class DecadeScreen extends StatefulWidget {
  const DecadeScreen({super.key, required this.decadeNumber});

  final int decadeNumber;

  @override
  State<DecadeScreen> createState() => _DecadeScreenState();
}

class _DecadeScreenState extends State<DecadeScreen> {
  DecadeController? _controller;
  bool _wired = false;
  int _view = 0;

  void _toIntro() => setState(() => _view = 0);

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    _controller ??= DecadeController(deps, widget.decadeNumber);
    if (!_wired) {
      _wired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller!.load());
    }

    return PopScope(
      canPop: _view == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _view != 0) _toIntro();
      },
      child: ListenableBuilder(
        listenable: _controller!,
        builder: (context, _) {
          return Scaffold(
            body: SafeArea(
              child: AppContentFrame(
                child: _controller!.isLoading
                    ? const AppLoadingView(message: 'Preparing your decade…')
                    : _controller!.error != null
                    ? AppErrorView(
                        message: _controller!.error!,
                        onRetry: _controller!.load,
                      )
                    : IndexedStack(
                        index: _view,
                        children: <Widget>[
                          _IntroView(
                            controller: _controller!,
                            onStart: () => setState(() => _view = 1),
                          ),
                          PrayerFlowView(
                            decadeNumber: widget.decadeNumber,
                            mysteryTitle: _controller!.decade.mysteryTitle,
                            completedCount: _controller!.completedCount,
                            alreadyCompleted: _controller!.isCompleted,
                            submitError: _controller!.submitError,
                            onMarkPrayed: () => _controller!.completeDecade(),
                            onExit: _toIntro,
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The calm introduction: mystery, scripture, intention, reflection.
class _IntroView extends StatelessWidget {
  const _IntroView({required this.controller, required this.onStart});

  final DecadeController controller;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final decade = c.decade;

    return Column(
      children: <Widget>[
        _BackBar(decadeNumber: c.decadeNumber),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              _MysteryHero(
                decade: decade,
                mysterySet: c.mysterySetTitle,
                breakLabel: c.slotForDecade?.time.label,
              ),
              const SizedBox(height: AppSpacing.lg),

              if (c.intention.trim().isNotEmpty)
                _IntentionBanner(intention: c.intention),
              if (c.intention.trim().isNotEmpty)
                const SizedBox(height: AppSpacing.lg),

              _ReflectionCard(decade: decade),
              const SizedBox(height: AppSpacing.xl),

              Text(
                'Prepare yourself. Take this decade gently — you are not in '
                'a hurry.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),

              AppPrimaryButton(
                label: 'START DECADE',
                icon: Icons.self_improvement,
                onPressed: onStart,
              ),

              if (c.isCompleted) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  color: AppColors.successSoft,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'You prayed this decade today. You can pray it again '
                          'any time.',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackBar extends StatelessWidget {
  const _BackBar({required this.decadeNumber});

  final int decadeNumber;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Go back',
          style: IconButton.styleFrom(minimumSize: const Size.square(48)),
        ),
        Expanded(
          child: Center(
            child: Text(
              '${ordinal(decadeNumber)} DECADE',
              style: context.textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
        const Opacity(opacity: 0, child: SizedBox.square(dimension: 48)),
      ],
    );
  }
}

/// Gradient hero with mystery, scripture and break time.
class _MysteryHero extends StatelessWidget {
  const _MysteryHero({
    required this.decade,
    required this.mysterySet,
    required this.breakLabel,
  });

  final Decade decade;
  final String mysterySet;
  final String? breakLabel;

  @override
  Widget build(BuildContext context) {
    final scripture = decade.scripture;

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
            mysterySet.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              color: const Color(0xFFB9C8EC),
              letterSpacing: 1.4,
            ),
          ),
          if (breakLabel != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Break · $breakLabel',
              style: context.textTheme.labelSmall?.copyWith(
                color: const Color(0xFFDDE6F8),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            decade.mysteryTitle,
            style: context.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              height: 1.25,
            ),
          ),
          if (scripture != null && scripture.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Text(
              scripture,
              style: context.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFFE7EDFB),
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Today's shared prayer intention.
class _IntentionBanner extends StatelessWidget {
  const _IntentionBanner({required this.intention});

  final String intention;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      color: isDark ? const Color(0xFF2A2512) : AppColors.goldSoft.withValues(alpha: 0.55),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.favorite_outline, size: 18, color: AppColors.goldDark),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'TODAY\'S INTENTION',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.goldDark,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(intention, style: context.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The personal reflection for this decade.
class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({required this.decade});

  final Decade decade;

  @override
  Widget build(BuildContext context) {
    final reflection = decade.reflection?.trim();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'REFLECTION',
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.goldDark,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            reflection?.isNotEmpty == true
                ? reflection!
                : 'Take a slow breath. Let this mystery sit with you while you pray.',
            style: context.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}