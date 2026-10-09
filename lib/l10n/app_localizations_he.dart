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

  @override
  String get dealsNearYou => 'מבצעים בקרבתך';

  @override
  String get summerSpecial => 'מבצע קיץ';

  @override
  String get kosher => 'כשר';

  @override
  String get forSale => 'למכירה';

  @override
  String get forRent => 'להשכרה';

  @override
  String rooms(int count) {
    return '$count חדרים';
  }

  @override
  String get monthShortJan => 'ינו';

  @override
  String get monthShortFeb => 'פבר';

  @override
  String get monthShortMar => 'מרץ';

  @override
  String get monthShortApr => 'אפר';

  @override
  String get monthShortMay => 'מאי';

  @override
  String get monthShortJun => 'יונ';

  @override
  String get monthShortJul => 'יול';

  @override
  String get monthShortAug => 'אוג';

  @override
  String get monthShortSep => 'ספט';

  @override
  String get monthShortOct => 'אוק';

  @override
  String get monthShortNov => 'נוב';

  @override
  String get monthShortDec => 'דצמ';

  @override
  String get monthJan => 'ינואר';

  @override
  String get monthFeb => 'פברואר';

  @override
  String get monthMar => 'מרץ';

  @override
  String get monthApr => 'אפריל';

  @override
  String get monthMay => 'מאי';

  @override
  String get monthJun => 'יוני';

  @override
  String get monthJul => 'יולי';

  @override
  String get monthAug => 'אוגוסט';

  @override
  String get monthSep => 'ספטמבר';

  @override
  String get monthOct => 'אוקטובר';

  @override
  String get monthNov => 'נובמבר';

  @override
  String get monthDec => 'דצמבר';

  @override
  String get profile => 'פרופיל';

  @override
  String get personalDetails => 'פרטים אישיים';

  @override
  String get editProfile => 'עריכת פרופיל';

  @override
  String get manageYourAlerts => 'ניהול ההתראות שלך';

  @override
  String get savedPlacesListings => 'מקומות ומודעות שנשמרו';

  @override
  String get appPreferences => 'העדפות אפליקציה';

  @override
  String get stepsReviewsRewards => 'צעדים, ביקורות ותגמולים';

  @override
  String get myActivity => 'הפעילות שלי';

  @override
  String get propertiesYouPosted => 'הנכסים שפרסמתם';

  @override
  String get myApartments => 'הדירות שלי';

  @override
  String get faqsContactUs => 'שאלות נפוצות ויצירת קשר';

  @override
  String get helpSupport => 'עזרה ותמיכה';

  @override
  String get manageContentUsers => 'ניהול תכנים ומשתמשים';

  @override
  String get controlCenter => 'מרכז הבקרה';

  @override
  String get realEstateBroker => 'מתווך נדל״ן';

  @override
  String get resident => 'תושב';

  @override
  String get businesses => 'עסקים';

  @override
  String get business => 'עסק';

  @override
  String get event => 'אירוע';

  @override
  String get saveThingsYouLove => 'שמרו מקומות ופריטים שאהבתם';

  @override
  String get fullName => 'שם מלא';

  @override
  String get phone => 'טלפון';

  @override
  String get enterYourPhone => 'הזינו מספר טלפון';

  @override
  String get neighborhood => 'שכונה';

  @override
  String get familyStatus => 'מצב משפחתי';

  @override
  String get single => 'רווק/ה';

  @override
  String get married => 'נשוי/אה';

  @override
  String get divorced => 'גרוש/ה';

  @override
  String get widowed => 'אלמן/ה';

  @override
  String get doYouHaveAPet => 'יש לכם חיית מחמד?';

  @override
  String get yes => 'כן';

  @override
  String get no => 'לא';

  @override
  String get dateOfBirth => 'תאריך לידה';

  @override
  String get saveChanges => 'שמירת שינויים';

  @override
  String get chooseStrongNewPassword => 'לביטחונכם, בחרו סיסמה חדשה וחזקה.';

  @override
  String get enterCurrentPassword => 'הזינו סיסמה נוכחית';

  @override
  String get enterNewPassword => 'הזינו סיסמה חדשה';

  @override
  String get reEnterNewPassword => 'הזינו שוב את הסיסמה החדשה';

  @override
  String get searchForHelp => 'חיפוש עזרה';

  @override
  String get stillNeedHelp => 'עדיין צריכים עזרה?';

  @override
  String get contactOurSupportTeam => 'צרו קשר עם צוות התמיכה שלנו';

  @override
  String get contactUs => 'צרו קשר';

  @override
  String get selectHint => 'בחרו';

  @override
  String get addApartment => 'הוספת דירה';

  @override
  String get stepBasics => 'מידע בסיסי';

  @override
  String get stepDetails => 'פרטים';

  @override
  String get stepPhotos => 'תמונות';

  @override
  String get next => 'הבא';

  @override
  String get submitForApproval => 'שליחה לאישור';

  @override
  String get basicInformation => 'פרטים בסיסיים';

  @override
  String get fillInPropertyDetails => 'מלאו את הפרטים הבסיסיים על הדירה.';

  @override
  String get listingType => 'סוג המודעה';

  @override
  String get propertyType => 'סוג הנכס';

  @override
  String get selectPropertyType => 'בחרו סוג נכס';

  @override
  String get listingTitle => 'כותרת';

  @override
  String get listingTitleHint => 'לדוגמה: דירת 3 חדרים במרכז העיר';

  @override
  String get price => 'מחיר';

  @override
  String get enterPrice => 'הזינו מחיר';

  @override
  String get pricePerMonth => 'מחיר לחודש';

  @override
  String get address => 'כתובת';

  @override
  String get enterAddress => 'הזינו כתובת';

  @override
  String get selectRooms => 'בחרו מספר חדרים';

  @override
  String get bathrooms => 'חדרי רחצה';

  @override
  String get selectBathrooms => 'בחרו מספר חדרי רחצה';

  @override
  String get propTypeApartment => 'דירה';

  @override
  String get propTypePenthouse => 'פנטהאוז';

  @override
  String get propTypeGarden => 'דירת גן';

  @override
  String get propTypeDuplex => 'דופלקס';

  @override
  String get propTypeVilla => 'וילה';

  @override
  String get propTypeStudio => 'סטודיו';

  @override
  String get propTypeOther => 'אחר';

  @override
  String get apartmentDetails => 'פרטי הדירה';

  @override
  String get addMoreDetails => 'הוסיפו פרטים נוספים על הדירה.';

  @override
  String get description => 'תיאור';

  @override
  String get describeYourApartment => 'תארו את הדירה, המאפיינים והיתרונות';

  @override
  String get floor => 'קומה';

  @override
  String get totalFloors => 'סה״כ קומות';

  @override
  String get areaSqm => 'שטח (מ״ר)';

  @override
  String get enterArea => 'הזינו שטח';

  @override
  String get amenities => 'מתקנים';

  @override
  String get amenityBalcony => 'מרפסת';

  @override
  String get amenityParking => 'חניה';

  @override
  String get amenityElevator => 'מעלית';

  @override
  String get amenityStorage => 'מחסן';

  @override
  String get amenityMamad => 'ממ״ד';

  @override
  String get addPhotos => 'הוספת תמונות';

  @override
  String get uploadApartmentPhotos =>
      'הוסיפו תמונות ברורות ומושכות שיציגו את הדירה.';

  @override
  String get mainImage => 'תמונת שער';

  @override
  String get firstPhotoIsCover => 'התמונה הראשונה תשמש כתמונת השער';

  @override
  String get listingSubmitted => 'המודעה נשלחה!';

  @override
  String get submittedForApproval => 'הדירה שלכם נשלחה לאישור.';

  @override
  String get listingBeingReviewed => 'המודעה שלכם נמצאת כעת בבדיקה.';

  @override
  String get checkStatusAnytime => 'תוכלו לבדוק את סטטוס המודעה בכל עת';

  @override
  String get backToMyApartments => 'חזרה לדירות שלי';

  @override
  String get statusPending => 'ממתין לאישור';

  @override
  String get statusApproved => 'מאושר';

  @override
  String get statusRejected => 'נדחה';

  @override
  String get noApartmentsYet => 'עדיין אין דירות';

  @override
  String get addYourFirstApartment =>
      'הוסיפו את הדירה הראשונה שלכם כדי להתחיל.';

  @override
  String get searchApartments => 'חיפוש דירות';

  @override
  String get noApartmentsMatch => 'לא נמצאו דירות מתאימות';

  @override
  String get errTitleRequired => 'יש להזין כותרת';

  @override
  String get errPriceRequired => 'יש להזין מחיר';

  @override
  String get errCouldNotSubmit => 'לא ניתן היה לשלוח. נסו שוב.';

  @override
  String get saveDraft => 'שמירת טיוטה';

  @override
  String get draftSaved => 'הטיוטה נשמרה. אפשר להשלים אותה מ״הדירות שלי״.';

  @override
  String get errCouldNotSaveDraft => 'לא ניתן היה לשמור את הטיוטה. נסו שוב.';

  @override
  String get statusDraft => 'טיוטה';

  @override
  String get continueEditing => 'המשך עריכה';

  @override
  String get signInToPostListing => 'התחברו כדי לפרסם מודעה';

  @override
  String get roomsLabel => 'חדרים';

  @override
  String get submittedForApprovalLong =>
      'הדירה שלכם נשלחה לאישור. נבדוק את הפרטים ונפרסם אותה לאחר האישור.';

  @override
  String get checkStatusAnytimeLong =>
      'תוכלו לבדוק את סטטוס המודעה בכל עת בעמוד ״הדירות שלי״.';

  @override
  String get pendingApproval => 'ממתין לאישור';

  @override
  String submittedOn(String date) {
    return 'נשלח ב-$date';
  }

  @override
  String pricePerMonthValue(String price) {
    return '$price לחודש';
  }

  @override
  String get aboutThisProperty => 'על הנכס';

  @override
  String get propertySpecs => 'מפרט הנכס';

  @override
  String get agent => 'איש קשר';

  @override
  String get contact => 'צור קשר';

  @override
  String get readMore => 'קראו עוד';

  @override
  String get showLess => 'הצג פחות';

  @override
  String aboutNeighborhood(String name) {
    return 'על $name';
  }

  @override
  String propertiesIn(String name) {
    return 'נכסים ב$name';
  }

  @override
  String get listingNotFound => 'המודעה לא נמצאה';

  @override
  String get sqmUnit => 'מ״ר';

  @override
  String get bathroomsUnit => 'חדרי רחצה';

  @override
  String get whereYoullBe => 'איפה זה נמצא';

  @override
  String get propertyLabel => 'נדל״ן';

  @override
  String get viaBroker => 'באמצעות מתווך';

  @override
  String get newBadge => 'חדש';

  @override
  String floorLabel(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '0': 'קומת קרקע',
      'other': 'קומה $n',
    });
    return '$_temp0';
  }

  @override
  String get viewOnMap => 'הצג במפה';

  @override
  String get forSaleBadge => 'למכירה';

  @override
  String get forRentBadge => 'להשכרה';

  @override
  String get photoTooLarge => 'הקובץ גדול מ-10MB';

  @override
  String get uploadFailed => 'ההעלאה נכשלה. נסו שוב.';

  @override
  String maxPhotosReached(int n) {
    return 'ניתן להעלות עד $n תמונות';
  }

  @override
  String get exploreDealsByCategory => 'מבצעים לפי קטגוריה';

  @override
  String get popularDealsInModiin => 'מבצעים פופולריים במודיעין';

  @override
  String get viewDeal => 'לצפייה במבצע';

  @override
  String get viewAll => 'ראה הכל';

  @override
  String get timeLeft => 'נותר';

  @override
  String get residentsOnly => 'לתושבים בלבד';

  @override
  String get noDealsYet => 'אין מבצעים כרגע';

  @override
  String get noDealsYetBody => 'כשעסקים במודיעין יוסיפו מבצעים, הם יופיעו כאן.';

  @override
  String get claimOffer => 'קבלת המבצע';

  @override
  String get offerClaimed => 'המבצע נשמר';

  @override
  String get alreadyClaimed => 'כבר קיבלתם את המבצע הזה';

  @override
  String get showThisCode => 'הציגו את הקוד בבית העסק';

  @override
  String get offerExpired => 'המבצע הסתיים';

  @override
  String get signInToClaim => 'התחברו כדי לקבל את המבצע';

  @override
  String daysShort(int n) {
    return '$n ימים';
  }

  @override
  String hoursShort(int n) {
    return '$n שעות';
  }

  @override
  String minutesShort(int n) {
    return '$n דקות';
  }

  @override
  String dealsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n מבצעים',
      one: 'מבצע אחד',
    );
    return '$_temp0';
  }

  @override
  String get validUntil => 'בתוקף עד';

  @override
  String get terms => 'תנאים';

  @override
  String get getDirections => 'ניווט';

  @override
  String get callBusiness => 'התקשרו לעסק';

  @override
  String moreDealsFrom(String name) {
    return 'עוד מבצעים מ$name';
  }

  @override
  String get offerNotFound => 'המבצע לא נמצא';

  @override
  String get close => 'סגירה';

  @override
  String get bestDealsHeading => 'המבצעים הטובים\nביותר במודיעין';

  @override
  String get dealsHeroSubtitle =>
      'גלו מבצעים, הנחות והטבות לזמן מוגבל ברחבי מודיעין.';

  @override
  String get stepCounter => 'מד צעדים';

  @override
  String get everyStepBetter => 'כל צעד עושה את מודיעין טובה יותר';

  @override
  String get todaysProgress => 'ההתקדמות היום';

  @override
  String get stepsUnit => 'צעדים';

  @override
  String streakDays(int n) {
    return 'רצף $n ימים';
  }

  @override
  String percentOfGoal(int percent, String goal) {
    return '$percent% מתוך $goal';
  }

  @override
  String get kmUnit => 'ק״מ';

  @override
  String get distanceEstimate => 'מרחק משוער';

  @override
  String get thisWeek => 'השבוע';

  @override
  String get leaderboard => 'טבלת מובילים';

  @override
  String get byNeighborhood => 'לפי שכונה';

  @override
  String get byCity => 'כל העיר';

  @override
  String get you => 'אתם';

  @override
  String get stepsPermissionNeeded =>
      'כדי לספור צעדים צריך אישור לזיהוי פעילות';

  @override
  String get stepsUnsupported => 'המכשיר הזה לא תומך בספירת צעדים';

  @override
  String get noStepsYet => 'עדיין אין נתוני צעדים';

  @override
  String get leaderboardEmpty => 'אף אחד עדיין לא מודד צעדים';

  @override
  String get leaderboardSignIn => 'התחברו כדי לראות את הטבלה';

  @override
  String get enableHealthToJoin =>
      'הפעילו ״נתוני כושר״ בהגדרות כדי להופיע בטבלה';

  @override
  String get weekdayMon => 'ב׳';

  @override
  String get weekdayTue => 'ג׳';

  @override
  String get weekdayWed => 'ד׳';

  @override
  String get weekdayThu => 'ה׳';

  @override
  String get weekdayFri => 'ו׳';

  @override
  String get weekdaySat => 'ש׳';

  @override
  String get weekdaySun => 'א׳';

  @override
  String get monthlyChallenge => 'אתגר חודשי במודיעין';

  @override
  String get viewChallenge => 'לצפייה באתגר';

  @override
  String get stepChallengeTitle => 'אתגר הצעדים של מודיעין';

  @override
  String get stepChallengeSub => 'התחרו מול אחרים וטפסו בדירוג';

  @override
  String get municipal => 'עירייה';

  @override
  String get searchMunicipal => 'חיפוש שירותי עירייה...';

  @override
  String get quickInfo => 'מידע מהיר';

  @override
  String get municipalServices => 'שירותי עירייה';

  @override
  String get exploreServices => 'שירותים ומידע';

  @override
  String get upcomingShabbat => 'שבת הקרובה';

  @override
  String get parkingInModiin => 'חניה במודיעין';

  @override
  String get comingSoon => 'בקרוב';

  @override
  String get svcParking => 'חניה';

  @override
  String get svcShabbat => 'שבת\nוחגים';

  @override
  String get svcInstitutions => 'מוסדות\nציבור';

  @override
  String get svcHealth => 'בריאות';

  @override
  String get svcEducation => 'חינוך';

  @override
  String get svcTransport => 'תחבורה';

  @override
  String get svcEmergency => 'חירום';

  @override
  String get svcParks => 'פארקים';

  @override
  String get svcForms => 'טפסים';

  @override
  String get tabOverview => 'סקירה';

  @override
  String get tabMenu => 'תפריט';

  @override
  String get tabPhotos => 'תמונות';

  @override
  String get tabReviews => 'מה חושבים תושבי העיר?';

  @override
  String get callNow => 'התקשרו עכשיו';

  @override
  String get uploadPhoto => 'העלאת תמונה';

  @override
  String get shareYourExperience => 'שתפו את החוויה שלכם עם הקהילה';

  @override
  String get howWasExperience => 'איך הייתה החוויה שלכם?';

  @override
  String get rateAndShare => 'דרגו ושתפו את החוויה שלכם';

  @override
  String get ratePoor => 'גרוע';

  @override
  String get rateFair => 'סביר';

  @override
  String get rateGood => 'טוב';

  @override
  String get rateVeryGood => 'טוב מאוד';

  @override
  String get rateExcellent => 'מצוין!';

  @override
  String get writeYourReview => 'כתבו ביקורת';

  @override
  String get reviewHint => 'שתפו פרטים על החוויה שלכם במקום הזה...';

  @override
  String get submit => 'שליחה';

  @override
  String get justNow => 'הרגע';

  @override
  String get yourReply => 'התגובה שלכם';

  @override
  String get reply => 'תגובה';

  @override
  String get writeReplyHint => 'כתבו תגובה...';

  @override
  String get replySent => 'התגובה נשלחה!';

  @override
  String get imGoing => 'אני מגיע/ה';

  @override
  String get going => 'מגיע/ה';

  @override
  String get signInToRsvp => 'התחברו כדי להירשם לאירוע';

  @override
  String get eventSoldOut => 'האירוע מלא';

  @override
  String get rsvpFailed => 'לא ניתן היה לעדכן. נסו שוב.';

  @override
  String get openInMaps => 'פתיחה במפות';

  @override
  String get reviewSubmitted => 'הביקורת נשלחה ותפורסם לאחר אישור';

  @override
  String get alreadyReviewed => 'כבר כתבתם ביקורת על העסק הזה';

  @override
  String get signInToReview => 'התחברו כדי לכתוב ביקורת';

  @override
  String get chooseRating => 'יש לבחור דירוג';

  @override
  String get realEstateInModiin => 'נדל״ן במודיעין';

  @override
  String get searchByLocation => 'חיפוש לפי מיקום, שכונה...';

  @override
  String get viewOnMapBtn => 'הצג במפה';

  @override
  String get noListingsYet => 'אין מודעות כרגע';

  @override
  String get noListingsYetBody => 'כשתפורסמנה דירות במודיעין, הן יופיעו כאן.';

  @override
  String get noListingsMatch => 'לא נמצאו מודעות מתאימות';

  @override
  String get listView => 'תצוגת רשימה';

  @override
  String get viewFullDetails => 'לפרטים מלאים';

  @override
  String get noListingsOnMap => 'אין מודעות עם מיקום על המפה';

  @override
  String get listingFilters => 'סינון';

  @override
  String get filterPriceMin => 'מינימום';

  @override
  String get filterPriceMax => 'מקסימום';

  @override
  String get filterReset => 'איפוס';

  @override
  String get filterShowResults => 'הצגת תוצאות';

  @override
  String get createYourAccount => 'יצירת חשבון';

  @override
  String get accountType => 'סוג חשבון';

  @override
  String get accountResident => 'תושב/ת';

  @override
  String get accountResidentSub => 'לתושבי מודיעין ולחברי הקהילה.';

  @override
  String get accountBrokerSub => 'אני מתווך/ת נדל״ן מורשה.';

  @override
  String get enterFullName => 'הזינו שם מלא';

  @override
  String get enterEmail => 'הזינו אימייל';

  @override
  String get selectNeighborhood => 'בחרו שכונה';

  @override
  String get familyStatusFamily => 'משפחה';

  @override
  String get selectDateOfBirth => 'בחרו תאריך לידה';

  @override
  String get termsOfService => 'תנאי השימוש';

  @override
  String get privacyPolicy => 'מדיניות הפרטיות';

  @override
  String get alreadyHaveAccount => 'יש לכם כבר חשבון?';

  @override
  String get fillRequiredFields => 'יש למלא את שדות החובה';

  @override
  String get choosePassword => 'בחרו סיסמה';

  @override
  String get reenterPassword => 'אשרו את הסיסמה';

  @override
  String get confirmPassword => 'אימות סיסמה';

  @override
  String get andConjunction => 'ו';

  @override
  String get privacyAndSecurity => 'פרטיות ואבטחה';

  @override
  String get changePasswordRow => 'שינוי סיסמה';

  @override
  String get searchEvents => 'חפשו אירועים, הופעות, פעילויות...';

  @override
  String get noEventsMatch => 'לא נמצאו אירועים מתאימים';

  @override
  String eventInterestedCount(int count) {
    return '$count מתעניינים';
  }

  @override
  String get noEventsOnMap => 'אין אירועים עם מיקום על המפה';

  @override
  String get searchPlaces => 'חיפוש מסעדה, מטבח או מקום';

  @override
  String get noPlacesOnMap => 'אין מקומות עם מיקום על המפה';

  @override
  String get noPlacesMatch => 'לא נמצאו מקומות מתאימים';

  @override
  String get viewAsList => 'תצוגת רשימה';

  @override
  String get notRatedYet => 'אין דירוג עדיין';

  @override
  String get shareRecommendation => 'שתפו את ההמלצה שלכם עם קהילת מודיעין.';

  @override
  String get mapLayerBusinesses => 'עסקים';

  @override
  String get mapLayerEvents => 'אירועים';

  @override
  String get mapLayerRealEstate => 'נדל\"ן';

  @override
  String get mapLayerParkings => 'חניונים';

  @override
  String get mapSearchHint => 'חיפוש מקומות, עסקים ואירועים';

  @override
  String get helpTitle => 'עזרה ותמיכה';

  @override
  String get helpSearchHint => 'חיפוש בעזרה';

  @override
  String get helpNoResults => 'לא נמצאו תוצאות';

  @override
  String get helpContactTitle => 'עדיין צריכים עזרה?';

  @override
  String get helpContactBody => 'כתבו לנו ונחזור אליכם.';

  @override
  String get helpContactButton => 'צרו קשר';

  @override
  String get helpQEditProfile => 'איך עורכים את פרטי הפרופיל?';

  @override
  String get helpAEditProfile =>
      'פתחו את הפרופיל ולחצו על “עריכת פרופיל”. אפשר לשנות שם, אימייל, טלפון, שכונה, מצב משפחתי ותאריך לידה, ואז ללחוץ על שמירה.';

  @override
  String get helpQPassword => 'איך משנים סיסמה?';

  @override
  String get helpAPassword =>
      'היכנסו להגדרות ← שינוי סיסמה. הזינו את הסיסמה הנוכחית ואז את החדשה פעמיים.';

  @override
  String get helpQLanguage => 'איך משנים את שפת האפליקציה?';

  @override
  String get helpALanguage =>
      'היכנסו להגדרות ← שפה ובחרו עברית או אנגלית. האפליקציה מתעדכנת מיד.';

  @override
  String get helpQFavorites => 'איך שומרים פריט במועדפים?';

  @override
  String get helpAFavorites =>
      'לחצו על הלב בכל עסק, אירוע, כתבה או נכס. כדי שהשמירה תתבצע צריך להיות מחוברים.';

  @override
  String get helpQFindFavorites => 'איפה המועדפים שלי?';

  @override
  String get helpAFindFavorites =>
      'פתחו את הפרופיל ולחצו על מועדפים. אפשר לסנן לפי עסקים, אירועים, חדשות או נכסים, או לראות הכול יחד.';

  @override
  String get helpQBusinesses => 'איך מוצאים עסקים במודיעין?';

  @override
  String get helpABusinesses =>
      'השתמשו בלשונית העסקים. אפשר לחפש לפי שם, לעיין לפי קטגוריה, או לפתוח את לשונית המפה כדי לראות אותם לפי מיקום.';

  @override
  String get helpQEvents => 'איך מוצאים אירועים?';

  @override
  String get helpAEvents =>
      'פתחו את מדור האירועים מהמסך הראשי. אפשר לחפש, או לעבור למפה כדי לראות איפה כל אירוע מתקיים.';

  @override
  String get helpQRealEstate => 'איך מחפשים דירות?';

  @override
  String get helpARealEstate =>
      'פתחו את הנדל\"ן מהמסך הראשי. סננו לפי שכונה, מחיר, חדרים וגודל, או עיינו במפה.';

  @override
  String get helpQAccount => 'איך מוחקים חשבון?';

  @override
  String get helpAAccount =>
      'היכנסו להגדרות ובחרו מחיקת חשבון. הפעולה מוחקת את הפרופיל ואי אפשר לבטל אותה.';

  @override
  String get onboardingTitle => 'כל מודיעין,\nבמקום אחד.';

  @override
  String get onboardingSubtitle =>
      'מסעדות, עסקים, אירועים, מבצעים, נדל\"ן ועוד.';

  @override
  String get onboardingSkip => 'דילוג';

  @override
  String get continueWithGoogle => 'המשך עם Google';

  @override
  String get dontHaveAccount => 'אין לכם חשבון?';

  @override
  String get onboardingTerms => 'בהרשמה אתם מסכימים ל';

  @override
  String get onboardingTermsFull =>
      'בהרשמה אתם מסכימים לתנאי השימוש ומדיניות הפרטיות';

  @override
  String resendAgainIn(String seconds) {
    return 'אפשר לשלוח שוב בעוד $seconds שניות.';
  }

  @override
  String get resendAgainSoon => 'אפשר לשלוח שוב בעוד רגע.';

  @override
  String get filter => 'סינון';

  @override
  String get delivery => 'משלוחים';

  @override
  String get clearFilter => 'נקו סינון';

  @override
  String get inModiinSuffix => ' במודיעין';

  @override
  String get openNowBadge => 'פתוח עכשיו';

  @override
  String get openNow => 'פתוח עכשיו';

  @override
  String get showAllPhotos => 'הצג את כל התמונות';

  @override
  String get businessGallery => 'גלריית העסק';

  @override
  String get eventCategories => 'קטגוריות אירועים';

  @override
  String get eventsInModiin => 'אירועים במודיעין';

  @override
  String get noUpcomingEvents => 'אין אירועים קרובים';

  @override
  String get newEventsAppearHere => 'אירועים חדשים יופיעו כאן';

  @override
  String peopleInterestedSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' מתעניינים',
      one: ' מתעניין',
    );
    return '$_temp0';
  }

  @override
  String get organizedBy => 'מארגנים';

  @override
  String get aboutThisEvent => 'על האירוע';

  @override
  String get whereIsIt => 'איפה זה?';

  @override
  String get youMayAlsoLike => 'אולי יעניין אתכם גם';

  @override
  String get allEvents => 'כל האירועים';

  @override
  String get free => 'חינם';

  @override
  String get noStoriesYet => 'אין כתבות להצגה';

  @override
  String get newStoriesAppearHere => 'כתבות חדשות יופיעו כאן';

  @override
  String get latestStories => 'הכתבות האחרונות';

  @override
  String get newsSeeAll => 'הצג הכל';

  @override
  String get nowInModiin => 'עכשיו במודיעין';

  @override
  String get moreRelatedNews => 'עוד חדשות קשורות';

  @override
  String get share => 'שיתוף';

  @override
  String get edit => 'עריכה';

  @override
  String get nothingMatchesFilter => 'אין תוצאות לסינון הזה';

  @override
  String searchInPlace(String place) {
    return 'חיפוש ב$place...';
  }

  @override
  String get parkingEmpty => 'החניונים יתווספו בקרוב';

  @override
  String parkingSpaces(int n) {
    return '$n מקומות חניה';
  }

  @override
  String parkingLotCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n חניונים',
      one: 'חניון אחד',
    );
    return '$_temp0';
  }

  @override
  String get parkingLoadError => 'לא הצלחנו לטעון את החניונים';

  @override
  String get parkingIntro => 'כל החניונים בעיר, על המפה.';

  @override
  String get parkingLotsHeading => 'חניונים';

  @override
  String get reviewBusinessResponse => 'תגובת העסק';

  @override
  String get sitePageAboutTitle => 'אודות';

  @override
  String get sitePageAccessibilityTitle => 'הצהרת נגישות';

  @override
  String get sitePageComingSoon => 'תוכן העמוד יפורסם בקרוב';

  @override
  String sitePageLastUpdated(String date) {
    return 'עודכן לאחרונה: $date';
  }

  @override
  String get sitePageBack => 'חזרה';

  @override
  String get sitePageLoadError => 'לא ניתן היה לטעון את העמוד';

  @override
  String get filterCuisine => 'סוג מטבח';

  @override
  String get allCuisines => 'כל סוגי המטבח';

  @override
  String get filterKosher => 'כשרות';

  @override
  String get notKosher => 'לא כשר';

  @override
  String get filterRating => 'דירוג';

  @override
  String get ratingAndUp => 'ומעלה';

  @override
  String get diningOptions => 'אפשרויות הגשה';

  @override
  String get sortBy => 'מיון';

  @override
  String get sortNewest => 'חדש ביותר';

  @override
  String get sortRating => 'דירוג';

  @override
  String get sortName => 'שם';

  @override
  String get candleLighting => 'כניסת שבת';

  @override
  String get havdalahLabel => 'צאת שבת';

  @override
  String get shabbatAndHolidaysTitle => 'שבת וחגים';

  @override
  String get upcomingHolidays => 'חגים ומועדים קרובים';

  @override
  String get noUpcomingHolidays => 'אין חגים בחודשים הקרובים';

  @override
  String get shabbatTimesCredit => 'הזמנים מ-Hebcal.com, מחושבים למודיעין';

  @override
  String get shabbatLoadError => 'לא ניתן היה לטעון את זמני השבת.';

  @override
  String get nearYou => 'קרוב אליך';

  @override
  String get businessesInModiin => 'עסקים במודיעין';

  @override
  String get showNearMe => 'הצג מה קרוב אליי';

  @override
  String get restaurantsInModiin => 'מסעדות במודיעין';

  @override
  String get allRestaurantsLink => 'לכל המסעדות';

  @override
  String get cafesAndBakeries => 'בתי קפה ומאפיות';

  @override
  String get allCafesLink => 'לכל בתי הקפה';

  @override
  String get mostRecommended => 'המומלצים ביותר';

  @override
  String get searchRestaurantsHint => 'חיפוש מסעדה, מטבח או מיקום';

  @override
  String placesCount(String count) {
    return '$count מקומות';
  }

  @override
  String get allBusinesses => 'כל העסקים';

  @override
  String get noBusinessesToShow => 'אין עסקים להצגה';

  @override
  String get businessesAppearHere => 'עסקים יופיעו כאן ברגע שיתווספו';

  @override
  String get searchBusinessesHint => 'חיפוש עסקים במודיעין';

  @override
  String businessesCount(String count) {
    return '$count עסקים';
  }

  @override
  String get openLabel => 'פתוח';

  @override
  String get verifiedResident => 'תושב מאומת';

  @override
  String get ownerReply => 'תגובת בעל העסק';

  @override
  String get couldNotLoadNeighborhood => 'לא הצלחנו לטעון את השכונה';

  @override
  String get neighborhoodNotFound => 'השכונה לא נמצאה';

  @override
  String get cityFullName => 'מודיעין מכבים רעות';

  @override
  String get propertiesForSale => 'נכסים למכירה';

  @override
  String get businessesInArea => 'עסקים באזור';

  @override
  String aboutPlace(String name) {
    return 'אודות $name';
  }

  @override
  String apartmentsForRentIn(String name) {
    return 'דירות להשכרה ב$name';
  }

  @override
  String apartmentsForSaleIn(String name) {
    return 'דירות למכירה ב$name';
  }

  @override
  String get noRentInNeighborhood => 'אין כרגע דירות להשכרה בשכונה הזו';

  @override
  String get noSaleInNeighborhood => 'אין כרגע דירות למכירה בשכונה הזו';

  @override
  String get perMonth => 'לחודש';

  @override
  String get noNotifications => 'אין התראות';

  @override
  String get notificationsAppearHere => 'כשיהיו עדכונים עבורכם, הם יופיעו כאן.';

  @override
  String get checkConnection => 'בדקו את החיבור לאינטרנט ונסו שוב';

  @override
  String get verifyingLink => 'מאמתים את הקישור…';

  @override
  String get linkInvalid => 'הקישור אינו בתוקף';

  @override
  String get resetLinkUsedOnce =>
      'כל קישור לאיפוס סיסמה פועל פעם אחת בלבד, ובקשה חדשה מבטלת את הקודמת. בקשו קישור חדש והשתמשו בו מההודעה האחרונה שהגיעה.';

  @override
  String get linkUsedOrExpired =>
      'ייתכן שהקישור כבר נוצל או שפג תוקפו. התחברו כדי לבקש קישור חדש.';

  @override
  String get requestNewLink => 'בקשת קישור חדש';

  @override
  String get sitePageTermsTitle => 'תקנון תנאי שימוש ומדיניות פרטיות';

  @override
  String get communityTitle => 'קהילה';

  @override
  String get communityIntro =>
      'הקהילה של מודיעין במקום אחד: קבוצת הפייסבוק, הסיפורים שלכם וחדשות מהעיר.';

  @override
  String get joinGroupTitle => 'הצטרפו לקבוצת הפייסבוק שלנו';

  @override
  String get joinGroupBody => 'שיחות עם תושבי מודיעין: שאלות, המלצות ועדכונים.';

  @override
  String get joinGroupCta => 'הצטרף עכשיו';

  @override
  String get shareWithUsTitle => 'שתפו אותנו';

  @override
  String get shareWithUsBody =>
      'שמעתם על משהו גדול? הייתם עדים לאירוע מסעיר? יש לכם תמונות או מידע שכולם חייבים לדעת? שלחו לנו – אנחנו נחקור, נאמת ונביא את הסיפור שלכם לקדמת הבמה!';

  @override
  String get shareWithUsCta => 'שליחת סיפור';

  @override
  String get communityNews => 'חדשות הקהילה';

  @override
  String parksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count פארקים',
      one: 'פארק אחד',
    );
    return '$_temp0';
  }

  @override
  String get replyToReview => 'הגבה';

  @override
  String get sendReply => 'שליחה';

  @override
  String get replySentForApproval => 'התגובה נשלחה ותופיע לאחר אישור.';

  @override
  String get signInToReply => 'התחברו כדי להגיב';

  @override
  String get couldNotSendReply => 'לא ניתן היה לשלוח את התגובה. נסו שוב.';

  @override
  String repliesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count תגובות',
      one: 'תגובה אחת',
    );
    return '$_temp0';
  }

  @override
  String get callAction => 'התקשרות';

  @override
  String get searchPlacesHint => 'חיפוש לפי שם או כתובת';

  @override
  String get nothingListedYet => 'עדיין לא נוספו רשומות.';

  @override
  String get couldNotLoadPlaces => 'לא ניתן היה לטעון את הרשימה.';

  @override
  String get noPlacesMatchSearch => 'אין תוצאות לחיפוש.';

  @override
  String get mapDataCredit => 'נתוני מפה © תורמי OpenStreetMap';

  @override
  String get noParksYet => 'עדיין לא נוספו פארקים';

  @override
  String get parksAppearHere => 'פארקים יופיעו כאן ברגע שיתווספו';

  @override
  String get restaurantsNearYou => 'מסעדות קרובות אליך';

  @override
  String get sgTabActivity => 'הפעילות שלי';

  @override
  String get sgTabGroups => 'קבוצות';

  @override
  String get sgConnectHealthConnect => 'חיבור ל-Health Connect';

  @override
  String get sgConnectAppleHealth => 'חיבור ל-Apple Health';

  @override
  String get sgConnectHealthBody =>
      'ספירת הצעדים המלאה של היום, החודש האחרון, מרחק וקלוריות — מהטלפון ומכל שעון.';

  @override
  String get sgConnect => 'חיבור';

  @override
  String get sgInstallHealthConnect => 'התקנת Health Connect';

  @override
  String get sgInstallHealthConnectBody =>
      'Health Connect, אפליקציה חינמית של Google, מאפשרת לאפליקציה לקרוא את היסטוריית הצעדים, המרחק והקלוריות.';

  @override
  String get sgInstall => 'התקנה';

  @override
  String get sgSourceHealthConnect => 'מתוך Health Connect';

  @override
  String get sgSourceAppleHealth => 'מתוך Apple Health';

  @override
  String get sgSourceSensor => 'נספר בטלפון כשהאפליקציה פתוחה';

  @override
  String get sgDistance => 'מרחק';

  @override
  String get sgActiveCalories => 'קלוריות פעילות';

  @override
  String get sgKcal => 'קק״ל';

  @override
  String get sgHistoryWeek => 'שבוע';

  @override
  String get sgHistoryMonth => 'חודש';

  @override
  String get sgLast30Days => '30 הימים האחרונים';

  @override
  String sgDailyAverage(String steps) {
    return 'ממוצע יומי $steps';
  }

  @override
  String sgPeriodTotal(String steps) {
    return 'סה״כ $steps';
  }

  @override
  String get sgSignInPrompt =>
      'התחברו כדי ליצור קבוצה, להזמין חברים וללכת יחד.';

  @override
  String get sgEmpty =>
      'עדיין אין קבוצות. צרו קבוצה והזמינו משפחה, חברים או עמיתים כדי להשוות צעדים.';

  @override
  String get sgCreateGroup => 'יצירת קבוצה';

  @override
  String get sgJoinWithCode => 'הצטרפות עם קוד';

  @override
  String get sgGroupName => 'שם הקבוצה';

  @override
  String get sgCreate => 'יצירה';

  @override
  String get sgInviteCode => 'קוד הזמנה';

  @override
  String get sgContinue => 'המשך';

  @override
  String sgMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count חברים',
      one: 'חבר אחד',
    );
    return '$_temp0';
  }

  @override
  String sgStepsToday(String steps) {
    return '$steps צעדים היום';
  }

  @override
  String sgMyRankToday(int rank) {
    return 'אתם במקום $rank היום';
  }

  @override
  String get sgOwner => 'מנהל/ת';

  @override
  String get sgInvite => 'הזמנה';

  @override
  String sgInviteMessage(String group, String link, String code) {
    return 'הצטרפו לקבוצת ההליכה שלי \"$group\" באפליקציית Modiin4U:\n$link\n\nאו הזינו את הקוד $code במונה הצעדים ← קבוצות ← הצטרפות עם קוד.';
  }

  @override
  String get sgToday => 'היום';

  @override
  String get sgThisMonth => 'החודש';

  @override
  String get sgGroupTotal => 'סה״כ הקבוצה';

  @override
  String get sgAverage => 'ממוצע לחבר';

  @override
  String get sgTopWalker => 'מוביל/ה';

  @override
  String get sgMembersTitle => 'חברים';

  @override
  String get sgGroupLast7 => 'הקבוצה, 7 הימים האחרונים';

  @override
  String get sgCompareTitle => 'השוואה';

  @override
  String get sgColMember => 'חבר/ה';

  @override
  String get sgRename => 'שינוי שם הקבוצה';

  @override
  String get sgSave => 'שמירה';

  @override
  String get sgNewInvite => 'קישור הזמנה חדש';

  @override
  String get sgNewInviteBody => 'קישורים וקודים שכבר נשלחו יפסיקו לעבוד.';

  @override
  String sgNewInviteDone(String code) {
    return 'קוד הזמנה חדש: $code';
  }

  @override
  String get sgDeleteGroup => 'מחיקת הקבוצה';

  @override
  String get sgDeleteGroupBody =>
      'הקבוצה תוסר עבור כל החברים. הצעדים של כל אחד נשארים אצלו.';

  @override
  String get sgLeaveGroup => 'יציאה מהקבוצה';

  @override
  String get sgLeaveGroupBody => 'אפשר לחזור עם הזמנה.';

  @override
  String get sgLeaveGroupOwnerBody =>
      'החבר/ה הוותיק/ה ביותר בקבוצה יהפוך/תהפוך למנהל/ת. אפשר לחזור עם הזמנה.';

  @override
  String get sgLeave => 'יציאה';

  @override
  String get sgRemove => 'הסרה';

  @override
  String sgRemoveMemberConfirm(String name) {
    return 'להסיר את $name מהקבוצה?';
  }

  @override
  String get sgGroupGone => 'הקבוצה הזו כבר לא זמינה.';

  @override
  String get sgInvitationTitle => 'הזמנה לקבוצת הליכה';

  @override
  String get sgJoinConsent =>
      'חברי הקבוצה רואים את מספר הצעדים היומי זה של זה. אפשר לצאת בכל עת.';

  @override
  String get sgJoin => 'הצטרפות לקבוצה';

  @override
  String get sgNotNow => 'לא עכשיו';

  @override
  String get sgSignInToJoin => 'התחברו כדי להצטרף';

  @override
  String get sgAlreadyMember => 'אתם כבר בקבוצה הזו.';

  @override
  String get sgOpenGroup => 'פתיחת הקבוצה';

  @override
  String get sgInviteInvalid => 'ההזמנה הזו כבר לא בתוקף. בקשו קישור חדש.';

  @override
  String get sgGroupFull => 'הקבוצה מלאה (50 חברים).';

  @override
  String get sgTooManyGroups => 'אפשר לנהל עד 10 קבוצות.';

  @override
  String get sgOpenInApp => 'פתיחה באפליקציה';

  @override
  String sgWebJoinHint(String code) {
    return 'יש לכם את אפליקציית Modiin4U? פתחו בה את ההזמנה, או הזינו את הקוד $code במונה הצעדים ← קבוצות ← הצטרפות עם קוד.';
  }

  @override
  String get sgNoStepsShared => 'עדיין לא נרשמו צעדים';

  @override
  String get sgRemoveHint => 'להסרת חבר/ה מהקבוצה, לחצו לחיצה ארוכה על השם.';

  @override
  String parkingFreeCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n מהם בחינם',
      one: 'אחד מהם בחינם',
    );
    return '$_temp0';
  }

  @override
  String get parkingPaid => 'בתשלום';

  @override
  String get parkingNavigateWith => 'ניווט עם';

  @override
  String get parkingWaze => 'Waze';

  @override
  String get parkingGoogleMaps => 'Google Maps';

  @override
  String get parkingPayment => 'תשלום';

  @override
  String get parkingPayCards => 'כרטיסי אשראי';

  @override
  String get parkingPayDebit => 'כרטיסי חיוב';

  @override
  String get parkingPayCash => 'מזומן בלבד';

  @override
  String get parkingPayNfc => 'תשלום ללא מגע';

  @override
  String parkingGoogleRating(String rating, int count) {
    return '$rating · $count דירוגים בגוגל';
  }

  @override
  String get parkingFromGoogle => 'מידע מתוך Google Maps';

  @override
  String get parkingViewOnGoogle => 'צפייה ב-Google Maps';

  @override
  String parkingPhotoBy(String name) {
    return 'צילום: $name';
  }

  @override
  String get parkingWebsite => 'אתר';

  @override
  String get parkingNotFound => 'החניון לא נמצא';

  @override
  String get whatLocalsSay => 'מה חושבים תושבי העיר?';
}
