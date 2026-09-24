// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class LHe extends L {
  LHe([String locale = 'he']) : super(locale);

  @override
  String get appName => 'מודיעין בשבילך';

  @override
  String get navHome => 'בית';

  @override
  String get navBusinesses => 'עסקים';

  @override
  String get navMap => 'מפה';

  @override
  String get navNews => 'חדשות';

  @override
  String get navMunicipal => 'עירייה';

  @override
  String get goodMorning => 'בוקר טוב';

  @override
  String get goodAfternoon => 'צהריים טובים';

  @override
  String get goodEvening => 'ערב טוב';

  @override
  String get whatAreYouLookingFor => 'מה אתה מחפש היום?';

  @override
  String get searchPlaceholder => 'שאל או חפש במודיעין...';

  @override
  String get ask => 'שאל';

  @override
  String get discoverModiin => 'גלו את מודיעין';

  @override
  String get popularNearYou => 'פופולרי בקרבתך';

  @override
  String get upcomingEvents => 'אירועים קרובים';

  @override
  String get latestNews => 'חדשות אחרונות';

  @override
  String get apartmentsNearYou => 'דירות בקרבתך';

  @override
  String get seeAll => 'ראה הכל';

  @override
  String get restaurants => 'מסעדות';

  @override
  String get events => 'אירועים';

  @override
  String get realEstate => 'נדל\"ן';

  @override
  String get news => 'חדשות';

  @override
  String get deals => 'מבצעים';

  @override
  String get signIn => 'התחברות';

  @override
  String get signUp => 'הרשמה';

  @override
  String get signOut => 'התנתקות';

  @override
  String get email => 'אימייל';

  @override
  String get emailHint => 'הזינו את כתובת האימייל';

  @override
  String get welcomeBack => 'ברוכים השבים! 👋';

  @override
  String get signInSubtitle => 'שמחים לראות אתכם שוב!';

  @override
  String get noAccount => 'אין לכם חשבון?';

  @override
  String get confirm => 'אישור';

  @override
  String get errEnterEmail => 'הזינו כתובת אימייל';

  @override
  String get errTooMany => 'יותר מדי ניסיונות. המתינו רגע ונסו שוב.';

  @override
  String get errNoConnection => 'אין חיבור. בדקו את הרשת ונסו שוב.';

  @override
  String get errCouldNotSave => 'לא ניתן היה לשמור. נסו שוב.';

  @override
  String get somethingWentWrong => 'משהו השתבש';

  @override
  String get tryAgain => 'נסו שוב';

  @override
  String get settings => 'הגדרות';

  @override
  String get notifications => 'התראות';

  @override
  String get access => 'גישה';

  @override
  String get account => 'חשבון';

  @override
  String get display => 'תצוגה';

  @override
  String get language => 'שפה';

  @override
  String get receiveNotifications => 'קבלת התראות';

  @override
  String get receiveNotificationsHint => 'כבו כדי להפסיק לקבל התראות';

  @override
  String get notifyNews => 'חדשות ועדכונים';

  @override
  String get notifyNewsHint => 'חדשות מקומיות, עדכוני עירייה';

  @override
  String get notifyDeals => 'הטבות ומבצעים';

  @override
  String get notifyDealsHint => 'קופונים חדשים מעסקים';

  @override
  String get notifyNeighborhood => 'עדכוני שכונה';

  @override
  String get notifyNeighborhoodHint => 'אירועים ועדכונים רלוונטיים לשכונה שלך';

  @override
  String get accessLocation => 'מיקום';

  @override
  String get accessLocationHint => 'למציאת עסקים ואירועים קרובים אליכם';

  @override
  String get accessHealth => 'נתוני כושר';

  @override
  String get accessHealthHint => 'לספירת צעדים ואתגרים';

  @override
  String get darkMode => 'מצב כהה';

  @override
  String get signInToSavePrefs => 'התחברו כדי לשמור את ההעדפות שלכם';

  @override
  String get deleteAccount => 'מחיקת חשבון';

  @override
  String get deleteAccountConfirm =>
      'פעולה זו תמחק את כל הנתונים שלך לצמיתות. האם להמשיך?';

  @override
  String get deleteAccountFailed =>
      'לא ניתן היה למחוק את החשבון. נסו שוב מאוחר יותר.';

  @override
  String get cancel => 'ביטול';

  @override
  String get delete => 'מחיקה';

  @override
  String get favorites => 'מועדפים';

  @override
  String get signInToSave => 'התחברו כדי לשמור';

  @override
  String get noFavoritesYet => 'אין עדיין מועדפים';

  @override
  String get noFavoritesHint => 'שמרו מקומות ופריטים שאהבתם';

  @override
  String get signInToSeeFavorites => 'התחברו כדי לראות את המועדפים שלכם';

  @override
  String get openingHours => 'שעות פתיחה';

  @override
  String get closed => 'סגור';

  @override
  String about(String name) {
    return 'אודות $name';
  }

  @override
  String reviewsFor(String name) {
    return 'ביקורות על $name';
  }

  @override
  String get noReviewsYet => 'אין עדיין ביקורות';

  @override
  String get noReviewsHint => 'היו הראשונים לכתוב ביקורת על המקום הזה';

  @override
  String get noPhotosYet => 'אין עדיין תמונות';

  @override
  String basedOnReviews(int count) {
    return 'מבוסס על $count ביקורות';
  }

  @override
  String get seeMore => 'הצג עוד';

  @override
  String get seeLess => 'הצג פחות';

  @override
  String haveYouVisited(String name) {
    return 'ביקרתם ב$name?';
  }

  @override
  String get searchResults => 'תוצאות חיפוש';

  @override
  String resultsCount(int count) {
    return '$count תוצאות';
  }

  @override
  String get noResults => 'לא נמצאו תוצאות';

  @override
  String get noResultsHint => 'נסו חיפוש אחר';

  @override
  String get all => 'הכל';

  @override
  String get noAdminAccess => 'אין לך גישה לאזור הניהול';

  @override
  String get backHome => 'חזרה לדף הבית';

  @override
  String get password => 'סיסמה';

  @override
  String get passwordHint => 'הזינו סיסמה';

  @override
  String get rememberMe => 'זכור אותי';

  @override
  String get forgotPassword => 'שכחתם סיסמה?';

  @override
  String get errEnterPassword => 'הזינו סיסמה';

  @override
  String get errEnterEmailFirst => 'הזינו קודם את כתובת האימייל';

  @override
  String get resetLinkSent =>
      'אם קיים חשבון עם הכתובת הזו, נשלח אליה קישור לאיפוס.';

  @override
  String get errWrongCredentials => 'האימייל או הסיסמה אינם נכונים.';

  @override
  String get errEmailNotConfirmed =>
      'יש לאשר את כתובת האימייל. בדקו את תיבת הדואר.';

  @override
  String get errPasswordsDoNotMatch => 'הסיסמאות אינן תואמות';

  @override
  String get errPasswordTooShort => 'הסיסמה חייבת להכיל לפחות 8 תווים';

  @override
  String get createAccount => 'יצירת חשבון';

  @override
  String get accountCreatedCheckEmail =>
      'החשבון נוצר. אשרו את כתובת האימייל כדי להתחבר.';

  @override
  String get currentPassword => 'סיסמה נוכחית';

  @override
  String get newPassword => 'סיסמה חדשה';

  @override
  String get confirmNewPassword => 'אימות סיסמה חדשה';

  @override
  String get changePassword => 'שינוי סיסמה';

  @override
  String get passwordChanged => 'הסיסמה שונתה';

  @override
  String get errCurrentPasswordWrong => 'הסיסמה הנוכחית אינה נכונה';

  @override
  String get errAgreeToTerms => 'יש לאשר את תנאי השימוש';

  @override
  String get chooseStrongPassword => 'למען האבטחה שלכם, בחרו סיסמה חזקה.';

  @override
  String get resendConfirmation => 'שליחת אימות שוב';

  @override
  String get confirmationResent => 'שלחנו שוב את הודעת האימות.';

  @override
  String get checkYourEmail => 'בדקו את האימייל';

  @override
  String get emailConfirmed => 'האימייל אומת!';

  @override
  String get emailConfirmedWeb =>
      'כתובת האימייל שלכם אומתה. חזרו לאפליקציה והתחברו.';

  @override
  String get emailConfirmedApp => 'כתובת האימייל שלכם אומתה. אפשר להתחיל.';

  @override
  String get confirmationFailed => 'האימות נכשל';

  @override
  String get confirmationFailedHint =>
      'ייתכן שהקישור פג תוקף או שכבר נעשה בו שימוש. נסו לשלוח אותו שוב.';
}
