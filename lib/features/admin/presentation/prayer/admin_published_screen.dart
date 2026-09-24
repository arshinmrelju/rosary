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

/// Published prayer intentions visible to students, with hide/delete controls.
class AdminPublishedScreen extends StatefulWidget {
  const AdminPublishedScreen({super.key});

  @override
  State<AdminPublishedScreen> createState() => _AdminPublishedScreenState();
}

class _AdminPublishedScreenState extends State<AdminPublishedScreen> {
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
          await AppScope.of(context).moderationRepository.fetchApproved();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load published intentions: $e';
        });
      }
    }
  }

  Future<void> _hide(PrayerIntention intention) async {
    final confirmed = await showAdminConfirm(
      context,
      title: 'Hide this intention?',
      message: Text(
        '"${intention.text}" will leave the prayer wall and return to the '
        'moderation queue. Its prayer counts are preserved.',
      ),
      confirmLabel: 'Hide',
    );
    if (!confirmed || !mounted) return;
    try {
      await AppScope.of(context).moderationRepository.hide(intention.id!);
      if (!mounted) return;
      await logAdminAction(
        context,
        AdminLogAction.hidPrayerIntention,
        '${intention.id}',
      );
      if (mounted) {
        AdminBadgeScope.maybeOf(context)?.refresh();
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not hide: $e')),
        );
      }
    }
  }

  Future<void> _delete(PrayerIntention intention) async {
    final confirmed = await showAdminConfirm(
      context,
      title: 'Delete this intention?',
      message: const Text(
        'This permanently removes the intention and its prayer counts. '
        'This cannot be undone.',
      ),
      confirmLabel: 'Delete forever',
      confirmColor: AppColors.error,
    );
    if (!confirmed || !mounted) return;
    try {
      await AppScope.of(context).moderationRepository.delete(intention.id!);
      if (!mounted) return;
      await logAdminAction(
        context,
        AdminLogAction.deletedPrayerIntention,
        '${intention.id}',
      );
      if (mounted) {
        AdminBadgeScope.maybeOf(context)?.refresh();
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canModerate =
        AppScope.of(context).adminSession.role?.canModerate ?? false;
    final canDelete =
        AppScope.of(context).adminSession.role?.canDeleteContent ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AdminPageHeader(
          title: 'Published Intentions',
          subtitle: '${_items.length} visible on the student prayer wall.',
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
            icon: Icons.chat_bubble_outline,
            message: 'No published intentions yet. Approve something from the '
                'pending queue and it will appear here.',
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
              child: _PublishedCard(
                intention: intention,
                onHide: () => _hide(intention),
                onDelete: canDelete ? () => _delete(intention) : null,
              ),
            ),
      ],
    );
  }
}

class _PublishedCard extends StatelessWidget {
  const _PublishedCard({
    required this.intention,
    required this.onHide,
    this.onDelete,
  });

  final PrayerIntention intention;
  final VoidCallback onHide;
  final VoidCallback? onDelete;

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
                label: 'Published',
                color: AppColors.successSoft,
                foregroundColor: AppColors.success,
              ),
              const Spacer(),
              const Icon(Icons.favorite_outline,
                  size: 14, color: AppColors.error),
              const SizedBox(width: 4),
              Text(
                '${intention.prayerCount} prayers',
                style: context.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(intention.text, style: context.textTheme.bodyLarge),
          if (createdAt != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Published ${friendlyDate(createdAt)}',
              style: context.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const Divider(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              if (onDelete != null) ...<Widget>[
                TextButton.icon(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              OutlinedButton.icon(
                onPressed: onHide,
                icon: const Icon(Icons.visibility_off_outlined, size: 18),
                label: const Text('Hide'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}