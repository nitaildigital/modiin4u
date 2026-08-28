-- ============================================================
-- Modiin4u Control Center — Seed Data
-- 20 businesses, 10 articles, 10 events, 3 campaigns,
-- 10 users, neighborhoods, categories, offers, reviews
-- ============================================================

-- ─── Neighborhoods ───
insert into neighborhoods (id, name, slug, color, sort_order) values
  ('n01', 'אבני חן',     'avnei-hen',       '#17A9D0', 1),
  ('n02', 'מורשת',       'moreshet',        '#2ECC71', 2),
  ('n03', 'בוכמן',       'buchman',         '#FFC107', 3),
  ('n04', 'רמת מודיעין', 'ramat-modiin',    '#8B5CF6', 4),
  ('n05', 'כפר הנוער',   'kfar-hanoar',     '#E74C3C', 5),
  ('n06', 'מרכז העיר',   'merkaz-hair',     '#123A72', 6),
  ('n07', 'נופים',       'nofim',           '#FF9800', 7),
  ('n08', 'ציפורים',     'tziporim',        '#00BCD4', 8),
  ('n09', 'שילת',        'shilat',          '#795548', 9),
  ('n10', 'מכבים',       'maccabim',        '#607D8B', 10);

-- ─── Categories — Businesses ───
insert into categories (id, scope, name, slug, sort_order) values
  ('cb01', 'business', 'מסעדות',        'restaurants',    1),
  ('cb02', 'business', 'קפה ומאפה',     'cafe-bakery',    2),
  ('cb03', 'business', 'בריאות',        'health',         3),
  ('cb04', 'business', 'ספורט וכושר',   'sports-fitness', 4),
  ('cb05', 'business', 'חינוך',         'education',      5),
  ('cb06', 'business', 'שירותים',       'services',       6),
  ('cb07', 'business', 'קניות',         'shopping',       7),
  ('cb08', 'business', 'רכב',           'automotive',     8),
  ('cb09', 'business', 'יופי וטיפוח',  'beauty',         9),
  ('cb10', 'business', 'בידור ופנאי',   'entertainment',  10);

-- Sub-categories
insert into categories (id, parent_id, scope, name, slug, sort_order) values
  ('cb11', 'cb01', 'business', 'פיצה',    'pizza',     1),
  ('cb12', 'cb01', 'business', 'אסייתי',  'asian',     2),
  ('cb13', 'cb01', 'business', 'בשרים',   'meat',      3),
  ('cb14', 'cb01', 'business', 'ים תיכוני','mediterranean', 4),
  ('cb15', 'cb01', 'business', 'דגים',    'fish',      5);

-- ─── Categories — Articles ───
insert into categories (id, scope, name, slug, sort_order) values
  ('ca01', 'article', 'עירייה',    'municipal',  1),
  ('ca02', 'article', 'עסקים',     'business',   2),
  ('ca03', 'article', 'ספורט',     'sports',     3),
  ('ca04', 'article', 'חינוך',     'education',  4),
  ('ca05', 'article', 'תרבות',     'culture',    5),
  ('ca06', 'article', 'ביטחון',    'safety',     6),
  ('ca07', 'article', 'נדל"ן',     'real-estate',7),
  ('ca08', 'article', 'קולינריה',  'food',       8);

-- ─── Categories — Events ───
insert into categories (id, scope, name, slug, sort_order) values
  ('ce01', 'event', 'הופעות',      'concerts',     1),
  ('ce02', 'event', 'ספורט',       'sports',       2),
  ('ce03', 'event', 'ילדים',       'kids',         3),
  ('ce04', 'event', 'קהילה',       'community',    4),
  ('ce05', 'event', 'סדנאות',      'workshops',    5),
  ('ce06', 'event', 'מזון ושתייה', 'food-drink',   6);

-- ─── Tags ───
insert into tags (id, name, slug) values
  ('t01', 'כשר',      'kosher'),
  ('t02', 'משלוחים',  'delivery'),
  ('t03', 'משפחות',   'families'),
  ('t04', 'חינם',     'free'),
  ('t05', 'מומלץ',    'recommended'),
  ('t06', 'חדש',      'new'),
  ('t07', 'ילדים',    'kids'),
  ('t08', 'נגיש',     'accessible'),
  ('t09', 'פתוח בשבת','open-shabbat'),
  ('t10', 'אורגני',   'organic');

-- ─── Admin Roles ───
insert into admin_roles (id, name, label, is_system) values
  ('r01', 'super_admin',   'מנהל ראשי',      true),
  ('r02', 'content_editor','עורך תוכן',      true),
  ('r03', 'business_mgr',  'מנהל עסקים',     true),
  ('r04', 'sales',         'מכירות',         true),
  ('r05', 'moderator',     'מודרטור',        true),
  ('r06', 'finance',       'כספים',          true),
  ('r07', 'support',       'תמיכה',          true),
  ('r08', 'analyst',       'אנליסט',         true);

-- ─── Super Admin: all permissions ───
insert into admin_role_permissions (role_id, module, action, allowed)
select 'r01', m, a, true
from unnest(array['businesses','articles','events','users','revenue','campaigns','push','offers','settings','audit','moderation','media','categories']) m,
     unnest(array['view','create','edit','delete','export']) a;

-- ─── Content Editor: articles + events ───
insert into admin_role_permissions (role_id, module, action, allowed)
select 'r02', m, a, true
from unnest(array['articles','events','media','categories']) m,
     unnest(array['view','create','edit','delete']) a;

-- ─── Business Manager: businesses ───
insert into admin_role_permissions (role_id, module, action, allowed)
select 'r03', m, a, true
from unnest(array['businesses','offers','media']) m,
     unnest(array['view','create','edit','delete']) a;

-- ─── Sales: revenue + campaigns ───
insert into admin_role_permissions (role_id, module, action, allowed)
select 'r04', m, a, true
from unnest(array['businesses','revenue','campaigns']) m,
     unnest(array['view','create','edit']) a;

-- ─── Ad Placements ───
insert into ad_placements (id, code, label, sort_order) values
  ('p01', 'HOME_TOP',           'ראש עמוד הבית',        1),
  ('p02', 'HOME_AFTER_NEWS',    'אחרי חדשות בעמוד הבית', 2),
  ('p03', 'ARTICLE_INLINE',     'תוך כדי כתבה',         3),
  ('p04', 'RESTAURANTS_TOP',    'ראש עמוד מסעדות',      4),
  ('p05', 'BUSINESS_CATEGORY',  'עמוד קטגוריה',         5),
  ('p06', 'EVENTS_TOP',         'ראש עמוד אירועים',     6),
  ('p07', 'MAP_BOTTOM',         'תחתית מפה',            7),
  ('p08', 'GAMES_HOME',         'עמוד משחקים',           8);

-- ─── Feature Flags (V1 defaults) ───
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

-- ─── Home Blocks (default layout) ───
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
