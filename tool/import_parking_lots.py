#!/usr/bin/env python3
"""The city's public car parks, from OpenStreetMap's map data.

Harshit (1 Oct): add the car parks so the parking page and the map's
Parkings layer show them. Neither the municipality's website nor
data.gov.il lists Modi'in's car parks, so the source is OpenStreetMap — the
map data, not its map: 148 car parks are mapped inside the city's boundary
(relation 1381425), almost none of them named.

What is added, and how it is said:

  * Only lots of 2,500 m² and more (about a hundred cars) that are open to
    the public (access yes/public/customers, not street-side), and only those
    with a named public place within 175 m — a train station, the water
    park, the city pool, the municipality, a mall or supermarket centre. A
    lot with nothing named beside it is left out: nothing true could name
    it. Two lots with the same name at the same address are one entry.
  * Each is named for that place, as being next to it — "חניון ליד תחנת
    הרכבת פאתי מודיעין" — which is what the data shows, and no more. A lot
    inside a named centre (ישפרו סנטר) takes the centre's name.
  * The address is the street the lot is on (OpenStreetMap's reverse
    lookup), the location the lot's middle, free or paid where the map says
    (`fee`). Hours, prices and capacity are left empty for the client to
    fill in the panel; the map's rare capacity tags proved wrong.

The parking screens credit OpenStreetMap's contributors for the data, as its
licence asks. Everything added is in tool/parking_registry.json; --undo
removes exactly those rows. The client edits, hides or adds lots in the
panel (חניונים).

    python3 tool/import_parking_lots.py            # dry run
    python3 tool/import_parking_lots.py --apply
    python3 tool/import_parking_lots.py --undo

Reads SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY from .env.local.
"""
import json
import math
import os
import sys
import time
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY = os.path.join(ROOT, 'tool', 'parking_registry.json')
UA = {'User-Agent': 'modiin4u-parking-import'}
MIRRORS = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
]
MIN_AREA = 2500     # m²
NEAR = 175          # m

# How each landmark is said, in Hebrew and English.
LANDMARKS = {
    'פאתי מודיעין': ('תחנת הרכבת פאתי מודיעין', 'Paatei Modiin train station'),
    'מודיעין מרכז': ('תחנת הרכבת מודיעין מרכז', 'Modiin Center train station'),
    'הולמס פלייס': ('הולמס פלייס', 'Holmes Place'),
    'פארק המים והספורט מודיעין': ('פארק המים והספורט', 'the Water and Sports Park'),
    'הבריכה העירונית': ('הבריכה העירונית', 'the city pool'),
    'יינות ביתן': ('יינות ביתן', 'Yeinot Bitan'),
    'הוט סינמה': ('הוט סינמה', 'Hot Cinema'),
    'עיריית מודיעין-מכבים-רעות': ('העירייה', 'City Hall'),
    'אמפי פארק ענבה': ('אמפי פארק ענבה', 'the Anava Park amphitheatre'),
    'שוק האיכרים - רעות': ('שוק האיכרים רעות', "the Re'ut farmers' market"),
    'שופרסל דיל': ('שופרסל דיל', 'Shufersal Deal'),
    'שופרסל אקספרס': ('שופרסל אקספרס', 'Shufersal Express'),
    'שופרסל': ('שופרסל', 'Shufersal'),
    'יוחננוף': ('יוחננוף', 'Yochananof'),
}
# A lot inside a named centre takes the centre's name.
CENTRES = {'ישפרו סנטר': ('חניון ישפרו סנטר', 'Ishpro Center parking')}

env = {}
for line in open(os.path.join(ROOT, '.env.local'), encoding='utf-8'):
    line = line.rstrip('\n')
    if line.strip() and not line.lstrip().startswith('#'):
        k, _, v = line.partition('=')
        env[k] = v
URL = env['SUPABASE_URL'].rstrip('/')
KEY = env['SUPABASE_SERVICE_ROLE_KEY']


def db(method, path, body=None, prefer='return=representation'):
    req = urllib.request.Request(
        f'{URL}/rest/v1/{path}', method=method,
        headers={'apikey': KEY, 'Authorization': 'Bearer ' + KEY,
                 'Content-Type': 'application/json', 'Prefer': prefer},
        data=None if body is None else json.dumps(body).encode())
    with urllib.request.urlopen(req, timeout=60) as r:
        raw = r.read()
        return json.loads(raw) if raw else None


def overpass(query):
    for mirror in MIRRORS * 2:
        try:
            req = urllib.request.Request(
                mirror, data=urllib.parse.urlencode({'data': query}).encode(), headers=UA)
            with urllib.request.urlopen(req, timeout=150) as r:
                return json.load(r)['elements']
        except Exception:
            time.sleep(3)
    raise SystemExit('OpenStreetMap (Overpass) did not answer')


def area_m2(geom):
    if len(geom) < 3:
        return 0
    lat0 = sum(p['lat'] for p in geom) / len(geom)
    kx, ky = 111320 * math.cos(math.radians(lat0)), 110540
    pts = [(p['lon'] * kx, p['lat'] * ky) for p in geom]
    return abs(sum(pts[i][0] * pts[i - 1][1] - pts[i - 1][0] * pts[i][1]
                   for i in range(len(pts)))) / 2


def dist(a, b, c, d):
    return math.hypot((a - c) * 110540, (b - d) * 111320 * math.cos(math.radians(a)))


def reverse(lat, lon):
    time.sleep(1.1)  # Nominatim's limit: one request a second
    q = urllib.parse.urlencode({'lat': lat, 'lon': lon, 'format': 'json', 'zoom': 18,
                                'addressdetails': 1, 'accept-language': 'he'})
    req = urllib.request.Request('https://nominatim.openstreetmap.org/reverse?' + q, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def lots():
    ways = overpass('[out:json][timeout:120];area(3601381425)->.city;'
                    'way["amenity"="parking"](area.city);out geom tags;')
    pois = overpass('''[out:json][timeout:120];area(3601381425)->.city;
      (nwr["railway"="station"]["name"](area.city);
       nwr["shop"~"mall|supermarket"]["name"](area.city);
       nwr["leisure"~"sports_centre|stadium|park|water_park"]["name"](area.city);
       nwr["amenity"~"community_centre|townhall|library|marketplace|theatre|cinema"]["name"](area.city););
      out center tags;''')
    found = []
    for w in ways:
        t = w.get('tags', {})
        if t.get('access', 'yes') not in ('yes', 'public', 'customers'):
            continue
        if t.get('parking') in ('street_side', 'lane'):
            continue
        a = area_m2(w.get('geometry', []))
        if a < MIN_AREA:
            continue
        g = w['geometry']
        lat = sum(p['lat'] for p in g) / len(g)
        lon = sum(p['lon'] for p in g) / len(g)
        best = None
        for p in pois:
            c = p.get('center') or {'lat': p.get('lat'), 'lon': p.get('lon')}
            if c.get('lat') is None:
                continue
            d = dist(lat, lon, c['lat'], c['lon'])
            name = p['tags'].get('name:he') or p['tags'].get('name')
            if d <= NEAR and name in LANDMARKS and (best is None or d < best[0]):
                best = (d, name)
        if best:
            found.append({'osm': w['id'], 'area': a, 'lat': lat, 'lon': lon,
                          'fee': t.get('fee'), 'capacity': t.get('capacity'), 'near': best[1]})
    return sorted(found, key=lambda x: -x['area'])


def main():
    if '--undo' in sys.argv:
        ids = json.load(open(REGISTRY, encoding='utf-8'))
        for i in ids:
            db('DELETE', f'parking_lots?id=eq.{i}', prefer='return=minimal')
        os.remove(REGISTRY)
        print('removed', len(ids), 'car parks')
        return
    if os.path.exists(REGISTRY):
        raise SystemExit('already imported — run --undo first')
    apply = '--apply' in sys.argv

    rows, seen = [], set()
    for lot in lots():
        r = reverse(lot['lat'], lot['lon'])
        a = r.get('address', {})
        centre = next((c for c in CENTRES if c in json.dumps(r, ensure_ascii=False)), None)
        if centre:
            name, name_en = CENTRES[centre]
        else:
            he, en = LANDMARKS[lot['near']]
            name, name_en = f'חניון ליד {he}', f'Parking by {en}'
        road = a.get('road') or ''
        road = f'כביש {road}' if road.isdigit() else road
        street = ' '.join(x for x in (road, a.get('house_number') or '') if x)
        area = a.get('suburb') or a.get('neighbourhood')
        address = ', '.join(x for x in (street, area, 'מודיעין') if x)
        # Two lots with the same name at the same address would be one entry
        # twice in the list; the larger (first, by area) stands for both.
        if (name, address) in seen:
            continue
        seen.add((name, address))
        rows.append({
            'name': name,
            'name_en': name_en,
            'address': address,
            'latitude': round(lot['lat'], 6),
            'longitude': round(lot['lon'], 6),
            'is_free': True if lot['fee'] == 'no' else False if lot['fee'] == 'yes' else None,
            # OpenStreetMap's capacity tag is rare here and unreliable — the
            # one lot tagged said 2 spaces for some 150 — so the client enters
            # the number in the panel.
            'capacity': None,
            'is_active': True,
            'sort_order': len(rows),
        })

    for r in rows:
        free = {True: 'חינם', False: 'בתשלום', None: '—'}[r['is_free']]
        print(f"{r['name']:42} | {r['address']:40} | {free:6} | {r['latitude']},{r['longitude']}")
    if not apply:
        print(f'\n{len(rows)} car parks — dry run, nothing written')
        return

    created = db('POST', 'parking_lots', rows)
    with open(REGISTRY, 'w', encoding='utf-8') as f:
        json.dump([c['id'] for c in created], f, indent=1)
    print(f'\nadded {len(created)} car parks')


main()
