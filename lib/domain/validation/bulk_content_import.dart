import 'dart:convert';

import '../models/daily_content.dart';
import '../models/decade.dart';
import 'content_validation.dart';

/// One parsed+validated entry from a bulk JSON upload.
class BulkContentEntry {
  const BulkContentEntry({
    required this.content,
    this.warnings = const <String>[],
  });

  final DailyContent content;

  /// Non-blocking concerns surfaced to the admin (missing fields the editor
  /// can complete before publishing).
  final List<String> warnings;
}

/// Result of running the whole-file validation, with per-entry details.
class BulkContentResult {
  const BulkContentResult({
    this.entries = const <BulkContentEntry>[],
    this.blockingErrors = const <String>[],
  });

  /// Valid entries (only populated when [blockingErrors] is empty).
  final List<BulkContentEntry> entries;

  /// File-level blocking problems. When non-empty the import must be refused
  /// in full — nothing is written to Firestore.
  final List<String> blockingErrors;

  bool get isValid => blockingErrors.isEmpty;

  int get warningCount => entries.fold(0, (sum, e) => sum + e.warnings.length);
}

/// Parses and validates a bulk JSON document before anything touches
/// Firestore. Every entry is checked first; on any structural error the whole
/// import is rejected (all-or-nothing).
class BulkContentImporter {
  const BulkContentImporter();

  final DailyContentValidator _validator = const DailyContentValidator();

  BulkContentResult importJson(String raw) {
    return importList(jsonDecode(raw));
  }

  BulkContentResult importList(dynamic decoded) {
    if (decoded is! List) {
      return const BulkContentResult(
        blockingErrors: <String>[
          'File must contain a list of daily content objects.',
        ],
      );
    }
    if (decoded.isEmpty) {
      return const BulkContentResult(
        blockingErrors: <String>['File is empty — nothing to import.'],
      );
    }

    final blockingErrors = <String>[];
    final entries = <BulkContentEntry>[];

    for (var i = 0; i < decoded.length; i++) {
      final item = decoded[i];
      final label = 'Item ${i + 1}';
      if (item is! Map<String, dynamic>) {
        blockingErrors.add('$label is not a JSON object.');
        continue;
      }

      final content = _parseItem(item);
      if (content == null) {
        blockingErrors.add('$label: date is invalid or missing.');
        continue;
      }

      // Blocking check: item must at least be saveable as a draft.
      final draftValidation = _validator.validate(content, forPublish: false);
      blockingErrors.addAll(
        draftValidation.errors.map((e) => '$label — $e'),
      );

      // Soft check: what would still be missing before publishing.
      final publishValidation = _validator.validate(content, forPublish: true);
      entries.add(BulkContentEntry(
        content: content,
        warnings: publishValidation.errors.map((e) => '$label — $e').toList(),
      ));
    }

    return BulkContentResult(
      entries: blockingErrors.isEmpty ? entries : const <BulkContentEntry>[],
      blockingErrors: blockingErrors,
    );
  }

  /// Reads one item into a [DailyContent]. Returns `null` when the date — the
  /// document key — is unusable.
  DailyContent? _parseItem(Map<String, dynamic> map) {
    final date = (map['date'] as String? ?? '').trim();
    final parsed = DateTime.tryParse(date);
    if (date.isEmpty || parsed == null) return null;
    if (date.length != 10 || date[4] != '-' || date[7] != '-') return null;

    final rawDecades = map['decades'] as List? ?? const <dynamic>[];
    final decades = <Decade>[];
    for (var i = 0; i < 5 && i < rawDecades.length; i++) {
      final raw = rawDecades[i];
      if (raw is! Map<String, dynamic>) continue;
      decades.add(
        Decade(
          number: i + 1,
          mysteryTitle:
              raw['title'] as String? ?? raw['mysteryTitle'] as String? ?? '',
          scripture: raw['scripture'] as String?,
          reflection: raw['reflection'] as String?,
          focus: raw['focus'] as String?,
          prayers: (raw['prayers'] as List?)?.cast<String>() ?? const <String>[],
        ),
      );
    }

    final mystery = map['mysteryType'] as String? ?? map['mystery'] as String? ?? '';
    return DailyContent(
      date: date,
      mysterySetTitle: mystery,
      theme: map['theme'] as String?,
      intention: map['intention'] as String? ?? '',
      scripture: map['scripture'] as String?,
      reflection: map['reflection'] as String?,
      decades: decades,
      published: map['published'] as bool? ?? false,
    );
  }
}