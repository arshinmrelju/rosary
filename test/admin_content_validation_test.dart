import 'package:flutter_test/flutter_test.dart';

import 'package:rosary_break/core/utils/formatters.dart';
import 'package:rosary_break/domain/models/daily_content.dart';
import 'package:rosary_break/domain/models/decade.dart';
import 'package:rosary_break/domain/validation/bulk_content_import.dart';
import 'package:rosary_break/domain/validation/content_validation.dart';

DailyContent _draftOnly(String date) => DailyContent(
      date: date,
      mysterySetTitle: '',
      intention: '',
      published: false,
    );

DailyContent _complete(String date) => DailyContent(
      date: date,
      mysterySetTitle: 'Joyful Mysteries',
      intention: 'For peace',
      theme: 'Trust',
      scripture: 'Luke 1:38',
      reflection: 'Mary said yes.',
      published: false,
      decades: <Decade>[
        for (var i = 1; i <= 5; i++)
          Decade(
            number: i,
            mysteryTitle: 'Mystery $i',
            reflection: 'Reflection $i',
          ),
      ],
    );

void main() {
  const validator = DailyContentValidator();

  group('DailyContentValidator', () {
    test('a date-only draft is valid as a draft', () {
      final result = validator.validate(_draftOnly('2026-10-01'),
          forPublish: false);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('a blank date always fails', () {
      final result = validator.validate(_draftOnly(''), forPublish: false);
      expect(result.isValid, isFalse);
      expect(result.errors, contains('A date is required to save the draft.'));
    });

    test('publish requires mystery + intention + reflection', () {
      final result = validator.validate(_draftOnly('2026-10-01'));
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Mystery set is required.'));
      expect(result.errors, contains("Today's intention is required."));
      expect(result.errors, contains("Today's reflection is required."));
    });

    test('publish requires all five decades with title + reflection', () {
      final result = validator.validate(_complete('2026-10-01'));
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('a single incomplete decade blocks publishing', () {
      final content = _complete('2026-10-01');
      final decades = <Decade>[
        for (final d in content.decades)
          if (d.number == 3)
            Decade(number: 3, mysteryTitle: '')
          else
            d,
      ];
      final result = validator.validate(
        DailyContent(
          date: content.date,
          mysterySetTitle: content.mysterySetTitle,
          intention: content.intention,
          theme: content.theme,
          scripture: content.scripture,
          reflection: content.reflection,
          decades: decades,
          published: content.published,
        ),
      );
      expect(result.isValid, isFalse);
      expect(
        result.errors,
        contains('3rd decade title is missing.'),
      );
    });

    test('empty scripture is a warning, not an error', () {
      final content = _complete('2026-10-01');
      final result = validator.validate(
        DailyContent(
          date: content.date,
          mysterySetTitle: content.mysterySetTitle,
          intention: content.intention,
          theme: content.theme,
          scripture: '',
          reflection: content.reflection,
          decades: content.decades,
          published: content.published,
        ),
      );
      expect(result.isValid, isTrue);
      expect(result.hasWarnings, isTrue);
    });
  });

  group('BulkContentImporter — all-or-nothing', () {
    test('valid list yields entries with publish warnings surfaced', () {
      final raw = '''
      [
        {
          "date": "2026-11-01",
          "mystery": "Joyful Mysteries",
          "intention": "For families",
          "reflection": "A reflection.",
          "decades": [
            {"title": "The Annunciation"},
            {"title": "The Visitation"},
            {"title": "The Nativity"},
            {"title": "The Presentation"},
            {"title": "The Finding in the Temple"}
          ]
        }
      ]
      ''';
      final result = const BulkContentImporter().importJson(raw);
      expect(result.isValid, isTrue);
      expect(result.entries, hasLength(1));
      expect(result.entries.first.content.mysterySetTitle, 'Joyful Mysteries');
      // Missing decade reflections become warnings, but never block the file.
      expect(result.warningCount, greaterThan(0));
    });

    test('non-list input is refused in full', () {
      final result = const BulkContentImporter().importJson('{"date":"x"}');
      expect(result.isValid, isFalse);
      expect(result.entries, isEmpty);
      expect(result.blockingErrors.first, contains('list'));
    });

    test('a single invalid item refuses the ENTIRE import', () {
      final raw = '''
      [
        {"date": "2026-11-01", "mystery": "Joyful Mysteries"},
        {"date": "not-a-date", "mystery": "Joyful Mysteries"}
      ]
      ''';
      final result = const BulkContentImporter().importJson(raw);
      expect(result.isValid, isFalse);
      // All-or-nothing: even the valid-looking first item is not imported.
      expect(result.entries, isEmpty);
      expect(result.blockingErrors, hasLength(1));
    });

    test('empty file is refused', () {
      final result = const BulkContentImporter().importJson('[]');
      expect(result.isValid, isFalse);
      expect(result.blockingErrors.first, contains('empty'));
    });

    test('malformed JSON surfaces a throw, not a partial result', () {
      expect(
        () => const BulkContentImporter().importJson('{ oops'),
        throwsA(isA<FormatException>()),
      );
    });

    test('dates from the importer keep the Firestore yyyy-MM-dd shape', () {
      final raw = '[{"date": "2026-11-30", "mystery": "Glorious Mysteries"}]';
      final result = const BulkContentImporter().importJson(raw);
      expect(result.entries.single.content.date, '2026-11-30');
      expect(dateKey(DateTime(2026, 11, 30)), result.entries.single.content.date);
    });
  });
}