import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../domain/models/admin_log_entry.dart';
import '../../../../domain/models/prayer_report.dart';
import 'admin_audit.dart';
import 'admin_badge_controller.dart';
import 'widgets/admin_widgets.dart';

/// Incoming reports about prayer intentions, with dismiss / review actions.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  ReportStatus _filter = ReportStatus.pending;
  List<PrayerReport> _items = <PrayerReport>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AdminReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await AppScope.of(context)
          .reportsRepository
          .fetchAll(status: _filter);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load reports: $e';
        });
      }
    }
  }

  void _setFilter(ReportStatus status) {
    setState(() => _filter = status);
    _load();
  }

  Future<void> _dismiss(PrayerReport report) async {
    await AppScope.of(context).reportsRepository.dismiss(report.id!);
    if (!mounted) return;
    await logAdminAction(
      context,
      AdminLogAction.dismissedReport,
      'report ${report.id}',
    );
    _afterAction();
  }

  Future<void> _reviewAndHide(PrayerReport report) async {
    final confirmed = await showAdminConfirm(
      context,
      title: 'Hide reported intention?',
      message: Text(
        '"${report.intentionText ?? 'Reported intention'}" will be hidden from '
        'the prayer wall and returned to the moderation queue.',
      ),
      confirmLabel: 'Review & hide',
    );
    if (!confirmed || !mounted) return;
    await AppScope.of(context).reportsRepository.review(report.id!);
    if (!mounted) return;
    if (report.intentionId.isNotEmpty) {
      await AppScope.of(context)
          .moderationRepository
          .hide(report.intentionId);
    }
    if (!mounted) return;
    await logAdminAction(
      context,
      AdminLogAction.reviewedReportAndHidden,
      'report ${report.id} · intention ${report.intentionId}',
    );
    _afterAction();
  }

  void _afterAction() {
    if (!mounted) return;
    AdminBadgeScope.maybeOf(context)?.refresh();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final canModerate =
        AppScope.of(context).adminSession.role?.canModerate ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AdminPageHeader(
          title: 'Reports',
          subtitle: 'Students can flag intentions that feel out of place.',
          trailing: IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ),
        SegmentedButton<ReportStatus>(
          segments: const <ButtonSegment<ReportStatus>>[
            ButtonSegment<ReportStatus>(
              value: ReportStatus.pending,
              label: Text('Pending'),
            ),
            ButtonSegment<ReportStatus>(
              value: ReportStatus.reviewed,
              label: Text('Reviewed'),
            ),
            ButtonSegment<ReportStatus>(
              value: ReportStatus.dismissed,
              label: Text('Dismissed'),
            ),
          ],
          selected: <ReportStatus>{_filter},
          onSelectionChanged: (selection) => _setFilter(selection.first),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_error != null)
          AdminErrorBanner(message: _error!, onRetry: _load)
        else if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_items.isEmpty)
          AdminEmptyState(
            icon: Icons.shield_outlined,
            message: _filter == ReportStatus.pending
                ? 'Nothing needs attention. New reports appear here first.'
                : 'No ${_filter.key} reports.',
          )
        else if (!canModerate)
          AdminErrorBanner(
            message:
                'Your role (${AppScope.of(context).adminSession.role?.label}) '
                'cannot review reports.',
          )
        else
          for (final report in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _ReportCard(
                report: report,
                onDismiss: () => _dismiss(report),
                onReviewAndHide: report.intentionId.isNotEmpty
                    ? () => _reviewAndHide(report)
                    : null,
              ),
            ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.onDismiss,
    this.onReviewAndHide,
  });

  final PrayerReport report;
  final VoidCallback onDismiss;
  final VoidCallback? onReviewAndHide;

  @override
  Widget build(BuildContext context) {
    final createdAt = report.createdAt;
    final isPending = report.status == ReportStatus.pending;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AdminPill(
                label: report.status.key,
                color: isPending
                    ? AppColors.goldSoft
                    : report.status == ReportStatus.dismissed
                        ? AppColors.surfaceMuted
                        : AppColors.successSoft,
                foregroundColor: isPending
                    ? AppColors.goldDark
                    : report.status == ReportStatus.dismissed
                        ? AppColors.inkMuted
                        : AppColors.success,
              ),
              const Spacer(),
              Text('Reported for · ${report.reason}',
                  style: context.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            report.intentionText ?? 'Intention text unavailable',
            style: context.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          if (report.note != null && report.note!.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text('Student note: ${report.note}',
                style: context.textTheme.bodyMedium),
          ],
          if (createdAt != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Reported ${friendlyDate(createdAt)}',
              style: context.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (isPending) ...<Widget>[
            const Divider(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Dismiss'),
                ),
                if (onReviewAndHide != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: onReviewAndHide,
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Review & hide'),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}