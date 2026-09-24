import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../domain/prayers/rosary_texts.dart';

/// The focused, high-readability prayer experience for one decade.
///
/// Flow: Our Father → 10 Hail Marys → Glory Be → Fatima Prayer → Complete.
/// An optional timer sits quietly at the top — it never blocks progress.
/// Completion is always an explicit "MARK AS PRAYED" action.
class PrayerFlowView extends StatefulWidget {
  const PrayerFlowView({
    super.key,
    required this.decadeNumber,
    required this.mysteryTitle,
    required this.completedCount,
    required this.alreadyCompleted,
    required this.onMarkPrayed,
    required this.onExit,
    this.submitError,
  });

  final int decadeNumber;
  final String mysteryTitle;
  final int completedCount;
  final bool alreadyCompleted;
  final Future<bool> Function() onMarkPrayed;
  final VoidCallback onExit;
  final String? submitError;

  @override
  State<PrayerFlowView> createState() => _PrayerFlowViewState();
}

enum _PrayerStep { ourFather, hailMary, gloryBe, fatima, complete }

class _PrayerFlowViewState extends State<PrayerFlowView> {
  _PrayerStep _step = _PrayerStep.ourFather;

  /// Beads counted so far (0 … 10). Reaching 10 advances to Glory Be.
  int _hailCount = 0;

  bool _marked = false;
  bool _saving = false;

  String get _stepLabel => switch (_step) {
    _PrayerStep.ourFather => 'OUR FATHER',
    _PrayerStep.hailMary => 'HAIL MARY',
    _PrayerStep.gloryBe => 'GLORY BE',
    _PrayerStep.fatima => 'FATIMA PRAYER',
    _PrayerStep.complete => 'DECADE COMPLETE',
  };

  void _next() {
    setState(() {
      switch (_step) {
        case _PrayerStep.ourFather:
          _step = _PrayerStep.hailMary;
        case _PrayerStep.hailMary:
          if (_hailCount < 10) _hailCount++;
          if (_hailCount >= 10) _step = _PrayerStep.gloryBe;
        case _PrayerStep.gloryBe:
          _step = _PrayerStep.fatima;
        case _PrayerStep.fatima:
          _step = _PrayerStep.complete;
        case _PrayerStep.complete:
          break;
      }
    });
  }

  void _goBack() {
    setState(() {
      switch (_step) {
        case _PrayerStep.ourFather:
          // Leave the flow back to the intro.
          widget.onExit();
        case _PrayerStep.hailMary:
          _step = _PrayerStep.ourFather;
        case _PrayerStep.gloryBe:
          _step = _PrayerStep.hailMary;
          _hailCount = 10;
        case _PrayerStep.fatima:
          _step = _PrayerStep.gloryBe;
        case _PrayerStep.complete:
          _step = _PrayerStep.fatima;
      }
    });
  }

  void _tapBead(int index) {
    setState(() {
      _hailCount = index + 1;
      if (_hailCount >= 10) _step = _PrayerStep.gloryBe;
    });
  }

  Future<void> _markPrayed() async {
    if (_saving || widget.alreadyCompleted || _marked) return;
    setState(() => _saving = true);
    final ok = await widget.onMarkPrayed();
    if (mounted) {
      setState(() {
        _saving = false;
        _marked = ok;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _FlowHeader(
          stepLabel: _stepLabel,
          onBack: _step == _PrayerStep.complete ? widget.onExit : _goBack,
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: _step == _PrayerStep.complete
              ? _CompletionView(
                  decadeNumber: widget.decadeNumber,
                  completedCount: widget.completedCount,
                  alreadyCompleted: widget.alreadyCompleted || _marked,
                  saving: _saving,
                  error: widget.submitError,
                  onMarkPrayed: _markPrayed,
                  onDone: widget.onExit,
                )
              : _stepBody(context),
        ),
      ],
    );
  }

  Widget _stepBody(BuildContext context) {
    final primaryAction = AppPrimaryButton(
      label: switch (_step) {
        _PrayerStep.ourFather => 'NEXT',
        _PrayerStep.hailMary => _hailCount >= 9 ? 'TENTH HAIL MARY' : 'NEXT HAIL MARY',
        _PrayerStep.gloryBe => 'NEXT',
        _PrayerStep.fatima => 'FINISH PRAYER',
        _PrayerStep.complete => 'CONTINUE',
      },
      icon: switch (_step) {
        _PrayerStep.fatima => Icons.check,
        _ => null,
      },
      onPressed: _next,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: <Widget>[
        _PrayerTimer(),
        const SizedBox(height: AppSpacing.lg),
        switch (_step) {
          _PrayerStep.ourFather => const _PrayerTextCard(
            title: 'Our Father',
            text: RosaryTexts.ourFather,
            subtitle: 'Begin the decade',
          ),
          _PrayerStep.hailMary => _HailMaryView(
            count: _hailCount,
            mysteryTitle: widget.mysteryTitle,
            onTapBead: _tapBead,
          ),
          _PrayerStep.gloryBe => const _PrayerTextCard(
            title: 'Glory Be',
            text: RosaryTexts.gloryBe,
            subtitle: 'Praise the Trinity',
          ),
          _PrayerStep.fatima => const _PrayerTextCard(
            title: 'O My Jesus',
            text: RosaryTexts.fatimaPrayer,
            subtitle: 'Fatima prayer — close the decade',
          ),
          _PrayerStep.complete => const SizedBox.shrink(),
        },
        const SizedBox(height: AppSpacing.xl),
        primaryAction,
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton.icon(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Previous'),
          ),
        ),
      ],
    );
  }
}

/// Minimal bar: back + current step name.
class _FlowHeader extends StatelessWidget {
  const _FlowHeader({required this.stepLabel, required this.onBack});

  final String stepLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Go back',
          style: IconButton.styleFrom(
            minimumSize: const Size.square(48),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              stepLabel,
              style: context.textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
        /// Balance the row so the label stays centred.
        const Opacity(opacity: 0, child: SizedBox.square(dimension: 48)),
      ],
    );
  }
}

/// Quiet, optional timer. A guide only — the user can ignore it entirely.
class _PrayerTimer extends StatefulWidget {
  const _PrayerTimer();

  @override
  State<_PrayerTimer> createState() => _PrayerTimerState();
}

class _PrayerTimerState extends State<_PrayerTimer> {
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;
  bool _running = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _label {
    final elapsed = _watch.elapsed;
    final minutes = elapsed.inMinutes;
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _start() {
    if (!_watch.isRunning) _watch.start();
    setState(() => _running = true);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _pause() {
    _watch.stop();
    _ticker?.cancel();
    if (mounted) setState(() => _running = false);
  }

  void _reset() {
    _watch
      ..stop()
      ..reset();
    _ticker?.cancel();
    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      child: Row(
        children: <Widget>[
          Icon(
            _watch.elapsed.inSeconds > 0
                ? Icons.timer_outlined
                : Icons.timer_off_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$_label   ·   a quiet guide, no rush',
            style: context.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _running ? _pause : _start,
            icon: Icon(_running ? Icons.pause : Icons.play_arrow, size: 22),
            tooltip: _running ? 'Pause timer' : 'Start timer',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.replay, size: 20),
            tooltip: 'Reset timer',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Large, readable prayer text — the primary visual focus.
class _PrayerTextCard extends StatelessWidget {
  const _PrayerTextCard({
    required this.title,
    required this.text,
    required this.subtitle,
  });

  final String title;
  final String text;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            title,
            style: context.textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            text,
            style: context.textTheme.bodyLarge?.copyWith(
              fontSize: 17,
              height: 1.7,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Ten large tappable beads with "Hail Mary n / 10" progress.
class _HailMaryView extends StatelessWidget {
  const _HailMaryView({
    required this.count,
    required this.mysteryTitle,
    required this.onTapBead,
  });

  final int count;
  final String mysteryTitle;
  final ValueChanged<int> onTapBead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: <Widget>[
          Text(
            'Hail Mary',
            style: context.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mysteryTitle,
            style: context.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '$count / 10',
            style: context.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            alignment: WrapAlignment.center,
            children: <Widget>[
              for (var i = 0; i < 10; i++)
                _Bead(
                  counted: i < count,
                  isNext: i == count,
                  number: i + 1,
                  onTap: () => onTapBead(i),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Repeat the Hail Mary ten times, resting on the mystery.',
            style: context.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Bead extends StatelessWidget {
  const _Bead({
    required this.counted,
    required this.isNext,
    required this.number,
    required this.onTap,
  });

  final bool counted;
  final bool isNext;
  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Hail Mary $number',
      button: true,
      selected: counted,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: counted
                ? AppColors.marianBlue
                : isNext
                ? AppColors.marianBlueSoft
                : isDark
                ? const Color(0xFF232B40)
                : const Color(0xFFF0F2F8),
            border: Border.all(
              color: counted
                  ? AppColors.marianBlue
                  : isNext
                  ? AppColors.marianBlue
                  : const Color(0xFFD4DAE6),
              width: 2,
            ),
          ),
          child: counted
              ? const Icon(Icons.check, size: 20, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

/// Final screen: "DECADE COMPLETE" with the explicit MARK AS PRAYED action.
class _CompletionView extends StatelessWidget {
  const _CompletionView({
    required this.decadeNumber,
    required this.completedCount,
    required this.alreadyCompleted,
    required this.saving,
    required this.error,
    required this.onMarkPrayed,
    required this.onDone,
  });

  final int decadeNumber;
  final int completedCount;
  final bool alreadyCompleted;
  final bool saving;
  final String? error;
  final Future<void> Function() onMarkPrayed;
  final VoidCallback onDone;

  String get _ordinal {
    final n = decadeNumber;
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: <Widget>[
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.goldGradient,
            ),
            child: const Text('🌹', style: TextStyle(fontSize: 34)),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'DECADE COMPLETE',
          style: context.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'You completed today\'s $_ordinal decade.',
          style: context.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$completedCount / 5 completed',
          style: context.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),

        if (alreadyCompleted) ...<Widget>[
          AppCard(
            color: AppColors.successSoft,
            child: Row(
              children: <Widget>[
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'This decade is saved. Thank you for praying it.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...<Widget>[
          if (error != null) ...<Widget>[
            Text(
              error!,
              style: context.textTheme.bodyMedium?.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppPrimaryButton(
            label: saving ? 'Saving…' : 'MARK AS PRAYED',
            icon: saving ? null : Icons.task_alt,
            onPressed: saving ? null : onMarkPrayed,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your progress is saved for today. You can come back later.',
            style: context.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        AppSecondaryButton(
          label: alreadyCompleted ? 'Done' : 'Pray again later',
          icon: Icons.arrow_back,
          onPressed: onDone,
        ),
      ],
    );
  }
}