import 'app_localizations.dart';

/// Month names in the current language.
///
/// Three screens each carried their own list — one of short names, two of
/// long ones — so a date read Hebrew even with the app set to English. The
/// lists live in the translations now, and this is how a screen reaches them
/// by month number.
extension MonthNames on L {
  /// 1 = January. Short form, for a date badge.
  String monthShort(int month) => switch (month) {
    1 => monthShortJan,
    2 => monthShortFeb,
    3 => monthShortMar,
    4 => monthShortApr,
    5 => monthShortMay,
    6 => monthShortJun,
    7 => monthShortJul,
    8 => monthShortAug,
    9 => monthShortSep,
    10 => monthShortOct,
    11 => monthShortNov,
    _ => monthShortDec,
  };

  /// 1 = January. Full form, for a line of prose.
  String monthLong(int month) => switch (month) {
    1 => monthJan,
    2 => monthFeb,
    3 => monthMar,
    4 => monthApr,
    5 => monthMay,
    6 => monthJun,
    7 => monthJul,
    8 => monthAug,
    9 => monthSep,
    10 => monthOct,
    11 => monthNov,
    _ => monthDec,
  };
}
