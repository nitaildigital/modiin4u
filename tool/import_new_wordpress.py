#!/usr/bin/env python3
"""Brings across the businesses and news added to the WordPress site since
the first import.

The client (1 Oct): "a few more businesses and articles have been added to
WordPress that haven't been put into the new website and app yet". Anything
on the site whose address is not already in the database (canonical_url, or
the slug) is new.

News comes whole from the REST API: title, the full story, its photograph,
its categories (taxonomy `new`, matched to ours by name) and the Yoast SEO
title and description. Photographs, the featured one and those inside the
story, are copied into our `media` bucket, because modiin4u.co.il sends no
CORS header and a browser will not show them on the website otherwise.

A business's REST record has only its title, photo and categories — the
phone, address and description are JetEngine fields the API does not
expose. They are read off the business's public page instead, where the
site prints them. What the page does not say is left empty: the opening
hours are not taken (the page shows this week's, holidays included, and
would save a holiday closure as permanent), and neither is a rating. The
location is looked up from the address on OpenStreetMap (Nominatim), and
left empty if the address does not resolve inside Modi'in. Categories are
given by hand below, as the first import's were (PLAN.md, B4).

Everything added is recorded in tool/new_wordpress_registry.json and --undo
removes exactly that.

    python3 tool/import_new_wordpress.py            # dry run: what it found
    python3 tool/import_new_wordpress.py --apply
    python3 tool/import_new_wordpress.py --undo

Reads SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY and SUPABASE_DB_URL from
.env.local.
"""
import hashlib
import html
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY = os.path.join(ROOT, 'tool', 'new_wordpress_registry.json')
WP = 'https://www.modiin4u.co.il/wp-json/wp/v2'
UA = {'User-Agent': 'Mozilla/5.0 (modiin4u-import)'}

# The site's own numbers, printed in its header and footer on every page —
# never a business's.
SITE_PHONES = {'0584770195', '058-4770195'}

# Our categories for each new business, by WordPress slug, chosen by hand
# from its terms and its own description (PLAN.md, 1 Oct). The banks carry
# only the site's catch-all term and fit no category — Services is the
# Professionals menu — so they stay uncategorised, as 44 businesses already
# are, and are found under All Businesses and in search.
CATEGORIES = {
    'שאוורמה-הרצל-50-מודיעין': ['restaurants', 'meat'],
    'twosome-burger-טוסום-מודיעין': ['restaurants', 'meat'],
    'מי-מה-מו-מודיעין-me-ma-mu': ['restaurants', 'meat'],
    'רוט-אנד-בלום-rootbloom-מודיעין': ['restaurants', 'mediterranean'],
    'מסעדת-בית-הכרם-מודיעין': ['restaurants'],
}

env = {}
for line in open(os.path.join(ROOT, '.env.local'), encoding='utf-8'):
    line = line.rstrip('\n')
    if line.strip() and not line.lstrip().startswith('#'):
        k, _, v = line.partition('=')
        env[k] = v
URL = env['SUPABASE_URL'].rstrip('/')
KEY = env['SUPABASE_SERVICE_ROLE_KEY']


# ─── plumbing ───

def fetch(url, binary=False, timeout=60):
    # WordPress file names are often Hebrew; the request line must be ASCII.
    url = urllib.parse.quote(url, safe=':/?&=%#+,;@')
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        data = r.read()
        return data if binary else data.decode('utf-8', 'ignore')


def wp(path):
    return json.loads(fetch(f'{WP}/{path}'))


def db(method, path, body=None, prefer='return=representation'):
    req = urllib.request.Request(
        f'{URL}/rest/v1/{path}', method=method,
        headers={'apikey': KEY, 'Authorization': 'Bearer ' + KEY,
                 'Content-Type': 'application/json', 'Prefer': prefer},
        data=None if body is None else json.dumps(body).encode())
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        raise SystemExit(f'{method} {path.split("?")[0]} -> {e.code}: {e.read().decode()[:300]}')


def sql(query):
    r = subprocess.run(
        ['/opt/homebrew/opt/libpq/bin/psql', env['SUPABASE_DB_URL'], '-At',
         '-c', 'set default_transaction_read_only=on;', '-c', query],
        capture_output=True, text=True, timeout=60)
    return [l for l in r.stdout.splitlines() if l and l != 'SET']


def text(s):
    s = re.sub(r'<[^>]+>', ' ', s or '')
    return re.sub(r'\s+', ' ', html.unescape(s)).strip()


def norm_link(link):
    return urllib.parse.unquote(link or '').rstrip('/')


def upload(src):
    """Copies a WordPress photograph into the media bucket; returns its
    public URL. The path is derived from the source, so a rerun reuses it."""
    data = fetch(src, binary=True, timeout=120)
    ext = os.path.splitext(urllib.parse.urlparse(src).path)[1].lower() or '.jpg'
    path = 'imports/' + hashlib.sha1(src.encode()).hexdigest()[:20] + ext
    ctype = {'.png': 'image/png', '.webp': 'image/webp', '.gif': 'image/gif'}.get(ext, 'image/jpeg')
    req = urllib.request.Request(
        f'{URL}/storage/v1/object/media/{path}', method='POST', data=data,
        headers={'apikey': KEY, 'Authorization': 'Bearer ' + KEY,
                 'Content-Type': ctype, 'x-upsert': 'true'})
    urllib.request.urlopen(req, timeout=120).read()
    return f'{URL}/storage/v1/object/public/media/{path}'


# ─── what is new ───

def all_wp(kind):
    out, page = [], 1
    while True:
        batch = wp(f'{kind}?per_page=100&page={page}&_fields=id,slug,link,date')
        out += batch
        if len(batch) < 100:
            return out
        page += 1


def missing(kind, table):
    have = {norm_link(x) for x in sql(f"select coalesce(canonical_url,'') from {table}")}
    slugs = {urllib.parse.unquote(x) for x in sql(f'select slug from {table}')}
    return [i for i in all_wp(kind)
            if norm_link(i['link']) not in have and urllib.parse.unquote(i['slug']) not in slugs]


# ─── news ───

def news_item(stub):
    p = wp(f"news/{stub['id']}?_embed")
    emb = p.get('_embedded') or {}
    media = emb.get('wp:featuredmedia') or []
    image = media[0].get('source_url') if media and isinstance(media[0], dict) else None
    terms = [t['name'] for grp in emb.get('wp:term') or [] for t in grp
             if isinstance(t, dict) and t.get('taxonomy') == 'new']
    yoast = p.get('yoast_head_json') or {}
    return {
        'wp_id': p['id'],
        'slug': urllib.parse.unquote(p['slug']),
        'link': p['link'],
        'title': text(p['title']['rendered']),
        'body': (p.get('content') or {}).get('rendered', ''),
        'excerpt': text((p.get('excerpt') or {}).get('rendered', ''))[:400],
        'published_at': p['date_gmt'] + '+00:00',
        'image': image,
        'categories': terms,
        'seo_title': text(yoast.get('title')) or None,
        'meta_description': text(yoast.get('description')) or None,
    }


# ─── businesses ───

def page_details(link, name):
    """Phone, address, subtitle, kosher, About and website off the public
    page. The business block sits between its own name and "שתפו אותי"."""
    h = fetch(link)
    t = re.sub(r'(?s)<(script|style)[^>]*>.*?</\1>', '', h)
    t = html.unescape(re.sub(r'<[^>]+>', '\n', t))
    lines = [l.strip() for l in t.split('\n') if l.strip()]
    starts = [i for i, l in enumerate(lines) if l == name]
    start = starts[-1] if starts else 0
    end = next((i for i in range(start, len(lines)) if lines[i].startswith('שתפו אותי')), len(lines))
    block = lines[start:end]

    def after(label):
        for i, l in enumerate(block):
            if l.startswith(label):
                rest = l[len(label):].strip()
                return rest or (block[i + 1] if i + 1 < len(block) else None)
        return None

    about = None
    if 'קצת עלינו' in block:
        i = block.index('קצת עלינו')
        about = '\n\n'.join(block[i + 1:]) or None
    phones = [urllib.parse.unquote(p).strip() for p in re.findall(r'href="tel:([^"]+)"', h)]
    phones = [p for p in phones if p and p not in SITE_PHONES]
    site = None
    m = re.search(r'href="(https?://[^"]+)"[^>]*>\s*(?:<[^>]+>\s*)*לאתר', h)
    if m and 'modiin4u' not in m.group(1):
        site = html.unescape(m.group(1))
    kosher = 'none'
    if any('מהדרין' in l for l in block[:6]):
        kosher = 'mehadrin'
    elif any(l == 'כשר' or l.startswith('כשר ') for l in block[:6]):
        kosher = 'other'
    return {
        'subtitle': block[1] if len(block) > 1 and block[1] not in ('כשר', 'התקשר')
                    and not block[1].startswith('⭐') else None,
        'kosher_level': kosher,
        'phone': phones[0] if phones else None,
        'address': after('כתובת:'),
        'about': about,
        'website': site,
    }


def geocode(address):
    """Nominatim, one request a second as its policy asks; only a result
    inside Modi'in's bounds is kept. Tries the address as written, then with
    the common spelling variants (וייצמן / ויצמן) and the city's long name."""
    if not address:
        return None, None
    street = re.split(r',', address)[0].strip()
    tries = [address, f'{street}, מודיעין-מכבים-רעות',
             f"{street.replace('וייצמן', 'ויצמן')}, מודיעין-מכבים-רעות",
             f"{street.replace('שדרות ', '')}, מודיעין-מכבים-רעות"]
    for q in dict.fromkeys(tries):
        time.sleep(1.1)
        try:
            res = json.loads(fetch('https://nominatim.openstreetmap.org/search?' + urllib.parse.urlencode(
                {'q': q, 'format': 'json', 'limit': 1, 'countrycodes': 'il'})))
        except Exception:
            continue
        if res:
            lat, lon = float(res[0]['lat']), float(res[0]['lon'])
            if 31.85 <= lat <= 31.95 and 34.94 <= lon <= 35.07:
                return lat, lon
    return None, None


def business_item(stub):
    p = wp(f"business/{stub['id']}?_embed")
    emb = p.get('_embedded') or {}
    media = emb.get('wp:featuredmedia') or []
    image = media[0].get('source_url') if media and isinstance(media[0], dict) else None
    terms = [t['name'] for grp in emb.get('wp:term') or [] for t in grp
             if isinstance(t, dict) and t.get('taxonomy') == 'business-cat']
    details = page_details(p['link'], text(p['title']['rendered']))
    lat, lon = geocode(details['address'])
    yoast = p.get('yoast_head_json') or {}
    return {
        'wp_id': p['id'],
        'slug': urllib.parse.unquote(p['slug']),
        'link': p['link'],
        'name': text(p['title']['rendered']),
        'image': image,
        'terms': terms,
        'latitude': lat,
        'longitude': lon,
        'meta_title': text(yoast.get('title')) or None,
        'meta_description': text(yoast.get('description')) or None,
        **details,
    }


# ─── main ───

def main():
    if '--undo' in sys.argv:
        reg = json.load(open(REGISTRY, encoding='utf-8'))
        for i in reg.get('articles', []):
            db('DELETE', f"entity_categories?entity_type=eq.article&entity_id=eq.{i}", prefer='return=minimal')
            db('DELETE', f'articles?id=eq.{i}', prefer='return=minimal')
        for i in reg.get('businesses', []):
            db('DELETE', f"entity_categories?entity_type=eq.business&entity_id=eq.{i}", prefer='return=minimal')
            db('DELETE', f'businesses?id=eq.{i}', prefer='return=minimal')
        os.remove(REGISTRY)
        print('removed', len(reg.get('articles', [])), 'articles and',
              len(reg.get('businesses', [])), 'businesses')
        return

    apply = '--apply' in sys.argv
    news = [news_item(s) for s in missing('news', 'articles')]
    businesses = [business_item(s) for s in missing('business', 'businesses')]

    if not apply:
        for n in news:
            print(f"NEWS  {n['published_at'][:10]}  {n['title'][:60]}")
            print(f"      cats={n['categories']} image={bool(n['image'])} body={len(n['body'])} seo={bool(n['seo_title'])}")
        for b in businesses:
            print(f"BIZ   {b['name']}  [{b['slug']}]")
            print(f"      terms={b['terms']} subtitle={b['subtitle']!r} kosher={b['kosher_level']}")
            print(f"      phone={b['phone']} address={b['address']!r} site={b['website']}")
            print(f"      latlng={b['latitude']},{b['longitude']} image={bool(b['image'])} about={len(b['about'] or '')}")
        print(f'\n{len(news)} news, {len(businesses)} businesses — dry run, nothing written')
        return

    if os.path.exists(REGISTRY):
        raise SystemExit('already imported — run --undo first')
    reg = {'articles': [], 'businesses': []}
    article_cats = {norm: cid for cid, norm in
                    (l.split('|', 1) for l in sql("select id||'|'||name from categories where scope='article'"))}
    business_cats = {slug: cid for cid, slug in
                     (l.split('|', 1) for l in sql("select id||'|'||slug from categories where scope='business'"))}

    def save_registry():
        with open(REGISTRY, 'w', encoding='utf-8') as fh:
            json.dump(reg, fh, ensure_ascii=False, indent=2)

    for n in news:
        body = n['body']
        # The story's own photographs, off modiin4u.co.il and into our
        # bucket; srcset and sizes still point at WordPress, so they go.
        for src in sorted(set(re.findall(r'<img[^>]+src="([^"]+)"', body))):
            if 'modiin4u.co.il' in src:
                body = body.replace(src, upload(html.unescape(src)))
        body = re.sub(r'\s(srcset|sizes)="[^"]*"', '', body)
        image = upload(n['image']) if n['image'] else None
        row = db('POST', 'articles', {
            'title': n['title'], 'slug': n['slug'], 'body': body, 'excerpt': n['excerpt'],
            'featured_image': image, 'og_image': image, 'status': 'published',
            'canonical_url': n['link'], 'published_at': n['published_at'],
            'seo_title': n['seo_title'], 'meta_description': n['meta_description'],
        })[0]
        reg['articles'].append(row['id']); save_registry()
        for i, name in enumerate(n['categories']):
            if name in article_cats:
                db('POST', 'entity_categories', {'entity_type': 'article', 'entity_id': row['id'],
                                                 'category_id': article_cats[name], 'is_primary': i == 0},
                   prefer='return=minimal')
        print('article', n['slug'], n['categories'])

    for b in businesses:
        image = upload(b['image']) if b['image'] else None
        row = db('POST', 'businesses', {
            'name': b['name'], 'slug': b['slug'], 'kind': 'business', 'status': 'active',
            'short_description': b['subtitle'], 'full_description': b['about'],
            'phone': b['phone'], 'website': b['website'], 'address': b['address'],
            'latitude': b['latitude'], 'longitude': b['longitude'],
            'kosher_level': b['kosher_level'], 'cover_url': image,
            'canonical_url': b['link'],
            'meta_title': b['meta_title'], 'meta_description': b['meta_description'],
        })[0]
        reg['businesses'].append(row['id']); save_registry()
        for i, slug in enumerate(CATEGORIES.get(b['slug'], [])):
            db('POST', 'entity_categories', {'entity_type': 'business', 'entity_id': row['id'],
                                             'category_id': business_cats[slug], 'is_primary': i == 0},
               prefer='return=minimal')
        print('business', b['slug'], CATEGORIES.get(b['slug'], []))
    print(f"added {len(reg['articles'])} articles and {len(reg['businesses'])} businesses")


main()
