-- ============================================================
-- Modiin4u — Migration 00046
-- Two more information pages: the Privacy Policy, and deleting an account
--
-- The client's lawyer wrote the Terms of Use and the Privacy Policy as two
-- documents (5 Oct); the site had one page holding both ('terms', from the
-- old WordPress page). 'privacy' is the second page. Its text is the
-- lawyer's, pasted in the panel once his brackets are filled in, so the row
-- starts empty.
--
-- 'delete-account' is the address both documents give for deleting an
-- account, and Google Play asks for one: a page on the web that tells
-- someone how to delete their account, with or without the app. The text
-- below says what the app does — Settings → Delete account removes the
-- account through delete_own_account (00015), and with it what is keyed to
-- the profile; property listings are kept without an owner (00018), so the
-- page offers to remove them on request. The client reads it in the panel
-- (עמודי מידע) and publishes it; until then the page says it is coming.
--
-- Rows only, unpublished; nothing an earlier row held is touched.
-- Safe to run more than once.
-- ============================================================

insert into site_pages (slug, title_he, title_en)
values ('privacy', 'מדיניות פרטיות', 'Privacy Policy')
on conflict (slug) do nothing;

insert into site_pages (slug, title_he, title_en, body_he, body_en)
values (
  'delete-account',
  'מחיקת חשבון',
  'Deleting your account',
  $he$אפשר למחוק את החשבון שלכם במודיעין בשבילך בכל עת.

## מחיקה באפליקציה

- פתחו את התפריט (☰) והיכנסו להגדרות.
- בתחתית המסך הקישו על "מחיקת חשבון" ואשרו.

החשבון נמחק מיד, ואתם מנותקים מהאפליקציה.

## מחיקה בלי האפליקציה

שלחו דוא"ל אל modiin4uoffice@gmail.com מהכתובת שאיתה נרשמתם, עם הנושא "מחיקת חשבון". נמחק את החשבון ונעדכן אתכם בתשובה.

## מה נמחק

- החשבון והפרופיל
- הביקורות והתגובות שכתבתם
- המועדפים
- האירועים שסימנתם שאתם מגיעים אליהם
- נתוני הצעדים והשתתפות בקבוצות צעדים
- ההטבות שמימשתם
- המועמדויות למשרות ששלחתם

## מה לא נמחק אוטומטית

מודעות נדל"ן שפרסמתם נשארות באתר גם אחרי מחיקת החשבון. כדי להסיר אותן, ציינו זאת בדוא"ל ונסיר אותן.

ההתראות שייכות למכשיר ולא לחשבון: כדי להפסיק לקבל אותן, כבו אותן בהגדרות האפליקציה או הסירו אותה.

לפרטים נוספים ראו את מדיניות הפרטיות.$he$,
  $en$You can delete your Modiin4u account at any time.

## In the app

- Open the menu (☰) and go to Settings.
- At the bottom of the screen, tap "Delete account" and confirm.

The account is deleted straight away, and you are signed out of the app.

## Without the app

Send an e-mail to modiin4uoffice@gmail.com from the address you signed up with, with the subject "Delete my account". We will delete the account and let you know in our reply.

## What is deleted

- Your account and profile
- The reviews and replies you wrote
- Your favourites
- The events you marked as going to
- Your step data and your step group memberships
- The deals you claimed
- The job applications you sent

## What is not deleted automatically

Property listings you posted stay on the site after the account is deleted. To have them removed, say so in your e-mail and we will remove them.

Notifications belong to the device, not the account: to stop them, turn them off in the app's settings or uninstall it.

For more details, see the Privacy Policy.$en$
)
on conflict (slug) do nothing;
