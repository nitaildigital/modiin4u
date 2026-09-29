#!/usr/bin/env python3
"""Fills the development database with SAMPLE content, and takes it out again.

The web design has sections that nothing in the database can fill yet: the
events calendar has only past events, `offers` and `listings` are empty, no
business has a review, and no banner slot has a campaign. So every one of
those sections draws its empty state, and the pages cannot be compared with
the Figma file. The owner asked for sample content in the development
database so each section has something to render — on the condition that all
of it comes out again with one command before launch.

What goes in, and where it comes from:

  events        16 upcoming events (October–December 2026), taken from the
                Events, Event Category and Event Detail frames: their titles,
                times, prices and "interested" counts, and their photographs.
                Venues are real places in Modiin (Anabe Park, the culture
                hall on Emek Dotan, the Maccabim sports centre, Titora hill,
                Lev HaIr). Filed under the existing event categories.
  offers        12 active deals on real businesses of a fitting kind, in the
                wording of the Deals frame ("20% off your dinner bill",
                "buy one get one free on all beverages"…). Their end dates
                are counted from the moment the script runs, so "time left"
                shows days and hours.
  listings      11 for sale, 11 for rent, every property type, from the Real
                Estate frames: prices, sizes, floors, the "via broker" ones,
                and the photographs. Streets are real Modiin streets; the
                neighbourhood is set only where the street is known to be in
                one of the `neighborhoods` rows (checked against
                OpenStreetMap and the city's own naming of its streets), and
                left empty otherwise.
  neighborhoods 4 real Modiin neighbourhoods the design pictures and the table
                lacked — HaNahalim, HaKeramim, HaNevi'im and Moriah — with the
                design's photographs, and for Moriah the design's description.
  media, entity_media  Moriah's gallery: the three photographs the Neighborhood
                frame draws (one large, two stacked), as `entity_media` rows
                with role 'gallery', in the order drawn.
  real_estate_agents  the one agent the listing page shows.
  reviews       41 approved reviews over 15 businesses that have photos,
                written by 6 sample reviewer accounts (the Restaurant Detail
                frame's Daniel Cohen, Maya Levi, Amit Shalev and Yael Friedman,
                and two more). The accounts are created through the Admin API
                with a `.test` address and no password, so nobody can sign in
                as them. The rating trigger (00025) rolls the reviews up onto
                each business.
  campaigns     20 banners, the design's own artwork, in every slot the
                design draws: HOME_TOP, HOME_MAP_SIDE, NEWS_SIDEBAR,
                RESTAURANTS_TOP, DEALS_TOP, and the two navbar menus (those use
                the photographs from the client's own WordPress mega menus).
  home_blocks   the "Traffic update" notice under the home hero.

And what it changes on rows that were already there — each previous value is
recorded before it is touched, and put back by --undo:

  businesses.is_recommended   on 8 businesses with photos ("Recommended for You")
  neighborhoods.image_url     Avnei Hen and Tziporim, the two the design pictures
  categories.image_url        the category circles on the Events and Deals pages
  articles.is_featured        off on the 8 invented articles supabase/seed_remote.sql put
                              in (PLAN.md §1f): two were featured and, having no photo,
                              took the news page's lead from the real stories

Photographs are in tool/sample_content/images and are uploaded to the
`media` bucket under `sample/`.

Everything the script writes is listed in tool/sample_content_registry.json:
the id of every row it created, every storage path, every account, and the
previous value of every field it changed. --undo works from that file alone.

Safe to run more than once: a row already in the registry is updated in place
rather than added again, and uploads overwrite their own path. Running it
again also moves the deals' end dates and the banners' start dates forward
from the new "now".

    python3 tool/seed_sample_content.py              # what it would do
    python3 tool/seed_sample_content.py --apply
    python3 tool/seed_sample_content.py --verify     # read it back with the public key
    python3 tool/seed_sample_content.py --undo --dry-run
    python3 tool/seed_sample_content.py --undo       # remove all of it
"""

import datetime as dt
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY = os.path.join(ROOT, 'tool', 'sample_content_registry.json')
IMAGES = os.path.join(ROOT, 'tool', 'sample_content', 'images')
BUCKET = 'media'
PREFIX = 'sample'

# Israel is on summer time until late October and winter time after; the
# events carry a local date and time, so only the timestamps below need a zone.
IL = dt.timezone(dt.timedelta(hours=3))
RUN_UNTIL = '2026-12-31T23:59:00+02:00'

# The site's own office line, from the design's footer. Sample listings and the
# sample agent route calls here rather than to a number that might be somebody's.
OFFICE_PHONE = '058-4770195'


# ═══════════════════════════════════════════════════════════
# Connection
# ═══════════════════════════════════════════════════════════

def env():
    """Read .env.local directly: the shell would treat a # inside a value as
    the start of a comment and cut it short."""
    values = {}
    with open(os.path.join(ROOT, '.env.local'), encoding='utf-8') as f:
        for line in f:
            line = line.rstrip('\n')
            if line.strip() and not line.lstrip().startswith('#'):
                key, _, value = line.partition('=')
                values[key] = value
    return values


ENV = env()
URL = ENV['SUPABASE_URL'].rstrip('/')
KEY = ENV['SUPABASE_SERVICE_ROLE_KEY']


class HttpError(Exception):
    pass


def http(method, url, body=None, headers=None, raw=None, key=KEY):
    h = {'apikey': key, 'Authorization': f'Bearer {key}'}
    data = None
    if raw is not None:
        data = raw
    elif body is not None:
        data = json.dumps(body).encode()
        h['Content-Type'] = 'application/json'
    h.update(headers or {})
    req = urllib.request.Request(url, method=method, data=data, headers=h)
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            text = r.read().decode()
            return json.loads(text) if text.strip() else None
    except urllib.error.HTTPError as e:
        raise HttpError(f'{method} {url.replace(URL, "")} -> {e.code}: {e.read().decode()[:400]}')


def rest(method, path, body=None, prefer=None):
    headers = {'Prefer': prefer} if prefer else None
    return http(method, f'{URL}/rest/v1/{path}', body, headers)


def q(value):
    return urllib.parse.quote(str(value), safe='')


# ═══════════════════════════════════════════════════════════
# Registry
# ═══════════════════════════════════════════════════════════

def empty_registry():
    return {
        'note': 'Written by tool/seed_sample_content.py. Everything the sample '
                'content added or changed; --undo reads this file.',
        'storage': [],
        'auth_users': {},
        'rows': {},
        'entity_categories': [],
        'modified': {},
    }


def load_registry():
    if os.path.exists(REGISTRY):
        with open(REGISTRY, encoding='utf-8') as f:
            reg = json.load(f)
        for k, v in empty_registry().items():
            reg.setdefault(k, v)
        return reg
    return empty_registry()


def save_registry(reg):
    reg['updated_at'] = dt.datetime.now(dt.timezone.utc).isoformat(timespec='seconds')
    tmp = REGISTRY + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(reg, f, ensure_ascii=False, indent=1)
    os.replace(tmp, REGISTRY)


# ═══════════════════════════════════════════════════════════
# The content
# ═══════════════════════════════════════════════════════════

def img(rel):
    """Public URL of a sample photograph once uploaded."""
    return f'{URL}/storage/v1/object/public/{BUCKET}/{PREFIX}/{rel}'


def waze(lat, lng):
    return f'https://waze.com/ul?ll={lat},{lng}&navigate=yes'


# Real places, located on OpenStreetMap.
ANABE = ('פארק ענבה', 'פארק ענבה, מודיעין', 31.8983, 35.0041)
LEV_HAIR = ('מרכז העיר', 'לב העיר, מודיעין', 31.8995, 35.0075)
CULTURE_HALL = ('היכל התרבות מודיעין', 'עמק דותן, מודיעין', 31.8992, 35.0147)
SPORTS = ('מרכז ספורט מכבים', 'נוף קדומים, מכבים, מודיעין', 31.8907, 35.0343)
TITORA = ('גבעת התיתורה', 'גבעת התיתורה, מודיעין', 31.9026, 35.0206)
BEGIN = ('שדרות מנחם בגין', 'דרך מנחם בגין, מודיעין', 31.8805, 35.0160)

INCLUDED = 'מה כלול:'

# key, title, category slugs, date, start, end, venue, price (None = free),
# interested (the design's count), featured, image, short, full
EVENTS = [
    ('summer-music-night', 'ערב מוזיקה תחת הכוכבים', ['concerts'], '2026-10-08', '20:00', '23:00', ANABE, 50, 124, True,
     'events/summer-music-night.jpg',
     'ערב של מוזיקה חיה תחת כוכבי מודיעין, עם אמנים מקומיים, אוכל ואווירה קהילתית.',
     'התכוננו לערב בלתי נשכח של מוזיקה חיה תחת כוכבי מודיעין. הופעות של אמנים מקומיים, מוזיקה טובה, אוכל ואווירה קהילתית תוססת.\n\n'
     'בין אם אתם מגיעים עם חברים, עם המשפחה או פשוט מחפשים יציאה טובה — ערב מוזיקה תחת הכוכבים הוא הדרך המושלמת ליהנות מערב של סוף קיץ.\n\n'
     f'{INCLUDED}\n• הופעות מוזיקה חיה\n• אוכל וכיבוד\n• ישיבה באוויר הפתוח\n• אווירה משפחתית\n• אמנים מקומיים'),
    ('community-festival', 'פסטיבל הקהילה של מודיעין', ['community'], '2026-10-09', '10:00', '14:00', LEV_HAIR, None, 86, True,
     'events/community-festival.jpg',
     'בוקר קהילתי במרכז העיר: דוכנים של עמותות וארגונים, הופעות ופעילות לכל המשפחה.',
     'פסטיבל הקהילה חוזר למרכז העיר. עמותות, ארגונים ומתנדבים מהעיר מציגים את הפעילות שלהם, לצד הופעות על הבמה ופעילויות לילדים.\n\n'
     'הזדמנות להכיר את מה שקורה בשכונות, להצטרף להתנדבות ולפגוש שכנים.\n\n'
     f'{INCLUDED}\n• דוכני עמותות וארגונים\n• הופעות על הבמה\n• פינת יצירה לילדים\n• הכניסה חופשית'),
    ('open-air-movie', 'ערב סרט באוויר הפתוח', ['community'], '2026-10-14', '20:30', '22:30', TITORA, None, 93, False,
     'events/open-air-movie.jpg',
     'מקרנת ענק על הדשא: מביאים שמיכה, מתיישבים ונהנים מסרט משפחתי תחת כיפת השמיים.',
     'ערב קולנוע קהילתי באוויר הפתוח. מסך גדול, מערכת הגברה ודשא רחב — כל מה שצריך זה שמיכה וכרית.\n\n'
     f'{INCLUDED}\n• הקרנת סרט משפחתי\n• פופקורן לילדים\n• הכניסה חופשית'),
    ('family-fun-day', 'יום כיף למשפחה', ['kids'], '2026-10-16', '11:00', '15:00', ANABE, 20, 64, False,
     'events/family-fun-day.jpg',
     'מתנפחים, משחקים, הפעלות ומוזיקה — יום שלם של כיף לכל המשפחה בפארק.',
     'יום כיף משפחתי בפארק ענבה עם מתנפחים, תחנות משחק, הפעלות לגיל הרך ומוזיקה.\n\n'
     f'{INCLUDED}\n• מתנפחים ומתקנים\n• הפעלות לגיל הרך\n• פינת ציור ויצירה\n• עמדת שתייה קרה'),
    ('acoustic-sunset', 'סשן אקוסטי בשקיעה', ['concerts'], '2026-10-18', '17:00', '19:30', TITORA, None, 86, False,
     'events/acoustic-sunset.jpg',
     'גיטרות, קולות ושקיעה מעל העיר — מופע אקוסטי אינטימי על גבעת התיתורה.',
     'מופע אקוסטי אינטימי בשעת השקיעה, עם נוף פתוח על העיר. מוזיקאים מקומיים בהרכבים קטנים.\n\n'
     f'{INCLUDED}\n• מופע אקוסטי\n• ישיבה על הדשא\n• הכניסה חופשית'),
    ('night-run', 'מרוץ הלילה של מודיעין', ['sports-events'], '2026-10-22', '19:30', '22:00', SPORTS, 35, 142, False,
     'events/night-run.jpg',
     'מרוץ לילה עירוני במקצים של 5 ו-10 ק״מ, לרצים מכל הרמות.',
     'מרוץ הלילה יוצא ממרכז הספורט במכבים, במקצים של 5 ו-10 ק״מ. מתאים לרצים ותיקים ולמתחילים.\n\n'
     f'{INCLUDED}\n• חולצת מרוץ\n• מדידת זמנים\n• עמדות שתייה לאורך המסלול\n• מדליה לכל המסיימים'),
    ('kids-cooking-workshop', 'סדנת בישול לילדים', ['kids', 'workshops'], '2026-10-23', '10:30', '12:30', CULTURE_HALL, 30, 35, False,
     'events/kids-cooking-workshop.jpg',
     'שפים קטנים במטבח: סדנת בישול ואפייה לילדים בגילאי 6–12.',
     'סדנה מעשית שבה הילדים מכינים בעצמם מנה ומאפה, ולוקחים הביתה את מה שהכינו ואת המתכונים.\n\n'
     f'{INCLUDED}\n• כל חומרי הגלם\n• סינר לכל משתתף\n• דף מתכונים\n• לגילאי 6–12'),
    ('open-air-music-movie', 'מוזיקה וסרט באוויר הפתוח', ['concerts', 'community'], '2026-10-28', '20:30', '23:00', ANABE, None, 93, False,
     'events/open-air-music-movie.jpg',
     'הופעה קצרה ואחריה סרט על מסך ענק — ערב קיץ אחרון בפארק.',
     'הערב נפתח בהופעה של להקה מקומית וממשיך בהקרנת סרט על מסך ענק בפארק.\n\n'
     f'{INCLUDED}\n• הופעה חיה\n• הקרנת סרט\n• הכניסה חופשית'),
    ('community-football', 'משחק כדורגל קהילתי', ['sports-events'], '2026-10-30', '10:30', '12:30', SPORTS, None, 68, False,
     'events/community-football.jpg',
     'משחק ידידות פתוח לכולם — הורים, ילדים ושכנים על אותו מגרש.',
     'בוקר של כדורגל קהילתי: קבוצות מעורבות, משחקים קצרים ואווירה טובה. מתאים מגיל 10.\n\n'
     f'{INCLUDED}\n• משחקים בקבוצות מעורבות\n• שופט ומאמנים\n• מים ופירות\n• ההשתתפות חופשית'),
    ('summer-nights-live', 'לילות מודיעין בהופעה חיה', ['concerts'], '2026-11-05', '20:30', '23:30', ANABE, None, 248, True,
     'events/summer-nights-live.jpg',
     'ערב הופעות גדול בפארק ענבה עם אמני הבית של מודיעין.',
     'במה גדולה, תאורה ומוזיקה חיה: ערב הופעות בפארק ענבה עם כמה מההרכבים המקומיים האהובים.\n\n'
     f'{INCLUDED}\n• שלוש הופעות\n• מתחם אוכל\n• הכניסה חופשית'),
    ('street-food-festival', 'פסטיבל אוכל רחוב מודיעין', ['food-drink', 'community'], '2026-11-12', '17:00', '23:00', LEV_HAIR, None, 326, True,
     'events/street-food-festival.jpg',
     'עשרות דוכני אוכל רחוב, מוזיקה ואווירת שוק לילה במרכז העיר.',
     'פסטיבל אוכל הרחוב מגיע למרכז העיר: דוכנים של מסעדות מהעיר ומהאזור, מוזיקה ואווירת שוק לילה.\n\n'
     f'{INCLUDED}\n• דוכני אוכל רחוב\n• מוזיקה חיה\n• פינת ישיבה\n• הכניסה חופשית'),
    ('family-fun-day-anava', 'יום כיף משפחתי בפארק ענבה', ['kids'], '2026-11-13', '10:00', '14:00', ANABE, 25, 184, False,
     'events/family-fun-day-anava.jpg',
     'פיקניק, הפעלות ומשחקים לכל המשפחה על הדשא של פארק ענבה.',
     'בוקר משפחתי על הדשא: מביאים סל פיקניק ונהנים מהפעלות, תחנות משחק ומופע ילדים.\n\n'
     f'{INCLUDED}\n• מופע ילדים\n• תחנות משחק\n• הפעלות יצירה'),
    ('night-run-2026', 'מרוץ הלילה מודיעין 2026', ['sports-events'], '2026-11-19', '19:30', '22:30', BEGIN, 40, 157, False,
     'events/night-run-2026.jpg',
     'מסלול לילה לאורך שדרות מנחם בגין, במקצים של 5, 10 ו-21 ק״מ.',
     'המרוץ העירוני הגדול של השנה יוצא משדרות מנחם בגין, במקצים של 5, 10 ו-21 ק״מ ובמקצה משפחות.\n\n'
     f'{INCLUDED}\n• חולצת מרוץ\n• מדידת זמנים אלקטרונית\n• עמדות שתייה\n• מדליה לכל המסיימים'),
    ('rock-festival', 'פסטיבל הרוק של מודיעין', ['concerts'], '2026-11-26', '19:30', '23:30', ANABE, 75, 168, True,
     'events/rock-festival.jpg',
     'ערב רוק עם להקות מקומיות ואורחות, במה גדולה ומתחם אוכל.',
     'פסטיבל הרוק של מודיעין: ארבע להקות, במה גדולה ומתחם אוכל ושתייה.\n\n'
     f'{INCLUDED}\n• ארבע הופעות\n• מתחם אוכל ושתייה\n• עמידה מול הבמה'),
    ('indie-music-night', 'ערב מוזיקת אינדי', ['concerts'], '2026-12-05', '21:00', '23:59', CULTURE_HALL, 40, 72, False,
     'events/indie-music-night.jpg',
     'הרכבי אינדי צעירים מהעיר ומהאזור, בהופעה במוצאי שבת.',
     'ערב של הרכבי אינדי צעירים — שירים מקוריים, אולם קטן ואווירה קרובה.\n\n'
     f'{INCLUDED}\n• שלוש הופעות\n• בר משקאות'),
    ('live-jazz-evening', 'ערב ג׳אז חי', ['concerts'], '2026-12-08', '20:30', '23:00', CULTURE_HALL, 60, 51, False,
     'events/live-jazz-evening.jpg',
     'שלישיית ג׳אז בהופעה חיה — סטנדרטים ישנים ועיבודים חדשים.',
     'ערב ג׳אז אינטימי עם שלישייה של סקסופון, קונטרבס ותופים — סטנדרטים ועיבודים חדשים.\n\n'
     f'{INCLUDED}\n• הופעה חיה\n• ישיבה ליד שולחנות\n• בר משקאות'),
]

# The design's deal cards: a percentage off, a fixed sum off, one plus one, a
# spa package. `ends` is counted from now; `featured` marks the carousel ones;
# `residents` is the design's "Residents Only" tag, stored as audience
# 'verified' (a verified resident).
OFFERS = [
    ('grill-dinner', 'grill-443', '20% הנחה על חשבון ארוחת הערב',
     '20% הנחה על כל החשבון בארוחת ערב במסעדה, לכל השולחן.',
     'בתוקף בימים א׳–ה׳ מהשעה 18:00, בישיבה במקום בלבד. יש להציג את ההטבה לפני התשלום. לא כפל מבצעים.',
     'offers/burger.jpg', dt.timedelta(days=2, hours=14), True, True, 200),
    ('evening-dress', 'la-eliya', '300 ₪ הנחה בקנייה מעל 2,999 ₪',
     'הנחה של 300 ₪ בקנייה או בהזמנת שמלה בסכום של 2,999 ₪ ומעלה.',
     'הטבה אחת לרכישה. לא תקף על פריטים שכבר במבצע. בתיאום מראש בחנות.',
     None, dt.timedelta(days=3, hours=5), True, True, 50),
    ('coffee-1plus1', 'roasters-modiin', '1+1 על כל המשקאות',
     'קונים משקה אחד ומקבלים את השני מתנה — על כל תפריט המשקאות.',
     'המשקה הזול מביניהם מתנה. בישיבה או בטייק אווי. עד פעמיים ביום לאדם.',
     None, dt.timedelta(days=1, hours=8), True, True, None),
    ('spa-packages', 'o-spa', '30% הנחה על כל חבילות הספא',
     '30% הנחה על כל חבילות הטיפולים בספא.',
     'בתיאום מראש בלבד ובכפוף לזמינות. לא כולל מוצרים. לא כפל מבצעים.',
     None, dt.timedelta(days=2, hours=14), True, True, 80),
    ('pizza-second-tray', 'papa-johns-modiin', 'מגש משפחתי שני ב-50%',
     'בהזמנת מגש משפחתי, המגש השני בחצי מחיר.',
     'בהזמנה טלפונית או באיסוף עצמי. המגש הזול מביניהם בהנחה. לא כולל תוספות.',
     None, dt.timedelta(days=6), True, False, None),
    ('dessert-for-two', 'betzel-hateena-modiin', 'קינוח מתנה לכל זוג',
     'בכל ארוחה זוגית — קינוח לבחירה מהתפריט, מתנה מאיתנו.',
     'בישיבה במקום. קינוח אחד לכל שני סועדים. לא כולל שישי ושבת.',
     'offers/dinner.jpg', dt.timedelta(days=9), False, False, None),
    ('facial-first', 'גילת-קוסמטיקס', '20% הנחה על טיפול פנים ראשון',
     '20% הנחה על טיפול הפנים הראשון שלכם בקליניקה.',
     'ללקוחות חדשים בלבד. בתיאום מראש.',
     'offers/cosmetics.jpg', dt.timedelta(days=12), False, True, 40),
    ('laser-second-entry', 'זירת-הלייזר-מודיעין', 'כניסה שנייה ב-50%',
     'מגיעים בזוג או בקבוצה? הכניסה השנייה בחצי מחיר.',
     'בתיאום מראש. לא כולל אירועי יום הולדת פרטיים.',
     None, dt.timedelta(days=14), False, False, None),
    ('wine-tasting', 'the-wine-stash', '15% הנחה על ערב טעימות יין',
     '15% הנחה על הרשמה לערב טעימות יין במקום.',
     'בכפוף למקום פנוי. מגיל 18 ומעלה.',
     None, dt.timedelta(days=20), False, False, 30),
    ('tyres-alignment', 'צמיגי-ליגד', 'כיוון פרונט מתנה בקניית 4 צמיגים',
     'בקנייה של ארבעה צמיגים — כיוון פרונט ואיזון גלגלים ללא תשלום.',
     'לרכבים פרטיים. בתיאום מראש.',
     None, dt.timedelta(days=25), False, False, None),
    ('ems-trial', 'only-20-ems-modiin', 'אימון ניסיון ראשון מתנה',
     'אימון EMS ראשון עם מאמן אישי, ללא עלות.',
     'למתאמנים חדשים בלבד. בתיאום מראש.',
     None, dt.timedelta(days=30), False, False, None),
    ('flowers-10', 'idan-fls-modiin', '10% הנחה על זרי פרחים',
     '10% הנחה על כל זרי הפרחים בחנות.',
     'לא כולל משלוחים. לא כפל מבצעים.',
     None, dt.timedelta(days=5), False, True, None),
]

AGENT = {
    'key': 'design-agent',
    'name': 'זאב שומאכר',
    'agency': 'RGF נכסים',
    'phone': OFFICE_PHONE,
    'whatsapp': OFFICE_PHONE,
    'photo': 'agents/agent.jpg',
    'about': 'יועץ נדל״ן במודיעין.',
}

# Neighbourhoods the design pictures ("Apartments by Neighborhoods", and the
# Moriah page) that the table did not have. All four are the city's own names
# for real neighbourhoods. The design's "Haganim" is left out: Modiin has no
# neighbourhood of that name (the nearest, HaMeginim, is a different word),
# so there is nothing true to file it as. Only Moriah has a description in
# the design; the others are left without one rather than given an invented
# one.
MORIAH = (
    'מוריה היא אחת השכונות הדרומיות ביותר במודיעין-מכבים-רעות. השכונה, שנקראה בעבר '
    'בוכמן דרום, החלה להתאכלס ב-2007 ומאופיינת בעיקר בבתים פרטיים ובבתים דו-משפחתיים.\n\n'
    'שם השכונה מייצג נשים מההיסטוריה היהודית הקדומה, ובהן ארבע האימהות וגיבורות מקראיות — '
    'וזה ניכר גם בשמות רבים מרחובות השכונה.\n\n'
    'כיום מוריה משלבת מגורים עם פארקים, פנאי, חינוך ומסחר שכונתי. מיקומה הדרומי מקרב את '
    'התושבים לכבישים הראשיים ולשטחים הפתוחים שבדרום העיר.'
)
# slug, name, colour, sort order, photograph, description — in the shape of
# the existing rows (Hebrew name, Latin slug, a colour for the map).
NEW_NEIGHBORHOODS = [
    ('hanahalim', 'הנחלים', '#E91E63', 11, 'neighborhoods/hanahalim.jpg', None),
    ('hakeramim', 'הכרמים', '#9C27B0', 12, 'neighborhoods/hakeramim.jpg', None),
    ('haneviim', 'הנביאים', '#3F51B5', 13, 'neighborhoods/haneviim.jpg', None),
    ('moriah', 'מוריה', '#009688', 14, 'neighborhoods/moriah.jpg', MORIAH),
]

# The Neighborhood frame's three panels for Moriah, in the order drawn: the
# large one (also the neighbourhood's own picture), then the two stacked
# beside it.
MORIAH_GALLERY = [
    'neighborhoods/moriah.jpg',
    'neighborhoods/moriah-aerial.jpg',
    'neighborhoods/moriah-street.jpg',
]

# Neighbourhood slug is set only where the street is known to lie in that
# `neighborhoods` row. Modiin names its streets by neighbourhood — gemstones
# in Avnei Hen, presidents and prime ministers in Moreshet, birds in
# HaTziporim, forests in Nofim, prophets in HaNevi'im, the matriarchs and
# biblical women in Moriah — and OpenStreetMap agrees at each address. The
# valley boulevards (Emek HaEla) and Begin run between neighbourhoods, so
# those two follow OpenStreetMap at the listing's own point. Yitzhak Rabin
# boulevard is left without one: the sources disagree about which side it is.
HOODS_OF_STREET = {
    'יהלום': 'avnei-hen', 'אודם': 'avnei-hen', 'בדולח': 'avnei-hen',
    'חיים ויצמן': 'moreshet', 'יצחק שמיר': 'moreshet', 'שמעון פרס': 'moreshet',
    'דוכיפת': 'tziporim', 'עפרוני': 'tziporim',
    'יער בן שמן': 'nofim', 'לב העיר': 'merkaz-hair', 'נוף קדומים': 'maccabim',
    'יונה הנביא': 'haneviim', 'עמק האלה': 'haneviim',
    'שרה אמנו': 'moriah', 'דרך מנחם בגין': 'moriah',
}
STREET_AT = {
    'יהלום': (31.9064, 34.9974), 'אודם': (31.9042, 34.9951), 'בדולח': (31.9051, 34.9948),
    'חיים ויצמן': (31.9041, 34.9882), 'יצחק שמיר': (31.9041, 34.9801), 'שמעון פרס': (31.9052, 34.9829),
    'דוכיפת': (31.8971, 34.9974), 'עפרוני': (31.8961, 35.0015), 'שדרות יצחק רבין': (31.8916, 35.0047),
    'יער בן שמן': (31.8968, 34.9809), 'לב העיר': (31.8997, 35.0077), 'נוף קדומים': (31.8922, 35.0339),
    'יונה הנביא': (31.9103, 35.0114), 'דרך מנחם בגין': (31.8805, 35.0165), 'שרה אמנו': (31.8826, 35.0031),
    'עמק האלה': (31.9142, 35.0058),
}

G_HOME = ['listings/living-blue.jpg', 'listings/bedroom.jpg', 'listings/night-terrace.jpg', 'listings/pool-villa.jpg']

# key, kind, type, title, street, number, price, rooms, baths, floor, of, sqm,
# cover, gallery, broker, featured, features, description
LISTINGS = [
    # ── For sale ──
    ('mini-penthouse-avnei-hen', 'sale', 'penthouse', 'מיני פנטהאוז 6 חדרים בשכונת אבני חן', 'יהלום', 7,
     4350000, 6, 2, 4, 4, 140, 'listings/rooftop-pool.jpg', G_HOME, True, True,
     {'has_balcony', 'has_parking', 'has_elevator', 'has_mamad', 'has_storage'},
     'חדשה מקבלן: מיני פנטהאוז 6 חדרים במיקום מעולה בשכונת אבני חן, דירה עורפית! כניסה 4 חודשים מחתימת החוזה. 140 מ״ר בנוי ומרפסת של 18 מ״ר. תנאי תשלום 20/80 ללא הצמדות.'),
    ('yona-hanavi-duplex', 'sale', 'duplex', 'דופלקס 6 חדרים עם בריכה פרטית', 'יונה הנביא', 3,
     3650000, 6, 2, 3, 4, 140, 'listings/pool-villa.jpg', ['listings/night-terrace.jpg', 'listings/living-blue.jpg', 'listings/bedroom.jpg'], True, True,
     {'has_balcony', 'has_parking', 'has_elevator', 'has_mamad'},
     'דופלקס מרווח עם מרפסת גג ובריכה פרטית, סלון גדול ומטבח פתוח. שתי חניות ומחסן.'),
    ('begin-4-rooms', 'sale', 'apartment', 'דירת 4 חדרים בדרך מנחם בגין', 'דרך מנחם בגין', 84,
     3790000, 4, 2, 2, 8, 133, 'listings/balcony-view.jpg', ['listings/living-bright.jpg', 'listings/bedroom.jpg'], False, False,
     {'has_balcony', 'has_parking', 'has_elevator', 'has_mamad'},
     'דירת 4 חדרים מוארת עם מרפסת שמש ונוף פתוח. קרובה לתחבורה ציבורית, לבתי ספר ולמרכז מסחרי.'),
    ('sarah-imenu-4-rooms', 'sale', 'apartment', 'דירת 4 חדרים גדולה ברחוב שרה אמנו', 'שרה אמנו', 73,
     5690000, 4, 2, 3, 6, 145, 'listings/street-stone.jpg', ['listings/living-art.jpg', 'listings/bedroom.jpg'], True, False,
     {'has_balcony', 'has_parking', 'has_elevator', 'has_mamad', 'has_storage'},
     'דירה גדולה ומושקעת ברחוב שקט, עם מרפסת סוכה, חניה כפולה ומחסן.'),
    ('emek-haela-6-rooms', 'sale', 'apartment', 'דירת 6 חדרים ברחוב עמק האלה', 'עמק האלה', 37,
     3050000, 6, 2, 3, 7, 140, 'listings/tower-block.jpg', ['listings/living-dining.jpg', 'listings/bedroom.jpg'], False, False,
     {'has_balcony', 'has_parking', 'has_elevator', 'has_mamad'},
     'דירה משפחתית גדולה עם שלושה כיווני אוויר, קרובה לגני ילדים ולפארק.'),
    ('shimon-peres-5-rooms', 'sale', 'apartment', 'דירת 5 חדרים ברחוב שמעון פרס', 'שמעון פרס', 12,
     3600000, 5, 2, 2, 6, 120, 'listings/stone-entrance.jpg', ['listings/living-bright.jpg', 'listings/bedroom.jpg'], False, False,
     {'has_balcony', 'has_parking', 'has_elevator', 'has_mamad'},
     'דירת 5 חדרים בבניין בוטיק חדש, לובי מפואר, מרפסת שמש וחניה בטאבו.'),
    ('yitzhak-shamir-6-rooms', 'sale', 'apartment', 'דירת 6 חדרים עם נוף פתוח', 'יצחק שמיר', 20,
     4800000, 6, 3, 4, 9, 163, 'listings/towers-aerial.jpg', ['listings/balcony-view.jpg', 'listings/living-blue.jpg'], False, False,
     {'has_balcony', 'has_parking', 'has_elevator', 'has_mamad', 'has_storage'},
     'דירה גדולה בקומה גבוהה עם נוף פתוח למערב, שלוש יחידות הורים ומרפסת גדולה.'),
    ('dukhifat-garden', 'sale', 'garden', 'דירת גן 4 חדרים בשכונת הציפורים', 'דוכיפת', 9,
     4100000, 4, 2, 0, 4, 135, 'listings/living-art.jpg', ['listings/living-dining.jpg', 'listings/bedroom.jpg'], False, True,
     {'has_parking', 'has_mamad', 'has_storage', 'is_renovated'},
     'דירת גן משופצת עם גינה מטופחת של 80 מ״ר, יציאה ישירה מהסלון. קרובה לפורום הציפורים.'),
    ('nofim-villa', 'sale', 'villa', 'וילה 7 חדרים בשכונת נופים', 'יער בן שמן', 18,
     6450000, 7, 3, 0, 2, 260, 'listings/night-terrace.jpg', ['listings/pool-villa.jpg', 'listings/living-blue.jpg', 'listings/bedroom.jpg'], False, True,
     {'has_parking', 'has_mamad', 'has_storage', 'has_balcony'},
     'וילה על מגרש גדול עם בריכה, מרפסות וחניה לשני רכבים. חדר עבודה ויחידת הורים מפנקת.'),
    ('lev-hair-studio', 'sale', 'studio', 'סטודיו במרכז העיר', 'לב העיר', 11,
     1290000, 1, 1, 5, 9, 38, 'listings/living-ac.jpg', ['listings/living-bright.jpg'], False, False,
     {'has_elevator', 'has_mamad'},
     'סטודיו מעוצב צמוד לקניון ולתחנת הרכבת. מתאים למגורים או להשקעה.'),
    ('maccabim-semi-detached', 'sale', 'other', 'בית דו-משפחתי במכבים', 'נוף קדומים', 14,
     5200000, 6, 3, 0, 2, 210, 'listings/pool-villa.jpg', ['listings/living-bright.jpg', 'listings/living-dining.jpg'], False, False,
     {'has_parking', 'has_mamad', 'has_storage', 'has_balcony'},
     'בית דו-משפחתי בן שתי קומות עם גינה, חניה פרטית ומרתף.'),
    # ── For rent ──
    ('weizmann-penthouse-rent', 'rent', 'penthouse', 'פנטהאוז עם בריכה על הגג ברחוב חיים ויצמן', 'חיים ויצמן', 10,
     7500, 6, 2, 3, 3, 140, 'listings/rooftop-pool.jpg', ['listings/living-blue.jpg', 'listings/bedroom.jpg'], False, True,
     {'has_balcony', 'has_parking', 'has_elevator', 'has_mamad'},
     'פנטהאוז להשכרה עם מרפסת גג ובריכה, נוף פתוח וחניה. כניסה גמישה.'),
    ('shamir-4-rooms-rent', 'rent', 'apartment', 'דירת 4 חדרים יוקרתית ברחוב יצחק שמיר', 'יצחק שמיר', 12,
     12000, 4, 2, 2, 6, 122, 'listings/stone-entrance.jpg', ['listings/living-art.jpg', 'listings/bedroom.jpg'], True, True,
     {'has_balcony', 'has_parking', 'has_elevator', 'has_mamad', 'is_furnished'},
     'דירה מרוהטת ברמה גבוהה בבניין בוטיק, כולל מכשירי חשמל. מתאימה לרילוקיישן.'),
    ('rabin-4-rooms-rent', 'rent', 'apartment', 'דירת 4 חדרים בשדרות יצחק רבין', 'שדרות יצחק רבין', 40,
     6500, 4, 2, 3, 5, 85, 'listings/balcony-view.jpg', ['listings/living-bright.jpg'], False, False,
     {'has_balcony', 'has_parking', 'has_elevator'},
     'דירה נעימה עם מרפסת, קרובה לתחבורה ציבורית ולמרכז הקניות.'),
    ('emek-haela-duplex-rent', 'rent', 'duplex', 'דופלקס 6 חדרים ברחוב עמק האלה', 'עמק האלה', 37,
     8500, 6, 2, 3, 4, 140, 'listings/green-block.jpg', ['listings/living-dining.jpg', 'listings/bedroom.jpg'], True, False,
     {'has_balcony', 'has_parking', 'has_elevator', 'has_mamad', 'has_storage'},
     'דופלקס מרווח בבניין מטופח מוקף ירק, מרפסת גג וחניה כפולה.'),
    ('efroni-garden-rent', 'rent', 'garden', 'דירת גן 5 חדרים עם חצר', 'עפרוני', 6,
     8900, 5, 2, 0, 4, 128, 'listings/night-terrace.jpg', ['listings/living-dining.jpg', 'listings/bedroom.jpg'], False, False,
     {'has_parking', 'has_mamad', 'has_storage'},
     'דירת גן עם חצר גדולה ופרגולה, מתאימה למשפחה עם ילדים או עם כלב.'),
    ('lev-hair-studio-rent', 'rent', 'studio', 'סטודיו מרוהט במרכז העיר', 'לב העיר', 7,
     3600, 1, 1, 4, 9, 35, 'listings/living-ac.jpg', [], False, False,
     {'has_elevator', 'is_furnished'},
     'סטודיו מרוהט וממוזג, צמוד לקניון ולתחנת הרכבת. כולל ארנונה וחשבונות.'),
    ('nofim-villa-rent', 'rent', 'villa', 'וילה להשכרה בשכונת נופים', 'יער בן שמן', 22,
     16000, 7, 3, 0, 2, 240, 'listings/pool-villa.jpg', ['listings/night-terrace.jpg', 'listings/living-blue.jpg', 'listings/bedroom.jpg'], False, True,
     {'has_parking', 'has_mamad', 'has_storage', 'has_balcony'},
     'וילה עם בריכה וגינה גדולה, חמישה חדרי שינה וחניה פרטית.'),
    ('maccabim-unit-rent', 'rent', 'other', 'יחידת דיור נפרדת במכבים', 'נוף קדומים', 20,
     3900, 2, 1, 0, 1, 45, 'listings/living-art.jpg', ['listings/bedroom.jpg'], False, False,
     {'is_furnished', 'has_parking'},
     'יחידת דיור עם כניסה נפרדת וחצר קטנה, מרוהטת. מתאימה ליחיד או לזוג.'),
    ('odem-3-rooms-rent', 'rent', 'apartment', 'דירת 3 חדרים משופצת באבני חן', 'אודם', 11,
     5800, 3, 1, 1, 4, 78, 'listings/living-bright.jpg', ['listings/bedroom.jpg'], False, False,
     {'has_balcony', 'is_renovated', 'has_mamad'},
     'דירה משופצת מהיסוד, מטבח חדש ומרפסת שמש. קרובה לבתי ספר ולגני ילדים.'),
    ('bdolah-5-rooms-rent', 'rent', 'apartment', 'דירת 5 חדרים עם נוף פתוח', 'בדולח', 15,
     7200, 5, 2, 6, 8, 118, 'listings/towers-aerial.jpg', ['listings/living-blue.jpg', 'listings/bedroom.jpg'], False, False,
     {'has_balcony', 'has_parking', 'has_elevator', 'has_mamad'},
     'דירה בקומה גבוהה עם נוף פתוח, מרפסת גדולה וחניה.'),
    ('dukhifat-4-rooms-rent', 'rent', 'apartment', 'דירת 4 חדרים ליד הפארק', 'דוכיפת', 14,
     6900, 4, 2, 2, 5, 102, 'listings/tower-block.jpg', ['listings/living-art.jpg', 'listings/bedroom.jpg'], True, False,
     {'has_balcony', 'has_parking', 'has_elevator', 'has_mamad'},
     'דירה מטופחת במרחק הליכה מהפארק ומהמרכז המסחרי של השכונה.'),
]

REVIEWERS = [
    ('daniel', 'sample.reviewer1@modiin4u.test', 'דניאל כהן'),
    ('maya', 'sample.reviewer2@modiin4u.test', 'מאיה לוי'),
    ('amit', 'sample.reviewer3@modiin4u.test', 'עמית שלו'),
    ('yael', 'sample.reviewer4@modiin4u.test', 'יעל פרידמן'),
    ('noa', 'sample.reviewer5@modiin4u.test', 'נועה אברהם'),
    ('ron', 'sample.reviewer6@modiin4u.test', 'רון מזרחי'),
]

# business slug → [(reviewer, stars, text)]. The first four on the grill are
# the Restaurant Detail frame's own four, in Hebrew.
REVIEWS = {
    'grill-443': [
        ('daniel', 5, 'אוכל מעולה ומנות נדיבות. הבשרים על הגריל היו טריים ועשויים בדיוק כמו שצריך. הצוות היה נחמד והאווירה רגועה. בהחלט נחזור.'),
        ('maya', 5, 'באנו לארוחת ערב עם כל המשפחה ונהנינו מאוד. המעורב על האש היה מצוין והסלטים טריים. מקום מעולה לארוחה משפחתית.'),
        ('amit', 4, 'אוכל טוב, שירות נעים וישיבה נוחה בחוץ. בערב יכול להיות עמוס, אבל האוכל שווה את ההמתנה.'),
        ('yael', 5, 'השיפודים היו מדהימים והחומוס מהטובים שאכלתי. שירות אדיב ומחירים הוגנים. נחזור בטוח!'),
        ('noa', 4, 'מקום נעים עם מנות גדולות. לקחנו גם טייק אווי והכול הגיע חם ומסודר.'),
    ],
    'betzel-hateena-modiin': [
        ('ron', 5, 'ארוחת בוקר מושקעת במיוחד, הכול טרי ויפה על הצלחת. הקפה מעולה והצוות מקסים.'),
        ('maya', 4, 'אווירה נעימה ושקטה, מתאים לבראנץ׳ עם חברות. המנות טעימות, קצת המתנה בשישי בבוקר.'),
        ('amit', 5, 'אחד המקומות האהובים עלינו במודיעין. תמיד נקי, תמיד טעים, ותמיד מקבלים אותנו בחיוך.'),
    ],
    'roasters-modiin': [
        ('yael', 5, 'הקפה הכי טוב בעיר לדעתי. הבריסטות יודעים מה הם עושים, והמאפים טריים.'),
        ('daniel', 4, 'מקום מצוין לשבת עם מחשב בבוקר. קפה חזק וטעים, לפעמים קצת רועש.'),
        ('noa', 3, 'הקפה טוב, אבל התור בבוקר ארוך ובשעות העומס קשה למצוא מקום לשבת.'),
    ],
    'papa-johns-modiin': [
        ('amit', 5, 'פיצה טעימה עם בצק אוורירי, הגיעה חמה ומהר מהצפוי. הזמנו כבר כמה פעמים וזה תמיד עקבי.'),
        ('ron', 4, 'פיצה טובה ומשלוח מהיר. היינו שמחים לקצת יותר תוספות על המגש, אבל בסך הכול מרוצים.'),
        ('maya', 2, 'הפעם ההזמנה התעכבה והפיצה הגיעה פושרת. חבל, כי בפעמים הקודמות היה טוב.'),
    ],
    'sushibox-modiin': [
        ('noa', 5, 'סושי טרי ומגוון, והרולים המיוחדים ממש מוצלחים. המשלוח הגיע מסודר ובזמן.'),
        ('daniel', 5, 'מקום קבוע אצלנו לארוחת ערב באמצע השבוע. טעים, מהיר והמחיר סביר.'),
        ('yael', 3, 'הסושי בסדר, אבל הרולים היו קטנים ממה שציפינו לפי המחיר.'),
    ],
    'carmia-modiin': [
        ('maya', 5, 'פסטה טרייה ורטבים עשירים — מרגישים שהכול מוכן במקום. הילדים ביקשו לחזור כבר למחרת.'),
        ('ron', 4, 'מנות טעימות ומשביעות ושירות מהיר. המקום קטן, כדאי להגיע מוקדם.'),
    ],
    'patricks-modiin': [
        ('amit', 5, 'מנות הבשר עסיסיות והבירה קרה — בדיוק מה שצריך אחרי יום ארוך. אווירה כיפית ומוזיקה טובה.'),
        ('noa', 3, 'האוכל היה טוב, אבל המוזיקה הייתה חזקה מדי בשבילנו וקשה היה לדבר.'),
        ('daniel', 2, 'באותו ערב השירות היה איטי והמנות הגיעו פושרות. אולי פשוט תפסנו ערב חלש.'),
    ],
    'gabrielpatisseriemodiin': [
        ('yael', 5, 'עוגות וקינוחים ברמה של פטיסרי פריזאי. הזמנו עוגה ליום הולדת וכולם התלהבו.'),
        ('daniel', 5, 'הקרואסונים פשוט מושלמים — פריכים מבחוץ ורכים מבפנים. שווה כל שקל.'),
        ('ron', 4, 'קינוחים יפהפיים וטעימים. קצת יקר, אבל מתאים לאירוע מיוחד.'),
    ],
    'hachla-falafel-modiin': [
        ('daniel', 5, 'פלאפל חם ופריך, פיתה טרייה והמון סלטים לבחירה. מהיר וזול.'),
        ('amit', 5, 'הפלאפל הכי טוב באזור. תמיד טרי, תמיד חם, ושירות מהיר גם בשעות הצהריים.'),
        ('maya', 4, 'טעים ומשביע, רק חבל שאין יותר מקומות ישיבה.'),
    ],
    'alaesh-modiin': [
        ('yael', 4, 'בשר איכותי ותיבול מצוין. המנות גדולות, כדאי להגיע רעבים.'),
        ('noa', 5, 'חגגנו יום הולדת והצוות דאג לנו לאורך כל הערב. אוכל מצוין ושירות חם.'),
    ],
    'o-spa': [
        ('maya', 5, 'טיפול מפנק ומרגיע במיוחד, המטפלת מקצועית וקשובה. יצאתי כמו חדשה.'),
        ('noa', 5, 'חוויה מושלמת מההתחלה ועד הסוף. המקום נקי, שקט ומעוצב בטוב טעם.'),
    ],
    'זירת-הלייזר-מודיעין': [
        ('ron', 5, 'חגגנו יום הולדת לבן שלנו והילדים לא הפסיקו לדבר על זה. הצוות מארגן הכול ברמה גבוהה.'),
        ('amit', 4, 'כיף גדול לכל הגילאים. היה קצת עמוס בחופש, אבל שווה.'),
    ],
    'modiin-water-park': [
        ('yael', 5, 'יום כיף מושלם לכל המשפחה. המגלשות מעולות והמקום נקי ומסודר.'),
        ('daniel', 3, 'נהנינו, אבל בסוף השבוע היה עמוס מאוד והתורים למגלשות היו ארוכים.'),
        ('ron', 1, 'לא נהנינו הפעם: היה צפוף מאוד ולא מצאנו מקום בצל כל היום. אולי ננסה שוב ביום חול.'),
    ],
    'only-20-ems-modiin': [
        ('noa', 5, 'אימונים קצרים ויעילים, והמאמנת מלווה צמוד. אחרי חודש כבר מרגישים הבדל.'),
        ('maya', 4, 'שיטה מעניינת שחוסכת זמן. לוקח כמה אימונים להתרגל.'),
    ],
    'גילת-קוסמטיקס': [
        ('yael', 5, 'טיפול פנים מעולה, העור מרגיש רענן ונקי. גילת מקצועית ומסבירה כל שלב.'),
        ('amit', 4, 'הגעתי בעקבות המלצה ולא התאכזבתי. יחס אישי ותוצאות טובות.'),
    ],
}

RECOMMENDED = [
    'betzel-hateena-modiin', 'grill-443', 'roasters-modiin', 'sushibox-modiin',
    'carmia-modiin', 'patricks-modiin', 'gabrielpatisseriemodiin', 'hachla-falafel-modiin',
]

# The articles supabase/seed_remote.sql invented (PLAN.md §1f, slated for
# removal). Unfeatured so the news lead goes to a real story.
SEEDED_ARTICLES = [
    'anaba-park-upgrade', 'light-rail-update', 'new-commercial-center-maar', 'modiin-fc-promotion',
    'farmers-market-friday', 'school-year-opening', 'residents-survey-improvements',
    'japan-japan-chef-review',
]

NEIGHBORHOOD_PHOTOS = {
    'avnei-hen': 'neighborhoods/avnei-hen.jpg',   # the design's "Avni Chen / Kaiser"
    'tziporim': 'neighborhoods/tziporim.jpg',     # the design's "The Birds"
}

# (scope, slug) → photograph from the design's category circles.
CATEGORY_PHOTOS = {
    ('event', 'concerts'): 'categories/event-concerts.jpg',        # "Music"
    ('event', 'community'): 'categories/event-community.jpg',      # "Municipal & Community"
    ('event', 'kids'): 'categories/event-kids.jpg',                # "Kids & Family"
    ('event', 'sports-events'): 'categories/event-sports.jpg',     # "Sports"
    ('business', 'restaurants'): 'categories/business-restaurants.jpg',      # "Restaurants & Nightlife"
    ('business', 'shopping'): 'categories/business-shopping.jpg',            # "Shopping"
    ('business', 'beauty'): 'categories/business-beauty.jpg',                # "Beauty & Wellness"
    ('business', 'entertainment'): 'categories/business-entertainment.jpg',  # "Leisure & Culture"
    ('business', 'services'): 'categories/business-services.jpg',            # "Services"
}

# key, slot, name, image, business slug, destination. Listed in the order the
# design draws them; priority counts down so active_banners() keeps it.
CAMPAIGNS = [
    ('home-top-morasha', 'HOME_TOP', 'מורשה — מצאו את הבית שלכם במודיעין', 'campaigns/home-top-morasha.jpg', None, None),
    ('home-map-showtime', 'HOME_MAP_SIDE', 'פסח של כוכבים בעזריאלי מודיעין', 'campaigns/home-map-showtime.jpg', 'azrieli-modiin-mall', None),
    ('home-map-papa-johns', 'HOME_MAP_SIDE', 'פאפא ג׳ונס מודיעין', 'campaigns/home-map-papa-johns.jpg', 'papa-johns-modiin', 'https://papajohns.co.il'),
    ('home-map-discount', 'HOME_MAP_SIDE', 'דיסקונט — למצטרפים חדשים', 'campaigns/home-map-discount.jpg', 'discount-modiin', None),
    ('news-football', 'NEWS_SIDEBAR', 'מדריך למתחילים בכדורגל', 'campaigns/news-football.jpg', None, None),
    ('news-showtime', 'NEWS_SIDEBAR', 'פסח של כוכבים בעזריאלי מודיעין', 'campaigns/news-showtime.jpg', 'azrieli-modiin-mall', None),
    ('news-papa-johns', 'NEWS_SIDEBAR', 'פאפא ג׳ונס מודיעין', 'campaigns/news-papa-johns.jpg', 'papa-johns-modiin', 'https://papajohns.co.il'),
    ('news-football-2', 'NEWS_SIDEBAR', 'מדריך למתחילים בכדורגל', 'campaigns/news-football.jpg', None, None),
    ('restaurants-best-in-modiin', 'RESTAURANTS_TOP', 'המסעדות הטובות במודיעין — עד 40% הנחה', 'campaigns/restaurants-best-in-modiin.jpg', None, None),
    ('restaurants-eat-more', 'RESTAURANTS_TOP', 'אוכלים יותר, משלמים פחות', 'campaigns/restaurants-eat-more.jpg', None, None),
    ('restaurants-best-food', 'RESTAURANTS_TOP', 'גלו את האוכל הטוב במודיעין', 'campaigns/restaurants-best-food.jpg', None, None),
    ('deals-exclusive-50', 'DEALS_TOP', 'מבצעים בלעדיים במודיעין — עד 50% הנחה', 'campaigns/deals-exclusive-50.jpg', None, None),
    ('deals-best-restaurants-40', 'DEALS_TOP', 'המסעדות הטובות במודיעין — עד 40% הנחה', 'campaigns/deals-best-restaurants-40.jpg', None, None),
    ('deals-exclusive-60', 'DEALS_TOP', 'מבצעים בלעדיים — עד 60% הנחה', 'campaigns/deals-exclusive-60.jpg', None, None),
    ('menu-businesses-1', 'MENU_BUSINESSES', 'עסקים במודיעין 1', 'campaigns/menu-businesses-1.jpg', None, None),
    ('menu-businesses-2', 'MENU_BUSINESSES', 'עסקים במודיעין 2', 'campaigns/menu-businesses-2.jpg', None, None),
    ('menu-businesses-3', 'MENU_BUSINESSES', 'באשר פרומז׳רי', 'campaigns/menu-businesses-3.jpg', 'באשר-פרומזרי-ישפרו', None),
    ('menu-professionals-1', 'MENU_PROFESSIONALS', 'בעלי מקצוע במודיעין 1', 'campaigns/menu-professionals-1.jpg', None, None),
    ('menu-professionals-2', 'MENU_PROFESSIONALS', 'בעלי מקצוע במודיעין 2', 'campaigns/menu-professionals-2.jpg', None, None),
    ('menu-professionals-3', 'MENU_PROFESSIONALS', 'בעלי מקצוע במודיעין 3', 'campaigns/menu-professionals-3.jpg', None, None),
]

NOTICE = {
    'key': 'traffic-update',
    'title': 'עדכון תנועה',
    'config': {
        'title_en': 'Traffic update',
        'title_he': 'עדכון תנועה',
        'message_en': 'Road work on Begin St. - expect delays in the area',
        'message_he': 'עבודות בכביש ברחוב בגין — צפויים עיכובים באזור',
        'link_label_en': 'View details',
        'link_label_he': 'לפרטים',
    },
}


# ═══════════════════════════════════════════════════════════
# Apply
# ═══════════════════════════════════════════════════════════

class Seeder:
    def __init__(self, reg, now):
        self.reg = reg
        self.now = now
        self.counts = {}

    # ─── generic helpers ───

    def ids(self, table):
        return self.reg['rows'].setdefault(table, {})

    def exists(self, table, row_id):
        rows = rest('GET', f'{table}?id=eq.{q(row_id)}&select=id')
        return bool(rows)

    def upsert(self, table, key, payload, find=None):
        """Insert the row, or update it in place when it is already ours.

        `find` is a PostgREST filter that identifies the row by its natural
        key, for when the registry was lost but the row is still there."""
        known = self.ids(table)
        row_id = known.get(key)
        if row_id and not self.exists(table, row_id):
            row_id = None
        if not row_id and find:
            hit = rest('GET', f'{table}?{find}&select=id')
            if hit:
                row_id = hit[0]['id']
        if row_id:
            rest('PATCH', f'{table}?id=eq.{q(row_id)}', payload, prefer='return=minimal')
            action = 'updated'
        else:
            row_id = rest('POST', table, payload, prefer='return=representation')[0]['id']
            action = 'added'
        known[key] = row_id
        self.counts.setdefault(table, {'added': 0, 'updated': 0})[action] += 1
        save_registry(self.reg)
        return row_id

    def modify(self, table, row_id, fields):
        """Change fields on a row that was not ours, remembering what it held.

        The previous value is recorded only the first time: a second run must
        not record our own value as the one to go back to."""
        mod = self.reg['modified'].setdefault(table, {})
        if row_id not in mod:
            cols = ','.join(fields)
            current = rest('GET', f'{table}?id=eq.{q(row_id)}&select={cols}')[0]
            mod[row_id] = {'previous': current, 'set': fields}
            save_registry(self.reg)
        else:
            mod[row_id]['set'] = fields
        rest('PATCH', f'{table}?id=eq.{q(row_id)}', fields, prefer='return=minimal')
        save_registry(self.reg)

    def iso(self, delta):
        return (self.now + delta).isoformat(timespec='seconds')

    # ─── storage ───

    def upload_all(self):
        files = []
        for base, _, names in os.walk(IMAGES):
            for n in sorted(names):
                if n.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')):
                    files.append(os.path.relpath(os.path.join(base, n), IMAGES))
        for rel in sorted(files):
            path = f'{PREFIX}/{rel}'
            with open(os.path.join(IMAGES, rel), 'rb') as f:
                data = f.read()
            ctype = 'image/png' if rel.endswith('.png') else 'image/webp' if rel.endswith('.webp') else 'image/jpeg'
            http('POST', f'{URL}/storage/v1/object/{BUCKET}/{path}', raw=data,
                 headers={'Content-Type': ctype, 'x-upsert': 'true', 'Cache-Control': 'max-age=86400'})
            if path not in self.reg['storage']:
                self.reg['storage'].append(path)
        save_registry(self.reg)
        print(f'  storage: {len(files)} photographs in {BUCKET}/{PREFIX}/')

    # ─── accounts ───

    def reviewer_ids(self):
        users = self.reg['auth_users']
        existing = None
        for key, email, name in REVIEWERS:
            uid = users.get(key)
            if uid:
                try:
                    http('GET', f'{URL}/auth/v1/admin/users/{uid}')
                except HttpError:
                    uid = None
            if not uid:
                try:
                    user = http('POST', f'{URL}/auth/v1/admin/users', {
                        'email': email,
                        # No password is set: the address is .test and nobody
                        # can sign in as a sample reviewer.
                        'email_confirm': True,
                        'user_metadata': {'full_name': name, 'sample_content': True},
                    })
                    uid = user['id']
                except HttpError as e:
                    if 'already' not in str(e) and 'exists' not in str(e):
                        raise
                    if existing is None:
                        existing = http('GET', f'{URL}/auth/v1/admin/users?page=1&per_page=1000')['users']
                    uid = next(u['id'] for u in existing if (u.get('email') or '').lower() == email)
            users[key] = uid
            save_registry(self.reg)
            # The sign-up trigger (00015) makes the profile from the metadata;
            # this only makes sure the name is the one shown on the review.
            prof = rest('GET', f'profiles?id=eq.{uid}&select=id')
            if prof:
                rest('PATCH', f'profiles?id=eq.{uid}', {'full_name': name}, prefer='return=minimal')
            else:
                rest('POST', 'profiles', {'id': uid, 'full_name': name, 'email': email}, prefer='return=minimal')
        print(f'  auth users: {len(REVIEWERS)} sample reviewers')
        return dict(users)

    # ─── tables ───

    def events(self):
        cats = {c['slug']: c['id'] for c in rest('GET', 'categories?scope=eq.event&select=id,slug')}
        for (key, title, cat_slugs, date, start, end, venue, price, interested, featured,
             image, short, full) in EVENTS:
            vname, address, lat, lng = venue
            slug = f'sample-{key}'
            row_id = self.upsert('events', key, {
                'title': title,
                'slug': slug,
                'short_description': short,
                'full_description': full,
                'image_url': img(image),
                'og_image': img(image),
                'start_date': date,
                'start_time': start,
                'end_date': date,
                'end_time': end,
                'is_all_day': False,
                'venue_name': vname,
                'address': address,
                'latitude': lat,
                'longitude': lng,
                'waze_url': waze(lat, lng),
                'is_free': price is None,
                'price': price,
                'status': 'published',
                'is_featured': featured,
                'rsvp_count': interested,
                'published_at': self.iso(dt.timedelta(0)),
            }, find=f'slug=eq.{q(slug)}')
            for i, cs in enumerate(cat_slugs):
                link = ['event', row_id, cats[cs]]
                rest('POST', 'entity_categories?on_conflict=entity_type,entity_id,category_id',
                     {'entity_type': 'event', 'entity_id': row_id, 'category_id': cats[cs], 'is_primary': i == 0},
                     prefer='resolution=ignore-duplicates,return=minimal')
                if link not in self.reg['entity_categories']:
                    self.reg['entity_categories'].append(link)
            save_registry(self.reg)

    def businesses_by_slug(self, slugs):
        found = {}
        for s in slugs:
            rows = rest('GET', f'businesses?slug=eq.{q(s)}&select=id,slug,cover_url,status')
            if not rows:
                raise SystemExit(f'no business with slug {s!r} — the content list needs updating')
            found[s] = rows[0]
        return found

    def offers(self):
        biz = self.businesses_by_slug({o[1] for o in OFFERS})
        for key, slug, name, desc, terms, image, ends, featured, residents, max_claims in OFFERS:
            b = biz[slug]
            self.upsert('offers', key, {
                'business_id': b['id'],
                'name': name,
                'description': desc,
                'terms': terms,
                # Where the design has no photograph for the deal, the
                # business's own cover stands in.
                'image_url': img(image) if image else b['cover_url'],
                'status': 'active',
                'start_at': self.iso(-dt.timedelta(days=1)),
                'end_at': self.iso(ends),
                'max_claims': max_claims,
                'max_per_user': 1,
                'is_featured': featured,
                'audience': 'verified' if residents else 'all',
            }, find=f'business_id=eq.{b["id"]}&name=eq.{q(name)}')

    def neighborhoods(self):
        for slug, name, colour, order, photo, desc in NEW_NEIGHBORHOODS:
            self.upsert('neighborhoods', slug, {
                'name': name,
                'slug': slug,
                'description': desc,
                'image_url': img(photo),
                'color': colour,
                'sort_order': order,
                'is_active': True,
            }, find=f'slug=eq.{q(slug)}')

    def neighborhood_gallery(self):
        from PIL import Image
        moriah = self.ids('neighborhoods')['moriah']
        for order, rel in enumerate(MORIAH_GALLERY):
            local = os.path.join(IMAGES, rel)
            with Image.open(local) as im:
                w, h = im.size
            path = f'{PREFIX}/{rel}'
            media_id = self.upsert('media', f'moriah-gallery-{order}', {
                'file_name': os.path.basename(rel),
                'file_path': path,
                'url': img(rel),
                'mime_type': 'image/jpeg',
                'size_bytes': os.path.getsize(local),
                'width': w,
                'height': h,
                'alt_text': 'מוריה, מודיעין',
                'folder': f'{PREFIX}/neighborhoods',
            }, find=f'file_path=eq.{q(path)}')
            self.upsert('entity_media', f'moriah-gallery-{order}', {
                'media_id': media_id,
                'entity_type': 'neighborhood',
                'entity_id': moriah,
                'role': 'gallery',
                'sort_order': order,
            }, find=f'media_id=eq.{media_id}&entity_type=eq.neighborhood&entity_id=eq.{moriah}')

    def agent(self):
        return self.upsert('real_estate_agents', AGENT['key'], {
            'name': AGENT['name'],
            'agency': AGENT['agency'],
            'phone': AGENT['phone'],
            'whatsapp': AGENT['whatsapp'],
            'photo_url': img(AGENT['photo']),
            'about': AGENT['about'],
            'is_active': True,
        }, find=f'name=eq.{q(AGENT["name"])}&agency=eq.{q(AGENT["agency"])}')

    def listings(self, agent_id):
        hoods = {h['slug']: h['id'] for h in rest('GET', 'neighborhoods?select=id,slug')}
        for n, (key, kind, ptype, title, street, number, price, rooms, baths, floor, of, sqm,
                cover, gallery, broker, featured, features, desc) in enumerate(LISTINGS):
            lat, lng = STREET_AT[street]
            # A few metres apart per house number, so the pins do not stack.
            lat = round(lat + ((number * 37) % 11 - 5) * 0.00012, 6)
            lng = round(lng + ((number * 53) % 11 - 5) * 0.00012, 6)
            hood = HOODS_OF_STREET.get(street)
            slug = f'sample-{key}'
            payload = {
                'title': title,
                'slug': slug,
                'description': desc,
                'kind': kind,
                'property_type': ptype,
                'status': 'active',
                'rooms': rooms,
                'bathrooms': baths,
                'floor': floor,
                'total_floors': of,
                'sqm': sqm,
                'price': price if kind == 'sale' else None,
                'price_per_month': price if kind == 'rent' else None,
                'address': f'{street} {number}, מודיעין',
                'neighborhood_id': hoods.get(hood) if hood else None,
                'latitude': lat,
                'longitude': lng,
                'cover_url': img(cover),
                'gallery': [img(cover)] + [img(g) for g in gallery if g != cover],
                'agent_id': agent_id if broker else None,
                'is_broker': broker,
                'contact_name': None if broker else 'מודיעין בשבילך',
                'contact_phone': None if broker else OFFICE_PHONE,
                'is_featured': featured,
                'available_from': '2026-11-01' if kind == 'rent' else None,
                'published_at': self.iso(-dt.timedelta(hours=n)),
            }
            for f in ('has_parking', 'has_elevator', 'has_storage', 'has_balcony', 'has_mamad',
                      'is_furnished', 'is_accessible', 'is_renovated'):
                payload[f] = f in features
            self.upsert('listings', key, payload, find=f'slug=eq.{q(slug)}')

    def reviews(self, users):
        biz = self.businesses_by_slug(REVIEWS.keys())
        n = 0
        for slug, items in REVIEWS.items():
            for who, stars, body in items:
                n += 1
                author = users[who]
                business = biz[slug]['id']
                # Spread over the last two months, oldest first.
                when = self.now - dt.timedelta(days=62 - (n * 37) % 60, hours=(n * 7) % 12)
                self.upsert('reviews', f'{slug}/{who}', {
                    'business_id': business,
                    'author_id': author,
                    'rating': stars,
                    'body': body,
                    'status': 'approved',
                    'created_at': when.isoformat(timespec='seconds'),
                }, find=f'business_id=eq.{business}&author_id=eq.{author}')

    def campaigns(self):
        slots = {p['code']: p['id'] for p in rest('GET', 'ad_placements?select=id,code')}
        slugs = {c[4] for c in CAMPAIGNS if c[4]}
        biz = self.businesses_by_slug(slugs)
        per_slot = {}
        for key, code, name, image, bslug, dest in CAMPAIGNS:
            per_slot.setdefault(code, []).append(key)
        for key, code, name, image, bslug, dest in CAMPAIGNS:
            order = per_slot[code]
            self.upsert('campaigns', key, {
                'placement_id': slots[code],
                'business_id': biz[bslug]['id'] if bslug else None,
                'name': name,
                'status': 'active',
                'desktop_image': img(image),
                'mobile_image': img(image),
                'destination_url': dest,
                'start_at': self.iso(-dt.timedelta(days=1)),
                'end_at': RUN_UNTIL,
                'priority': len(order) - order.index(key),
                'target_audience': 'all',
            }, find=f'placement_id=eq.{slots[code]}&name=eq.{q(name)}'
                    f'&desktop_image=eq.{q(img(image))}&priority=eq.{len(order) - order.index(key)}')

    def notice(self):
        self.upsert('home_blocks', NOTICE['key'], {
            'block_type': 'alert',
            'title': NOTICE['title'],
            'config': NOTICE['config'],
            'sort_order': 0,
            'is_active': True,
            'published': True,
            'published_at': self.iso(dt.timedelta(0)),
            'audience': 'all',
            'start_at': self.iso(-dt.timedelta(days=1)),
            'end_at': RUN_UNTIL,
        }, find=f'block_type=eq.alert&title=eq.{q(NOTICE["title"])}')

    def changes(self):
        biz = self.businesses_by_slug(RECOMMENDED)
        for s in RECOMMENDED:
            self.modify('businesses', biz[s]['id'], {'is_recommended': True})
        hoods = {h['slug']: h['id'] for h in rest('GET', 'neighborhoods?select=id,slug')}
        for slug, photo in NEIGHBORHOOD_PHOTOS.items():
            self.modify('neighborhoods', hoods[slug], {'image_url': img(photo)})
        for (scope, slug), photo in CATEGORY_PHOTOS.items():
            rows = rest('GET', f'categories?scope=eq.{scope}&slug=eq.{q(slug)}&select=id')
            self.modify('categories', rows[0]['id'], {'image_url': img(photo)})
        for slug in SEEDED_ARTICLES:
            rows = rest('GET', f'articles?slug=eq.{q(slug)}&select=id')
            if rows:
                self.modify('articles', rows[0]['id'], {'is_featured': False})
        print(f'  changed: is_featured off on {len(SEEDED_ARTICLES)} seeded articles')
        print(f'  changed: is_recommended on {len(RECOMMENDED)} businesses, '
              f'{len(NEIGHBORHOOD_PHOTOS)} neighbourhood photos, {len(CATEGORY_PHOTOS)} category photos')


def apply():
    reg = load_registry()
    s = Seeder(reg, dt.datetime.now(IL).replace(microsecond=0))
    print('Applying sample content…')
    s.upload_all()
    users = s.reviewer_ids()
    s.events()
    s.offers()
    s.neighborhoods()
    s.neighborhood_gallery()
    agent_id = s.agent()
    s.listings(agent_id)
    s.reviews(users)
    s.campaigns()
    s.notice()
    s.changes()
    for table, c in s.counts.items():
        print(f'  {table}: {c["added"]} added, {c["updated"]} updated')
    print(f'Registry: {os.path.relpath(REGISTRY, ROOT)}')


# ═══════════════════════════════════════════════════════════
# Undo
# ═══════════════════════════════════════════════════════════

def undo(dry):
    if not os.path.exists(REGISTRY):
        print('No registry — nothing to undo.')
        return
    reg = load_registry()
    say = (lambda m: print('  would ' + m)) if dry else (lambda m: print('  ' + m))

    # Links first, then the rows. Reviews go before their authors so the
    # rating trigger recounts each business as they leave.
    for et, eid, cid in list(reg['entity_categories']):
        say(f'unlink {et} {eid[:8]} from category {cid[:8]}')
        if not dry:
            rest('DELETE', f'entity_categories?entity_type=eq.{et}&entity_id=eq.{eid}&category_id=eq.{cid}')
            reg['entity_categories'].remove([et, eid, cid])
            save_registry(reg)

    # Favourites and comments point at an event or a listing by id with no
    # foreign key, so nothing removes them with the row. Anyone who saved or
    # commented on a sample item while it was up would be left holding a
    # reference to nothing; only references to the sample rows are touched.
    sample_ids = list(reg['rows'].get('events', {}).values()) + list(reg['rows'].get('listings', {}).values())
    for table in ('favorites', 'comments'):
        for i in range(0, len(sample_ids), 50):
            chunk = ','.join(sample_ids[i:i + 50])
            hits = rest('GET', f'{table}?entity_id=in.({chunk})&select=id') or []
            if hits:
                say(f'delete {len(hits)} {table} left on sample events and listings')
                if not dry:
                    rest('DELETE', f'{table}?entity_id=in.({chunk})')

    order = ['campaigns', 'offers', 'reviews', 'listings', 'real_estate_agents', 'events',
             'home_blocks', 'entity_media', 'media', 'neighborhoods']
    for table in order + [t for t in reg['rows'] if t not in order]:
        rows = reg['rows'].get(table, {})
        if not rows:
            continue
        if table == 'neighborhoods':
            # Profiles and businesses point at a neighbourhood with no
            # ON DELETE rule, so a resident or a business filed under a sample
            # neighbourhood would block its removal. They lose the reference;
            # the neighbourhood they pointed at is going.
            chunk = ','.join(rows.values())
            for ref in ('profiles', 'businesses'):
                hits = rest('GET', f'{ref}?neighborhood_id=in.({chunk})&select=id') or []
                if hits:
                    say(f'clear the neighbourhood on {len(hits)} {ref} filed under a sample one')
                    if not dry:
                        rest('PATCH', f'{ref}?neighborhood_id=in.({chunk})', {'neighborhood_id': None},
                             prefer='return=minimal')
        say(f'delete {len(rows)} {table}')
        if dry:
            continue
        ids = list(rows.values())
        for i in range(0, len(ids), 50):
            chunk = ','.join(ids[i:i + 50])
            rest('DELETE', f'{table}?id=in.({chunk})')
        reg['rows'][table] = {}
        save_registry(reg)

    # Put back what was there, but only where the field still holds the value
    # this script set: if someone has changed it since, their change stands.
    for table, rows in reg['modified'].items():
        for row_id, entry in list(rows.items()):
            prev, ours = entry['previous'], entry['set']
            cols = ','.join(prev)
            now = rest('GET', f'{table}?id=eq.{q(row_id)}&select={cols}')
            if not now:
                say(f'skip {table} {row_id[:8]}: the row is gone')
            elif any(now[0].get(k) != v for k, v in ours.items()):
                say(f'leave {table} {row_id[:8]}: changed since ({now[0]})')
            else:
                say(f'restore {table} {row_id[:8]} to {prev}')
                if not dry:
                    rest('PATCH', f'{table}?id=eq.{q(row_id)}', prev, prefer='return=minimal')
            if not dry:
                del rows[row_id]
                save_registry(reg)

    # The accounts: deleting one removes its profile (and any review left).
    for key, uid in list(reg['auth_users'].items()):
        say(f'delete sample account {key} ({uid[:8]})')
        if not dry:
            try:
                http('DELETE', f'{URL}/auth/v1/admin/users/{uid}')
            except HttpError as e:
                if '404' not in str(e):
                    raise
            del reg['auth_users'][key]
            save_registry(reg)

    paths = list(reg['storage'])
    if paths:
        say(f'delete {len(paths)} photographs from {BUCKET}/{PREFIX}/')
        if not dry:
            for i in range(0, len(paths), 100):
                http('DELETE', f'{URL}/storage/v1/object/{BUCKET}', {'prefixes': paths[i:i + 100]})
            reg['storage'] = []
            save_registry(reg)

    if dry:
        print('Dry run — nothing removed. Run with --undo alone to remove it.')
    else:
        os.remove(REGISTRY)
        print('Sample content removed; registry deleted.')


# ═══════════════════════════════════════════════════════════
# Verify, with the key the public site uses
# ═══════════════════════════════════════════════════════════

def verify():
    cfg = open(os.path.join(ROOT, 'lib', 'core', 'supabase', 'supabase_config.dart'), encoding='utf-8').read()
    anon = re.search(r"anonKey\s*=\s*'([^']+)'", cfg).group(1)
    reg = load_registry()
    today = dt.date.today().isoformat()

    def get(path):
        return http('GET', f'{URL}/rest/v1/{path}', headers={'Prefer': 'count=exact'}, key=anon)

    def ids_of(table):
        return list(reg['rows'].get(table, {}).values())

    def seen(table, extra=''):
        ids = ids_of(table)
        if not ids:
            return 0, 0
        rows = get(f'{table}?id=in.({",".join(ids)})&select=id{extra}')
        return len(rows), len(ids)

    print('Public reads (anon key):')
    n, t = seen('events', f'&status=eq.published&start_date=gte.{today}')
    print(f'  events published and upcoming: {n}/{t}')
    n, t = seen('offers', '&status=eq.active')
    print(f'  offers active: {n}/{t}')
    n, t = seen('listings', '&status=eq.active')
    print(f'  listings active: {n}/{t}')
    n, t = seen('reviews', '&status=eq.approved')
    print(f'  reviews approved: {n}/{t}')
    n, t = seen('reviews', '&status=eq.approved&author_name=not.is.null')
    print(f'  reviews with the author\'s name: {n}/{t}')
    n, t = seen('neighborhoods', '&is_active=eq.true&image_url=not.is.null')
    print(f'  neighborhoods added (active, with photo): {n}/{t}')
    n, t = seen('listings', '&neighborhood_id=not.is.null')
    print(f'  listings with a neighbourhood: {n}/{t}')
    moriah = reg['rows'].get('neighborhoods', {}).get('moriah')
    if moriah:
        rows = get(f'entity_media?entity_type=eq.neighborhood&entity_id=eq.{moriah}&role=eq.gallery'
                   f'&select=sort_order,media(url)&order=sort_order') or []
        ok = 0
        for r in rows:
            try:
                req = urllib.request.Request(r['media']['url'], method='HEAD')
                with urllib.request.urlopen(req, timeout=30) as resp:
                    ok += resp.status == 200
            except Exception:
                pass
        print(f'  Moriah gallery (entity_media → media): {len(rows)} photos, {ok} load')
    n, t = seen('real_estate_agents')
    print(f'  real_estate_agents: {n}/{t}')
    n, t = seen('home_blocks')
    print(f'  home_blocks (notice): {n}/{t}')
    for code in sorted({c[1] for c in CAMPAIGNS}):
        rows = http('POST', f'{URL}/rest/v1/rpc/active_banners', {'p_code': code}, key=anon) or []
        ok = 0
        for r in rows:
            try:
                req = urllib.request.Request(r['image_url'], method='HEAD')
                with urllib.request.urlopen(req, timeout=30) as resp:
                    ok += resp.status == 200
            except Exception:
                pass
        print(f'  active_banners({code}): {len(rows)} banners, {ok} images load')


def plan():
    print('Dry run. Would add:')
    print(f'  {len(EVENTS)} events, {len(OFFERS)} offers, {len(LISTINGS)} listings, 1 agent,')
    print(f'  {len(NEW_NEIGHBORHOODS)} neighbourhoods, {len(MORIAH_GALLERY)} gallery photos for Moriah,')
    print(f'  {sum(len(v) for v in REVIEWS.values())} reviews by {len(REVIEWERS)} sample accounts,')
    print(f'  {len(CAMPAIGNS)} campaigns, 1 home notice,')
    print(f'  and set is_recommended on {len(RECOMMENDED)} businesses, photos on '
          f'{len(NEIGHBORHOOD_PHOTOS)} neighbourhoods and {len(CATEGORY_PHOTOS)} categories.')
    print('Re-run with --apply.')


def main():
    args = set(sys.argv[1:])
    if '--undo' in args:
        undo(dry='--dry-run' in args)
    elif '--verify' in args:
        verify()
    elif '--apply' in args:
        apply()
    else:
        plan()


if __name__ == '__main__':
    main()
