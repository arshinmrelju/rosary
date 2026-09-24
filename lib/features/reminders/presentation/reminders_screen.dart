import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_content_frame.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../data/notifications/notification_settings_store.dart';
import '../../../domain/models/notification_settings.dart';
import '../../../domain/schedule/break_schedule.dart';

/// Daily reminder preferences.
///
/// Owns the three decisions the notification architecture supports:
///   * which breaks should remind (master + per-break switches),
///   * how far ahead to warn (2 / 5 minutes, or off),
///   * quiet mode (only the at-break tap, nothing in advance).
///
/// Every change persists locally and re-schedules the platform notifications
/// by calling `notificationService.applySettings`.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  NotificationSettingsStore? _store;
  BreakSchedule? _schedule;
  bool? _permission;
  bool _loading = true;
  bool _wired = false;

  Future<void> _load() async {
    final deps = AppScope.of(context);
    final store = deps.notificationSettingsStore;
    _store = store;
    _schedule = await deps.breakScheduleSource.load();
    _permission = await deps.notificationService.hasPermission();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _change(
    NotificationSettings Function(NotificationSettings) update,
  ) async {
    final deps = AppScope.of(context);
    final store = _store;
    if (store == null) return;
    final next = await store.update(update);
    final schedule = _schedule;
    if (schedule != null) {
      await deps.notificationService.applySettings(schedule, next);
    }
  }

  Future<void> _enableNotifications() async {
    final deps = AppScope.of(context);
    final granted = await deps.notificationService.requestPermission();
    if (granted == true) {
      setState(() => _permission = true);
      final store = _store;
      final schedule = _schedule;
      if (store != null && schedule != null) {
        await deps.notificationService.applySettings(schedule, store.settings);
      }
    } else if (granted == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notifications are turned off for Rosary Break. '
              'You can allow them in your device settings.',
            ),
          ),
        );
      }
      setState(() => _permission = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    _store ??= deps.notificationSettingsStore;
    if (!_wired) {
      _wired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }

    return Scaffold(
      body: SafeArea(
        child: AppContentFrame(
          child: _loading || _store == null
              ? const AppLoadingView(message: 'Loading reminder settings…')
              : ListenableBuilder(
                  listenable: _store!,
                  builder: (context, _) {
                    final settings = _store!.settings;
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      children: <Widget>[
                        _BackBar(title: 'Reminders'),
                        const SizedBox(height: AppSpacing.lg),

                        Text(
                          'Your five daily reminders',
                          style: context.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A soft tap before each Rosary break — never a '
                          'demand, always an invitation.',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        if (_permission == false) ...<Widget>[
                          _PermissionCard(onEnable: _enableNotifications),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        AppCard(
                          child: SwitchListTile(
                            value: settings.masterEnabled,
                            onChanged: (v) => _change(
                              (s) => s.copyWith(masterEnabled: v),
                            ),
                            title: Text(
                              'Break reminders',
                              style: context.textTheme.titleSmall,
                            ),
                            subtitle: Text(
                              'Remind me near each of the five breaks.',
                              style: context.textTheme.bodySmall,
                            ),
                            activeThumbColor: AppColors.marianBlue,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        Text(
                          'WHICH BREAKS',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: AppColors.goldDark,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppCard(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          child: Column(
                            children: <Widget>[
                              for (var n = 1; n <= BreakSchedule.totalDecades; n++)
                                _BreakToggle(
                                  decade: n,
                                  label: '${ordinal(n)} Decade',
                                  time: _schedule
                                      ?.slotForDecade(n)
                                      .time
                                      .label,
                                  enabled: settings.breakEnabledAt(n) &&
                                      settings.masterEnabled,
                                  masterOn: settings.masterEnabled,
                                  onChanged: (v) => _change(
                                    (s) {
                                      final breaks = List<bool>.of(s.breakEnabled);
                                      breaks[n - 1] = v;
                                      return s.copyWith(breakEnabled: breaks);
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        Text(
                          'HEADS-UP TIMING',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: AppColors.goldDark,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Remind me before each break',
                                style: context.textTheme.titleSmall,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: <Widget>[
                                  for (final minutes in NotificationSettings.remindChoices)
                                    ChoiceChip(
                                      label: Text(
                                        minutes == 0
                                            ? 'Right at the break'
                                            : '$minutes min before',
                                      ),
                                      selected: settings.remindMinutes == minutes,
                                      onSelected: settings.masterEnabled &&
                                              !settings.quiet
                                          ? (_) => _change(
                                                (s) => s.copyWith(
                                                  remindMinutes: minutes,
                                                ),
                                              )
                                          : null,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        AppCard(
                          child: SwitchListTile(
                            value: settings.quiet,
                            onChanged: settings.masterEnabled
                                ? (v) => _change((s) => s.copyWith(quiet: v))
                                : null,
                            title: Text('Quiet mode', style: context.textTheme.titleSmall),
                            subtitle: Text(
                              'Only a gentle tap at the break itself — '
                              'nothing ahead of time.',
                              style: context.textTheme.bodySmall,
                            ),
                            activeThumbColor: AppColors.marianBlue,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        Center(
                          child: Text(
                            'Reminders are scheduled locally in your timezone.',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    );
                  },
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

class _BreakToggle extends StatelessWidget {
  const _BreakToggle({
    required this.decade,
    required this.label,
    required this.time,
    required this.enabled,
    required this.masterOn,
    required this.onChanged,
  });

  final int decade;
  final String label;
  final String? time;
  final bool enabled;
  final bool masterOn;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: enabled,
      onChanged: masterOn ? onChanged : null,
      secondary: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.marianBlueSoft,
        ),
        alignment: Alignment.center,
        child: Text(
          '$decade',
          style: context.textTheme.titleSmall?.copyWith(color: AppColors.marianBlue),
        ),
      ),
      title: Text(label, style: context.textTheme.titleSmall),
      subtitle: time == null
          ? null
          : Text('Break at $time', style: context.textTheme.bodySmall),
      activeThumbColor: AppColors.marianBlue,
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.onEnable});

  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.goldSoft.withValues(alpha: 0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'ALLOW REMINDERS',
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.goldDark,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your device needs permission before Rosary Break can remind you '
            'about the five daily breaks.',
            style: context.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSecondaryButton(
            label: 'Allow notifications',
            icon: Icons.notifications_active_outlined,
            onPressed: onEnable,
          ),
        ],
      ),
    );
  }
}