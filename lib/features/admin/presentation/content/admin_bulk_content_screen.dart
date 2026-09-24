import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../domain/models/admin_log_entry.dart';
import '../../../../domain/models/daily_content.dart';
import '../../../../domain/validation/bulk_content_import.dart';
import '../admin_audit.dart';
import '../widgets/admin_widgets.dart';

String _kSampleJson() {
  const Map<String, dynamic> one = <String, dynamic>{
    'date': '2026-11-01',
    'mystery': 'Joyful Mysteries',
    'theme': 'Saying yes to God',
    'intention': 'For families beginning the season of hope.',
    'reflection': 'Mary\'s fiat teaches us to trust.',
    'decades': <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'The Annunciation',
        'focus': 'Let it be done',
        'reflection': 'Faith responds with open hands.',
      },
      <String, dynamic>{
        'title': 'The Visitation',
        'focus': 'Service',
        'reflection': 'Love carries each other.',
      },
      <String, dynamic>{
        'title': 'The Nativity',
        'focus': 'Humility',
        'reflection': 'God enters our poverty.',
      },
      <String, dynamic>{
        'title': 'The Presentation',
        'focus': 'Obedience',
        'reflection': 'We return to God what is His.',
      },
      <String, dynamic>{
        'title': 'The Finding in the Temple',
        'focus': 'Seeking wisdom',
        'reflection': 'Growth comes through searching.',
      },
    ],
  };
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(<Map<String, dynamic>>[one]);
}

/// Bulk imports daily content from a pasted JSON list.
///
/// Every entry is validated first; on ANY structural error the whole import is
/// refused (all-or-nothing). Valid imports are written as drafts that the
/// editor can polish before publishing.
class AdminBulkContentScreen extends StatefulWidget {
  const AdminBulkContentScreen({super.key});

  @override
  State<AdminBulkContentScreen> createState() => _AdminBulkContentScreenState();
}

class _AdminBulkContentScreenState extends State<AdminBulkContentScreen> {
  final TextEditingController _controller = TextEditingController();
  BulkContentResult? _result;
  bool _saving = false;
  String? _parseError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parse() {
    try {
      final result = const BulkContentImporter().importJson(_controller.text);
      setState(() {
        _result = result;
        _parseError = result.isValid ? null : 'File-level problems found.';
      });
    } catch (e) {
      setState(() {
        _result = null;
        _parseError = 'Could not parse as JSON: $e';
      });
    }
  }

  Future<void> _import() async {
    final result = _result;
    if (result == null || !result.isValid) return;
    final confirmed = await showAdminConfirm(
      context,
      title: 'Import ${result.entries.length} day(s)?',
      message: const Text(
        'Everything will be saved as a draft. You can still edit and publish '
        'each day from the calendar.',
      ),
      confirmLabel: 'Import drafts',
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    try {
      final repo = AppScope.of(context).adminContentRepository;
      for (final entry in result.entries) {
        final content = entry.content;
        await repo.saveDraft(
          DailyContent(
            date: content.date,
            mysterySetTitle: content.mysterySetTitle,
            intention: content.intention,
            theme: content.theme,
            scripture: content.scripture,
            reflection: content.reflection,
            decades: content.decades,
            published: false,
          ),
        );
      }
      if (!mounted) return;
      await logAdminAction(
        context,
        AdminLogAction.importedBulkContent,
        '${result.entries.length} days imported',
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _result = null;
          _controller.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.entries.length} day(s) imported.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final canEdit = AppScope.of(context).adminSession.role?.canEditContent ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AdminPageHeader(
          title: 'Bulk Content',
          subtitle: 'Paste a JSON list of daily content to import as drafts.',
          trailing: TextButton.icon(
            onPressed: () {
              setState(() {
                _controller.text = _kSampleJson();
                _result = null;
                _parseError = null;
              });
            },
            icon: const Icon(Icons.description_outlined, size: 18),
            label: const Text('Load sample'),
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _controller,
                maxLines: 14,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
                onChanged: (_) => setState(() {
                  _result = null;
                  _parseError = null;
                }),
                decoration: const InputDecoration(
                  hintText: '[{ "date": "2026-11-01", "mystery": "Joyful '
                      'Mysteries", "intention": "...", "decades": [...] }, ...]',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: _parse,
                    icon: const Icon(Icons.rule, size: 18),
                    label: const Text('Validate & preview'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (canEdit && result != null && result.isValid)
                    FilledButton.icon(
                      onPressed: _saving ? null : _import,
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Import'),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (_parseError != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          AdminErrorBanner(message: _parseError!),
        ],
        if (result != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          if (result.isValid) ...<Widget>[
            AdminPill(
              label: '${result.entries.length} valid · ${result.warningCount} '
                  'warnings that still allow saving',
              color: AppColors.successSoft,
              foregroundColor: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final entry in result.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            entry.content.date,
                            style: context.textTheme.titleSmall,
                          ),
                          const Spacer(),
                          if (entry.warnings.isNotEmpty)
                            AdminPill(
                              label: '${entry.warnings.length} warning(s)',
                              color: AppColors.goldSoft,
                              foregroundColor: AppColors.goldDark,
                            )
                          else
                            const AdminPill(
                              label: 'Ready to publish',
                              color: AppColors.successSoft,
                              foregroundColor: AppColors.success,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${entry.content.mysterySetTitle} · ${entry.content.intention}',
                        style: context.textTheme.bodyMedium,
                      ),
                      if (entry.warnings.isNotEmpty) ...<Widget>[
                        const Divider(height: AppSpacing.xxl),
                        for (final warning in entry.warnings)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Icon(Icons.warning_amber_outlined,
                                    size: 16, color: AppColors.goldDark),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    warning,
                                    style: context.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
          ] else ...<Widget>[
            AdminErrorBanner(
              message: 'Nothing was written. Fix the problems and validate '
                  'again — the import is refused as a whole.',
            ),
            const SizedBox(height: AppSpacing.md),
            for (final error in result.blockingErrors)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• $error',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }
}