#!/usr/bin/env python3
"""Every address the WordPress site has, and where it lives on the new site.

The client (1 Oct): "This is very important for SEO; it's this site's
strongest income source. Therefore, in the final migration, we also need to
export all current links and cross-reference them to the new ones."

Reads the old site's sitemaps (what Google knows) and its REST API (each
item's slug and Yoast title and description), matches every address to a
row in our database, and writes:

  tool/seo/url_map.csv     old address, kind, what it matched, new address,
                           and how — for Michael and for the redirects
  tool/seo/yoast.json      the Yoast title and description of each matched
                           row, which tool/seo_fill.py copies into the
                           database's SEO fields where they are empty

The new address keeps the old path wherever the new site can serve it
(news, businesses and both kinds of category keep theirs exactly — see the
slug routes in app_router.dart), so most addresses need no redirect at all.
Where the new site has no equivalent page, it names the nearest one and
the address is redirected there (deploy/nginx/seo-redirects.conf, written
by tool/build_seo_pages.py from this map).

Read only: nothing is written to WordPress or the database.

    python3 tool/seo_inventory.py

Reads SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY from .env.local.
"""
import csv
import html
import json
import os
import re
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'tool', 'seo')
WP = 'https://www.modiin4u.co.il'
UA = {'User-Agent': 'Mozilla/5.0 (modiin4u-seo-inventory)'}

SITEMAPS = [
    'page', 'news', 'apartments', 'real-estate-agents', 'professionals',
    'business', 'new', 'real-astate-agents', 'professionals-cat',
    'business-cat',
]

# The old site has 63 business categories, many of them search landing
# pages ("מסעדות במודיעין", "פיצריות במודיעין"); the new one has 22 broader
# ones. Each old one goes to the nearest new category by our slug, chosen by
# hand and marked so in the map for the client to review; None means the
# businesses section. Professionals' categories became business categories.
NEAREST_CATEGORY = {
    'אוכל ביתי במודיעין': 'restaurants', 'אולמות אירועים': 'entertainment',
    'אופטיקה': 'health', 'אטרקציות במודיעין': 'entertainment',
    'איטלקי': 'restaurants', 'אירועים במודיעין': 'entertainment',
    'אסיאתי': 'asian', 'אסתטיקה טיפוח': 'beauty',
    'ארוחת בוקר במודיעין': 'cafe-bakery', 'ביגוד': 'shopping',
    'בנקים במודיעין': 'services', 'ברים במודיעין': 'entertainment',
    'בתי קפה במודיעין': 'cafe-bakery', 'גלידות': 'cafe-bakery',
    'גני ילדים במודיעין': 'education', 'גריל': 'meat', 'המבורגר': 'meat',
    'וטרינר': 'services', 'חברת הסעות במודיעין': 'services',
    'חומרי בניין במודיעין': 'renovations',
    'חנויות חד פעמי במודיעין': 'shopping', 'חנות בגדים במודיעין': 'shopping',
    'חנות דגים': 'shopping', 'חנות יין ואלכהול': 'shopping',
    'חנות נוחות': 'shopping', 'חנות ספרים במודיעין': 'shopping',
    'חנות פרחים במודיעין': 'shopping', 'חנות תבלינים במודיעין': 'shopping',
    'כשר לפסח במודיעין': 'restaurants', 'לימודים': 'education',
    'מאפייה': 'cafe-bakery', 'מכבסה': 'services',
    'מסעדה איטלקית במודיעין': 'restaurants', 'מסעדות במודיעין': 'restaurants',
    'מסעדות בשריות כשרות במודיעין': 'meat',
    'מסעדות חלביות כשרות במודיעין': 'restaurants',
    'מסעדות כשרות המודיעין': 'restaurants', 'מספרה במודיעין': 'beauty',
    'מעדנייה': 'shopping', 'מרכזים מסחריים': 'shopping',
    'סוכנות נסיעות': 'services', 'סופרים במודיעין': 'shopping',
    'סושי': 'asian', 'סלולר': 'shopping', 'עגלות קפה במודיעין': 'cafe-bakery',
    'עיצוב הבית': 'shopping', 'עיצוב פנים במודיעין': 'renovations',
    'עסקים באתר': None, 'פיצריות במודיעין': 'pizza',
    'פירות וירקות': 'shopping', 'פלאפל במודיעין': 'mediterranean',
    'פנצ׳ריה': 'automotive', 'פתוח בשבת במודיעין': None,
    'צ׳יינג׳ מודיעין': 'services', 'קופות חולים במודיעין': 'health',
    'קצבייה במודיעין': 'shopping', 'קריוקי': 'entertainment',
    'תחנות דלק במודיעין': 'automotive',
    # professionals-cat
    'בונה אתרים': 'web-design', 'הנדימן': 'handyman', 'חשמלאי': 'electrician',
    'טכנאי מקררים': 'fridge-technician', 'לק ג׳ל': 'gel-nails',
    'עורך דין': 'lawyer', 'שיפוצניק': 'renovations',
}

# The old site's pages, by their address, to the new site's page.
PAGES = {
    '/personal-area/': '/',              # accounts are the app's
    '/share-with-us/': '/community',
    '/facebookgruop/': '/community',
    '/shabat-times-modiin/': '/shabbat',
    '/modiin-news/': '/news',
    '/search-rest-modiin/': '/restaurants',
    '/maar/': '/businesses',             # the city-centre business page
    '/my-avenue/': '/realestate',        # a housing project's page
}

env = {}
for line in open(os.path.join(ROOT, '.env.local'), encoding='utf-8'):
    line = line.rstrip('\n')
    if line.strip() and not line.lstrip().startswith('#'):
        k, _, v = line.partition('=')
        env[k] = v
URL = env['SUPABASE_URL'].rstrip('/')
KEY = env['SUPABASE_SERVICE_ROLE_KEY']


def fetch(url):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=90) as r:
        return r.read().decode('utf-8', 'ignore')


def db(path):
    rows, start = [], 0
    while True:
        req = urllib.request.Request(
            f'{URL}/rest/v1/{path}',
            headers={'apikey': KEY, 'Authorization': 'Bearer ' + KEY,
                     'Range': f'{start}-{start + 999}'})
        with urllib.request.urlopen(req, timeout=60) as r:
            page = json.loads(r.read())
        rows += page
        if len(page) < 1000:
            return rows
        start += 1000


def norm(url):
    """Lower-cased, decoded path with one trailing slash, no host."""
    path = urllib.parse.unquote(urllib.parse.urlparse(url).path)
    return '/' + path.strip('/') + ('/' if path.strip('/') else '')


def wp_items(rest_base):
    items, page = [], 1
    while True:
        try:
            batch = json.loads(fetch(
                f'{WP}/wp-json/wp/v2/{rest_base}?per_page=100&page={page}'
                '&_fields=id,link,slug,title,name,yoast_head_json'))
        except urllib.error.HTTPError:
            break
        items += batch
        if len(batch) < 100:
            break
        page += 1
    return items


def text(s):
    return html.unescape(re.sub(r'<[^>]+>', '', s or '')).replace('\xa0', ' ').strip()


def main():
    os.makedirs(OUT, exist_ok=True)

    # What Google knows: every address in the sitemaps.
    urls = []
    for m in SITEMAPS:
        xml = fetch(f'{WP}/{m}-sitemap.xml')
        for loc in re.findall(r'<loc>([^<]+)</loc>', xml):
            if re.search(r'\.(jpe?g|png|webp|gif)$', loc, re.I):
                continue
            urls.append((m, html.unescape(loc)))

    # What WordPress says about each: slug and Yoast title/description.
    yoast_by_path = {}
    for base in ['news', 'business', 'new', 'business-cat', 'professionals',
                 'professionals-cat', 'apartments', 'real-estate-agents',
                 'real-astate-agents', 'pages']:
        for it in wp_items(base):
            y = it.get('yoast_head_json') or {}
            yoast_by_path[norm(it['link'])] = {
                'slug': urllib.parse.unquote(it.get('slug') or ''),
                'name': text((it.get('title') or {}).get('rendered') if isinstance(it.get('title'), dict) else it.get('name')),
                'seo_title': text(y.get('title')),
                'description': text(y.get('description')),
            }

    articles = db('articles?select=id,slug,canonical_url,title,status')
    businesses = db('businesses?select=id,slug,canonical_url,name,status,kind')
    categories = db('categories?select=id,slug,name,scope,is_active')

    def by(rows, key):
        out = {}
        for r in rows:
            v = r.get(key)
            if v:
                out.setdefault(norm(v) if key == 'canonical_url' else urllib.parse.unquote(v), r)
        return out

    art_canon, art_slug = by(articles, 'canonical_url'), by(articles, 'slug')
    biz_canon, biz_slug = by(businesses, 'canonical_url'), by(businesses, 'slug')
    biz_name = {r['name'].strip(): r for r in businesses if r.get('name')}
    cat_biz = {urllib.parse.unquote(r['slug']): r for r in categories if r['scope'] == 'business' and r.get('slug')}
    cat_art = {urllib.parse.unquote(r['slug']): r for r in categories if r['scope'] == 'article' and r.get('slug')}
    cat_biz_name = {r['name'].strip(): r for r in categories if r['scope'] == 'business'}
    cat_art_name = {r['name'].strip(): r for r in categories if r['scope'] == 'article'}

    # Pages and archives with no row of their own: the nearest page.
    fixed = {
        '/': '/', '/news/': '/news', '/business/': '/businesses',
        '/apartments/': '/realestate', '/real-estate-agents/': '/realestate',
        '/professionals/': '/businesses',
        **PAGES,
    }

    rows, yoast_out = [], {'articles': {}, 'businesses': {}, 'categories': {}}
    for kind, url in urls:
        path = norm(url)
        parts = path.strip('/').split('/')
        slug = parts[-1] if parts and parts[-1] else ''
        y = yoast_by_path.get(path, {})
        rec = {'old_url': url, 'old_path': path, 'kind': kind,
               'table': '', 'id': '', 'name': '', 'new_path': '', 'how': ''}

        if path in fixed:
            rec.update(new_path=fixed[path], how='section page')
        elif kind == 'news':
            r = art_canon.get(path) or art_slug.get(slug)
            if r:
                same = urllib.parse.unquote(r['slug'] or '') == slug
                rec.update(table='articles', id=r['id'], name=r['title'],
                           new_path=path if same else f"/news/{r['slug']}/",
                           how='same address' if same else 'redirect to its slug')
                if r['status'] != 'published':
                    rec['how'] += f" (article is {r['status']})"
                yoast_out['articles'][r['id']] = y
        elif kind == 'business':
            r = biz_canon.get(path) or biz_slug.get(slug) or biz_name.get(y.get('name', ''))
            if r:
                rec.update(table='businesses', id=r['id'], name=r['name'], new_path=f"/business/{r['slug']}/",
                           how='same address' if urllib.parse.unquote(r['slug']) == slug else 'redirect to its slug')
                if r['status'] != 'active':
                    rec['how'] += f" (business is {r['status']})"
                yoast_out['businesses'][r['id']] = y
        elif kind in ('business-cat', 'professionals-cat'):
            r = cat_biz.get(slug) or cat_biz_name.get(y.get('name', ''))
            near = NEAREST_CATEGORY.get(y.get('name', ''), 'missing')
            if not r and near not in (None, 'missing'):
                r = cat_biz.get(near)
                if r:
                    rec.update(table='categories', id=r['id'], name=y.get('name', ''),
                               new_path=f"/business-cat/{r['slug']}/",
                               how=f"nearest category by hand ({r['name']})")
            elif r:
                rec.update(table='categories', id=r['id'], name=r['name'], new_path=f"/business-cat/{r['slug']}/",
                           how='same address' if urllib.parse.unquote(r['slug']) == slug else 'redirect to its slug')
                yoast_out['categories'][r['id']] = y
        elif kind == 'professionals':
            r = biz_slug.get(slug) or biz_name.get(y.get('name', ''))
            if r:
                rec.update(table='businesses', id=r['id'], name=r['name'],
                           new_path=f"/business/{r['slug']}/", how='redirect to its slug')
                yoast_out['businesses'][r['id']] = y
        elif kind == 'new':
            r = cat_art.get(slug) or cat_art_name.get(y.get('name', ''))
            if r:
                rec.update(table='categories', id=r['id'], name=r['name'], new_path=f"/new/{r['slug']}/",
                           how='same address' if urllib.parse.unquote(r['slug']) == slug else 'redirect to its slug')
                yoast_out['categories'][r['id']] = y

        if not rec['new_path']:
            # No row: the section it belonged to, so the visitor and the
            # link's value land somewhere relevant rather than on a 404.
            section = {
                'news': '/news', 'business': '/businesses', 'business-cat': '/businesses',
                'new': '/news', 'apartments': '/realestate', 'real-estate-agents': '/realestate',
                'real-astate-agents': '/realestate', 'professionals': '/businesses',
                'professionals-cat': '/businesses', 'page': '/',
            }[kind]
            rec.update(new_path=section, how='no match — redirect to section', name=y.get('name', ''))
        rows.append(rec)

    with open(os.path.join(OUT, 'url_map.csv'), 'w', encoding='utf-8-sig', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    with open(os.path.join(OUT, 'yoast.json'), 'w', encoding='utf-8') as f:
        json.dump(yoast_out, f, ensure_ascii=False, indent=1)

    from collections import Counter
    print(len(rows), 'addresses')
    for (kind, how), n in sorted(Counter((r['kind'], r['how'].split(' (')[0]) for r in rows).items()):
        print(f'  {kind:20} {how:32} {n}')


main()
