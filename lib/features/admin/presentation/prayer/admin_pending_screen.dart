import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../domain/models/admin_log_entry.dart';
import '../../../../domain/models/prayer_intention.dart';
import '../admin_audit.dart';
import '../admin_badge_controller.dart';
import '../widgets/admin_widgets.dart';

/// Moderation queue for student prayer intentions awaiting approval.
class AdminPendingScreen extends StatefulWidget {
  const AdminPendingScreen({super.key});

  @override
  State<AdminPendingScreen> createState() => _AdminPendingScreenState();
}

class _AdminPendingScreenState extends State<AdminPendingScreen> {
  List<PrayerIntention> _items = <PrayerIntention>[];
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
      final items =
          await AppScope.of(context).moderationRepository.fetchPending();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load the moderation queue: $e';
        });
      }
    }
  }

  Future<void> _approve(PrayerIntention intention) async {
    final confirmed = await showAdminConfirm(
      context,
      title: 'Approve this intention?',
      message: Text(
        '"${intention.text}" will appear on the prayer wall for students.',
      ),
      confirmLabel: 'Approve',
    );
    if (!confirmed || !mounted) return;
    try {
      await AppScope.of(context)
          .moderationRepository
          .approve(intention.id!);
      if (!mounted) return;
      await logAdminAction(
        context,
        AdminLogAction.approvedPrayerIntention,
        '${intention.id}',
      );
      if (mounted) {
        AdminBadgeScope.maybeOf(context)?.refresh();
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not approve: $e')),
        );
      }
    }
  }

  Future<void> _reject(PrayerIntention intention) async {
    final confirmed = await showAdminConfirm(
      context,
      title: 'Reject this intention?',
      message: const Text(
        'It will be removed from the queue entirely and never shown to students.',
      ),
      confirmLabel: 'Reject',
      confirmColor: AppColors.error,
    );
    if (!confirmed || !mounted) return;
    try {
      await AppScope.of(context).moderationRepository.reject(intention.id!);
      if (!mounted) return;
      await logAdminAction(
        context,
        AdminLogAction.rejectedPrayerIntention,
        '${intention.id}',
      );
      if (mounted) {
        AdminBadgeScope.maybeOf(context)?.refresh();
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reject: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canModerate =
        AppScope.of(context).adminSession.role?.canModerate ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AdminPageHeader(
          title: 'Moderation Queue',
          subtitle: '${_items.length} waiting for review.',
          trailing: IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ),
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
          const AdminEmptyState(
            icon: Icons.task_alt,
            message: 'Nothing waiting right now. New submissions land here '
                'and need an approval before they go live.',
          )
        else if (!canModerate)
          AdminErrorBanner(
            message:
                'Your role (${AppScope.of(context).adminSession.role?.label}) '
                'cannot moderate the prayer wall.',
          )
        else
          for (final intention in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _IntentionCard(
                intention: intention,
                onApprove: () => _approve(intention),
                onReject: () => _reject(intention),
              ),
            ),
      ],
    );
  }
}

class _IntentionCard extends StatelessWidget {
  const _IntentionCard({
    required this.intention,
    required this.onApprove,
    required this.onReject,
  });

  final PrayerIntention intention;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final createdAt = intention.createdAt;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const AdminPill(
                label: 'Pending',
                color: AppColors.goldSoft,
                foregroundColor: AppColors.goldDark,
              ),
              const Spacer(),
              if (intention.anonymous) ...<Widget>[
                const Icon(Icons.visibility_off_outlined,
                    size: 14, color: AppColors.inkMuted),
                const SizedBox(width: 4),
                Text('Anonymous', style: context.textTheme.bodySmall),
              ] else
                Text('Student', style: context.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(intention.text, style: context.textTheme.bodyLarge),
          if (createdAt != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Submitted ${friendlyDate(createdAt)}',
              style: context.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const Divider(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                icon: const Icon(Icons.block, size: 18),
                label: const Text('Reject'),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Approve'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}