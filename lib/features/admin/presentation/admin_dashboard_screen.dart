import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../domain/models/campaign_settings.dart';
import '../../../domain/models/daily_content.dart';
import '../../../domain/models/day_stats.dart';
import '../../../domain/models/month_stats.dart';
import 'widgets/admin_widgets.dart';

class _DashboardSnapshot {
  const _DashboardSnapshot({
    required this.todayContent,
    required this.pendingIntentions,
    required this.publishedIntentions,
    required this.pendingReports,
    required this.campaign,
    required this.today,
    required this.month,
  });

  final DailyContent? todayContent;
  final int pendingIntentions;
  final int publishedIntentions;
  final int pendingReports;
  final CampaignSettings? campaign;
  final DayStats today;
  final MonthStats month;
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

/// Landing page after sign-in: today's state + quick actions.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<_DashboardSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardSnapshot> _load() async {
    final deps = AppScope.of(context);
    final now = clockNow();
    final results = await Future.wait<Object?>(
      <Future<Object?>>[
        deps.adminContentRepository.fetch(dateKey(now)),
        deps.moderationRepository.fetchPending(),
        deps.moderationRepository.fetchApproved(),
        deps.reportsRepository.countPending(),
        deps.campaignRepository.fetch(),
        deps.adminStatsRepository.fetchDay(now),
        deps.adminStatsRepository.fetchMonth(now),
      ],
    );
    return _DashboardSnapshot(
      todayContent: results[0] as DailyContent?,
      pendingIntentions: (results[1] as List).length,
      publishedIntentions: (results[2] as List).length,
      pendingReports: results[3] as int,
      campaign: results[4] as CampaignSettings?,
      today: results[5] as DayStats,
      month: results[6] as MonthStats,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const AdminPageHeader(
          title: 'Dashboard',
          subtitle: 'Everything happening right now in the campaign.',
        ),
        _buildBody(),
      ],
    );
  }

  Widget _buildBody() {
    return FutureBuilder<_DashboardSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AdminErrorBanner(
                message: 'Could not load the dashboard: ${snapshot.error}',
                onRetry: () => setState(() => _future = _load()),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _QuickActions(),
            ],
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxxl),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final data = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (data.todayContent == null || !data.todayContent!.published)
              _TodayStatusBanner(content: data.todayContent),
            if (data.campaign?.paused == true) const _PausedBanner(),
            const SizedBox(height: AppSpacing.xl),
            _StatRow(
              cards: <Widget>[
                AdminStatCard(
                  icon: '🙏',
                  label: 'Participants today',
                  value: formatThousands(data.today.totalParticipants),
                ),
                AdminStatCard(
                  icon: '☾',
                  label: 'Decades today',
                  value: formatThousands(data.today.totalDecades),
                ),
                AdminStatCard(
                  icon: '❤',
                  label: 'Prayers this month',
                  value: formatThousands(data.month.totalPrayers),
                  accent: AppColors.goldDark,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _StatRow(
              cards: <Widget>[
                AdminStatCard(
                  icon: '⏳',
                  label: 'Awaiting moderation',
                  value: '${data.pendingIntentions}',
                  accent: data.pendingIntentions > 0
                      ? AppColors.error
                      : AppColors.success,
                ),
                AdminStatCard(
                  icon: '🕊',
                  label: 'Intentions published',
                  value: '${data.publishedIntentions}',
                ),
                AdminStatCard(
                  icon: '🚩',
                  label: 'Reports pending',
                  value: '${data.pendingReports}',
                  accent: data.pendingReports > 0
                      ? AppColors.goldDark
                      : AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxxl),
            const _QuickActions(),
          ],
        );
      },
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

class _TodayStatusBanner extends StatelessWidget {
  const _TodayStatusBanner({required this.content});

  final DailyContent? content;

  @override
  Widget build(BuildContext context) {
    final label = content == null ? 'Nothing scheduled today' : 'Draft only';
    return AppCard(
      color: AppColors.goldSoft,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: <Widget>[
          const Icon(Icons.edit_calendar_outlined, color: AppColors.goldDark),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '$label — students will not see content for today yet.',
              style: context.textTheme.bodyLarge?.copyWith(
                color: AppColors.goldDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.marianBlue),
            onPressed: () =>
                context.go(AppRoutes.adminContentDateFor(dateKey(clockNow()))),
            child: const Text('Edit & publish'),
          ),
        ],
      ),
    );
  }
}

class _PausedBanner extends StatelessWidget {
  const _PausedBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: <Widget>[
            const Icon(Icons.pause_circle_outline, color: AppColors.inkSoft),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'The campaign is paused — students see a calm message instead '
                'of breaks.',
                style: context.textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.adminCampaign),
              child: const Text('Manage'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  /// First item uses an empty route marker; it becomes "today" at build time.
  static final List<_QuickAction> _actions = <_QuickAction>[
    _QuickAction('Edit today', Icons.edit_calendar_outlined, ''),
    _QuickAction('Calendar', Icons.calendar_month_outlined,
        AppRoutes.adminContentCalendar),
    _QuickAction('Moderation', Icons.pending_actions_outlined,
        AppRoutes.adminPrayerPending),
    _QuickAction('Reports', Icons.flag_outlined, AppRoutes.adminReports),
    _QuickAction('Bulk import', Icons.library_add_outlined,
        AppRoutes.adminContentBulk),
    _QuickAction('Statistics', Icons.bar_chart_outlined,
        AppRoutes.adminStatistics),
  ];

  @override
  Widget build(BuildContext context) {
    final todayRoute = AppRoutes.adminContentDateFor(dateKey(clockNow()));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Quick actions', style: context.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        _StatRow(
          cards: <Widget>[
            for (final action in _actions)
              _ActionCard(
                label: action.label,
                icon: action.icon,
                onTap: () =>
                    context.go(action.route.isEmpty ? todayRoute : action.route),
              ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 24, color: AppColors.marianBlue),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: context.textTheme.titleSmall),
        ],
      ),
    );
  }
}