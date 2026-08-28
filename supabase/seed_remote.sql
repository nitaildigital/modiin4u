-- ============================================================
-- Modiin4u Control Center — Seed Data (UUID-compatible)
-- ============================================================

-- ─── Neighborhoods ───
insert into neighborhoods (name, slug, color, sort_order) values
  ('אבני חן',     'avnei-hen',       '#17A9D0', 1),
  ('מורשת',       'moreshet',        '#2ECC71', 2),
  ('בוכמן',       'buchman',         '#FFC107', 3),
  ('רמת מודיעין', 'ramat-modiin',    '#8B5CF6', 4),
  ('כפר הנוער',   'kfar-hanoar',     '#E74C3C', 5),
  ('מרכז העיר',   'merkaz-hair',     '#123A72', 6),
  ('נופים',       'nofim',           '#FF9800', 7),
  ('ציפורים',     'tziporim',        '#00BCD4', 8),
  ('שילת',        'shilat',          '#795548', 9),
  ('מכבים',       'maccabim',        '#607D8B', 10);

-- ─── Categories — Businesses ───
insert into categories (scope, name, slug, sort_order) values
  ('business', 'מסעדות',        'restaurants',    1),
  ('business', 'קפה ומאפה',     'cafe-bakery',    2),
  ('business', 'בריאות',        'health',         3),
  ('business', 'ספורט וכושר',   'sports-fitness', 4),
  ('business', 'חינוך',         'education',      5),
  ('business', 'שירותים',       'services',       6),
  ('business', 'קניות',         'shopping',       7),
  ('business', 'רכב',           'automotive',     8),
  ('business', 'יופי וטיפוח',  'beauty',         9),
  ('business', 'בידור ופנאי',   'entertainment',  10);

-- Sub-categories for restaurants
insert into categories (parent_id, scope, name, slug, sort_order)
select id, 'business', sub.name, sub.slug, sub.ord
from categories c,
(values ('פיצה','pizza',1), ('אסייתי','asian',2), ('בשרים','meat',3), ('ים תיכוני','mediterranean',4), ('דגים','fish',5)) as sub(name, slug, ord)
where c.slug = 'restaurants' and c.scope = 'business';

-- ─── Categories — Articles ───
insert into categories (scope, name, slug, sort_order) values
  ('article', 'עירייה',    'municipal',  1),
  ('article', 'עסקים',     'business-news', 2),
  ('article', 'ספורט',     'sports',     3),
  ('article', 'חינוך',     'education-news', 4),
  ('article', 'תרבות',     'culture',    5),
  ('article', 'ביטחון',    'safety',     6),
  ('article', 'נדל"ן',     'real-estate',7),
  ('article', 'קולינריה',  'food',       8);

-- ─── Categories — Events ───
insert into categories (scope, name, slug, sort_order) values
  ('event', 'הופעות',      'concerts',     1),
  ('event', 'ספורט',       'sports-events',2),
  ('event', 'ילדים',       'kids',         3),
  ('event', 'קהילה',       'community',    4),
  ('event', 'סדנאות',      'workshops',    5),
  ('event', 'מזון ושתייה', 'food-drink',   6);

-- ─── Tags ───
insert into tags (name, slug) values
  ('כשר',      'kosher'),
  ('משלוחים',  'delivery'),
  ('משפחות',   'families'),
  ('חינם',     'free'),
  ('מומלץ',    'recommended'),
  ('חדש',      'new'),
  ('ילדים',    'kids'),
  ('נגיש',     'accessible'),
  ('פתוח בשבת','open-shabbat'),
  ('אורגני',   'organic');

-- ─── Admin Roles ───
insert into admin_roles (name, label, is_system) values
  ('super_admin',    'מנהל ראשי',      true),
  ('content_editor', 'עורך תוכן',      true),
  ('business_mgr',   'מנהל עסקים',     true),
  ('sales',          'מכירות',         true),
  ('moderator',      'מודרטור',        true),
  ('finance',        'כספים',          true),
  ('support',        'תמיכה',          true),
  ('analyst',        'אנליסט',         true);

-- ─── Super Admin: all permissions ───
insert into admin_role_permissions (role_id, module, action, allowed)
select r.id, m, a, true
from admin_roles r,
     unnest(array['businesses','articles','events','users','revenue','campaigns','push','offers','settings','audit','moderation','media','categories']) m,
     unnest(array['view','create','edit','delete','export']) a
where r.name = 'super_admin';

-- ─── Content Editor permissions ───
insert into admin_role_permissions (role_id, module, action, allowed)
select r.id, m, a, true
from admin_roles r,
     unnest(array['articles','events','media','categories']) m,
     unnest(array['view','create','edit','delete']) a
where r.name = 'content_editor';

-- ─── Business Manager permissions ───
insert into admin_role_permissions (role_id, module, action, allowed)
select r.id, m, a, true
from admin_roles r,
     unnest(array['businesses','offers','media']) m,
     unnest(array['view','create','edit','delete']) a
where r.name = 'business_mgr';

-- ─── Sales permissions ───
insert into admin_role_permissions (role_id, module, action, allowed)
select r.id, m, a, true
from admin_roles r,
     unnest(array['businesses','revenue','campaigns']) m,
     unnest(array['view','create','edit']) a
where r.name = 'sales';

-- ─── Ad Placements ───
insert into ad_placements (code, label, sort_order) values
  ('HOME_TOP',           'ראש עמוד הבית',         1),
  ('HOME_AFTER_NEWS',    'אחרי חדשות בעמוד הבית',  2),
  ('ARTICLE_INLINE',     'תוך כדי כתבה',          3),
  ('RESTAURANTS_TOP',    'ראש עמוד מסעדות',       4),
  ('BUSINESS_CATEGORY',  'עמוד קטגוריה',          5),
  ('EVENTS_TOP',         'ראש עמוד אירועים',      6),
  ('MAP_BOTTOM',         'תחתית מפה',             7),
  ('GAMES_HOME',         'עמוד משחקים',            8);

-- ─── Feature Flags ───
insert into feature_flags (key, label, is_enabled) values
  ('AI_SEARCH',    'חיפוש AI',          true),
  ('REAL_ESTATE',  'נדל"ן',             false),
  ('STEPS',        'מד צעדים',          true),
  ('MARKETPLACE',  'בעלי מקצוע',       false),
  ('GAMES',        'משחקים',            true),
  ('OFFERS',       'הטבות',             true),
  ('EVENTS',       'אירועים',           true),
  ('COMMUNITY',    'קהילה',             false);

-- ─── Point Rules ───
insert into point_rules (action, label, points, max_per_day) values
  ('signup',        'הרשמה',               50, null),
  ('review',        'כתיבת ביקורת',        20, 3),
  ('invite',        'הזמנת חבר',           100, null),
  ('daily_steps',   'יעד צעדים יומי',      5, 1),
  ('game_play',     'משחק',                3, 5),
  ('offer_claim',   'מימוש הטבה',          10, 2),
  ('event_rsvp',    'אישור הגעה לאירוע',   5, null),
  ('first_favorite','שמירה ראשונה',        10, null);

-- ─── Home Blocks ───
insert into home_blocks (block_type, title, sort_order, is_active, published, config) values
  ('hero',               null,                 1, true, true, '{}'),
  ('news_grid',          'חדשות אחרונות',      2, true, true, '{"items_count": 4}'),
  ('banner',             null,                 3, true, true, '{"placement": "HOME_TOP"}'),
  ('event_carousel',     'מה קורה היום?',      4, true, true, '{"items_count": 6}'),
  ('restaurant_carousel','מסעדות מומלצות',     5, true, true, '{"items_count": 8}'),
  ('business_carousel',  'עסקים חדשים',        6, true, true, '{"items_count": 8}'),
  ('offers',             'הטבות חמות',         7, true, true, '{"items_count": 4}'),
  ('game',               'משחק השבוע',         8, true, true, '{}'),
  ('ai_search',          'שאל את מודיעין AI',  9, true, true, '{}'),
  ('map_preview',        'מפת מודיעין',       10, true, true, '{}');

-- ─── Seed Businesses (20) ───
-- First get the neighborhood IDs we need
do $$
declare
  n_merkaz uuid;
  n_avnei uuid;
  n_moreshet uuid;
  n_buchman uuid;
  n_ramat uuid;
  n_kfar uuid;
  n_nofim uuid;
  n_tziporim uuid;
  n_shilat uuid;
  n_maccabim uuid;
begin
  select id into n_merkaz from neighborhoods where slug = 'merkaz-hair';
  select id into n_avnei from neighborhoods where slug = 'avnei-hen';
  select id into n_moreshet from neighborhoods where slug = 'moreshet';
  select id into n_buchman from neighborhoods where slug = 'buchman';
  select id into n_ramat from neighborhoods where slug = 'ramat-modiin';
  select id into n_kfar from neighborhoods where slug = 'kfar-hanoar';
  select id into n_nofim from neighborhoods where slug = 'nofim';
  select id into n_tziporim from neighborhoods where slug = 'tziporim';
  select id into n_shilat from neighborhoods where slug = 'shilat';
  select id into n_maccabim from neighborhoods where slug = 'maccabim';

  insert into businesses (name, slug, neighborhood_id, short_description, full_description, meta_description, phone, address, latitude, longitude, rating, review_count, kosher_level, price_level, has_delivery, is_accessible, status, created_at) values
    ('פיצה פרגו', 'pizza-frago', n_merkaz, 'פיצריה איטלקית אותנטית', 'פיצריה איטלקית אותנטית במרכז מודיעין. פיצות, פסטות, סלטים ועוד.', 'פיצה פרגו — פיצריה איטלקית במודיעין. משלוחים, ישיבה במקום, כשר.', '08-9712345', 'רח׳ המעיין 12, מרכז העיר', 31.8975, 35.0104, 4.5, 87, 'rabbanut', '₪₪', true, true, 'active', now() - interval '18 months'),
    ('סופר פארם מודיעין', 'super-pharm-modiin', n_merkaz, 'בית מרקחת וקוסמטיקה', 'סניף סופר פארם — תרופות, קוסמטיקה ומוצרי טיפוח.', 'סופר פארם מודיעין — בית מרקחת, קוסמטיקה ופארם.', '08-9714567', 'מרכז עזריאלי מודיעין', 31.8960, 35.0120, 4.1, 42, 'none', '₪₪', false, true, 'active', now() - interval '16 months'),
    ('סטודיו שרה — יוגה ופילאטיס', 'studio-sara-yoga', n_avnei, 'יוגה ופילאטיס לכל הרמות', 'שיעורי יוגה ופילאטיס פרטיים וקבוצתיים.', 'סטודיו שרה — יוגה ופילאטיס במודיעין. שיעורים פרטיים וקבוצתיים.', '053-5556666', 'רח׳ האלון 8, אבני חן', 31.9010, 35.0050, 4.8, 63, 'none', '₪₪', false, true, 'active', now() - interval '14 months'),
    ('ביסטרו מודיעין', 'bistro-modiin', n_moreshet, 'מסעדת שף — מטבח ים תיכוני', 'מסעדת שף חדשה עם מטבח ים תיכוני מודרני. תפריט עונתי.', null, '08-9719999', 'רח׳ הנרקיס 3, מורשת', 31.8990, 35.0080, 0, 0, 'none', '₪₪₪', false, false, 'pending', now() - interval '7 days'),
    ('Japan Japan', 'japan-japan', n_merkaz, 'מסעדת סושי ואסייתי', 'מסעדה יפנית עם סושי, ראמן, ומנות אסייתיות מגוונות.', 'Japan Japan — סושי ואסייתי במודיעין. משלוחים וישיבה במקום.', '08-9715555', 'מרכז עזריאלי מודיעין', 31.8962, 35.0118, 4.3, 124, 'rabbanut', '₪₪₪', true, true, 'active', now() - interval '24 months'),
    ('ד"ר שלומי כהן — רופא שיניים', 'dr-shlomi-cohen-dental', n_buchman, 'מרפאת שיניים', 'מרפאת שיניים מתקדמת — טיפולים אסתטיים, שתלים, והלבנה.', 'ד"ר שלומי כהן — רופא שיניים במודיעין. שתלים, אסתטיקה, טיפולי שיניים.', '08-9718888', 'רח׳ השקד 15, בוכמן', 31.9025, 35.0065, 4.7, 38, 'none', null, false, true, 'active', now() - interval '20 months'),
    ('קפה גרג', 'cafe-greg', n_merkaz, 'בית קפה ומאפייה', 'סניף קפה גרג — קפה, מאפים, ארוחות בוקר וצהריים.', 'קפה גרג מודיעין — קפה, מאפים וארוחות.', '08-9713333', 'קניון עזריאלי מודיעין, קומה 1', 31.8958, 35.0122, 4.0, 95, 'rabbanut', '₪₪', false, true, 'active', now() - interval '30 months'),
    ('חנות ספורט מודיעין', 'sport-shop-modiin', n_nofim, 'ציוד ספורט', 'חנות ציוד ספורט — נעליים, ביגוד, ואביזרים לכל סוגי הספורט.', 'חנות ספורט מודיעין — ציוד ספורט, נעליים וביגוד.', '08-9716666', 'רח׳ הדקל 22, נופים', 31.9040, 35.0030, 3.9, 27, 'none', '₪₪', false, true, 'active', now() - interval '12 months'),
    ('פלאפל הכיכר', 'falafel-hakikar', n_merkaz, 'פלאפל ושווארמה', 'פלאפל טרי כל יום — גם שווארמה, חומוס וסלטים.', 'פלאפל הכיכר מודיעין — פלאפל, שווארמה וחומוס.', '08-9711111', 'כיכר העיר, מרכז מודיעין', 31.8970, 35.0100, 4.6, 210, 'mehadrin', '₪', true, true, 'active', now() - interval '36 months'),
    ('סלון אורלי — עיצוב שיער', 'salon-orly', n_avnei, 'מספרה ועיצוב שיער', 'סלון שיער — תספורות, צבע, החלקות והארכות.', 'סלון אורלי — עיצוב שיער במודיעין. תספורות, צבע, החלקות.', '054-7778888', 'רח׳ הזית 5, אבני חן', 31.9015, 35.0055, 4.4, 52, 'none', '₪₪', false, false, 'active', now() - interval '22 months'),
    ('מכון כושר FIT4U', 'fit4u-gym', n_ramat, 'מכון כושר מתקדם', 'מכון כושר עם ציוד מתקדם, שיעורים קבוצתיים, ומאמנים אישיים.', 'FIT4U — מכון כושר במודיעין. שיעורים, מאמנים אישיים, ציוד מתקדם.', '08-9717777', 'רח׳ התמר 10, רמת מודיעין', 31.9050, 35.0040, 4.2, 78, 'none', '₪₪₪', false, true, 'active', now() - interval '10 months'),
    ('מכבסת מודיעין', 'laundry-modiin', n_moreshet, 'מכבסה וניקוי יבש', 'מכבסה — ניקוי יבש, כביסה, גיהוץ ותיקונים.', 'מכבסת מודיעין — ניקוי יבש, כביסה וגיהוץ.', '08-9714444', 'רח׳ הרימון 7, מורשת', 31.8985, 35.0075, 3.8, 19, 'none', '₪', false, false, 'active', now() - interval '28 months'),
    ('גן ילדים שמש', 'gan-shemesh', n_tziporim, 'גן ילדים פרטי', 'גן ילדים פרטי לגילאי 3-6 — חינוך, יצירה ומשחק.', 'גן שמש — גן ילדים פרטי במודיעין. גילאי 3-6.', '052-3334444', 'רח׳ הציפור 12, ציפורים', 31.9030, 35.0090, 4.9, 44, 'none', '₪₪₪', false, true, 'active', now() - interval '26 months'),
    ('אופטיקה ראייה', 'optika-reiya', n_merkaz, 'משקפיים ועדשות מגע', 'חנות אופטיקה — משקפי ראייה, שמש, ועדשות מגע. בדיקות ראייה.', 'אופטיקה ראייה מודיעין — משקפיים, עדשות מגע ובדיקות ראייה.', '08-9712222', 'קניון עזריאלי מודיעין, קומה 0', 31.8957, 35.0121, 4.3, 31, 'none', '₪₪₪', false, true, 'active', now() - interval '15 months'),
    ('מוסך אלי', 'musach-eli', n_shilat, 'מוסך רכב', 'מוסך מורשה — טיפולים, תיקונים, ומערכות חשמל רכב.', 'מוסך אלי — מוסך רכב מורשה במודיעין. טיפולים ותיקונים.', '08-9719111', 'אזור תעשייה שילת', 31.9060, 35.0010, 4.1, 56, 'none', null, false, false, 'active', now() - interval '40 months'),
    ('פרחי מודיעין', 'flowers-modiin', n_buchman, 'חנות פרחים', 'חנות פרחים — זרים, סידורי פרחים, ועציצים. משלוחים לכל העיר.', 'פרחי מודיעין — פרחים, זרים ומשלוחים.', '08-9715111', 'רח׳ הדס 3, בוכמן', 31.9020, 35.0060, 4.6, 67, 'none', '₪₪', true, false, 'active', now() - interval '32 months'),
    ('עורך דין דנה לוי', 'lawyer-dana-levi', n_moreshet, 'משרד עורכי דין', 'משרד עו"ד — נדל"ן, חוזים, דיני משפחה, וירושות.', 'עו"ד דנה לוי — משרד עורכי דין במודיעין. נדל"ן, חוזים, משפחה.', '08-9718111', 'רח׳ הגפן 14, מורשת', 31.8988, 35.0078, 4.5, 23, 'none', null, false, true, 'active', now() - interval '19 months'),
    ('פט שופ מודיעין', 'pet-shop-modiin', n_kfar, 'חנות חיות מחמד', 'חנות חיות — מזון, אביזרים, וטיפוח לכלבים, חתולים ועוד.', 'פט שופ מודיעין — חנות חיות מחמד. מזון, אביזרים וטיפוח.', '08-9716111', 'רח׳ הברוש 9, כפר הנוער', 31.9035, 35.0045, 4.0, 35, 'none', '₪₪', true, false, 'active', now() - interval '11 months'),
    ('מסעדת גויה', 'goya-restaurant', n_maccabim, 'מסעדת שף', 'מסעדת שף יוקרתית — מטבח צרפתי-ישראלי. תפריט טעימות.', 'גויה — מסעדת שף במודיעין מכבים. מטבח צרפתי-ישראלי.', '08-9713777', 'רח׳ הגפן 1, מכבים', 31.8940, 35.0150, 4.7, 156, 'rabbanut', '₪₪₪₪', false, true, 'active', now() - interval '48 months'),
    ('חנות ספרים סיפור', 'sipur-bookshop', n_buchman, 'חנות ספרים', 'חנות ספרים עצמאית — ספרות, ילדים, לימוד, ומתנות.', 'סיפור — חנות ספרים במודיעין. ספרות, ילדים ומתנות.', '08-9714222', 'רח׳ האגוז 6, בוכמן', 31.9022, 35.0062, 4.8, 41, 'none', '₪₪', false, true, 'active', now() - interval '35 months');
end;
$$;

-- ─── Seed Articles (10) ───
insert into articles (title, subtitle, slug, body, excerpt, status, is_breaking, is_featured, seo_title, meta_description, view_count, published_at, created_at) values
  ('פארק ענבה — שדרוג חדש לתושבים', 'פארק ענבה עובר מתיחת פנים', 'anaba-park-upgrade', 'עיריית מודיעין מכבים רעות השיקה היום את תוכנית השדרוג של פארק ענבה. התוכנית כוללת מגרשי משחקים חדשים, שבילים מונגשים, תאורה משודרגת, ומתחם כושר חיצוני. העבודות צפויות להסתיים תוך 6 חודשים.', 'פארק ענבה עובר שדרוג — מגרשים, שבילים ותאורה חדשים.', 'published', false, true, 'שדרוג פארק ענבה מודיעין', 'פארק ענבה במודיעין עובר שדרוג — מגרשי משחקים חדשים, שבילים ותאורה.', 1240, now() - interval '2 days', now() - interval '3 days'),
  ('פתיחת מרכז מסחרי חדש במע"ר', null, 'new-commercial-center-maar', 'מרכז מסחרי חדש בן 3 קומות צפוי להיפתח בחודשים הקרובים במע"ר מודיעין. המרכז יכלול חנויות אופנה, מסעדות, בית קפה, וחלל עבודה משותף. היזם מדווח על שיעור אכלוס של 70%.', 'מרכז מסחרי חדש במע"ר — חנויות, מסעדות ובילוי.', 'published', false, false, 'מרכז מסחרי חדש במע"ר מודיעין', 'מרכז מסחרי חדש במע"ר מודיעין — חנויות, מסעדות ובילוי.', 890, now() - interval '5 days', now() - interval '6 days'),
  ('קבוצת הכדורגל העירונית עלתה ליגה', null, 'modiin-fc-promotion', 'הקבוצה העירונית ניצחה אתמול 2-0 ועלתה לליגה הארצית. אלפי אוהדים חגגו ברחובות העיר. ראש העיר בירך את השחקנים ואמר: "זוהי הישג היסטורי לעיר מודיעין".', 'הקבוצה העירונית עלתה לליגה הארצית!', 'published', true, false, null, null, 2100, now() - interval '7 days', now() - interval '8 days'),
  ('טיפים לקיץ בטוח — מדריך הורים', null, 'summer-safety-tips', 'עם הגעת הקיץ חשוב לשמור על כללי בטיחות. הנה 10 טיפים: הגנה מהשמש, שתייה מרובה, השגחה על ילדים ליד מים, זהירות מחום יתר...', 'מדריך בטיחות קיץ להורים — 10 טיפים חשובים.', 'draft', false, false, null, 'מדריך בטיחות קיץ להורים — טיפים, הנחיות ומידע.', 0, null, now() - interval '9 days'),
  ('רכבת קלה למודיעין — עדכון מצב', null, 'light-rail-update', 'פרויקט הרכבת הקלה למודיעין ממשיך להתקדם. שלב התכנון המפורט הושלם ועבודות התשתית צפויות להתחיל ברבעון הראשון של 2027. הקו יחבר את מודיעין לירושלים ב-20 דקות.', 'עדכון על פרויקט הרכבת הקלה למודיעין.', 'published', false, true, 'רכבת קלה למודיעין — עדכון 2026', 'פרויקט הרכבת הקלה למודיעין — עדכון מצב, לוחות זמנים ותוכניות.', 3200, now() - interval '1 day', now() - interval '2 days'),
  ('שוק איכרים חדש נפתח בכל יום שישי', null, 'farmers-market-friday', 'שוק איכרים חדש ייפתח כל יום שישי בכיכר העיר מ-7:00 עד 14:00. השוק יציע ירקות ופירות אורגניים, גבינות, לחם, דבש, ומוצרים מקומיים.', 'שוק איכרים חדש בכל שישי במרכז מודיעין.', 'published', false, false, null, 'שוק איכרים מודיעין — כל שישי בכיכר העיר. ירקות אורגניים, גבינות ועוד.', 560, now() - interval '10 days', now() - interval '11 days'),
  ('פתיחת שנת הלימודים — כל מה שצריך לדעת', null, 'school-year-opening', 'שנת הלימודים מתחילה ב-1 בספטמבר. הנה כל המידע החשוב: רשימות ציוד, שעות פעילות, הסעות, ומידע על חוגים חדשים.', 'מידע על פתיחת שנת הלימודים במודיעין.', 'published', false, false, null, null, 1800, now() - interval '4 days', now() - interval '5 days'),
  ('סקר תושבים — מה אתם רוצים לשפר?', null, 'residents-survey-improvements', 'העירייה פרסמה סקר תושבים חדש. השתתפו והשפיעו על סדרי העדיפויות: תחבורה, חינוך, ספורט, תרבות, ועוד. הסקר פתוח עד סוף החודש.', 'סקר תושבים — השתתפו והשפיעו.', 'published', false, false, null, null, 430, now() - interval '12 days', now() - interval '13 days'),
  ('מסעדת Japan Japan — ביקורת שף', null, 'japan-japan-chef-review', 'ביקרנו במסעדת Japan Japan וטעמנו את תפריט הטעימות החדש. סושי מעולה, ראמן עשיר, ואווירה יפנית אותנטית. המחירים סבירים ביחס לאיכות.', 'ביקורת מסעדה: Japan Japan.', 'published', false, false, null, null, 1450, now() - interval '6 days', now() - interval '7 days'),
  ('עונת הגשמים — הכנה והתגוננות', null, 'winter-prep-guide', 'מודיעין מתכוננת לעונת הגשמים. העירייה מפרסמת מדריך: ניקוי מרזבים, בדיקת גגות, הכנת ערכות חירום, ועדכוני מזג אוויר.', 'מדריך הכנה לעונת הגשמים במודיעין.', 'draft', false, false, null, null, 0, null, now() - interval '3 days');

-- ─── Seed Events (10) ───
insert into events (title, slug, short_description, full_description, start_date, start_time, end_date, end_time, venue_name, address, latitude, longitude, is_free, status, is_featured, view_count, published_at, created_at) values
  ('הופעת אביב גפן — מודיעין', 'aviv-gefen-modiin', 'הופעה חיה של אביב גפן בפארק ענבה', 'אביב גפן מגיע למודיעין! הופעה חיה בפארק ענבה — להיטים ישנים וחדשים. שערים נפתחים ב-19:00.', '2026-08-25', '20:00', '2026-08-25', '22:30', 'פארק ענבה', 'פארק ענבה, מודיעין', 31.8980, 35.0095, false, 'published', true, 2800, now() - interval '5 days', now() - interval '6 days'),
  ('שוק איכרים שבועי', 'weekly-farmers-market', 'שוק איכרים בכל שישי', 'ירקות ופירות אורגניים, גבינות, לחם, דבש ומוצרים מקומיים. כל יום שישי 7:00-14:00.', '2026-08-22', '07:00', '2026-08-22', '14:00', 'כיכר העיר', 'כיכר העיר, מודיעין', 31.8968, 35.0098, true, 'published', false, 650, now() - interval '3 days', now() - interval '4 days'),
  ('סדנת בישול אסייתי', 'asian-cooking-workshop', 'סדנת בישול למבוגרים', 'למדו להכין סושי, פאד תאי, וראמן אמיתי. השף יאיר בן דוד מלמד טכניקות מקצועיות. מקסימום 15 משתתפים.', '2026-08-28', '18:00', '2026-08-28', '21:00', 'Japan Japan', 'מרכז עזריאלי מודיעין', 31.8962, 35.0118, false, 'published', false, 340, now() - interval '2 days', now() - interval '3 days'),
  ('יום כיף משפחות בפארק', 'family-fun-day-park', 'יום פעילויות לכל המשפחה', 'קפצנייה, ציור פנים, הופעת ליצנים, דוכני מזון, ומשחקי מים. חינם לכל התושבים!', '2026-08-30', '10:00', '2026-08-30', '17:00', 'פארק ענבה', 'פארק ענבה, מודיעין', 31.8980, 35.0095, true, 'published', true, 1200, now() - interval '1 day', now() - interval '2 days'),
  ('מרוץ מודיעין 2026', 'modiin-race-2026', 'מרוץ עירוני — 5K / 10K', 'מרוץ עירוני שנתי. מסלולי 5K ו-10K דרך שכונות העיר. הרשמה עד 20/8.', '2026-09-05', '07:00', '2026-09-05', '12:00', 'כיכר העיר — הזינוק', 'כיכר העיר, מודיעין', 31.8968, 35.0098, false, 'published', false, 890, now() - interval '7 days', now() - interval '8 days'),
  ('סיפורי ערב לילדים בספרייה', 'kids-storytime-library', 'שעת סיפור לגילאי 3-8', 'כל יום רביעי ב-17:00 — שעת סיפור עם הספרנית עדי. כניסה חופשית.', '2026-08-20', '17:00', '2026-08-20', '18:00', 'ספריית מודיעין', 'ספריית מודיעין, מרכז העיר', 31.8972, 35.0102, true, 'published', false, 180, now() - interval '10 days', now() - interval '11 days'),
  ('תערוכת אמנות מקומית', 'local-art-exhibition', 'תערוכה של אמנים מקומיים', 'תערוכה קבוצתית של 12 אמנים מקומיים — ציור, פיסול, צילום וקרמיקה. פתיחה חגיגית עם יין.', '2026-09-01', '19:00', '2026-09-15', null, 'גלריה מודיעין', 'מרכז תרבות מודיעין', 31.8965, 35.0108, true, 'published', false, 420, now() - interval '4 days', now() - interval '5 days'),
  ('יריד יזמות מודיעין', 'modiin-startup-fair', 'יריד סטארטאפים ויזמים', 'פגשו יזמים מקומיים, שמעו הרצאות, ונטוורקינג. בשיתוף הרשות לחדשנות ועיריית מודיעין.', '2026-09-10', '09:00', '2026-09-10', '18:00', 'מרכז הכנסים מודיעין', 'מרכז הכנסים, מע"ר', 31.8955, 35.0115, true, 'pending', false, 0, null, now() - interval '1 day'),
  ('קונצרט ג׳אז בפארק', 'jazz-in-the-park', 'קונצרט ג׳אז חינמי', 'הרכב הג׳אז של מודיעין מופיע בפארק ענבה. כניסה חופשית. מומלץ להביא שמיכה וחטיפים.', '2026-08-29', '20:00', '2026-08-29', '22:00', 'פארק ענבה', 'פארק ענבה, מודיעין', 31.8980, 35.0095, true, 'published', false, 310, now() - interval '3 days', now() - interval '4 days'),
  ('חוגי ילדים — רישום לשנת תשפ"ז', 'kids-activities-registration', 'רישום לחוגים לשנה הבאה', 'רישום לחוגים: כדורגל, ג׳ודו, בלט, ציור, מוזיקה, רובוטיקה, ועוד. הנחה לנרשמים מוקדם.', '2026-08-18', '09:00', '2026-09-01', null, 'אונליין', null, null, null, true, 'published', false, 950, now() - interval '8 days', now() - interval '9 days');
