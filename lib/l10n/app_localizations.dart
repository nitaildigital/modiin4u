import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// No description provided for @appName.
  ///
  /// In he, this message translates to:
  /// **'מודיעין בשבילך'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In he, this message translates to:
  /// **'בית'**
  String get navHome;

  /// No description provided for @navBusinesses.
  ///
  /// In he, this message translates to:
  /// **'עסקים'**
  String get navBusinesses;

  /// No description provided for @navMap.
  ///
  /// In he, this message translates to:
  /// **'מפה'**
  String get navMap;

  /// No description provided for @navNews.
  ///
  /// In he, this message translates to:
  /// **'חדשות'**
  String get navNews;

  /// No description provided for @navMunicipal.
  ///
  /// In he, this message translates to:
  /// **'עירייה'**
  String get navMunicipal;

  /// No description provided for @goodMorning.
  ///
  /// In he, this message translates to:
  /// **'בוקר טוב'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In he, this message translates to:
  /// **'צהריים טובים'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In he, this message translates to:
  /// **'ערב טוב'**
  String get goodEvening;

  /// No description provided for @whatAreYouLookingFor.
  ///
  /// In he, this message translates to:
  /// **'מה אתה מחפש היום?'**
  String get whatAreYouLookingFor;

  /// No description provided for @searchPlaceholder.
  ///
  /// In he, this message translates to:
  /// **'שאל או חפש במודיעין...'**
  String get searchPlaceholder;

  /// No description provided for @ask.
  ///
  /// In he, this message translates to:
  /// **'שאל'**
  String get ask;

  /// No description provided for @discoverModiin.
  ///
  /// In he, this message translates to:
  /// **'גלו את מודיעין'**
  String get discoverModiin;

  /// No description provided for @popularNearYou.
  ///
  /// In he, this message translates to:
  /// **'פופולרי בקרבתך'**
  String get popularNearYou;

  /// No description provided for @upcomingEvents.
  ///
  /// In he, this message translates to:
  /// **'אירועים קרובים'**
  String get upcomingEvents;

  /// No description provided for @latestNews.
  ///
  /// In he, this message translates to:
  /// **'חדשות אחרונות'**
  String get latestNews;

  /// No description provided for @apartmentsNearYou.
  ///
  /// In he, this message translates to:
  /// **'דירות בקרבתך'**
  String get apartmentsNearYou;

  /// No description provided for @seeAll.
  ///
  /// In he, this message translates to:
  /// **'ראה הכל'**
  String get seeAll;

  /// No description provided for @restaurants.
  ///
  /// In he, this message translates to:
  /// **'מסעדות'**
  String get restaurants;

  /// No description provided for @events.
  ///
  /// In he, this message translates to:
  /// **'אירועים'**
  String get events;

  /// No description provided for @realEstate.
  ///
  /// In he, this message translates to:
  /// **'נדל\"ן'**
  String get realEstate;

  /// No description provided for @news.
  ///
  /// In he, this message translates to:
  /// **'חדשות'**
  String get news;

  /// No description provided for @deals.
  ///
  /// In he, this message translates to:
  /// **'מבצעים'**
  String get deals;

  /// No description provided for @signIn.
  ///
  /// In he, this message translates to:
  /// **'התחברות'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In he, this message translates to:
  /// **'הרשמה'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In he, this message translates to:
  /// **'התנתקות'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In he, this message translates to:
  /// **'אימייל'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In he, this message translates to:
  /// **'הזינו את כתובת האימייל'**
  String get emailHint;

  /// No description provided for @welcomeBack.
  ///
  /// In he, this message translates to:
  /// **'ברוכים השבים! 👋'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In he, this message translates to:
  /// **'שמחים לראות אתכם שוב!'**
  String get signInSubtitle;

  /// No description provided for @noAccount.
  ///
  /// In he, this message translates to:
  /// **'אין לכם חשבון?'**
  String get noAccount;

  /// No description provided for @confirm.
  ///
  /// In he, this message translates to:
  /// **'אישור'**
  String get confirm;

  /// No description provided for @errEnterEmail.
  ///
  /// In he, this message translates to:
  /// **'הזינו כתובת אימייל'**
  String get errEnterEmail;

  /// No description provided for @errTooMany.
  ///
  /// In he, this message translates to:
  /// **'יותר מדי ניסיונות. המתינו רגע ונסו שוב.'**
  String get errTooMany;

  /// No description provided for @errNoConnection.
  ///
  /// In he, this message translates to:
  /// **'אין חיבור. בדקו את הרשת ונסו שוב.'**
  String get errNoConnection;

  /// No description provided for @errCouldNotSave.
  ///
  /// In he, this message translates to:
  /// **'לא ניתן היה לשמור. נסו שוב.'**
  String get errCouldNotSave;

  /// No description provided for @somethingWentWrong.
  ///
  /// In he, this message translates to:
  /// **'משהו השתבש'**
  String get somethingWentWrong;

  /// No description provided for @tryAgain.
  ///
  /// In he, this message translates to:
  /// **'נסו שוב'**
  String get tryAgain;

  /// No description provided for @settings.
  ///
  /// In he, this message translates to:
  /// **'הגדרות'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In he, this message translates to:
  /// **'התראות'**
  String get notifications;

  /// No description provided for @access.
  ///
  /// In he, this message translates to:
  /// **'גישה'**
  String get access;

  /// No description provided for @account.
  ///
  /// In he, this message translates to:
  /// **'חשבון'**
  String get account;

  /// No description provided for @display.
  ///
  /// In he, this message translates to:
  /// **'תצוגה'**
  String get display;

  /// No description provided for @language.
  ///
  /// In he, this message translates to:
  /// **'שפה'**
  String get language;

  /// No description provided for @receiveNotifications.
  ///
  /// In he, this message translates to:
  /// **'קבלת התראות'**
  String get receiveNotifications;

  /// No description provided for @receiveNotificationsHint.
  ///
  /// In he, this message translates to:
  /// **'כבו כדי להפסיק לקבל התראות'**
  String get receiveNotificationsHint;

  /// No description provided for @notifyNews.
  ///
  /// In he, this message translates to:
  /// **'חדשות ועדכונים'**
  String get notifyNews;

  /// No description provided for @notifyNewsHint.
  ///
  /// In he, this message translates to:
  /// **'חדשות מקומיות, עדכוני עירייה'**
  String get notifyNewsHint;

  /// No description provided for @notifyDeals.
  ///
  /// In he, this message translates to:
  /// **'הטבות ומבצעים'**
  String get notifyDeals;

  /// No description provided for @notifyDealsHint.
  ///
  /// In he, this message translates to:
  /// **'קופונים חדשים מעסקים'**
  String get notifyDealsHint;

  /// No description provided for @notifyNeighborhood.
  ///
  /// In he, this message translates to:
  /// **'עדכוני שכונה'**
  String get notifyNeighborhood;

  /// No description provided for @notifyNeighborhoodHint.
  ///
  /// In he, this message translates to:
  /// **'אירועים ועדכונים רלוונטיים לשכונה שלך'**
  String get notifyNeighborhoodHint;

  /// No description provided for @accessLocation.
  ///
  /// In he, this message translates to:
  /// **'מיקום'**
  String get accessLocation;

  /// No description provided for @accessLocationHint.
  ///
  /// In he, this message translates to:
  /// **'למציאת עסקים ואירועים קרובים אליכם'**
  String get accessLocationHint;

  /// No description provided for @accessHealth.
  ///
  /// In he, this message translates to:
  /// **'נתוני כושר'**
  String get accessHealth;

  /// No description provided for @accessHealthHint.
  ///
  /// In he, this message translates to:
  /// **'לספירת צעדים ואתגרים'**
  String get accessHealthHint;

  /// No description provided for @darkMode.
  ///
  /// In he, this message translates to:
  /// **'מצב כהה'**
  String get darkMode;

  /// No description provided for @signInToSavePrefs.
  ///
  /// In he, this message translates to:
  /// **'התחברו כדי לשמור את ההעדפות שלכם'**
  String get signInToSavePrefs;

  /// No description provided for @deleteAccount.
  ///
  /// In he, this message translates to:
  /// **'מחיקת חשבון'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In he, this message translates to:
  /// **'פעולה זו תמחק את כל הנתונים שלך לצמיתות. האם להמשיך?'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In he, this message translates to:
  /// **'לא ניתן היה למחוק את החשבון. נסו שוב מאוחר יותר.'**
  String get deleteAccountFailed;

  /// No description provided for @cancel.
  ///
  /// In he, this message translates to:
  /// **'ביטול'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In he, this message translates to:
  /// **'מחיקה'**
  String get delete;

  /// No description provided for @favorites.
  ///
  /// In he, this message translates to:
  /// **'מועדפים'**
  String get favorites;

  /// No description provided for @signInToSave.
  ///
  /// In he, this message translates to:
  /// **'התחברו כדי לשמור'**
  String get signInToSave;

  /// No description provided for @noFavoritesYet.
  ///
  /// In he, this message translates to:
  /// **'אין עדיין מועדפים'**
  String get noFavoritesYet;

  /// No description provided for @noFavoritesHint.
  ///
  /// In he, this message translates to:
  /// **'שמרו מקומות ופריטים שאהבתם'**
  String get noFavoritesHint;

  /// No description provided for @signInToSeeFavorites.
  ///
  /// In he, this message translates to:
  /// **'התחברו כדי לראות את המועדפים שלכם'**
  String get signInToSeeFavorites;

  /// No description provided for @openingHours.
  ///
  /// In he, this message translates to:
  /// **'שעות פתיחה'**
  String get openingHours;

  /// No description provided for @closed.
  ///
  /// In he, this message translates to:
  /// **'סגור'**
  String get closed;

  /// No description provided for @about.
  ///
  /// In he, this message translates to:
  /// **'אודות {name}'**
  String about(String name);

  /// No description provided for @reviewsFor.
  ///
  /// In he, this message translates to:
  /// **'ביקורות על {name}'**
  String reviewsFor(String name);

  /// No description provided for @noReviewsYet.
  ///
  /// In he, this message translates to:
  /// **'אין עדיין ביקורות'**
  String get noReviewsYet;

  /// No description provided for @noReviewsHint.
  ///
  /// In he, this message translates to:
  /// **'היו הראשונים לכתוב ביקורת על המקום הזה'**
  String get noReviewsHint;

  /// No description provided for @noPhotosYet.
  ///
  /// In he, this message translates to:
  /// **'אין עדיין תמונות'**
  String get noPhotosYet;

  /// No description provided for @basedOnReviews.
  ///
  /// In he, this message translates to:
  /// **'מבוסס על {count} ביקורות'**
  String basedOnReviews(int count);

  /// No description provided for @seeMore.
  ///
  /// In he, this message translates to:
  /// **'הצג עוד'**
  String get seeMore;

  /// No description provided for @seeLess.
  ///
  /// In he, this message translates to:
  /// **'הצג פחות'**
  String get seeLess;

  /// No description provided for @haveYouVisited.
  ///
  /// In he, this message translates to:
  /// **'ביקרתם ב{name}?'**
  String haveYouVisited(String name);

  /// No description provided for @searchResults.
  ///
  /// In he, this message translates to:
  /// **'תוצאות חיפוש'**
  String get searchResults;

  /// No description provided for @resultsCount.
  ///
  /// In he, this message translates to:
  /// **'{count} תוצאות'**
  String resultsCount(int count);

  /// No description provided for @noResults.
  ///
  /// In he, this message translates to:
  /// **'לא נמצאו תוצאות'**
  String get noResults;

  /// No description provided for @noResultsHint.
  ///
  /// In he, this message translates to:
  /// **'נסו חיפוש אחר'**
  String get noResultsHint;

  /// No description provided for @all.
  ///
  /// In he, this message translates to:
  /// **'הכל'**
  String get all;

  /// No description provided for @noAdminAccess.
  ///
  /// In he, this message translates to:
  /// **'אין לך גישה לאזור הניהול'**
  String get noAdminAccess;

  /// No description provided for @backHome.
  ///
  /// In he, this message translates to:
  /// **'חזרה לדף הבית'**
  String get backHome;

  /// No description provided for @password.
  ///
  /// In he, this message translates to:
  /// **'סיסמה'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In he, this message translates to:
  /// **'הזינו סיסמה'**
  String get passwordHint;

  /// No description provided for @rememberMe.
  ///
  /// In he, this message translates to:
  /// **'זכור אותי'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In he, this message translates to:
  /// **'שכחתם סיסמה?'**
  String get forgotPassword;

  /// No description provided for @errEnterPassword.
  ///
  /// In he, this message translates to:
  /// **'הזינו סיסמה'**
  String get errEnterPassword;

  /// No description provided for @errEnterEmailFirst.
  ///
  /// In he, this message translates to:
  /// **'הזינו קודם את כתובת האימייל'**
  String get errEnterEmailFirst;

  /// No description provided for @resetLinkSent.
  ///
  /// In he, this message translates to:
  /// **'אם קיים חשבון עם הכתובת הזו, נשלח אליה קישור לאיפוס.'**
  String get resetLinkSent;

  /// No description provided for @errWrongCredentials.
  ///
  /// In he, this message translates to:
  /// **'האימייל או הסיסמה אינם נכונים.'**
  String get errWrongCredentials;

  /// No description provided for @errEmailNotConfirmed.
  ///
  /// In he, this message translates to:
  /// **'יש לאשר את כתובת האימייל. בדקו את תיבת הדואר.'**
  String get errEmailNotConfirmed;

  /// No description provided for @errPasswordsDoNotMatch.
  ///
  /// In he, this message translates to:
  /// **'הסיסמאות אינן תואמות'**
  String get errPasswordsDoNotMatch;

  /// No description provided for @errPasswordTooShort.
  ///
  /// In he, this message translates to:
  /// **'הסיסמה חייבת להכיל לפחות 8 תווים'**
  String get errPasswordTooShort;

  /// No description provided for @createAccount.
  ///
  /// In he, this message translates to:
  /// **'יצירת חשבון'**
  String get createAccount;

  /// No description provided for @accountCreatedCheckEmail.
  ///
  /// In he, this message translates to:
  /// **'החשבון נוצר. אשרו את כתובת האימייל כדי להתחבר.'**
  String get accountCreatedCheckEmail;

  /// No description provided for @currentPassword.
  ///
  /// In he, this message translates to:
  /// **'סיסמה נוכחית'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In he, this message translates to:
  /// **'סיסמה חדשה'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In he, this message translates to:
  /// **'אימות סיסמה חדשה'**
  String get confirmNewPassword;

  /// No description provided for @changePassword.
  ///
  /// In he, this message translates to:
  /// **'שינוי סיסמה'**
  String get changePassword;

  /// No description provided for @passwordChanged.
  ///
  /// In he, this message translates to:
  /// **'הסיסמה שונתה'**
  String get passwordChanged;

  /// No description provided for @errCurrentPasswordWrong.
  ///
  /// In he, this message translates to:
  /// **'הסיסמה הנוכחית אינה נכונה'**
  String get errCurrentPasswordWrong;

  /// No description provided for @errAgreeToTerms.
  ///
  /// In he, this message translates to:
  /// **'יש לאשר את תנאי השימוש'**
  String get errAgreeToTerms;

  /// No description provided for @chooseStrongPassword.
  ///
  /// In he, this message translates to:
  /// **'למען האבטחה שלכם, בחרו סיסמה חזקה.'**
  String get chooseStrongPassword;

  /// No description provided for @resendConfirmation.
  ///
  /// In he, this message translates to:
  /// **'שליחת אימות שוב'**
  String get resendConfirmation;

  /// No description provided for @confirmationResent.
  ///
  /// In he, this message translates to:
  /// **'שלחנו שוב את הודעת האימות.'**
  String get confirmationResent;

  /// No description provided for @checkYourEmail.
  ///
  /// In he, this message translates to:
  /// **'בדקו את האימייל'**
  String get checkYourEmail;

  /// No description provided for @emailConfirmed.
  ///
  /// In he, this message translates to:
  /// **'האימייל אומת!'**
  String get emailConfirmed;

  /// No description provided for @emailConfirmedWeb.
  ///
  /// In he, this message translates to:
  /// **'כתובת האימייל שלכם אומתה. חזרו לאפליקציה והתחברו.'**
  String get emailConfirmedWeb;

  /// No description provided for @emailConfirmedApp.
  ///
  /// In he, this message translates to:
  /// **'כתובת האימייל שלכם אומתה. אפשר להתחיל.'**
  String get emailConfirmedApp;

  /// No description provided for @confirmationFailed.
  ///
  /// In he, this message translates to:
  /// **'האימות נכשל'**
  String get confirmationFailed;

  /// No description provided for @confirmationFailedHint.
  ///
  /// In he, this message translates to:
  /// **'ייתכן שהקישור פג תוקף או שכבר נעשה בו שימוש. נסו לשלוח אותו שוב.'**
  String get confirmationFailedHint;

  /// No description provided for @dealsNearYou.
  ///
  /// In he, this message translates to:
  /// **'מבצעים בקרבתך'**
  String get dealsNearYou;

  /// No description provided for @summerSpecial.
  ///
  /// In he, this message translates to:
  /// **'מבצע קיץ'**
  String get summerSpecial;

  /// No description provided for @kosher.
  ///
  /// In he, this message translates to:
  /// **'כשר'**
  String get kosher;

  /// No description provided for @forSale.
  ///
  /// In he, this message translates to:
  /// **'למכירה'**
  String get forSale;

  /// No description provided for @forRent.
  ///
  /// In he, this message translates to:
  /// **'להשכרה'**
  String get forRent;

  /// No description provided for @rooms.
  ///
  /// In he, this message translates to:
  /// **'{count} חדרים'**
  String rooms(int count);

  /// No description provided for @monthShortJan.
  ///
  /// In he, this message translates to:
  /// **'ינו'**
  String get monthShortJan;

  /// No description provided for @monthShortFeb.
  ///
  /// In he, this message translates to:
  /// **'פבר'**
  String get monthShortFeb;

  /// No description provided for @monthShortMar.
  ///
  /// In he, this message translates to:
  /// **'מרץ'**
  String get monthShortMar;

  /// No description provided for @monthShortApr.
  ///
  /// In he, this message translates to:
  /// **'אפר'**
  String get monthShortApr;

  /// No description provided for @monthShortMay.
  ///
  /// In he, this message translates to:
  /// **'מאי'**
  String get monthShortMay;

  /// No description provided for @monthShortJun.
  ///
  /// In he, this message translates to:
  /// **'יונ'**
  String get monthShortJun;

  /// No description provided for @monthShortJul.
  ///
  /// In he, this message translates to:
  /// **'יול'**
  String get monthShortJul;

  /// No description provided for @monthShortAug.
  ///
  /// In he, this message translates to:
  /// **'אוג'**
  String get monthShortAug;

  /// No description provided for @monthShortSep.
  ///
  /// In he, this message translates to:
  /// **'ספט'**
  String get monthShortSep;

  /// No description provided for @monthShortOct.
  ///
  /// In he, this message translates to:
  /// **'אוק'**
  String get monthShortOct;

  /// No description provided for @monthShortNov.
  ///
  /// In he, this message translates to:
  /// **'נוב'**
  String get monthShortNov;

  /// No description provided for @monthShortDec.
  ///
  /// In he, this message translates to:
  /// **'דצמ'**
  String get monthShortDec;

  /// No description provided for @monthJan.
  ///
  /// In he, this message translates to:
  /// **'ינואר'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In he, this message translates to:
  /// **'פברואר'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In he, this message translates to:
  /// **'מרץ'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In he, this message translates to:
  /// **'אפריל'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In he, this message translates to:
  /// **'מאי'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In he, this message translates to:
  /// **'יוני'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In he, this message translates to:
  /// **'יולי'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In he, this message translates to:
  /// **'אוגוסט'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In he, this message translates to:
  /// **'ספטמבר'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In he, this message translates to:
  /// **'אוקטובר'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In he, this message translates to:
  /// **'נובמבר'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In he, this message translates to:
  /// **'דצמבר'**
  String get monthDec;

  /// No description provided for @profile.
  ///
  /// In he, this message translates to:
  /// **'פרופיל'**
  String get profile;

  /// No description provided for @personalDetails.
  ///
  /// In he, this message translates to:
  /// **'פרטים אישיים'**
  String get personalDetails;

  /// No description provided for @editProfile.
  ///
  /// In he, this message translates to:
  /// **'עריכת פרופיל'**
  String get editProfile;

  /// No description provided for @manageYourAlerts.
  ///
  /// In he, this message translates to:
  /// **'ניהול ההתראות שלך'**
  String get manageYourAlerts;

  /// No description provided for @savedPlacesListings.
  ///
  /// In he, this message translates to:
  /// **'מקומות ומודעות שנשמרו'**
  String get savedPlacesListings;

  /// No description provided for @appPreferences.
  ///
  /// In he, this message translates to:
  /// **'העדפות אפליקציה'**
  String get appPreferences;

  /// No description provided for @stepsReviewsRewards.
  ///
  /// In he, this message translates to:
  /// **'צעדים, ביקורות ותגמולים'**
  String get stepsReviewsRewards;

  /// No description provided for @myActivity.
  ///
  /// In he, this message translates to:
  /// **'הפעילות שלי'**
  String get myActivity;

  /// No description provided for @propertiesYouPosted.
  ///
  /// In he, this message translates to:
  /// **'הנכסים שפרסמתם'**
  String get propertiesYouPosted;

  /// No description provided for @myApartments.
  ///
  /// In he, this message translates to:
  /// **'הדירות שלי'**
  String get myApartments;

  /// No description provided for @faqsContactUs.
  ///
  /// In he, this message translates to:
  /// **'שאלות נפוצות ויצירת קשר'**
  String get faqsContactUs;

  /// No description provided for @helpSupport.
  ///
  /// In he, this message translates to:
  /// **'עזרה ותמיכה'**
  String get helpSupport;

  /// No description provided for @manageContentUsers.
  ///
  /// In he, this message translates to:
  /// **'ניהול תכנים ומשתמשים'**
  String get manageContentUsers;

  /// No description provided for @controlCenter.
  ///
  /// In he, this message translates to:
  /// **'מרכז הבקרה'**
  String get controlCenter;

  /// No description provided for @realEstateBroker.
  ///
  /// In he, this message translates to:
  /// **'מתווך נדל״ן'**
  String get realEstateBroker;

  /// No description provided for @resident.
  ///
  /// In he, this message translates to:
  /// **'תושב'**
  String get resident;

  /// No description provided for @businesses.
  ///
  /// In he, this message translates to:
  /// **'עסקים'**
  String get businesses;

  /// No description provided for @business.
  ///
  /// In he, this message translates to:
  /// **'עסק'**
  String get business;

  /// No description provided for @event.
  ///
  /// In he, this message translates to:
  /// **'אירוע'**
  String get event;

  /// No description provided for @saveThingsYouLove.
  ///
  /// In he, this message translates to:
  /// **'שמרו מקומות ופריטים שאהבתם'**
  String get saveThingsYouLove;

  /// No description provided for @fullName.
  ///
  /// In he, this message translates to:
  /// **'שם מלא'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In he, this message translates to:
  /// **'טלפון'**
  String get phone;

  /// No description provided for @enterYourPhone.
  ///
  /// In he, this message translates to:
  /// **'הזינו מספר טלפון'**
  String get enterYourPhone;

  /// No description provided for @neighborhood.
  ///
  /// In he, this message translates to:
  /// **'שכונה'**
  String get neighborhood;

  /// No description provided for @familyStatus.
  ///
  /// In he, this message translates to:
  /// **'מצב משפחתי'**
  String get familyStatus;

  /// No description provided for @single.
  ///
  /// In he, this message translates to:
  /// **'רווק/ה'**
  String get single;

  /// No description provided for @married.
  ///
  /// In he, this message translates to:
  /// **'נשוי/אה'**
  String get married;

  /// No description provided for @divorced.
  ///
  /// In he, this message translates to:
  /// **'גרוש/ה'**
  String get divorced;

  /// No description provided for @widowed.
  ///
  /// In he, this message translates to:
  /// **'אלמן/ה'**
  String get widowed;

  /// No description provided for @doYouHaveAPet.
  ///
  /// In he, this message translates to:
  /// **'יש לכם חיית מחמד?'**
  String get doYouHaveAPet;

  /// No description provided for @yes.
  ///
  /// In he, this message translates to:
  /// **'כן'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In he, this message translates to:
  /// **'לא'**
  String get no;

  /// No description provided for @dateOfBirth.
  ///
  /// In he, this message translates to:
  /// **'תאריך לידה'**
  String get dateOfBirth;

  /// No description provided for @saveChanges.
  ///
  /// In he, this message translates to:
  /// **'שמירת שינויים'**
  String get saveChanges;

  /// No description provided for @chooseStrongNewPassword.
  ///
  /// In he, this message translates to:
  /// **'לביטחונכם, בחרו סיסמה חדשה וחזקה.'**
  String get chooseStrongNewPassword;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In he, this message translates to:
  /// **'הזינו סיסמה נוכחית'**
  String get enterCurrentPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In he, this message translates to:
  /// **'הזינו סיסמה חדשה'**
  String get enterNewPassword;

  /// No description provided for @reEnterNewPassword.
  ///
  /// In he, this message translates to:
  /// **'הזינו שוב את הסיסמה החדשה'**
  String get reEnterNewPassword;

  /// No description provided for @searchForHelp.
  ///
  /// In he, this message translates to:
  /// **'חיפוש עזרה'**
  String get searchForHelp;

  /// No description provided for @stillNeedHelp.
  ///
  /// In he, this message translates to:
  /// **'עדיין צריכים עזרה?'**
  String get stillNeedHelp;

  /// No description provided for @contactOurSupportTeam.
  ///
  /// In he, this message translates to:
  /// **'צרו קשר עם צוות התמיכה שלנו'**
  String get contactOurSupportTeam;

  /// No description provided for @contactUs.
  ///
  /// In he, this message translates to:
  /// **'צרו קשר'**
  String get contactUs;

  /// No description provided for @selectHint.
  ///
  /// In he, this message translates to:
  /// **'בחרו'**
  String get selectHint;

  /// No description provided for @addApartment.
  ///
  /// In he, this message translates to:
  /// **'הוספת דירה'**
  String get addApartment;

  /// No description provided for @stepBasics.
  ///
  /// In he, this message translates to:
  /// **'בסיס'**
  String get stepBasics;

  /// No description provided for @stepDetails.
  ///
  /// In he, this message translates to:
  /// **'פרטים'**
  String get stepDetails;

  /// No description provided for @stepPhotos.
  ///
  /// In he, this message translates to:
  /// **'תמונות'**
  String get stepPhotos;

  /// No description provided for @next.
  ///
  /// In he, this message translates to:
  /// **'הבא'**
  String get next;

  /// No description provided for @submitForApproval.
  ///
  /// In he, this message translates to:
  /// **'שליחה לאישור'**
  String get submitForApproval;

  /// No description provided for @basicInformation.
  ///
  /// In he, this message translates to:
  /// **'פרטים בסיסיים'**
  String get basicInformation;

  /// No description provided for @fillInPropertyDetails.
  ///
  /// In he, this message translates to:
  /// **'מלאו את פרטי הנכס'**
  String get fillInPropertyDetails;

  /// No description provided for @listingType.
  ///
  /// In he, this message translates to:
  /// **'סוג המודעה'**
  String get listingType;

  /// No description provided for @propertyType.
  ///
  /// In he, this message translates to:
  /// **'סוג הנכס'**
  String get propertyType;

  /// No description provided for @selectPropertyType.
  ///
  /// In he, this message translates to:
  /// **'בחרו סוג נכס'**
  String get selectPropertyType;

  /// No description provided for @listingTitle.
  ///
  /// In he, this message translates to:
  /// **'כותרת'**
  String get listingTitle;

  /// No description provided for @listingTitleHint.
  ///
  /// In he, this message translates to:
  /// **'לדוגמה: דירת 3 חדרים במרכז העיר'**
  String get listingTitleHint;

  /// No description provided for @price.
  ///
  /// In he, this message translates to:
  /// **'מחיר'**
  String get price;

  /// No description provided for @enterPrice.
  ///
  /// In he, this message translates to:
  /// **'הזינו מחיר'**
  String get enterPrice;

  /// No description provided for @pricePerMonth.
  ///
  /// In he, this message translates to:
  /// **'מחיר לחודש'**
  String get pricePerMonth;

  /// No description provided for @address.
  ///
  /// In he, this message translates to:
  /// **'כתובת'**
  String get address;

  /// No description provided for @enterAddress.
  ///
  /// In he, this message translates to:
  /// **'הזינו כתובת'**
  String get enterAddress;

  /// No description provided for @selectRooms.
  ///
  /// In he, this message translates to:
  /// **'בחרו מספר חדרים'**
  String get selectRooms;

  /// No description provided for @bathrooms.
  ///
  /// In he, this message translates to:
  /// **'חדרי רחצה'**
  String get bathrooms;

  /// No description provided for @selectBathrooms.
  ///
  /// In he, this message translates to:
  /// **'בחרו מספר חדרי רחצה'**
  String get selectBathrooms;

  /// No description provided for @propTypeApartment.
  ///
  /// In he, this message translates to:
  /// **'דירה'**
  String get propTypeApartment;

  /// No description provided for @propTypePenthouse.
  ///
  /// In he, this message translates to:
  /// **'פנטהאוז'**
  String get propTypePenthouse;

  /// No description provided for @propTypeGarden.
  ///
  /// In he, this message translates to:
  /// **'דירת גן'**
  String get propTypeGarden;

  /// No description provided for @propTypeDuplex.
  ///
  /// In he, this message translates to:
  /// **'דופלקס'**
  String get propTypeDuplex;

  /// No description provided for @propTypeVilla.
  ///
  /// In he, this message translates to:
  /// **'וילה'**
  String get propTypeVilla;

  /// No description provided for @propTypeStudio.
  ///
  /// In he, this message translates to:
  /// **'סטודיו'**
  String get propTypeStudio;

  /// No description provided for @propTypeOther.
  ///
  /// In he, this message translates to:
  /// **'אחר'**
  String get propTypeOther;

  /// No description provided for @apartmentDetails.
  ///
  /// In he, this message translates to:
  /// **'פרטי הדירה'**
  String get apartmentDetails;

  /// No description provided for @addMoreDetails.
  ///
  /// In he, this message translates to:
  /// **'הוסיפו פרטים נוספים על הנכס'**
  String get addMoreDetails;

  /// No description provided for @description.
  ///
  /// In he, this message translates to:
  /// **'תיאור'**
  String get description;

  /// No description provided for @describeYourApartment.
  ///
  /// In he, this message translates to:
  /// **'תארו את הדירה, המאפיינים והיתרונות'**
  String get describeYourApartment;

  /// No description provided for @floor.
  ///
  /// In he, this message translates to:
  /// **'קומה'**
  String get floor;

  /// No description provided for @totalFloors.
  ///
  /// In he, this message translates to:
  /// **'סה״כ קומות'**
  String get totalFloors;

  /// No description provided for @areaSqm.
  ///
  /// In he, this message translates to:
  /// **'שטח (מ״ר)'**
  String get areaSqm;

  /// No description provided for @enterArea.
  ///
  /// In he, this message translates to:
  /// **'הזינו שטח'**
  String get enterArea;

  /// No description provided for @amenities.
  ///
  /// In he, this message translates to:
  /// **'מתקנים'**
  String get amenities;

  /// No description provided for @amenityBalcony.
  ///
  /// In he, this message translates to:
  /// **'מרפסת'**
  String get amenityBalcony;

  /// No description provided for @amenityParking.
  ///
  /// In he, this message translates to:
  /// **'חניה'**
  String get amenityParking;

  /// No description provided for @amenityElevator.
  ///
  /// In he, this message translates to:
  /// **'מעלית'**
  String get amenityElevator;

  /// No description provided for @amenityStorage.
  ///
  /// In he, this message translates to:
  /// **'מחסן'**
  String get amenityStorage;

  /// No description provided for @amenityMamad.
  ///
  /// In he, this message translates to:
  /// **'ממ״ד'**
  String get amenityMamad;

  /// No description provided for @addPhotos.
  ///
  /// In he, this message translates to:
  /// **'הוספת תמונות'**
  String get addPhotos;

  /// No description provided for @uploadApartmentPhotos.
  ///
  /// In he, this message translates to:
  /// **'העלו תמונות של הדירה'**
  String get uploadApartmentPhotos;

  /// No description provided for @mainImage.
  ///
  /// In he, this message translates to:
  /// **'תמונה ראשית'**
  String get mainImage;

  /// No description provided for @firstPhotoIsCover.
  ///
  /// In he, this message translates to:
  /// **'התמונה הראשונה תשמש כתמונת השער'**
  String get firstPhotoIsCover;

  /// No description provided for @listingSubmitted.
  ///
  /// In he, this message translates to:
  /// **'המודעה נשלחה!'**
  String get listingSubmitted;

  /// No description provided for @submittedForApproval.
  ///
  /// In he, this message translates to:
  /// **'הדירה שלכם נשלחה לאישור.'**
  String get submittedForApproval;

  /// No description provided for @listingBeingReviewed.
  ///
  /// In he, this message translates to:
  /// **'המודעה שלכם בבדיקה'**
  String get listingBeingReviewed;

  /// No description provided for @checkStatusAnytime.
  ///
  /// In he, this message translates to:
  /// **'תוכלו לבדוק את סטטוס המודעה בכל עת'**
  String get checkStatusAnytime;

  /// No description provided for @backToMyApartments.
  ///
  /// In he, this message translates to:
  /// **'חזרה לדירות שלי'**
  String get backToMyApartments;

  /// No description provided for @statusPending.
  ///
  /// In he, this message translates to:
  /// **'ממתין לאישור'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In he, this message translates to:
  /// **'מאושר'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In he, this message translates to:
  /// **'נדחה'**
  String get statusRejected;

  /// No description provided for @noApartmentsYet.
  ///
  /// In he, this message translates to:
  /// **'עדיין אין דירות'**
  String get noApartmentsYet;

  /// No description provided for @addYourFirstApartment.
  ///
  /// In he, this message translates to:
  /// **'הוסיפו את הדירה הראשונה שלכם כדי להתחיל.'**
  String get addYourFirstApartment;

  /// No description provided for @searchApartments.
  ///
  /// In he, this message translates to:
  /// **'חיפוש דירות'**
  String get searchApartments;

  /// No description provided for @noApartmentsMatch.
  ///
  /// In he, this message translates to:
  /// **'לא נמצאו דירות מתאימות'**
  String get noApartmentsMatch;

  /// No description provided for @errTitleRequired.
  ///
  /// In he, this message translates to:
  /// **'יש להזין כותרת'**
  String get errTitleRequired;

  /// No description provided for @errPriceRequired.
  ///
  /// In he, this message translates to:
  /// **'יש להזין מחיר'**
  String get errPriceRequired;

  /// No description provided for @errCouldNotSubmit.
  ///
  /// In he, this message translates to:
  /// **'לא ניתן היה לשלוח. נסו שוב.'**
  String get errCouldNotSubmit;

  /// No description provided for @signInToPostListing.
  ///
  /// In he, this message translates to:
  /// **'התחברו כדי לפרסם מודעה'**
  String get signInToPostListing;

  /// No description provided for @roomsLabel.
  ///
  /// In he, this message translates to:
  /// **'חדרים'**
  String get roomsLabel;

  /// No description provided for @submittedForApprovalLong.
  ///
  /// In he, this message translates to:
  /// **'הדירה שלכם נשלחה לאישור. נבדוק את הפרטים ונפרסם אותה לאחר האישור.'**
  String get submittedForApprovalLong;

  /// No description provided for @checkStatusAnytimeLong.
  ///
  /// In he, this message translates to:
  /// **'תוכלו לבדוק את סטטוס המודעה בכל עת בעמוד ״הדירות שלי״.'**
  String get checkStatusAnytimeLong;

  /// No description provided for @pendingApproval.
  ///
  /// In he, this message translates to:
  /// **'ממתין לאישור'**
  String get pendingApproval;

  /// No description provided for @submittedOn.
  ///
  /// In he, this message translates to:
  /// **'נשלח ב-{date}'**
  String submittedOn(String date);

  /// No description provided for @pricePerMonthValue.
  ///
  /// In he, this message translates to:
  /// **'{price} לחודש'**
  String pricePerMonthValue(String price);

  /// No description provided for @aboutThisProperty.
  ///
  /// In he, this message translates to:
  /// **'על הנכס'**
  String get aboutThisProperty;

  /// No description provided for @propertySpecs.
  ///
  /// In he, this message translates to:
  /// **'מפרט הנכס'**
  String get propertySpecs;

  /// No description provided for @agent.
  ///
  /// In he, this message translates to:
  /// **'איש קשר'**
  String get agent;

  /// No description provided for @contact.
  ///
  /// In he, this message translates to:
  /// **'צור קשר'**
  String get contact;

  /// No description provided for @readMore.
  ///
  /// In he, this message translates to:
  /// **'קראו עוד'**
  String get readMore;

  /// No description provided for @showLess.
  ///
  /// In he, this message translates to:
  /// **'הצג פחות'**
  String get showLess;

  /// No description provided for @aboutNeighborhood.
  ///
  /// In he, this message translates to:
  /// **'על {name}'**
  String aboutNeighborhood(String name);

  /// No description provided for @propertiesIn.
  ///
  /// In he, this message translates to:
  /// **'נכסים ב{name}'**
  String propertiesIn(String name);

  /// No description provided for @listingNotFound.
  ///
  /// In he, this message translates to:
  /// **'המודעה לא נמצאה'**
  String get listingNotFound;

  /// No description provided for @sqmUnit.
  ///
  /// In he, this message translates to:
  /// **'מ״ר'**
  String get sqmUnit;

  /// No description provided for @bathroomsUnit.
  ///
  /// In he, this message translates to:
  /// **'חדרי רחצה'**
  String get bathroomsUnit;

  /// No description provided for @whereYoullBe.
  ///
  /// In he, this message translates to:
  /// **'איפה זה נמצא'**
  String get whereYoullBe;

  /// No description provided for @propertyLabel.
  ///
  /// In he, this message translates to:
  /// **'נדל״ן'**
  String get propertyLabel;

  /// No description provided for @viaBroker.
  ///
  /// In he, this message translates to:
  /// **'באמצעות מתווך'**
  String get viaBroker;

  /// No description provided for @newBadge.
  ///
  /// In he, this message translates to:
  /// **'חדש'**
  String get newBadge;

  /// No description provided for @floorLabel.
  ///
  /// In he, this message translates to:
  /// **'קומה {n}'**
  String floorLabel(String n);

  /// No description provided for @viewOnMap.
  ///
  /// In he, this message translates to:
  /// **'הצג במפה'**
  String get viewOnMap;

  /// No description provided for @forSaleBadge.
  ///
  /// In he, this message translates to:
  /// **'למכירה'**
  String get forSaleBadge;

  /// No description provided for @forRentBadge.
  ///
  /// In he, this message translates to:
  /// **'להשכרה'**
  String get forRentBadge;

  /// No description provided for @photoTooLarge.
  ///
  /// In he, this message translates to:
  /// **'הקובץ גדול מ-10MB'**
  String get photoTooLarge;

  /// No description provided for @uploadFailed.
  ///
  /// In he, this message translates to:
  /// **'ההעלאה נכשלה. נסו שוב.'**
  String get uploadFailed;

  /// No description provided for @maxPhotosReached.
  ///
  /// In he, this message translates to:
  /// **'ניתן להעלות עד {n} תמונות'**
  String maxPhotosReached(int n);
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'he':
      return LHe();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
