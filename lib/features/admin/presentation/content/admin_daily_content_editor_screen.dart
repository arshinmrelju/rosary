import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../domain/models/admin_log_entry.dart';
import '../../../../domain/models/daily_content.dart';
import '../../../../domain/models/decade.dart';
import '../../../../domain/validation/content_validation.dart';
import '../admin_audit.dart';
import '../widgets/admin_widgets.dart';

/// Mystery set presets offered in the editor.
const List<String> kMysterySets = <String>[
  'Joyful Mysteries',
  'Sorrowful Mysteries',
  'Glorious Mysteries',
  'Luminous Mysteries',
];

/// Editor + publisher + previewer for one day's rosaary content.
///
/// Drafts only need a date; publishing enforces the full student experience
/// via [DailyContentValidator]. Every mutation is written to the audit log.
class AdminDailyContentEditorScreen extends StatefulWidget {
  const AdminDailyContentEditorScreen({super.key, this.initialDate});

  /// `yyyy-MM-dd` key the editor opens on; defaults to today.
  final String? initialDate;

  @override
  State<AdminDailyContentEditorScreen> createState() =>
      _AdminDailyContentEditorScreenState();
}

class _AdminDailyContentEditorScreenState
    extends State<AdminDailyContentEditorScreen> {
  static const DailyContentValidator _validator = DailyContentValidator();

  late final TextEditingController _date;
  late final TextEditingController _mystery;
  late final TextEditingController _theme;
  late final TextEditingController _intention;
  late final TextEditingController _scripture;
  late final TextEditingController _reflection;

  late final List<DecadeEditorFields> _decades;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  DailyContent? _saved;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _date = TextEditingController(text: widget.initialDate ?? dateKey(clockNow()));
    _mystery = TextEditingController();
    _theme = TextEditingController();
    _intention = TextEditingController();
    _scripture = TextEditingController();
    _reflection = TextEditingController();
    _decades = <DecadeEditorFields>[
      for (var i = 1; i <= 5; i++)
        DecadeEditorFields(i, controllerState: this),
    ];
    _load();
  }

  @override
  void dispose() {
    for (final field in _decades) {
      field.dispose();
    }
    _date.dispose();
    _mystery.dispose();
    _theme.dispose();
    _intention.dispose();
    _scripture.dispose();
    _reflection.dispose();
    super.dispose();
  }

  void _markDirty() {
    _dirty = true;
    setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _saved = null;
    });
    try {
      final content = await AppScope.of(context)
          .adminContentRepository
          .fetch(_date.text.trim());
      _applyToFields(content);
      if (mounted) {
        setState(() {
          _loading = false;
          _saved = content;
          _dirty = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Could not load content for this day: $e';
        });
      }
    }
  }

  void _applyToFields(DailyContent? content) {
    final c = content;
    _mystery.text = c?.mysterySetTitle ?? 'Glorious Mysteries';
    _theme.text = c?.theme ?? '';
    _intention.text = c?.intention ?? '';
    _scripture.text = c?.scripture ?? '';
    _reflection.text = c?.reflection ?? '';
    for (final field in _decades) {
      field.apply(c?.decade(field.number));
    }
  }

  DailyContent _toContent({required bool published}) {
    return DailyContent(
      date: _date.text.trim(),
      mysterySetTitle: _mystery.text.trim(),
      theme: _theme.text.trim().isEmpty ? null : _theme.text.trim(),
      intention: _intention.text.trim(),
      scripture: _scripture.text.trim().isEmpty ? null : _scripture.text.trim(),
      reflection: _reflection.text.trim().isEmpty ? null : _reflection.text.trim(),
      decades: <Decade>[
        for (final field in _decades) field.toDecade(),
      ],
      published: published,
    );
  }

  ContentValidation _validation() =>
      _validator.validate(_toContent(published: true));

  Future<void> _pickDate() async {
    final now = clockNow();
    final initial = DateTime.tryParse(_date.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked == null) return;
    final key = dateKey(picked);
    if (key == _date.text) return;
    setState(() => _date.text = key);
    await _load();
  }

  Future<void> _saveDraft() async {
    final validation = _validator.validate(_toContent(published: false));
    if (!validation.isValid) {
      _showErrors(validation);
      return;
    }
    setState(() => _saving = true);
    try {
      await AppScope.of(context)
          .adminContentRepository
          .saveDraft(_toContent(published: false));
      if (!mounted) return;
      await logAdminAction(
        context,
        AdminLogAction.savedDailyContentDraft,
        '${_date.text} daily content',
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _dirty = false;
          _saved = _toContent(published: false);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved.')),
        );
      }
    } catch (e) {
      _failSave(e);
    }
  }

  Future<void> _publish() async {
    final validation = _validation();
    if (!validation.isValid) {
      _showErrors(validation);
      return;
    }
    final confirmed = await showAdminConfirm(
      context,
      title: 'Publish this content?',
      message: Text(
        'Students will immediately see the content for ${friendlyDate(DateTime.parse(_date.text))}. '
        'Incomplete or unexpected content is discouraged.',
      ),
      confirmLabel: 'Yes, publish',
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    try {
      await AppScope.of(context)
          .adminContentRepository
          .publish(_toContent(published: true));
      if (!mounted) return;
      await logAdminAction(
        context,
        AdminLogAction.publishedDailyContent,
        '${_date.text} daily content',
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _dirty = false;
          _saved = _toContent(published: true);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Published for students.')),
        );
      }
    } catch (e) {
      _failSave(e);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showAdminConfirm(
      context,
      title: 'Delete ${_date.text}?',
      message: const Text(
        'This removes the content entirely. Students will see nothing for this '
        'day. This cannot be undone.',
      ),
      confirmLabel: 'Delete forever',
      confirmColor: AppColors.error,
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    try {
      await AppScope.of(context).adminContentRepository.delete(_date.text.trim());
      if (!mounted) return;
      await logAdminAction(
        context,
        AdminLogAction.deletedDailyContent,
        '${_date.text} daily content',
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _saved = null;
          _dirty = false;
        });
        _applyToFields(null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content deleted.')),
        );
      }
    } catch (e) {
      _failSave(e);
    }
  }

  void _failSave(Object error) {
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $error')),
      );
    }
  }

  void _showErrors(ContentValidation validation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(validation.errors.first),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: AdminErrorBanner(
          message: _loadError!,
          onRetry: _load,
        ),
      );
    }
    final validation = _validation();
    final canEdit = AppScope.of(context).adminSession.role?.canEditContent ?? false;
    final canDelete =
        AppScope.of(context).adminSession.role?.canDeleteContent ?? false;
    final date = DateTime.tryParse(_date.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AdminPageHeader(
          title: 'Daily Content',
          subtitle: _saved?.published == true
              ? 'Published · students can see this'
              : _saved != null
                  ? 'Draft · not visible to students yet'
                  : 'Nothing saved for this day yet',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event, size: 18),
                label: Text(date == null ? _date.text : friendlyMonthDay(date)),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Preview',
                onPressed: () => _showPreview(context),
                icon: const Icon(Icons.visibility_outlined),
              ),
            ],
          ),
        ),
        if (validation.errors.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: AdminErrorBanner(
              message:
                  '${validation.errors.length} item(s) block publishing — '
                  'see the list below.',
            ),
          ),
        if (!canEdit) ...<Widget>[
          AdminErrorBanner(
            message:
                'Your role (${AppScope.of(context).adminSession.role?.label}) '
                'cannot edit content.',
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        _FieldsColumn(
          date: _date,
          mystery: _mystery,
          theme: _theme,
          intention: _intention,
          scripture: _scripture,
          reflection: _reflection,
          decades: _decades,
          onChanged: _markDirty,
          onPickDate: _pickDate,
        ),
        const SizedBox(height: AppSpacing.xl),
        _ValidationPanel(validation: validation),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: <Widget>[
            if (canEdit) ...<Widget>[
              OutlinedButton.icon(
                onPressed: _saving ? null : _saveDraft,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save Draft'),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: _saving ? null : _publish,
                icon: const Icon(Icons.publish, size: 18),
                label: const Text('Publish'),
              ),
            ],
            const Spacer(),
            if (canDelete && (_saved != null || _dirty))
              TextButton.icon(
                onPressed: _saving ? null : _delete,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
              ),
          ],
        ),
      ],
    );
  }

  void _showPreview(BuildContext context) {
    final content = _toContent(published: true);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Preview · ${friendlyDate(DateTime.parse(content.date))}'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(content.mysterySetTitle,
                    style: context.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  content.intention,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.marianBlue,
                  ),
                ),
                if (content.theme != null && content.theme!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text('Theme · ${content.theme}'),
                ],
                if (content.scripture != null && content.scripture!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(content.scripture!, style: context.textTheme.bodySmall),
                ],
                if (content.reflection != null && content.reflection!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(content.reflection!),
                ],
                const Divider(height: AppSpacing.xxl),
                for (final decade in content.decades) ...<Widget>[
                  Text(
                    'Decade ${decade.number} · ${decade.mysteryTitle}',
                    style: context.textTheme.titleSmall,
                  ),
                  if (decade.focus != null && decade.focus!.isNotEmpty)
                    Text('Focus · ${decade.focus}'),
                  if (decade.scripture != null && decade.scripture!.isNotEmpty)
                    Text(decade.scripture!, style: context.textTheme.bodySmall),
                  if (decade.reflection != null && decade.reflection!.isNotEmpty)
                    Text(decade.reflection!),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Holds the text controllers for one decade in the editor.
class DecadeEditorFields {
  DecadeEditorFields(this.number, {required this.controllerState});

  final int number;
  final State<AdminDailyContentEditorScreen> controllerState;

  late final TextEditingController title = TextEditingController();
  late final TextEditingController focus = TextEditingController();
  late final TextEditingController scripture = TextEditingController();
  late final TextEditingController reflection = TextEditingController();

  void apply(Decade? decade) {
    if (decade == null) {
      title.text = '';
      focus.text = '';
      scripture.text = '';
      reflection.text = '';
      return;
    }
    title.text = decade.mysteryTitle;
    focus.text = decade.focus ?? '';
    scripture.text = decade.scripture ?? '';
    reflection.text = decade.reflection ?? '';
  }

  Decade toDecade() => Decade(
    number: number,
    mysteryTitle: title.text.trim(),
    focus: focus.text.trim().isEmpty ? null : focus.text.trim(),
    scripture: scripture.text.trim().isEmpty ? null : scripture.text.trim(),
    reflection: reflection.text.trim().isEmpty ? null : reflection.text.trim(),
  );

  void dispose() {
    title.dispose();
    focus.dispose();
    scripture.dispose();
    reflection.dispose();
  }
}

class _FieldsColumn extends StatelessWidget {
  const _FieldsColumn({
    required this.date,
    required this.mystery,
    required this.theme,
    required this.intention,
    required this.scripture,
    required this.reflection,
    required this.decades,
    required this.onChanged,
    required this.onPickDate,
  });

  final TextEditingController date;
  final TextEditingController mystery;
  final TextEditingController theme;
  final TextEditingController intention;
  final TextEditingController scripture;
  final TextEditingController reflection;
  final List<DecadeEditorFields> decades;
  final VoidCallback onChanged;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: date,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    helperText: 'yyyy-MM-dd',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_month_outlined),
                tooltip: 'Pick a date',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _MysterySetDropdown(controller: mystery, onChanged: onChanged),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: theme,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Today\'s theme (one line)',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: intention,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Today\'s intention',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: scripture,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Day scripture',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: reflection,
            onChanged: (_) => onChanged(),
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Day reflection',
            ),
          ),
          const Divider(height: AppSpacing.xxxl),
          Text('The five decades', style: context.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final field in decades) ...<Widget>[
            _DecadeEditor(field: field, onChanged: onChanged),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _MysterySetDropdown extends StatelessWidget {
  const _MysterySetDropdown({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final current = controller.text.trim();
    final options = kMysterySets.contains(current) || current.isEmpty
        ? kMysterySets
        : <String>[...kMysterySets, current];
    final selected = options.contains(current)
        ? current
        : kMysterySets.first;

    return DropdownButtonFormField<String>(
      key: ValueKey<String>('mystery-set-$current'),
      initialValue: selected,
      decoration: const InputDecoration(labelText: 'Mystery set'),
      items: <DropdownMenuItem<String>>[
        for (final set in options)
          DropdownMenuItem<String>(value: set, child: Text(set)),
      ],
      onChanged: (value) {
        if (value != null) {
          controller.text = value;
          onChanged();
        }
      },
    );
  }
}

class _DecadeEditor extends StatelessWidget {
  const _DecadeEditor({required this.field, required this.onChanged});

  final DecadeEditorFields field;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final has = field.title.text.trim().isNotEmpty ||
        field.focus.text.trim().isNotEmpty ||
        field.scripture.text.trim().isNotEmpty ||
        field.reflection.text.trim().isNotEmpty;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Decade ${field.number}${has ? ' · ${field.title.text.trim()}' : ''}',
            style: context.textTheme.titleSmall?.copyWith(
              color: AppColors.marianBlue,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: field.title,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(labelText: 'Mystery title'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: field.focus,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(labelText: 'Focus (one line)'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: field.scripture,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(labelText: 'Scripture'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: field.reflection,
            onChanged: (_) => onChanged(),
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Reflection'),
          ),
        ],
      ),
    );
  }
}

class _ValidationPanel extends StatelessWidget {
  const _ValidationPanel({required this.validation});

  final ContentValidation validation;

  @override
  Widget build(BuildContext context) {
    if (validation.errors.isEmpty && !validation.hasWarnings) {
      return RichText(
        text: TextSpan(
          style: context.textTheme.bodySmall?.copyWith(
            color: AppColors.success,
          ),
          children: const <TextSpan>[
            TextSpan(text: '✓ '),
            TextSpan(text: 'This content is ready to publish.'),
          ],
        ),
      );
    }
    return AppCard(
      color: AppColors.surfaceMuted,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (validation.errors.isNotEmpty) ...<Widget>[
            Text('Blocks publishing',
                style: context.textTheme.titleSmall
                    ?.copyWith(color: AppColors.error)),
            const SizedBox(height: AppSpacing.sm),
            for (final error in validation.errors)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.cancel_outlined,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(error, style: context.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
          ],
          if (validation.hasWarnings) ...<Widget>[
            if (validation.errors.isNotEmpty) const SizedBox(height: AppSpacing.md),
            Text('Warnings', style: context.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            for (final warning in validation.warnings)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.warning_amber_outlined,
                        size: 16, color: AppColors.goldDark),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(warning, style: context.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}