import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_content_frame.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../domain/prayers/rosary_texts.dart';
import 'decade_controller.dart';

/// The guided prayer screen for one decade (the "Today's Decade" experience).
class DecadeScreen extends StatefulWidget {
  const DecadeScreen({super.key, required this.decadeNumber});

  final int decadeNumber;

  @override
  State<DecadeScreen> createState() => _DecadeScreenState();
}

class _DecadeScreenState extends State<DecadeScreen> {
  DecadeController? _controller;
  bool _wired = false;

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

    return ListenableBuilder(
      listenable: _controller!,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('${ordinal(widget.decadeNumber)} Decade'),
            leading: BackButton(
              onPressed: () {
                Navigator.of(context).maybePop();
              },
            ),
          ),
          body: _buildBody(context),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final c = _controller!;
    if (c.isLoading) return const AppLoadingView(message: 'Preparing your decade…');
    if (c.error != null) {
      return AppErrorView(message: c.error!, onRetry: c.load);
    }

    return AppContentFrame(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          _MysteryHeader(
            decadeNumber: widget.decadeNumber,
            mysteryTitle: c.decade.mysteryTitle,
            mysterySet: c.content?.mysterySetTitle,
            breakLabel: c.slotForDecade?.time.label,
          ),
          const SizedBox(height: AppSpacing.lg),

          if (c.content != null && c.content!.intention.trim().isNotEmpty)
            _IntentionBanner(intention: c.content!.intention),
          if (c.content!.intention.trim().isNotEmpty)
            const SizedBox(height: AppSpacing.lg),

          _PrayerSteps(decadeNumber: widget.decadeNumber),
          const SizedBox(height: AppSpacing.xl),

          _CompleteSection(
            isCompleted: c.isCompleted,
            isSubmitting: c.isSubmitting,
            error: c.submitError,
            onComplete: () async {
              await c.completeDecade();
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _MysteryHeader extends StatelessWidget {
  const _MysteryHeader({
    required this.decadeNumber,
    required this.mysteryTitle,
    required this.mysterySet,
    required this.breakLabel,
  });

  final int decadeNumber;
  final String mysteryTitle;
  final String? mysterySet;
  final String? breakLabel;

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
            (mysterySet ?? 'Rosary Mysteries').toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              color: const Color(0xFFB9C8EC),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            mysteryTitle,
            style: context.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              const Icon(
                Icons.schedule,
                size: 16,
                color: Color(0xFFDDE6F8),
              ),
              const SizedBox(width: 6),
              Text(
                breakLabel == null
                    ? 'Decade $decadeNumber of 5'
                    : 'Break $decadeNumber · $breakLabel',
                style: context.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFFDDE6F8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntentionBanner extends StatelessWidget {
  const _IntentionBanner({required this.intention});

  final String intention;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.goldSoft.withValues(alpha: 0.55),
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

/// The guided prayer sequence with an interactive 10-bead counter.
class _PrayerSteps extends StatefulWidget {
  const _PrayerSteps({required this.decadeNumber});

  final int decadeNumber;

  @override
  State<_PrayerSteps> createState() => _PrayerStepsState();
}

class _PrayerStepsState extends State<_PrayerSteps> {
  int _beadsDone = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const _StepCard(
          title: 'Sign of the Cross',
          subtitle: 'Begin',
          text: RosaryTexts.signOfTheCross,
        ),
        const SizedBox(height: AppSpacing.md),
        const _StepCard(
          title: 'Our Father',
          subtitle: 'First bead',
          text: RosaryTexts.ourFather,
        ),
        const SizedBox(height: AppSpacing.md),
        _DecadeBeads(
          beadsDone: _beadsDone,
          onTap: () => setState(() => _beadsDone = (_beadsDone + 1) % 11),
        ),
        const SizedBox(height: AppSpacing.md),
        const _StepCard(
          title: 'Glory Be',
          subtitle: 'Between decades',
          text: RosaryTexts.gloryBe,
        ),
        const SizedBox(height: AppSpacing.md),
        const _StepCard(
          title: 'O My Jesus',
          subtitle: 'End of the decade',
          text: RosaryTexts.fatimaPrayer,
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.text,
  });

  final String title;
  final String subtitle;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(title, style: context.textTheme.titleMedium),
              ),
              Text(
                subtitle.toUpperCase(),
                style: context.textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            text,
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecadeBeads extends StatelessWidget {
  const _DecadeBeads({required this.beadsDone, required this.onTap});

  final int beadsDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text('Hail Mary ×10', style: context.textTheme.titleMedium),
              ),
              Text(
                '$beadsDone / 10',
                style: context.textTheme.titleSmall?.copyWith(
                  color: AppColors.marianBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: 'Tap to count a Hail Mary. $beadsDone of 10 counted.',
            button: true,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (var i = 1; i <= 10; i++)
                  GestureDetector(
                    onTap: onTap,
                    child: _Bead(counted: i <= beadsDone),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            RosaryTexts.hailMary10,
            style: context.textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _Bead extends StatelessWidget {
  const _Bead({required this.counted});

  final bool counted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: counted ? AppColors.marianBlue : AppColors.surface,
        border: Border.all(
          color: counted ? AppColors.marianBlue : const Color(0xFFD4DAE6),
          width: 2,
        ),
      ),
      child: counted
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _CompleteSection extends StatelessWidget {
  const _CompleteSection({
    required this.isCompleted,
    required this.isSubmitting,
    required this.error,
    required this.onComplete,
  });

  final bool isCompleted;
  final bool isSubmitting;
  final String? error;
  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return AppCard(
        color: AppColors.successSoft,
        child: Row(
          children: <Widget>[
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Decade completed. One more step of your Rosary.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text(
          error!,
          style: context.textTheme.bodyMedium?.copyWith(color: AppColors.error),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: isSubmitting ? null : () => onComplete(),
      icon: const Icon(Icons.task_alt, size: 20),
      label: Text(
        isSubmitting ? 'Saving…' : 'I prayed this decade',
      ),
    );
  }
}