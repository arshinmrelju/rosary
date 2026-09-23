/// Date/time helpers shared across the app.
library;

/// Returns the current wall-clock time as a [DateTime] in the local zone.
///
/// Wrapped so screens/controllers never depend on `DateTime.now()` directly,
/// which keeps scheduled behaviour testable.
DateTime clockNow() => DateTime.now();

/// True when the two dates refer to the same calendar day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Formats a [DateTime] as a Firestore-safe key (`yyyy-MM-dd`).
String dateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Human readable date, e.g. "Tuesday, 23 September".
String friendlyDate(DateTime date) {
  const List<String> weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const List<String> months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}

/// Short day label, e.g. "Tue".
String shortWeekday(DateTime date) {
  const List<String> weekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  return weekdays[date.weekday - 1];
}

/// Formats an hour/minute pair as `h:mm AM/PM`.
String formatHourMinute(int hour, int minute) {
  final period = hour >= 12 ? 'PM' : 'AM';
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  final m = minute.toString().padLeft(2, '0');
  return '$h12:$m $period';
}

/// Ordinal suffix for a number, e.g. 1 -> "1st", 3 -> "3rd".
String ordinal(int n) {
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