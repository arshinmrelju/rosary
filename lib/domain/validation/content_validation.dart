import '../models/daily_content.dart';

/// Result of validating a day's content before saving / publishing.
class ContentValidation {
  const ContentValidation({
    this.errors = const <String>[],
    this.warnings = const <String>[],
  });

  /// Blocking problems — publish must never go ahead with any of these.
  final List<String> errors;

  /// Soft concerns that do not block publishing.
  final List<String> warnings;

  bool get isValid => errors.isEmpty;

  bool get hasWarnings => warnings.isNotEmpty;
}

/// Validates a [DailyContent] document.
///
/// * Drafts only require a date (so the editor can always save work in
///   progress).
/// * Publishing requires the full student experience: mystery, intention,
///   reflection, all five decades with title + reflection.
///
/// The same rules drive the editor's live error list, the bulk importer and
/// the unit tests, so "incomplete content cannot be published" holds in one
/// place.
class DailyContentValidator {
  const DailyContentValidator();

  ContentValidation validate(DailyContent content, {bool forPublish = true}) {
    final errors = <String>[];
    final warnings = <String>[];

    if (content.date.trim().isEmpty) {
      errors.add('Date is required.');
    }

    if (forPublish) {
      if (content.mysterySetTitle.trim().isEmpty) {
        errors.add('Mystery set is required.');
      }
      if (content.intention.trim().isEmpty) {
        errors.add("Today's intention is required.");
      }
      if (content.theme != null && content.theme!.trim().isEmpty) {
        warnings.add("Today's theme is empty.");
      }
      if (content.reflection == null || content.reflection!.trim().isEmpty) {
        errors.add("Today's reflection is required.");
      }
      if (content.scripture == null || content.scripture!.trim().isEmpty) {
        warnings.add("Today's scripture is empty.");
      }

      for (var i = 1; i <= 5; i++) {
        final decade = content.decade(i);
        final label = '${_ordinal(i)} decade';
        final hasDecade = content.decades.any((d) => d.number == i);
        if (!hasDecade || decade.mysteryTitle.trim().isEmpty) {
          errors.add('$label title is missing.');
        }
        if (!hasDecade ||
            decade.reflection == null ||
            decade.reflection!.trim().isEmpty) {
          errors.add('$label reflection is missing.');
        }
        if (hasDecade &&
            (decade.scripture == null || decade.scripture!.trim().isEmpty)) {
          warnings.add('$label scripture is empty.');
        }
      }
    } else {
      if (content.date.trim().isEmpty) {
        errors.add('A date is required to save the draft.');
      }
    }

    return ContentValidation(errors: errors, warnings: warnings);
  }

  String _ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }
}