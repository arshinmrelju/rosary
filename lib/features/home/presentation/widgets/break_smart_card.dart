import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/decade_dots.dart';
import '../../../../domain/models/break_slot.dart';
import '../../../../domain/models/daily_content.dart';
import '../../../../domain/schedule/break_day_state.dart';

/// The Home hero — a living card that always answers the five questions the
/// schedule is about: what's happening now, when the next break is, whether
/// the current decade was completed, whether a break was missed, and how many
/// decades remain.
///
/// The card describes the moment; the schedule is a reminder, never a
/// restriction. Every state below still leaves every incomplete decade open.
class BreakSmartCard extends StatelessWidget {
  const BreakSmartCard({
    super.key,
    required this.dayState,
    required this.content,
    required this.now,
    required this.onPray,
    this.dayEnded = false,
  });

  final BreakDayState dayState;
  final DailyContent? content;
  final DateTime now;
  final bool dayEnded;

  /// Called with the decade number the student chose to pray.
  final ValueChanged<int> onPray;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: _Body(dayState: dayState, content: content, now: now, dayEnded: dayEnded, onPray: onPray),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.dayState,
    required this.content,
    required this.now,
    required this.dayEnded,
    required this.onPray,
  });

  final BreakDayState dayState;
  final DailyContent? content;
  final DateTime now;
  final bool dayEnded;
  final ValueChanged<int> onPray;

  @override
  Widget build(BuildContext context) {
    final mystery = content?.mysterySetTitle ?? 'Rosary Mysteries';
    final view = _CardView.forState(dayState, now, dayEnded: dayEnded);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        gradient: AppColors.heroGradient,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x331C3D8A),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "TODAY'S MYSTERY",
            style: context.textTheme.labelSmall?.copyWith(
              color: const Color(0xFFB9C8EC),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mystery,
            style: context.textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xl),

          Row(
            children: <Widget>[
              DecadeDots(
                completedCount: dayState.completedCount,
                nextDecade: dayState.nextToPray?.decadeNumber,
              ),
              const Spacer(),
              Text(
                'YOUR JOURNEY: ${dayState.completedCount} / 5 Moments',
                style: context.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFFDDE6F8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          _StatusBody(view: view, now: now),
          const SizedBox(height: AppSpacing.xl),

          if (view.showPrayButton)
            AppPrimaryButton(
              label: view.actionLabel,
              icon: view.actionIcon,
              onPressed: view.prayDecade == null
                  ? null
                  : () => onPray(view.prayDecade!),
            )
          else if (dayState.allCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                '🌹  Rosary complete — come back tomorrow',
                textAlign: TextAlign.center,
                style: context.textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// The copy + action for one snapshot of the college day.
class _CardView {
  const _CardView({
    required this.overline,
    required this.label,
    required this.sublabel,
    this.showPrayButton = false,
    this.actionLabel = '',
    this.actionIcon = Icons.self_improvement,
    this.prayDecade,
    this.countdownTarget,
  });

  final String overline;
  final String label;
  final String sublabel;
  final bool showPrayButton;
  final String actionLabel;
  final IconData actionIcon;
  final int? prayDecade;

  /// The next break's start time when a countdown should tick.
  final DateTime? countdownTarget;

  static _CardView forState(
    BreakDayState state,
    DateTime now, {
    required bool dayEnded,
  }) {
    if (state.allCompleted) {
      return const _CardView(
        overline: 'JOURNEY COMPLETE',
        label: 'You completed the five moments.',
        sublabel: 'Five decades. One Rosary. One journey of prayer.\n'
            'BEAD5 — Five Moments. One Journey.',
      );
    }

    if (dayEnded) {
      final count = state.completedCount;
      return _CardView(
        overline: 'YOUR JOURNEY',
        label: '$count / 5 Moments',
        sublabel: 'You prayed $count decade${count == 1 ? '' : 's'} today. '
            'Give God five moments within your day.',
        showPrayButton: state.nextToPray != null,
        actionLabel: 'PRAY REMAINING',
        actionIcon: Icons.self_improvement,
        prayDecade: state.nextToPray?.decadeNumber,
      );
    }

    final target = state.nextToPray;
    switch (state.phase) {
      case BreakDayPhase.breakIsActive:
        final active = state.activeBreak ?? target;
        final num = active?.decadeNumber ?? 1;
        return _CardView(
          overline: 'NOW • MOMENT 0$num',
          label: 'Pray the ${_decade(num)} Decade',
          sublabel: 'Take a moment. Pray together.',
          showPrayButton: true,
          actionLabel: 'PRAY NOW',
          actionIcon: Icons.self_improvement,
          prayDecade: active?.decadeNumber,
        );
      case BreakDayPhase.breakEnded:
        final ended = state.justEndedBreak ?? target;
        final num = ended?.decadeNumber ?? 1;
        return _CardView(
          overline: 'MOMENT 0$num • PAUSE & PRAY',
          label: 'Pray the ${_decade(num)} Decade',
          sublabel: 'Pause. Pray. Continue the journey.',
          showPrayButton: true,
          actionLabel: 'PRAY ${_decade(num).toUpperCase()} DECADE',
          actionIcon: Icons.schedule,
          prayDecade: ended?.decadeNumber,
        );
      case BreakDayPhase.nextBreak:
      case BreakDayPhase.beforeFirstBreak:
      case BreakDayPhase.dayComplete:
        final upcoming = state.nextUpcomingBreak ?? state.nextToPray;
        final num = upcoming?.decadeNumber ?? 1;
        return _CardView(
          overline: 'NEXT • MOMENT 0$num',
          label: upcoming == null
              ? 'Check back shortly'
              : 'Pray the ${_decade(num)} Decade · ${upcoming.time.label}',
          sublabel: dayEnded
              ? 'The college day has wrapped. Moments remain open for you.'
              : 'Pause. Pray. Continue the journey.',
          countdownTarget: upcoming?.on(now),
        );
    }
  }

  static String _decade(int? n) => n == null ? '' : ordinal(n);

  static String? _window(BreakSlot? slot) {
    if (slot == null) return null;
    final minutes = slot.activeWindow.inMinutes;
    return '$minutes minute${minutes == 1 ? '' : 's'}';
  }
}

/// Renders the status copy and, when a countdown is due, the live timer.
class _StatusBody extends StatelessWidget {
  const _StatusBody({required this.view, required this.now});

  final _CardView view;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final countdown = view.countdownTarget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          countdown != null ? Icons.schedule : Icons.self_improvement,
          color: AppColors.goldSoft,
          size: 22,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          view.overline,
          style: context.textTheme.labelSmall?.copyWith(
            color: const Color(0xFFB9C8EC),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          view.label,
          style: context.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 2),
        if (countdown == null)
          Text(
            view.sublabel,
            style: context.textTheme.bodySmall?.copyWith(
              color: const Color(0xFFDDE6F8),
            ),
          )
        else ...<Widget>[
          Text(
            view.sublabel,
            style: context.textTheme.bodySmall?.copyWith(
              color: const Color(0xFFDDE6F8),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _BreakCountdown(target: countdown),
        ],
      ],
    );
  }
}

/// Lightweight per-second countdown to the next break.
///
/// * Fires only while the widget is visible: it pauses when the screen leaves
///   the current route or when it's not producing frames (`TickerMode`).
/// * Stops at zero of its own accord — the parent controller handles the
///   state flip to "break is active".
/// * Recomputes from the wall clock, so background/resume never drifts.
class _BreakCountdown extends StatefulWidget {
  const _BreakCountdown({required this.target});

  final DateTime target;

  @override
  State<_BreakCountdown> createState() => _BreakCountdownState();
}

class _BreakCountdownState extends State<_BreakCountdown> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Route visibility / frame production changed — start or pause.
    if (_autoPaused) {
      _stop();
    } else {
      _start();
    }
  }

  @override
  void didUpdateWidget(covariant _BreakCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _start();
    }
  }

  bool get _autoPaused {
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent == false) return true;
    if (TickerMode.valuesOf(context).enabled == false) return true;
    return false;
  }

  void _start() {
    if (_timer != null) return;
    _now = DateTime.now();
    if (_now.isBefore(widget.target)) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_autoPaused) {
          _stop();
          return;
        }
        _now = DateTime.now();
        setState(() {});
        if (!_now.isBefore(widget.target)) {
          _stop();
        }
      });
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_now.isBefore(widget.target)) {
      return Text(
        'Starting now',
        style: context.textTheme.titleMedium?.copyWith(color: Colors.white),
      );
    }
    return Row(
      children: <Widget>[
        Text(
          'Starts in ',
          style: context.textTheme.bodySmall?.copyWith(
            color: const Color(0xFFDDE6F8),
          ),
        ),
        Text(
          formatCountdown(widget.target.difference(_now)),
          style: context.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}