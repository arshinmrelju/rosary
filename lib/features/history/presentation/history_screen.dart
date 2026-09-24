import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_content_frame.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../domain/models/day_participation.dart';

/// The student's own history: a monthly calendar with per-day indicators and
/// a gentle per-day detail view.
///
/// Deliberately no streaks, no missing-day line and no leaderboards here —
/// the calendar only ever *reflects* prayer. Missed breaks are shown as open
/// decades, never as failures.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _month;
  DateTime? _selected;
  bool _loading = true;
  bool _wired = false;
  Map<String, DayParticipation> _days = <String, DayParticipation>{};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = now;
  }

  Future<void> _load() async {
    final deps = AppScope.of(context);
    final userId = await deps.authService.ensureUserId();
    final start = DateTime(_month.year, _month.month);
    final end = DateTime(_month.year, _month.month + 1, 0);

    final results = await Future.wait<Object?>(<Future<Object?>>[
      deps.participationRepository.fetchRange(userId, start, end),
    ]);
    final days = results[0] as List<DayParticipation>;
    _days = <String, DayParticipation>{
      for (final day in days) day.date: day,
    };
    if (mounted) setState(() => _loading = false);
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _loading = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    if (!_wired) {
      _wired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }

    final selectedKey = dateKey(_selected!);
    final todayKey = dateKey(DateTime.now());
    final selectedDay = _days[selectedKey];

    return Scaffold(
      body: SafeArea(
        child: AppContentFrame(
          child: _loading
              ? const AppLoadingView(message: 'Loading your history…')
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  children: <Widget>[
                    _BackBar(title: 'Your history'),
                    const SizedBox(height: AppSpacing.md),

                    _MonthNavigator(
                      month: _month,
                      onPrevious: () => _changeMonth(-1),
                      onNext: () => _changeMonth(1),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _MonthSummary(days: _days),
                    const SizedBox(height: AppSpacing.xl),

                    _CalendarGrid(
                      month: _month,
                      days: _days,
                      selectedKey: selectedKey,
                      todayKey: todayKey,
                      onSelect: (date) =>
                          setState(() => _selected = DateTime(date.year, date.month, date.day)),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    _DayDetail(
                      day: selectedDay,
                      date: _selected!,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BackBar extends StatelessWidget {
  const _BackBar({required this.title});

  final String title;

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
              title.toUpperCase(),
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

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous month',
        ),
        Expanded(
          child: Center(
            child: Text(
              '${monthName(month.month)} ${month.year}',
              style: context.textTheme.titleLarge?.copyWith(
                color: AppColors.marianBlue,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next month',
        ),
      ],
    );
  }
}

/// Simple, non-gamified summary: days prayed and decades prayed this month.
class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.days});

  final Map<String, DayParticipation> days;

  @override
  Widget build(BuildContext context) {
    var decades = 0;
    for (final day in days.values) {
      decades += day.totalCompleted;
    }
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatTile(
            label: 'DAYS WITH PRAYER',
            value: '${days.length}',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatTile(
            label: 'DECADES PRAYED',
            value: '$decades',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: context.textTheme.headlineSmall?.copyWith(
              color: AppColors.marianBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.inkMuted,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.days,
    required this.selectedKey,
    required this.todayKey,
    required this.onSelect,
  });

  final DateTime month;
  final Map<String, DayParticipation> days;
  final String selectedKey;
  final String todayKey;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    const weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final cells = <Widget>[
      for (final label in weekdays)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
        ),
    ];
    for (var i = 0; i < firstWeekday - 1; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final key = dateKey(date);
      cells.add(
        _DayCell(
          date: date,
          count: days[key]?.totalCompleted ?? 0,
          selected: key == selectedKey,
          isToday: key == todayKey,
          onTap: () => onSelect(date),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: cells,
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.count,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final int count;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final prayed = count > 0;
    final chipColor = selected
        ? AppColors.marianBlue
        : prayed
        ? AppColors.successSoft
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Semantics(
      label: '${shortWeekday(date)}, ${friendlyDate(date)}'
          '${prayed ? ' , $count decades prayed' : ''}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: chipColor,
            shape: BoxShape.circle,
            border: isToday ? Border.all(color: AppColors.goldDark, width: 2) : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '${date.day}',
                style: context.textTheme.labelLarge?.copyWith(
                  color: selected ? Colors.white : null,
                  fontWeight: isToday || selected ? FontWeight.w700 : null,
                ),
              ),
              if (prayed) ...<Widget>[
                Text(
                  '$count',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: selected ? const Color(0xFFDDE6F8) : AppColors.success,
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The selected day, broken into the five decades — each one either prayed or
/// still open, without judgment.
class _DayDetail extends StatelessWidget {
  const _DayDetail({required this.day, required this.date});

  final DayParticipation? day;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final current = day ?? DayParticipation.empty(date);
    final completed = current.totalCompleted;

    return AppCard(
      color: AppColors.marianBlueSoft.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  friendlyDate(date),
                  style: context.textTheme.titleMedium,
                ),
              ),
              Text(
                '$completed / 5 decades',
                style: context.textTheme.labelMedium?.copyWith(
                  color: completed == 5 ? AppColors.success : AppColors.marianBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var n = 1; n <= 5; n++)
            _DecadeRow(
              decade: n,
              prayed: current.isDecadeCompleted(n),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            completed == 5
                ? 'A complete Rosary. 🌹'
                : 'Open decades stay open — you can pray them whenever '
                    'you wish.',
            style: context.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecadeRow extends StatelessWidget {
  const _DecadeRow({required this.decade, required this.prayed});

  final int decade;
  final bool prayed;

  @override
  Widget build(BuildContext context) {
    final color = prayed ? AppColors.success : Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Icon(
            prayed ? Icons.check_circle : Icons.circle_outlined,
            size: 20,
            color: color,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '${ordinal(decade)} decade',
            style: context.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: prayed ? FontWeight.w600 : null,
            ),
          ),
          const Spacer(),
          Text(
            prayed ? 'Prayed' : 'Open',
            style: context.textTheme.labelMedium?.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}