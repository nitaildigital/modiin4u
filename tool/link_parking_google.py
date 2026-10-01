#!/usr/bin/env python3
"""Links the car parks to Google Maps, and adds the ones only Google lists.

The client (1 Oct): "We need to pull all the parking information available
on Google … It should display whatever information we can get from Google."

Searches Google Places (API New) for every place of type `parking` in
Modi'in: a grid of nearby searches over the city and text searches in
Hebrew and English. Google lists about fifteen, a few of which are not car
parks at all. Then:

  * Each of our car parks within 100 m of a Google one is linked to it
    (`google_place_id`, migration 00044), nearest pairs first, one to one.
  * Google's car parks with nothing of ours nearby are added. Google's terms
    let us keep a place's ID, not its details, so the row gets a name of our
    own — the street it is on ("חניון ברחוב הרכבת"), from OpenStreetMap's
    address lookup — and a location from OpenStreetMap's outline of the
    lot where there is one within 60 m, Google's otherwise. The car park
    page shows Google's own name, hours, rating and photos, fetched live.
  * Places that are not public car parks are left out: EXCLUDE below.

Everything changed is recorded in tool/parking_google_registry.json, and
--undo puts it back: the links are cleared and the added rows removed.

    python3 tool/link_parking_google.py            # dry run
    python3 tool/link_parking_google.py --apply
    python3 tool/link_parking_google.py --undo

Reads SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY and GOOGLE_PLACES_WEB_KEY from
.env.local.
"""
import json
import math
import os
import sys
import time
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY = os.path.join(ROOT, 'tool', 'parking_google_registry.json')
UA = {'User-Agent': 'modiin4u-parking-google'}
LINK = 100      # m
SNAP = 60       # m
BOUNDS = (31.862, 31.940, 34.950, 35.060)   # south, north, west, east

# Google lists these as parking; they are not public car parks — a private
# home, a person's name, a bus company's depot, a private parking business.
EXCLUDE = {'בית של אראל', 'אברהם דובינסקי', 'חניון חברת קווים', 'Buzz Car Parking'}

env = {}
for line in open(os.path.join(ROOT, '.env.local'), encoding='utf-8'):
    line = line.rstrip('\n')
    if line.strip() and not line.lstrip().startswith('#'):
        k, _, v = line.partition('=')
        env[k] = v.strip()
URL = env['SUPABASE_URL'].rstrip('/')
KEY = env['SUPABASE_SERVICE_ROLE_KEY']
PLACES = env['GOOGLE_PLACES_WEB_KEY']


def db(method, path, body=None, prefer='return=representation'):
    req = urllib.request.Request(
        f'{URL}/rest/v1/{path}', method=method,
        headers={'apikey': KEY, 'Authorization': 'Bearer ' + KEY,
                 'Content-Type': 'application/json', 'Prefer': prefer},
        data=None if body is None else json.dumps(body).encode())
    with urllib.request.urlopen(req, timeout=60) as r:
        raw = r.read()
        return json.loads(raw) if raw else None


def places(path, body):
    req = urllib.request.Request(
        'https://places.googleapis.com/v1/' + path, method='POST',
        data=json.dumps(body).encode(),
        headers={'Content-Type': 'application/json', 'X-Goog-Api-Key': PLACES,
                 # Only a text search pages; a nearby search refuses the field.
                 'X-Goog-FieldMask': 'places.id,places.displayName,places.location,'
                                     'places.types,places.primaryType'
                                     + (',nextPageToken' if 'searchText' in path else '')})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def dist(a, b, c, d):
    return math.hypot((a - c) * 110540, (b - d) * 111320 * math.cos(math.radians(a)))


def google_parking():
    s, n, w, e = BOUNDS
    found = {}
    lat = s
    while lat <= n + 1e-9:
        lon = w
        while lon <= e + 1e-9:
            r = places('places:searchNearby', {
                'includedTypes': ['parking'], 'maxResultCount': 20, 'languageCode': 'he',
                'locationRestriction': {'circle': {'center': {'latitude': lat, 'longitude': lon},
                                                   'radius': 1300}}})
            for p in r.get('places', []):
                found[p['id']] = p
            lon += 0.018
        lat += 0.016
    rect = {'rectangle': {'low': {'latitude': s, 'longitude': w},
                          'high': {'latitude': n, 'longitude': e}}}
    for q in ('חניון', 'חניה', 'parking', 'חניון מודיעין', 'parking lot Modiin'):
        token = None
        for _ in range(3):
            body = {'textQuery': q, 'pageSize': 20, 'languageCode': 'he', 'locationRestriction': rect}
            if token:
                body['pageToken'] = token
            r = places('places:searchText', body)
            for p in r.get('places', []):
                if 'parking' in p.get('types', []):
                    found[p['id']] = p
            token = r.get('nextPageToken')
            if not token:
                break
            time.sleep(2)
    return [p for p in found.values() if p['displayName']['text'] not in EXCLUDE]


def osm_lots():
    """OpenStreetMap's car park outlines in the city: (lat, lon) of each."""
    q = ('[out:json][timeout:120];area(3601381425)->.city;'
         'way["amenity"="parking"](area.city);out center;')
    for mirror in ('https://overpass-api.de/api/interpreter',
                   'https://overpass.kumi.systems/api/interpreter',
                   'https://overpass.private.coffee/api/interpreter'):
        try:
            req = urllib.request.Request(mirror, data=urllib.parse.urlencode({'data': q}).encode(),
                                         headers=UA)
            with urllib.request.urlopen(req, timeout=150) as r:
                return [(w['center']['lat'], w['center']['lon'])
                        for w in json.load(r)['elements'] if 'center' in w]
        except Exception:
            time.sleep(3)
    return []


def street(lat, lon, lang):
    time.sleep(1.1)  # Nominatim: one request a second
    q = urllib.parse.urlencode({'lat': lat, 'lon': lon, 'format': 'json', 'zoom': 18,
                                'addressdetails': 1, 'accept-language': lang})
    req = urllib.request.Request('https://nominatim.openstreetmap.org/reverse?' + q, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        a = json.load(r).get('address', {})
    return a.get('road'), a.get('suburb') or a.get('neighbourhood')


def main():
    if '--undo' in sys.argv:
        reg = json.load(open(REGISTRY, encoding='utf-8'))
        for i in reg['linked']:
            db('PATCH', f'parking_lots?id=eq.{i}', {'google_place_id': None}, prefer='return=minimal')
        for i in reg['added']:
            db('DELETE', f'parking_lots?id=eq.{i}', prefer='return=minimal')
        os.remove(REGISTRY)
        print('cleared', len(reg['linked']), 'links, removed', len(reg['added']), 'car parks')
        return
    if os.path.exists(REGISTRY):
        raise SystemExit('already applied — run --undo first')
    apply = '--apply' in sys.argv

    google = google_parking()
    ours = db('GET', 'parking_lots?select=id,name,latitude,longitude,google_place_id')
    taken = {o['google_place_id'] for o in ours if o['google_place_id']}
    google = [g for g in google if g['id'] not in taken]

    # Nearest pairs first, one to one.
    pairs = sorted(
        ((dist(g['location']['latitude'], g['location']['longitude'], o['latitude'], o['longitude']), g, o)
         for g in google for o in ours if not o['google_place_id']),
        key=lambda t: t[0])
    linked, used_g, used_o = [], set(), set()
    for d, g, o in pairs:
        if d > LINK or g['id'] in used_g or o['id'] in used_o:
            continue
        used_g.add(g['id'])
        used_o.add(o['id'])
        linked.append((o, g, d))

    new = [g for g in google if g['id'] not in used_g]
    outlines = osm_lots() if new else []
    added = []
    for g in new:
        glat, glon = g['location']['latitude'], g['location']['longitude']
        snap = min(outlines, key=lambda p: dist(glat, glon, *p), default=None)
        lat, lon = snap if snap and dist(glat, glon, *snap) <= SNAP else (glat, glon)
        road_he, area = street(lat, lon, 'he')
        road_en, _ = street(lat, lon, 'en')
        added.append({
            'name': f'חניון ברחוב {road_he}' if road_he else 'חניון',
            'name_en': f'Parking on {road_en}' if road_en else 'Parking',
            'address': ', '.join(x for x in (road_he, area, 'מודיעין') if x),
            'latitude': round(lat, 6),
            'longitude': round(lon, 6),
            'google_place_id': g['id'],
            'is_active': True,
            'sort_order': 100 + len(added),
            '_google_name': g['displayName']['text'],
        })

    print('link:')
    for o, g, d in linked:
        print(f"  {o['name'][:40]:40} ← {g['displayName']['text'][:40]:40} ({round(d)} m)")
    print('add:')
    for a in added:
        print(f"  {a['name'][:40]:40} (Google: {a['_google_name'][:40]}) | {a['address']}")
    if not apply:
        print(f'\n{len(linked)} to link, {len(added)} to add — dry run, nothing written')
        return

    reg = {'linked': [], 'added': []}
    for o, g, _ in linked:
        db('PATCH', f"parking_lots?id=eq.{o['id']}", {'google_place_id': g['id']}, prefer='return=minimal')
        reg['linked'].append(o['id'])
    for a in added:
        a.pop('_google_name')
    if added:
        reg['added'] = [r['id'] for r in db('POST', 'parking_lots', added)]
    with open(REGISTRY, 'w', encoding='utf-8') as f:
        json.dump(reg, f, indent=1)
    print(f"\nlinked {len(reg['linked'])}, added {len(reg['added'])}")


main()
