import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../domain/models/day_stats.dart';
import '../../../../domain/models/month_stats.dart';
import 'widgets/admin_widgets.dart';

/// Community statistics: today, this month, and a daily chart.
class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  DayStats? _today;
  MonthStats? _month;
  List<DayStats> _days = <DayStats>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = AppScope.of(context).adminStatsRepository;
      final now = clockNow();
      final results = await Future.wait<Object?>(
        <Future<Object?>>[
          repo.fetchDay(now),
          repo.fetchMonth(now),
          repo.fetchDailyRange(
            now.subtract(const Duration(days: 13)),
            now,
          ),
        ],
      );
      if (!mounted) return;
      setState(() {
        _today = results[0] as DayStats;
        _month = results[1] as MonthStats;
        _days = _sortedDays(results[2] as List<DayStats>);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load statistics: $e';
        });
      }
    }
  }

  static List<DayStats> _sortedDays(List<DayStats> days) {
    final sorted = <DayStats>[...days];
    sorted.sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AdminPageHeader(
            title: 'Statistics',
            subtitle: 'Community participation at a glance.',
          ),
          AdminErrorBanner(message: _error!, onRetry: _load),
        ],
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final today = _today!;
    final month = _month!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AdminPageHeader(
          title: 'Statistics',
          subtitle: 'Live aggregates as students participate.',
          trailing: IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ),
        Text('Today', style: context.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        _StatRow(
          cards: <Widget>[
            AdminStatCard(
              icon: '🙏',
              label: 'Prayed today',
              value: formatThousands(today.totalParticipants),
              accent: AppColors.marianBlue,
            ),
            AdminStatCard(
              icon: '☾',
              label: 'Decades prayed',
              value: formatThousands(today.totalDecades),
              accent: AppColors.goldDark,
            ),
            AdminStatCard(
              icon: '🕊',
              label: 'Intentions shared',
              value: formatThousands(today.totalIntentions),
              accent: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Text('This month', style: context.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        _StatRow(
          cards: <Widget>[
            AdminStatCard(
              icon: '🙏',
              label: 'Participants',
              value: formatThousands(month.totalParticipants),
            ),
            AdminStatCard(
              icon: '☾',
              label: 'Decades prayed',
              value: formatThousands(month.totalDecades),
            ),
            AdminStatCard(
              icon: '❤',
              label: 'Prayers given',
              value: formatThousands(month.totalPrayers),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Text('Last 14 days · decades prayed',
            style: context.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        _DailyChart(days: _days),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            children: <Widget>[
              for (final card in cards) ...<Widget>[
                Expanded(child: card),
                if (card != cards.last) const SizedBox(width: AppSpacing.lg),
              ],
            ],
          );
        }
        return Column(
          children: <Widget>[
            for (final card in cards) ...<Widget>[
              card,
              if (card != cards.last) const SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.days});

  final List<DayStats> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const AdminEmptyState(
        icon: Icons.query_stats,
        message: 'No statistics recorded in the last two weeks.',
      );
    }
    final max =
        days.fold<int>(0, (current, d) => d.totalDecades > current ? d.totalDecades : current);
    final safeMax = max == 0 ? 1 : max;

    return AppCard(
      child: SizedBox(
        height: 240,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  for (final day in days) ...<Widget>[
                    Expanded(
                      child: Tooltip(
                        message:
                            '${friendlyMonthDay(DateTime.parse(day.date))} · '
                            '${day.totalDecades} decades · ${day.totalParticipants} participants',
                        child: Container(
                          height: (day.totalDecades / safeMax) * 200,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: day.totalDecades == 0
                                ? const Color(0xFFE6EAF2)
                                : AppColors.marianBlue.withValues(
                                    alpha: 0.35 + 0.65 * (day.totalDecades / safeMax),
                                  ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                const SizedBox(height: 180),
                Text('Powered by stats/{date}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}