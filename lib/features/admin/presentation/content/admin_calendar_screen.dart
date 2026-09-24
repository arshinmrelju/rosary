import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/daily_content.dart';
import '../widgets/admin_widgets.dart';

/// Month grid of daily content. Each cell reflects published / draft /
/// missing status; tapping navigates to the editor for that date.
class AdminCalendarScreen extends StatefulWidget {
  const AdminCalendarScreen({super.key});

  @override
  State<AdminCalendarScreen> createState() => _AdminCalendarScreenState();
}

class _AdminCalendarScreenState extends State<AdminCalendarScreen> {
  late DateTime _month = DateTime(clockNow().year, clockNow().month);
  Map<String, DailyContent> _content = <String, DailyContent>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final start = DateTime(_month.year, _month.month);
    final end = DateTime(_month.year, _month.month + 1, 0);
    final items =
        await AppScope.of(context).adminContentRepository.fetchRange(start, end);
    if (!mounted) return;
    setState(() {
      _content = <String, DailyContent>{
        for (final item in items) item.date: item,
      };
      _loading = false;
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday % 7;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final todayKey = dateKey(clockNow());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AdminPageHeader(
          title: 'Content Calendar',
          subtitle: 'Plan and spot gaps across the campaign.',
          trailing: _MonthNav(
            month: _month,
            onPrev: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
        ),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: CircularProgressIndicator(),
            ),
          )
        else ...<Widget>[
          const _WeekdayHeader(weekStart: 0),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: firstWeekday + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final day = index - firstWeekday + 1;
              if (day < 1 || day > daysInMonth) {
                return const SizedBox.shrink();
              }
              final date = DateTime(_month.year, _month.month, day);
              final key = dateKey(date);
              final content = _content[key];
              return _DayCell(
                day: day,
                dateKey: key,
                content: content,
                isToday: key == todayKey,
                onTap: () => context.go(
                  AppRoutes.adminContentDateFor(key),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              const _LegendDot(color: AppColors.success),
              Text('Published', style: context.textTheme.bodySmall),
              const _LegendDot(color: AppColors.gold, border: true),
              Text('Draft', style: context.textTheme.bodySmall),
              const _LegendDot(color: AppColors.surfaceMuted, border: true),
              Text('Empty', style: context.textTheme.bodySmall),
            ],
          ),
        ],
      ],
    );
  }
}

class _MonthNav extends StatelessWidget {
  const _MonthNav({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous month',
        ),
        Text(
          '${monthName(month.month)} ${month.year}',
          style: context.textTheme.titleMedium,
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

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.weekStart});

  final int weekStart;

  @override
  Widget build(BuildContext context) {
    const List<String> week = <String>['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final ordered = <String>[
      for (var i = weekStart; i < weekStart + 7; i++) week[i % 7],
    ];
    return Row(
      children: <Widget>[
        for (final label in ordered)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: context.textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.dateKey,
    required this.content,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final String dateKey;
  final DailyContent? content;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final published = content?.published == true;
    final draft = content != null && !published;
    final color = published
        ? AppColors.successSoft
        : draft
        ? AppColors.goldSoft
        : AppColors.surfaceMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday
                ? AppColors.marianBlue
                : color == AppColors.surfaceMuted
                    ? const Color(0xFFE9EDF4)
                    : Colors.transparent,
            width: isToday ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '$day',
              style: context.textTheme.labelMedium?.copyWith(
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday ? AppColors.marianBlue : null,
              ),
            ),
            const Spacer(),
            if (published)
              Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.success.withValues(alpha: 0.7),
              )
            else if (draft)
              Icon(
                Icons.edit_note,
                size: 16,
                color: AppColors.goldDark.withValues(alpha: 0.8),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, this.border = false});

  final Color color;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: border ? Border.all(color: const Color(0xFFC4CBD9)) : null,
      ),
    );
  }
}