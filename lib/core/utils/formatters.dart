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

/// Month-long name, e.g. "October".
String monthName(int month) {
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
  return months[month - 1];
}

/// Formats a [DateTime] as a Firestore-safe calendar-month key (`yyyy-MM`),
/// used by `monthlyStats/{month}`.
String monthKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$y-$m';
}

/// Formats the first day of the month containing [date] as `yyyy-MM-dd`.
String startOfMonthKey(DateTime date) => dateKey(DateTime(date.year, date.month));

/// Formats the last instant of the month containing [date] as `yyyy-MM-dd`.
String endOfMonthKey(DateTime date) =>
    dateKey(DateTime(date.year, date.month + 1, 0));

/// Human readable day-of-month + month, e.g. "October 1".
String friendlyMonthDay(DateTime date) =>
    '${monthName(date.month)} ${date.day}';

/// Locale-independent thousands separator, e.g. 4821 -> "4,821".
String formatThousands(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return negative ? '-$buffer' : buffer.toString();
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

/// Formats a remaining duration as `hh:mm:ss`, e.g. 4 min 32 s -> "00:04:32".
///
/// Clamps negative values to zero so a countdown stops cleanly at the break.
String formatCountdown(Duration remaining) {
  final total = remaining.isNegative ? 0 : remaining.inSeconds;
  final h = (total ~/ 3600).toString().padLeft(2, '0');
  final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
  final s = (total % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

/// Human friendly "until X" phrase, e.g. 28 min -> "Starts in 28 minutes".
String startsInCopy(Duration remaining) {
  if (remaining.isNegative || remaining.inSeconds <= 0) return 'Starting now';
  final minutes = remaining.inMinutes;
  if (minutes == 0) {
    final seconds = remaining.inSeconds;
    if (seconds <= 1) return 'Starting now';
    return 'Starts in $seconds second${seconds == 1 ? '' : 's'}';
  }
  if (minutes < 60) return 'Starts in $minutes minute${minutes == 1 ? '' : 's'}';
  final hours = minutes ~/ 60;
  final left = minutes % 60;
  if (left == 0) return 'Starts in $hours hour${hours == 1 ? '' : 's'}';
  return 'Starts in $hours h $left min';
}