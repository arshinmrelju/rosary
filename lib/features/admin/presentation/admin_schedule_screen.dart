import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../domain/models/admin_log_entry.dart';
import '../../../../domain/models/break_time.dart';
import '../../../../domain/models/rosary_schedule_settings.dart';
import 'admin_audit.dart';
import 'widgets/admin_widgets.dart';

/// Edits the single break schedule all students follow
/// (`settings/rosarySchedule`).
class AdminScheduleScreen extends StatefulWidget {
  const AdminScheduleScreen({super.key});

  @override
  State<AdminScheduleScreen> createState() => _AdminScheduleScreenState();
}

class _AdminScheduleScreenState extends State<AdminScheduleScreen> {
  RosaryScheduleSettings? _settings;
  late int _duration;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _duration = 3;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final settings =
          await AppScope.of(context).scheduleSettingsRepository.fetch();
      if (!mounted) return;
      setState(() {
        _settings = settings ?? const RosaryScheduleSettings();
        _duration = _settings?.durationMinutes ?? 3;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load the schedule: $e';
        });
      }
    }
  }

  void _setBreak(int index, BreakTime time) {
    final current = _settings!;
    final breaks = <BreakTime>[...current.breaks];
    breaks[index] = time;
    setState(() {
      _settings = current.copyWith(breaks: breaks);
    });
  }

  Future<void> _pickTime(int index, BreakTime initial) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (picked == null) return;
    _setBreak(index, BreakTime(picked.hour, picked.minute));
  }

  Future<void> _openDefaults() async {
    await showAdminConfirm(
      context,
      title: 'Restore default times?',
      message: const Text(
        'Breaks will reset to 11:00, 12:05, 13:00, 14:00 and 15:00.',
      ),
      confirmLabel: 'Reset',
    );
    if (mounted) {
      setState(() => _settings = const RosaryScheduleSettings());
    }
  }

  bool get _canManage {
    final role = AppScope.of(context).adminSession.role;
    return role != null && role.canManageSchedule;
  }

  Future<void> _save() async {
    final settings = _settings!;
    final confirmed = await showAdminConfirm(
      context,
      title: 'Update break schedule?',
      message: Text(
        'Students will follow this schedule within one app load. Today\'s '
        'breaks: ${settings.breaks.map((b) => b.label).join(', ')}.',
      ),
      confirmLabel: 'Save schedule',
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    try {
      final updated = settings.copyWith(durationMinutes: _duration);
      await AppScope.of(context).scheduleSettingsRepository.save(updated);
      if (!mounted) return;
      await logAdminAction(
        context,
        AdminLogAction.updatedSchedule,
        updated.breaks.map((b) => b.label).join(', '),
      );
      if (!mounted) return;
      final deps = AppScope.of(context);
      // Push the new times into the student-facing reminder engine.
      try {
        await deps.notificationService.applySettings(
          updated.toBreakSchedule(),
          deps.notificationSettingsStore.settings,
        );
      } catch (_) {
        // Reminders are best-effort; the schedule itself is already saved.
      }
      if (mounted) {
        setState(() {
          _saving = false;
          _settings = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule saved and applied.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save schedule: $e')),
        );
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
            title: 'Break Schedule',
            subtitle: 'The five daily breaks students follow.',
          ),
          AdminErrorBanner(message: _error!, onRetry: _load),
        ],
      );
    }
    if (_loading || settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final breaks = settings.breaks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AdminPageHeader(
          title: 'Break Schedule',
          subtitle:
              'Stored in a single settings document, student reminders follow '
              'it automatically.',
          trailing: _canManage
              ? TextButton.icon(
                  onPressed: _openDefaults,
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('Reset defaults'),
                )
              : null,
        ),
        if (!_canManage)
          AdminErrorBanner(
            message:
                'Your role (${AppScope.of(context).adminSession.role?.label}) '
                'cannot change the schedule.',
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Breaks', style: context.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < 5; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.marianBlueSoft,
                      child: Text(
                        '${i + 1}',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: AppColors.marianBlue,
                        ),
                      ),
                    ),
                    title: Text('Break ${i + 1}'),
                    trailing: _canManage
                        ? OutlinedButton(
                            onPressed: () => _pickTime(
                              i,
                              i < breaks.length
                                  ? breaks[i]
                                  : const BreakTime(12, 0),
                            ),
                            child: Text(
                              i < breaks.length
                                  ? breaks[i].label
                                  : 'Set time',
                            ),
                          )
                        : Text(
                            i < breaks.length
                                ? breaks[i].label
                                : '—',
                            style: context.textTheme.titleSmall,
                          ),
                  ),
                ),
              const Divider(height: AppSpacing.xxl),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Active window (minutes per break)',
                      style: context.textTheme.bodyMedium,
                    ),
                  ),
                  DropdownButton<int>(
                    value: _duration.clamp(1, 15),
                    items: <DropdownMenuItem<int>>[
                      for (var i = 1; i <= 15; i++)
                        DropdownMenuItem<int>(value: i, child: Text('$i min')),
                    ],
                    onChanged: _canManage
                        ? (v) => setState(() => _duration = v ?? 3)
                        : null,
                  ),
                ],
              ),
              if (_canManage) ...<Widget>[
                const Divider(height: AppSpacing.xxl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Save & apply'),
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