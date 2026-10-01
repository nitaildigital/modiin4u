#!/usr/bin/env python3
"""Imports the city's parks from the municipality's website.

The client (1 Oct): "Regarding the parks: you can pull everything from the
municipality website — names, descriptions, locations, and photos — and
insert them directly into the app."

The source is the municipality's "גנים ופארקים" page, which lists some
seventy parks and gardens by neighbourhood, each with a photograph, an
address (most with a Google Maps link) and a description. Each becomes a
row in `businesses` with kind = 'park' (migration 00038), so it gets the
park page, reviews and the panel's editor:

  name                 the park's name on the page
  short_description    its neighbourhood, as the page groups it
  full_description     the page's text, address line removed, with a line
                       naming the municipality as the source
  address              the address the page gives
  latitude/longitude   from its Google Maps link where it has one (the
                       place's own pin), otherwise looked up from the
                       address on OpenStreetMap; left empty if neither
                       lands inside Modi'in
  neighborhood_id      matched by name where the neighbourhood exists
  cover_url            its photograph, copied into our `media` bucket
                       (the municipality's site is not ours to hot-link)

No phone, website or menu, as the client set for parks. Nothing is written
that the page does not say.

Everything added is recorded in tool/parks_registry.json; --undo removes
exactly those rows. A park already in the table by the same name is
skipped, so a rerun adds only what is new on the page.

    python3 tool/import_parks.py            # dry run
    python3 tool/import_parks.py --apply
    python3 tool/import_parks.py --undo

Reads SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY from .env.local.
"""
import hashlib
import html
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY = os.path.join(ROOT, 'tool', 'parks_registry.json')
BASE = 'https://www.modiin.muni.il/modiinwebsite/'
PAGE = BASE + 'ArticlePage.aspx?PageID=314_209'
UA = {'User-Agent': 'Mozilla/5.0 (modiin4u-import)'}
SOURCE_LINE = 'מקור: אתר עיריית מודיעין מכבים רעות'

env = {}
for line in open(os.path.join(ROOT, '.env.local'), encoding='utf-8'):
    line = line.rstrip('\n')
    if line.strip() and not line.lstrip().startswith('#'):
        k, _, v = line.partition('=')
        env[k] = v
URL = env['SUPABASE_URL'].rstrip('/')
KEY = env['SUPABASE_SERVICE_ROLE_KEY']


def fetch(url, binary=False, timeout=60):
    url = urllib.parse.quote(url, safe=':/?&=%#+,;@')
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=timeout) as r:
        data = r.read()
        return data if binary else data.decode('utf-8', 'ignore')


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


def upload(src):
    data = fetch(src, binary=True, timeout=120)
    ext = os.path.splitext(urllib.parse.urlparse(src).path)[1].lower() or '.jpg'
    path = 'parks/' + hashlib.sha1(src.encode()).hexdigest()[:20] + ext
    ctype = {'.png': 'image/png', '.webp': 'image/webp'}.get(ext, 'image/jpeg')
    req = urllib.request.Request(
        f'{URL}/storage/v1/object/media/{path}', method='POST', data=data,
        headers={'apikey': KEY, 'Authorization': 'Bearer ' + KEY,
                 'Content-Type': ctype, 'x-upsert': 'true'})
    urllib.request.urlopen(req, timeout=120).read()
    return f'{URL}/storage/v1/object/public/media/{path}'


def in_modiin(lat, lon):
    return 31.85 <= lat <= 31.95 and 34.94 <= lon <= 35.07


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *a, **k):
        return None


def coords_from_map_link(link):
    """A Google Maps short link expands to a place URL; its `!3d…!4d…` is the
    place's own pin, and `@lat,lng` the map's centre as a fallback."""
    if not link:
        return None
    opener = urllib.request.build_opener(_NoRedirect)
    target = link
    for _ in range(3):
        try:
            r = opener.open(urllib.request.Request(target, headers=UA), timeout=30)
            loc = r.headers.get('Location')
        except urllib.error.HTTPError as e:
            loc = e.headers.get('Location')
        except Exception:
            return None
        if not loc:
            break
        target = loc
    m = re.search(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)', target) or \
        re.search(r'@(-?\d+\.\d+),(-?\d+\.\d+)', target)
    if not m:
        return None
    lat, lon = float(m.group(1)), float(m.group(2))
    return (lat, lon) if in_modiin(lat, lon) else None


def geocode(address):
    if not address:
        return None
    street = re.split(r'[,(–]', address)[0].strip()
    for q in dict.fromkeys([f'{street}, מודיעין-מכבים-רעות', f'{address}, מודיעין']):
        time.sleep(1.1)
        try:
            res = json.loads(fetch('https://nominatim.openstreetmap.org/search?' + urllib.parse.urlencode(
                {'q': q, 'format': 'json', 'limit': 1, 'countrycodes': 'il'})))
        except Exception:
            continue
        if res:
            lat, lon = float(res[0]['lat']), float(res[0]['lon'])
            if in_modiin(lat, lon):
                return lat, lon
    return None


def clean_name(name):
    """The page writes quotation marks as two apostrophes, leaves one quote
    unclosed and doubles spaces; tidied so the names read as names."""
    name = re.sub(r"''", '"', name)
    name = re.sub(r'\s+', ' ', name).strip()
    if name.count('"') % 2:
        name += '"'
    # A name that is only a quotation ("הנחל הרטוב") needs no quotes.
    if name.startswith('"') and name.endswith('"') and name.count('"') == 2:
        name = name[1:-1].strip()
    return name


def make_slug(name):
    base = name if name.startswith(('פארק', 'גן', 'גינ')) else f'פארק {name}'
    base = re.sub(r'["\'׳״()]', '', base)
    return re.sub(r'[\s-]+', '-', base).strip('-')


def parse():
    h = fetch(PAGE)
    h = h[h.find('id="שכונת_הכרמים"') - 200:]
    end = h.find('<footer')
    if end > 0:
        h = h[:end]
    parks, hood = [], None
    for blk in h.split('<div class="line"></div>'):
        m = re.search(r'<h2><span id="[^"]*">([^<]+)</span></h2>', blk)
        if m:
            hood = html.unescape(m.group(1)).strip()
        for part in re.split(r'(?=<div class="(?:right-image-caption|left-image|right-image|left-image-caption)">)', blk):
            nm = re.search(r'<h3>(.*?)</h3>', part, re.S)
            if not nm:
                continue
            name = clean_name(html.unescape(re.sub(r'<[^>]+>', '', nm.group(1))))
            if not name:
                continue
            img = re.search(r'<img src="([^"]+)"', part)
            link = re.search(r'(?:כתובת|מיקום):\s*</strong>\s*(?:<strong>)?\s*<a href="([^"]+)"', part)
            body = part[nm.end():]
            t = re.sub(r'<br\s*/?>', '\n', body)
            t = html.unescape(re.sub(r'<[^>]+>', '', t))
            lines = [re.sub(r'[ \t]+', ' ', l).strip() for l in t.split('\n')]
            address = None
            kept = []
            for l in lines:
                a = re.match(r'^(?:כתובת|מיקום):\s*(.+)$', l)
                if a and address is None:
                    address = a.group(1).strip()
                    continue
                kept.append(l)
            text = re.sub(r'\n{3,}', '\n\n', '\n'.join(kept)).strip()
            parks.append({
                'hood': hood,
                'name': name,
                'image': urllib.parse.urljoin(BASE, img.group(1)) if img else None,
                'map': link.group(1) if link else None,
                'address': address,
                'text': text,
            })
    return parks


def main():
    if '--undo' in sys.argv:
        ids = json.load(open(REGISTRY, encoding='utf-8'))
        for i in ids:
            db('DELETE', f'businesses?id=eq.{i}', prefer='return=minimal')
        os.remove(REGISTRY)
        print('removed', len(ids), 'parks')
        return

    apply = '--apply' in sys.argv
    parks = parse()
    hoods = {r['name']: r['id'] for r in db('GET', 'neighborhoods?select=id,name')}
    existing = {r['name'] for r in db('GET', 'businesses?kind=eq.park&select=name')}
    slugs = {r['slug'] for r in db('GET', 'businesses?select=slug')}

    rows = []
    for p in parks:
        if p['name'] in existing:
            continue
        where = coords_from_map_link(p['map']) or geocode(p['address'])
        hood_name = (p['hood'] or '').replace('שכונת ', '').strip()
        slug = make_slug(p['name'])
        base, n = slug, 2
        while slug in slugs:
            slug, n = f'{base}-{n}', n + 1
        slugs.add(slug)
        rows.append({**p, 'slug': slug, 'where': where,
                     'neighborhood_id': hoods.get(hood_name)})

    if not apply:
        located = sum(1 for r in rows if r['where'])
        for r in rows:
            print(f"{r['name'][:34]:34} | {r['hood'] or '':14} | {('%.4f,%.4f' % r['where']) if r['where'] else '—':16} | "
                  f"{'hood✓' if r['neighborhood_id'] else 'hood—'} | {len(r['text'])} chars | {r['address'] or ''}")
        print(f'\n{len(rows)} parks to add, {located} with a location — dry run, nothing written')
        return

    # A rerun continues: parks already added are skipped above by name, and
    # the registry keeps every id this script has ever added.
    ids = json.load(open(REGISTRY, encoding='utf-8')) if os.path.exists(REGISTRY) else []
    for r in rows:
        about = (r['text'] + '\n\n' + SOURCE_LINE).strip()
        created = db('POST', 'businesses', {
            'kind': 'park', 'status': 'active',
            'name': r['name'], 'slug': r['slug'],
            'short_description': r['hood'],
            'full_description': about,
            # The address column is required; a park the page gives no
            # address for is placed by its neighbourhood, as the page groups it.
            'address': r['address'] or f"{r['hood'] or ''}, מודיעין".strip(', '),
            'latitude': r['where'][0] if r['where'] else None,
            'longitude': r['where'][1] if r['where'] else None,
            'neighborhood_id': r['neighborhood_id'],
            'cover_url': upload(r['image']) if r['image'] else None,
            'kosher_level': 'none',
        })[0]
        ids.append(created['id'])
        with open(REGISTRY, 'w', encoding='utf-8') as fh:
            json.dump(ids, fh, indent=2)
        print('added', r['name'])
    print(f'added {len(ids)} parks')


main()
