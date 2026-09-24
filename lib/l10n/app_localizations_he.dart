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
  String get stepBasics => 'בסיס';

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
  String get fillInPropertyDetails => 'מלאו את פרטי הנכס';

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
  String get addMoreDetails => 'הוסיפו פרטים נוספים על הנכס';

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
  String get uploadApartmentPhotos => 'העלו תמונות של הדירה';

  @override
  String get mainImage => 'תמונה ראשית';

  @override
  String get firstPhotoIsCover => 'התמונה הראשונה תשמש כתמונת השער';

  @override
  String get listingSubmitted => 'המודעה נשלחה!';

  @override
  String get submittedForApproval => 'הדירה שלכם נשלחה לאישור.';

  @override
  String get listingBeingReviewed => 'המודעה שלכם בבדיקה';

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
    return 'קומה $n';
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
    return '$n מבצעים';
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
}
