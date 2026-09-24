import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../domain/models/admin_log_entry.dart';
import '../../../../domain/models/break_time.dart';
import '../../../../domain/models/campaign_settings.dart';
import 'admin_audit.dart';
import 'widgets/admin_widgets.dart';

/// Campaign-wide configuration: name, window and the single pause switch.
class AdminCampaignScreen extends StatefulWidget {
  const AdminCampaignScreen({super.key});

  @override
  State<AdminCampaignScreen> createState() => _AdminCampaignScreenState();
}

class _AdminCampaignScreenState extends State<AdminCampaignScreen> {
  CampaignSettings? _settings;
  late final TextEditingController _name;
  late final TextEditingController _timezone;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _timezone = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _timezone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final settings =
          await AppScope.of(context).campaignRepository.fetch();
      if (!mounted) return;
      _apply(settings ?? const CampaignSettings());
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load campaign settings: $e';
        });
      }
    }
  }

  void _apply(CampaignSettings settings) {
    _name.text = settings.name;
    _timezone.text = settings.timezone;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  bool get _canManage {
    final role = AppScope.of(context).adminSession.role;
    return role != null && role.canManageCampaign;
  }

  Future<void> _pickDate({required bool start}) async {
    final current = _settings!;
    final initial =
        start ? current.startDate ?? clockNow() : current.endDate ?? clockNow();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 1),
      lastDate: DateTime(initial.year + 2, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      _settings = start
          ? current.copyWith(
              startDate: DateTime(picked.year, picked.month, picked.day))
          : current.copyWith(
              endDate: DateTime(picked.year, picked.month, picked.day));
    });
  }

  Future<void> _pickCollegeTime({required bool start}) async {
    final current = _settings!;
    final initial = start ? current.collegeStart : current.collegeEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (picked == null) return;
    final time = BreakTime(picked.hour, picked.minute);
    setState(() {
      _settings = start
          ? current.copyWith(collegeStart: time)
          : current.copyWith(collegeEnd: time);
    });
  }

  Future<void> _togglePause(bool paused) async {
    final current = _settings!;
    final updated = current.copyWith(paused: paused);
    setState(() => _settings = updated);
    await _save(silent: true, forcePauseLog: paused);
  }

  Future<void> _save({bool silent = false, bool? forcePauseLog}) async {
    final current = _settings!;
    final confirmed = silent
        ? true
        : await showAdminConfirm(
            context,
            title: 'Save campaign settings?',
            message: Text(
              'These apply immediately across the student app.'
              '${current.paused ? ' The campaign is currently paused.' : ''}',
            ),
            confirmLabel: 'Save settings',
          );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    try {
      final updated = current.copyWith(
        name: _name.text.trim().isEmpty ? current.name : _name.text.trim(),
        timezone: _timezone.text.trim().isEmpty
            ? current.timezone
            : _timezone.text.trim(),
      );
      await AppScope.of(context).campaignRepository.save(updated);
      final pausedChanged = updated.paused != current.paused;
      final action = forcePauseLog == true
          ? AdminLogAction.pausedCampaign
          : forcePauseLog == false
              ? AdminLogAction.resumedCampaign
              : pausedChanged
                  ? (updated.paused
                      ? AdminLogAction.pausedCampaign
                      : AdminLogAction.resumedCampaign)
                  : AdminLogAction.updatedCampaign;
      if (!mounted) return;
      await logAdminAction(context, action, updated.name);
      if (mounted) {
        _apply(updated);
        setState(() => _saving = false);
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Campaign settings saved.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save campaign: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AdminPageHeader(
            title: 'Campaign',
            subtitle: 'Campaign-wide configuration and the pause switch.',
          ),
          AdminErrorBanner(message: _error!, onRetry: _load),
        ],
      );
    }
    if (_loading || settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AdminPageHeader(
          title: 'Campaign',
          subtitle: settings.paused
              ? 'Paused — students see a calm message instead of breaks.'
              : 'Live — breaks and prayer wall are active.',
          trailing: _canManage
              ? Switch(
                  value: !settings.paused,
                  onChanged: _saving ? null : (on) => _togglePause(!on),
                )
              : null,
        ),
        if (!_canManage)
          AdminErrorBanner(
            message:
                'Your role (${AppScope.of(context).adminSession.role?.label}) '
                'cannot manage the campaign.',
          ),
        if (settings.paused)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: AppCard(
              color: AppColors.goldSoft,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.pause_circle_outline,
                      color: AppColors.goldDark),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Paused. Your organizers can resume at any time.',
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: AppColors.goldDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _name,
                enabled: _canManage,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Campaign name'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Campaign window', style: context.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _canManage
                          ? () => _pickDate(start: true)
                          : null,
                      icon: const Icon(Icons.date_range_outlined, size: 18),
                      label: Text(
                        settings.startDate == null
                            ? 'No start'
                            : friendlyMonthDay(settings.startDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Text('→'),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _canManage
                          ? () => _pickDate(start: false)
                          : null,
                      icon: const Icon(Icons.date_range_outlined, size: 18),
                      label: Text(
                        settings.endDate == null
                            ? 'No end'
                            : friendlyMonthDay(settings.endDate!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _canManage
                          ? () => _pickCollegeTime(start: true)
                          : null,
                      icon: const Icon(Icons.schedule, size: 18),
                      label: Text(
                        'College start ${settings.collegeStart.label}',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _canManage
                          ? () => _pickCollegeTime(start: false)
                          : null,
                      icon: const Icon(Icons.schedule, size: 18),
                      label: Text('College end ${settings.collegeEnd.label}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _timezone,
                enabled: _canManage,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Timezone',
                  helperText: 'IANA zone name, e.g. Asia/Kolkata',
                ),
              ),
              if (_canManage) ...<Widget>[
                const Divider(height: AppSpacing.xxl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _saving ? null : () => _save(),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Save settings'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}