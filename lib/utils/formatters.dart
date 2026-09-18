import 'package:intl/intl.dart';

/// Extension to format numbers with localized thousands separators and precision.
extension NumberFormatting on num {
  /// Formats number according to user locale (e.g. 1,234 in US, 1.234 in Germany).
  String toLocaleString([String? locale]) {
    return NumberFormat.decimalPattern(locale).format(this);
  }
}

/// Extension to format dates cleanly and in accordance with user locale.
extension DateTimeFormatting on DateTime {
  /// Standard localized date: e.g. "Jul 24, 2026" or "24 Jul 2026"
  String toLocalizedDate([String? locale]) {
    return DateFormat.yMMMd(locale).format(this);
  }

  /// Full localized date with weekday: e.g. "Friday, Jul 24, 2026"
  String toLocalizedFullDate([String? locale]) {
    return DateFormat.yMMMMEEEEd(locale).format(this);
  }

  /// Month and year: e.g. "July 2026"
  String toLocalizedMonth([String? locale]) {
    return DateFormat.yMMMM(locale).format(this);
  }

  /// Short month and year: e.g. "Jul 2026"
  String toLocalizedShortMonth([String? locale]) {
    return DateFormat.yMMM(locale).format(this);
  }

  /// Weekday with short date: e.g. "Friday, Jul 24"
  String toLocalizedWeekdayDate([String? locale]) {
    return DateFormat('EEEE, MMM d', locale).format(this);
  }

  /// Weekday name: e.g. "Monday"
  String toWeekdayName([String? locale]) {
    return DateFormat.EEEE(locale).format(this);
  }
}
