import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../domain/models/admin_log_entry.dart';
import '../../../../domain/models/admin_role.dart';
import '../../../../domain/models/admin_user.dart';
import '../../../../domain/models/announcement.dart';
import 'admin_audit.dart';
import 'widgets/admin_widgets.dart';

/// Dashboard settings: announcements, administrators and the audit trail.
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const AdminPageHeader(
          title: 'Settings',
          subtitle: 'Announcements, administrator roles and the audit trail.',
        ),
        SegmentedButton<int>(
          segments: const <ButtonSegment<int>>[
            ButtonSegment<int>(value: 0, label: Text('Announcements')),
            ButtonSegment<int>(value: 1, label: Text('Administrators')),
            ButtonSegment<int>(value: 2, label: Text('Audit log')),
          ],
          selected: <int>{_tab},
          onSelectionChanged: (selection) => setState(() => _tab = selection.first),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_tab == 0)
          const _AnnouncementsTab()
        else if (_tab == 1)
          const _AdministratorsTab()
        else
          const _AuditLogTab(),
      ],
    );
  }
}

class _AnnouncementsTab extends StatefulWidget {
  const _AnnouncementsTab();

  @override
  State<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab> {
  List<Announcement> _items = <Announcement>[];
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
          await AppScope.of(context).announcementsRepository.fetchAll();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load announcements: $e';
        });
      }
    }
  }

  Future<void> _openEditor([Announcement? existing]) async {
    final draft = existing ?? const Announcement(id: null, title: '', message: '');
    final result = await showDialog<_AnnouncementDraft>(
      context: context,
      builder: (context) => _AnnouncementDialog(draft: draft),
    );
    if (result == null || !mounted) return;

    final repo = AppScope.of(context).announcementsRepository;
    final announcement = existing == null
        ? Announcement(
            id: existing?.id,
            title: result.title,
            message: result.message,
            active: existing?.active ?? false,
          )
        : existing.copyWith(title: result.title, message: result.message);
    await repo.save(announcement);
    if (!mounted) return;
    await logAdminAction(
      context,
      existing == null
          ? AdminLogAction.createdAnnouncement
          : AdminLogAction.updatedAnnouncement,
      result.title,
    );
    _load();
  }

  Future<void> _toggle(Announcement announcement) async {
    await AppScope.of(context)
        .announcementsRepository
        .setActive(announcement.id!, !announcement.active);
    if (!mounted) return;
    await logAdminAction(
      context,
      AdminLogAction.updatedAnnouncement,
      announcement.title,
    );
    _load();
  }

  Future<void> _delete(Announcement announcement) async {
    final confirmed = await showAdminConfirm(
      context,
      title: 'Delete announcement?',
      message: Text('"${announcement.title}" will be removed permanently.'),
      confirmLabel: 'Delete',
      confirmColor: AppColors.error,
    );
    if (!confirmed || !mounted) return;
    await AppScope.of(context).announcementsRepository.delete(announcement.id!);
    if (!mounted) return;
    await logAdminAction(
      context,
      AdminLogAction.deletedAnnouncement,
      announcement.title,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Students see the single active announcement on Home.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New announcement'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_error != null)
          AdminErrorBanner(message: _error!, onRetry: _load)
        else if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_items.isEmpty)
          const AdminEmptyState(
            icon: Icons.campaign_outlined,
            message: 'No announcements yet. Create one to reach students.',
          )
        else
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(item.title,
                              style: context.textTheme.titleMedium),
                        ),
                        Switch(
                          value: item.active,
                          onChanged: (_) => _toggle(item),
                        ),
                      ],
                    ),
                    Text(item.message,
                        style: context.textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: <Widget>[
                        Text(
                          item.active ? 'Visible to students' : 'Hidden',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: item.active
                                ? AppColors.success
                                : AppColors.inkMuted,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _openEditor(item),
                          child: const Text('Edit'),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () => _delete(item),
                          icon: const Icon(Icons.delete_outline, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _AnnouncementDraft {
  const _AnnouncementDraft(this.title, this.message);

  final String title;
  final String message;
}

class _AnnouncementDialog extends StatefulWidget {
  const _AnnouncementDialog({required this.draft});

  final Announcement draft;

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  late final TextEditingController _title = TextEditingController(
    text: widget.draft.title,
  );
  late final TextEditingController _message = TextEditingController(
    text: widget.draft.message,
  );

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.draft.id == null ? 'New announcement' : 'Edit announcement'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _message,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Message',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _title.text.trim().isEmpty || _message.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(
                    _AnnouncementDraft(_title.text.trim(), _message.text.trim()),
                  ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AdministratorsTab extends StatefulWidget {
  const _AdministratorsTab();

  @override
  State<_AdministratorsTab> createState() => _AdministratorsTabState();
}

class _AdministratorsTabState extends State<_AdministratorsTab> {
  List<AdminUser> _users = <AdminUser>[];
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
      final users =
          await AppScope.of(context).adminUsersRepository.fetchAll();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load administrators: $e';
        });
      }
    }
  }

  Future<void> _grant() async {
    final session = AppScope.of(context).adminSession;
    final result = await showDialog<_NewAdmin>(
      context: context,
      builder: (context) => const _GrantDialog(),
    );
    if (result == null || !mounted) return;
    final now = clockNow();
    await AppScope.of(context).adminUsersRepository.grant(
      AdminUser(
        uid: result.uid,
        role: result.role,
        displayName: result.displayName,
        createdAt: now,
      ),
      grantedBy: session.user?.uid,
    );
    if (!mounted) return;
    await logAdminAction(context, AdminLogAction.grantedAdmin, result.uid);
    _load();
  }

  Future<void> _revoke(AdminUser user) async {
    final confirmed = await showAdminConfirm(
      context,
      title: 'Revoke access for ${user.displayName ?? user.uid}?',
      message: Text(
        'This removes the administrator role. The Google account stays valid; '
        'it just loses dashboard access.',
      ),
      confirmLabel: 'Revoke',
      confirmColor: AppColors.error,
    );
    if (!confirmed || !mounted) return;
    await AppScope.of(context).adminUsersRepository.revoke(user.uid);
    if (!mounted) return;
    await logAdminAction(context, AdminLogAction.revokedAdmin, user.uid);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final canManage =
        AppScope.of(context).adminSession.role?.canManageAdmins ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'The admins/{uid} documents are the authoritative role store '
                'checked by the Firestore rules.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (canManage)
              OutlinedButton.icon(
                onPressed: _grant,
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Grant role'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_error != null)
          AdminErrorBanner(message: _error!, onRetry: _load)
        else if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_users.isEmpty)
          const AdminEmptyState(
            icon: Icons.admin_panel_settings_outlined,
            message: 'No administrators configured yet.',
          )
        else
          for (final user in _users)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: <Widget>[
                    AdminPill(
                      label: user.role.label,
                      color: user.role == AdminRole.superAdmin
                          ? AppColors.marianBlueSoft
                          : AppColors.surfaceMuted,
                      foregroundColor: user.role == AdminRole.superAdmin
                          ? AppColors.marianBlue
                          : AppColors.inkSoft,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            user.displayName ?? 'Admin ${user.uid}',
                            style: context.textTheme.titleSmall,
                          ),
                          Text(
                            user.email ?? user.uid,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canManage &&
                        user.uid != AppScope.of(context).adminSession.user?.uid) ...<Widget>[
                      IconButton(
                        tooltip: 'Revoke',
                        onPressed: () => _revoke(user),
                        icon: const Icon(Icons.person_remove_alt_1,
                            size: 20, color: AppColors.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _NewAdmin {
  const _NewAdmin(this.uid, this.role, this.displayName);

  final String uid;
  final AdminRole role;
  final String displayName;
}

class _GrantDialog extends StatefulWidget {
  const _GrantDialog();

  @override
  State<_GrantDialog> createState() => _GrantDialogState();
}

class _GrantDialogState extends State<_GrantDialog> {
  final TextEditingController _uid = TextEditingController();
  final TextEditingController _displayName = TextEditingController();
  AdminRole _role = AdminRole.moderator;

  @override
  void dispose() {
    _uid.dispose();
    _displayName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Grant an admin role'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _uid,
              decoration: const InputDecoration(
                labelText: 'Firebase UID',
                helperText: 'Find it in Firebase Auth console.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _displayName,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: DropdownButton<AdminRole>(
                value: _role,
                items: <DropdownMenuItem<AdminRole>>[
                  for (final role in AdminRole.all)
                    DropdownMenuItem<AdminRole>(
                      value: role,
                      child: Text(role.label),
                    ),
                ],
                onChanged: (role) =>
                    setState(() => _role = role ?? AdminRole.moderator),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _uid.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(
                    _NewAdmin(
                      _uid.text.trim(),
                      _role,
                      _displayName.text.trim(),
                    ),
                  ),
          child: const Text('Grant'),
        ),
      ],
    );
  }
}

class _AuditLogTab extends StatefulWidget {
  const _AuditLogTab();

  @override
  State<_AuditLogTab> createState() => _AuditLogTabState();
}

class _AuditLogTabState extends State<_AuditLogTab> {
  List<AdminLogEntry> _entries = <AdminLogEntry>[];
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
      final entries = await AppScope.of(context).adminLogRepository.fetchRecent();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load the audit log: $e';
        });
      }
    }
  }

  static String _caps(String value) => value.toLowerCase().replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Every significant admin action is recorded here.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_error != null)
          AdminErrorBanner(message: _error!, onRetry: _load)
        else if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_entries.isEmpty)
          const AdminEmptyState(
            icon: Icons.receipt_long_outlined,
            message: 'No admin actions recorded yet.',
          )
        else
          for (final entry in _entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _caps(entry.action.key),
                            style: context.textTheme.titleSmall,
                          ),
                          Text(
                            entry.target,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (entry.timestamp != null)
                      Text(
                        friendlyDate(entry.timestamp!),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}