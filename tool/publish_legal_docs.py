#!/usr/bin/env python3
"""Publishes the lawyer's Terms of Use and Privacy Policy with the template's
brackets filled in, in place of the WordPress text (tool/import_wp_legal.py).

The words are the lawyer's (the two .docx files of 5 Oct, read as
tool/import_legal_docs.py reads them). Only the brackets change, each one
listed in FILL below with where its value comes from:
  - a bracket around a value already written in it: the brackets go;
  - the operator, address, phone and e-mail: the documents' own values, used
    for the addresses the template left as examples (info@, legal@… on a
    domain with no mailboxes);
  - the accessibility coordinator: the panel's Accessibility Statement;
  - sign-in, outside services, where the data is held: what the app does
    (e-mail sign-in only; Supabase in ap-south-1, Mumbai; Firebase Cloud
    Messaging; Brevo for e-mail; PersonaAI for the chat, which we do not
    store; steps, distance and active energy from HealthKit / Health
    Connect; no analytics, crash or advertising SDK);
  - the lawyer's open choices: his own suggested values (age 16, 24 hours,
    30 days, 7 business days, 12 months), and notes that say "delete if
    unused" acted on;
  - each document's "internal appendix – not for publication" is cut, as it
    says.
The run stops if any bracket is left or a replacement does not match.

Whatever the rows held before is written to tool/legal_publish_registry.json,
and --undo puts exactly that back.

    python3 tool/publish_legal_docs.py            # show what would be written
    python3 tool/publish_legal_docs.py --apply
    python3 tool/publish_legal_docs.py --undo
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from import_legal_docs import DOCS, ROOT, current, db, to_text  # noqa: E402

REGISTRY = os.path.join(ROOT, 'tool', 'legal_publish_registry.json')
UPDATED = '08.10.2026'
EMAIL = 'modiin4uoffice@gmail.com'
PHONE = '058-4770195'
OPERATOR = 'מודיעין בשבילך, ח.פ./ע.מ. 558559068'
ADDRESS = 'אלמוגן 11, מודיעין'

# Each document is cut at its internal appendix.
CUT = {
    'terms': '## נספח פנימי – לא לפרסום',
    'privacy': '## נספחים פנימיים – לא לפרסום',
}

# (old, new, how many times old appears). Applied in order.
FILL = {
    'terms': [
        ('עדכון אחרון: [02.10.2026] · גרסה: [1.0]', f'עדכון אחרון: {UPDATED} · גרסה: 1.0', 1),
        ('מגיל [16]', 'מגיל 16', 2),
        ('[מודיעין בשבילך], ח.פ./ע.מ. [558559068], [אלמוגן 11, מודיעין]',
         f'{OPERATOR}, {ADDRESS}', 1),
        # Sign-in is by e-mail only: no phone, Google or Apple sign-in.
        ('באמצעות [טלפון / דוא"ל / Google / Apple].', 'באמצעות דוא"ל.', 1),
        (' [להחליט אם לאמץ את תקנון האתיקה של מועצת העיתונות והתקשורת].', '', 1),
        ('לפי [רלוונטיות לחיפוש, קרבה גיאוגרפית אם אישרתם מיקום, דירוג ממוצע, עדכניות ושלמות הרשומה].',
         'לפי רלוונטיות לחיפוש, קרבה גיאוגרפית אם אישרתם מיקום, דירוג ממוצע, עדכניות ושלמות הרשומה.', 1),
        ('לפי [ממוצע כל הביקורות שפורסמו].', 'לפי ממוצע כל הביקורות שפורסמו.', 1),
        ('"בשיתוף [שם המפרסם]"', '"בשיתוף" ושם המפרסם', 1),
        ('ל-modiin4uoffice@gmail.coml].', f'ל-{EMAIL}.', 1),
        (f'[{EMAIL}]', EMAIL, 4),
        ('תוך [24] שעות', 'תוך 24 שעות', 1),
        ('([שם הספק])', '(PersonaAI)', 1),
        ('[30] יום', '30 יום', 2),
        ('[שם רכז/ת הנגישות], [0584770195], ', f'ניתאי לוי, {PHONE}, ', 1),
        ('[שם מלא / שם החברה], [ח.פ./ע.מ.]', OPERATOR, 1),
        ('[רחוב, מספר, עיר, מיקוד]', ADDRESS, 1),
        ('[___]', PHONE, 1),
        ('[info@modiin4u.co.il]', EMAIL, 1),
        ('[legal@modiin4u.co.il]', EMAIL, 1),
        ('[corrections@modiin4u.co.il]', EMAIL, 1),
        ('[privacy@modiin4u.co.il]', EMAIL, 1),
        ('[appeals@modiin4u.co.il]', EMAIL, 1),
        ('בתוך [7] ימי עסקים', 'בתוך 7 ימי עסקים', 1),
        ('ב-[12] החודשים', 'ב-12 החודשים', 1),
    ],
    'privacy': [
        ('עדכון אחרון: [02.10.2026]', f'עדכון אחרון: {UPDATED}', 1),
        ('[מודיעין בשבילך], ח.פ./ע.מ. [558559068], בעלת', f'{OPERATOR}, בעלת', 1),
        ('ל[תנאי השימוש].', 'לתנאי השימוש.', 1),
        ('[מודיעין בשבילך] · ח.פ./ע.מ. [558559068] · [אלמוגן 11, מודיעין\n\n] · ',
         f'מודיעין בשבילך · ח.פ./ע.מ. 558559068 · {ADDRESS} · ', 1),
        # No Google or Apple sign-in, so the note says the sentence goes.
        ('\n\nמידע מצדדים שלישיים: אם תתחברו באמצעות Google או Apple, נקבל מהם את השם '
         'וכתובת הדוא"ל (או כתובת ממסרת של Apple) ומזהה חשבון. [למחוק אם אין התחברות חברתית].', '', 1),
        (' [לעדכן לפי המימוש].', '', 1),
        # health_steps.dart reads these three, with the person's permission.
        (' [לעדכן אם יתווספו מקורות נתונים, למשל HealthKit או Health Connect].',
         ' בהרשאתכם, נקראים מ-Apple Health (HealthKit) או מ-Health Connect נתוני הצעדים, '
         'המרחק והאנרגיה הפעילה בלבד.', 1),
        ('השירות כולל [סוכן / חיפוש] מבוסס', 'השירות כולל סוכן מבוסס', 1),
        ('אצל [שם ספק ה-AI], הפועל', 'אצל PersonaAI, הפועל', 1),
        # Nothing on record says what PersonaAI does with the chats, so only
        # our own part stays.
        ('- אימון מודלים: [הספק אינו משתמש בתוכן השיחות לאימון מודלים, בהתאם להסכם עמו]. '
         'אנו איננו משתמשים בשיחות לאימון מודלים [לעדכן אם ישתנה].',
         '- אימון מודלים: אנו איננו משתמשים בשיחות לאימון מודלים.', 1),
        # The chat runs in PersonaAI's page; the app keeps no conversations.
        ('- שמירה: שיחות נשמרות אצלנו עד 90 יום, לצורך מתן השירות, בקרת איכות וטיפול בשימוש לרעה. '
         'אצל הספק: [תקופה לפי ההסכם, למשל עד 30 יום או ללא שמירה].',
         '- שמירה: איננו שומרים את השיחות אצלנו. השיחות נשמרות אצל PersonaAI לפי תנאי השירות שלה.', 1),
        ('- סקירה אנושית: [צוות מורשה עשוי לעיין בשיחות מסוימות, בהיקף מוגבל, לצורך שיפור איכות וטיפול בתקלות ובדיווחים].',
         '- סקירה אנושית: צוות מורשה עשוי לעיין בשיחות מסוימות, בהיקף מוגבל, לצורך שיפור איכות וטיפול בתקלות ובדיווחים.', 1),
        (' [אם יוטמע SDK פרסומי – תוצג בקשת App Tracking Transparency והסעיף יעודכן].', '', 1),
        (' [למלא לאחר המיפוי הטכני; למחוק שורות שאינן בשימוש].', '', 1),
        # The providers table, one cell per paragraph.
        ('[Firebase / Supabase]', 'Supabase', 1),
        ('פרטי חשבון, תוכן, העדפות\n\n[מדינה]', 'פרטי חשבון, תוכן, העדפות\n\nהודו', 1),
        ('[Firebase Cloud Messaging / OneSignal]', 'Firebase Cloud Messaging', 1),
        ('מזהה Push, העדפות\n\n[מדינה]', 'מזהה Push, העדפות\n\nארה"ב', 1),
        ('[Google Analytics for Firebase]\n\nאנליטיקה\n\nנתוני שימוש, מזהי התקנה\n\n[מדינה]\n\n', '', 1),
        ('[Firebase Crashlytics / Sentry]\n\nדוחות קריסה וביצועים\n\nמידע טכני, לוגים\n\n[מדינה]\n\n', '', 1),
        ('[ספק AI]\n\nיכולות בינה מלאכותית\n\nשאלות, תוכן שיחה, הקשר\n\n[מדינה]',
         'PersonaAI\n\nיכולות בינה מלאכותית\n\nשאלות, תוכן שיחה, הקשר\n\nלפי תנאי PersonaAI', 1),
        ('[ספק דוא"ל / SMS]\n\nשליחת קודי אימות והודעות\n\nטלפון, דוא"ל\n\n[מדינה]',
         # No SMS is sent (phone sign-in is off), so only e-mail reaches Brevo.
         'Brevo\n\nשליחת קודי אימות והודעות\n\nדוא"ל\n\nצרפת (האיחוד האירופי)', 1),
        ('[Google / Apple Sign-In]\n\nהתחברות\n\nשם, דוא"ל, מזהה חשבון\n\n[מדינה]\n\n', '', 1),
        ('בין היתר [ארה"ב / האיחוד האירופי].', 'בין היתר הודו, ארה"ב והאיחוד האירופי.', 1),
        # Reviews and the rest of a person's content go with the account
        # (author_id ... on delete cascade).
        ('– יימחק, או יוצג כ"משתמש שנמחק" ללא פרטים מזהים כשהוא חלק מדיון של אחרים. [להחליט];',
         '– יימחק;', 1),
        ('פנו אל [privacy@modiin4u.co.il].', f'פנו אל {EMAIL}.', 1),
        ('תוך [30] יום.', 'תוך 30 יום.', 1),
        ('מגיל [13 / 16].', 'מגיל 16.', 1),
        (' [להחליט].', '', 1),
        ('## משתמשים בגילאי [13/16]–17:', '## משתמשים בגילאי 16–17:', 1),
        ('\n- [ככל שיידרש – מנגנון לאישור הורה לפיצ\'רים מסוימים].', '', 1),
        ('בעל השליטה במידע: [שם משפטי מלא], ח.פ./ע.מ. [מספר] כתובת: [כתובת] '
         'דוא"ל לענייני פרטיות: [privacy@modiin4u.co.il] [ממונה הגנת פרטיות, אם ימונה: שם ופרטי קשר]',
         f'בעל השליטה במידע: {OPERATOR} · כתובת: {ADDRESS} · דוא"ל לענייני פרטיות: {EMAIL}', 1),
    ],
}


def filled(slug):
    name = DOCS[slug][0]
    body = to_text(os.path.join(ROOT, name))
    cut = body.find(CUT[slug])
    if cut < 0:
        raise SystemExit(f'{slug}: internal appendix heading not found')
    body = body[:cut].rstrip()
    for old, new, times in FILL[slug]:
        n = body.count(old)
        if n != times:
            raise SystemExit(f'{slug}: expected {times}× {old[:60]!r}, found {n}')
        body = body.replace(old, new)
    left = [ln for ln in body.split('\n') if '[' in ln or ']' in ln]
    if left:
        raise SystemExit(f'{slug}: brackets left:\n' + '\n'.join(left))
    return body


def main():
    if '--undo' in sys.argv:
        reg = json.load(open(REGISTRY, encoding='utf-8'))
        for slug, before in reg.items():
            db('PATCH', f'site_pages?slug=eq.{slug}',
               {k: before[k] for k in ('title_he', 'title_en', 'body_he', 'is_published')})
            print('restored', slug)
        os.remove(REGISTRY)
        return

    apply = '--apply' in sys.argv
    if apply and os.path.exists(REGISTRY):
        raise SystemExit('already applied: run --undo first')

    bodies = {slug: filled(slug) for slug in DOCS}
    registry = {}
    for slug, body in bodies.items():
        before = current(slug)
        print(f'{slug}: {len(body.split())} words, no brackets left')
        if not apply:
            continue
        registry[slug] = before
        json.dump(registry, open(REGISTRY, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
        _, title_he, title_en = DOCS[slug]
        db('PATCH', f'site_pages?slug=eq.{slug}',
           {'title_he': title_he, 'title_en': title_en, 'body_he': body, 'is_published': True})
        print('published', slug)
    if not apply:
        print('dry run: pass --apply to write')


if __name__ == '__main__':
    main()
