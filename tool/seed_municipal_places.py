#!/usr/bin/env python3
"""Fills `municipal_places` (migration 00040) from public sources.

  python3 tool/seed_municipal_places.py --emergency     # the national numbers
  python3 tool/seed_municipal_places.py --osm           # places from OpenStreetMap
  python3 tool/seed_municipal_places.py --undo          # removes what this added

--emergency adds the emergency numbers the client listed for the Municipal
page ("the 106 hotline, police, MADA") and fire and rescue beside them. They
are Israel's national numbers, the same in every town, not content made up
for the app.

--osm reads OpenStreetMap (open data, ODbL — the pages credit it) inside
the city's own boundary, relation 1381425 "Modiin-Maccabim-Reut", so the
neighbouring councils and Modi'in Illit stay out: public institutions (city
hall, library, police, fire station, post office, community centres),
synagogues, clinics and pharmacies, schools, kindergartens, the train
stations and the bus stops. Only places with a name are taken. It is real
data, but not complete — OpenStreetMap has 17 of the city's kindergartens
and 16 of its synagogues — so the client adds the rest in the panel.

Rows go in with `source` and `source_ref`, so a second run skips what is
there, and --undo removes exactly the rows this script added (recorded in
tool/municipal_places_registry.json) and nothing the client typed in the
panel.

Reads SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY from .env.local.
"""
import json
import os
import sys
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY = os.path.join(ROOT, 'tool', 'municipal_places_registry.json')

EMERGENCY = [
    # (source_ref, Hebrew name, English name, phone, sort order)
    ('106', 'מוקד עירוני', 'Municipal hotline', '106', 1),
    ('100', 'משטרה', 'Police', '100', 2),
    ('101', 'מגן דוד אדום', 'Magen David Adom (ambulance)', '101', 3),
    ('102', 'כבאות והצלה', 'Fire and rescue', '102', 4),
]

env = {}
for line in open(os.path.join(ROOT, '.env.local'), encoding='utf-8'):
    line = line.rstrip('\n')
    if line.strip() and not line.lstrip().startswith('#'):
        k, _, v = line.partition('=')
        env[k] = v
URL = env['SUPABASE_URL'].rstrip('/')
KEY = env['SUPABASE_SERVICE_ROLE_KEY']


def db(method, path, body=None):
    req = urllib.request.Request(
        URL + '/rest/v1/' + path, method=method,
        headers={'apikey': KEY, 'Authorization': 'Bearer ' + KEY,
                 'Content-Type': 'application/json', 'Prefer': 'return=representation'},
        data=None if body is None else json.dumps(body).encode())
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        raise SystemExit(f'{method} {path.split("?")[0]} -> {e.code}: {e.read().decode()[:300]}')


def load_registry():
    if os.path.exists(REGISTRY):
        return json.load(open(REGISTRY, encoding='utf-8'))
    return []


def save_registry(ids):
    with open(REGISTRY, 'w', encoding='utf-8') as f:
        json.dump(ids, f, indent=2)


def add(rows):
    """Inserts the rows not already there (by source + source_ref)."""
    ids = load_registry()
    added = 0
    for row in rows:
        existing = db('GET', f"municipal_places?source=eq.{row['source']}"
                             f"&source_ref=eq.{urllib.request.quote(row['source_ref'])}&select=id")
        if existing:
            continue
        created = db('POST', 'municipal_places', row)
        ids.append(created[0]['id'])
        added += 1
    save_registry(ids)
    print(f'added {added}, skipped {len(rows) - added} already there')


OVERPASS = 'https://overpass-api.de/api/interpreter'
QUERY = """[out:json][timeout:120];
area(3601381425)->.a;
(
 nwr(area.a)["amenity"~"^(school|kindergarten|place_of_worship|clinic|doctors|hospital|pharmacy|townhall|library|community_centre|police|fire_station|post_office|courthouse)$"];
 nwr(area.a)["office"="government"];
 node(area.a)["railway"="station"];
 node(area.a)["highway"="bus_stop"];
);
out tags center;"""

# Not social_facility: in Modi'in those are private senior residences, not
# public institutions.
INSTITUTIONS = {'townhall', 'library', 'community_centre', 'police', 'fire_station',
                'post_office', 'courthouse'}
HEALTH = {'clinic', 'doctors', 'hospital', 'pharmacy'}


def osm_category(t):
    if t.get('railway') == 'station':
        return 'train_station'
    if t.get('highway') == 'bus_stop':
        return 'bus_stop'
    a = t.get('amenity')
    if a == 'place_of_worship':
        return 'synagogue' if t.get('religion') == 'jewish' else None
    if a in INSTITUTIONS or t.get('office') == 'government':
        return 'institution'
    if a in HEALTH:
        return 'health'
    if a in ('school', 'kindergarten'):
        return a
    return None


def osm_rows():
    import urllib.parse
    req = urllib.request.Request(
        OVERPASS, data=urllib.parse.urlencode({'data': QUERY}).encode(),
        headers={'User-Agent': 'modiin4u-import/1.0'})
    with urllib.request.urlopen(req, timeout=300) as r:
        elements = json.load(r)['elements']
    rows = []
    for e in elements:
        t = e.get('tags', {})
        name = (t.get('name') or t.get('name:he') or '').strip()
        category = osm_category(t)
        if not name or not category:
            continue
        lat = e.get('lat') or (e.get('center') or {}).get('lat')
        lon = e.get('lon') or (e.get('center') or {}).get('lon')
        street = (t.get('addr:street') or '').strip()
        number = (t.get('addr:housenumber') or '').strip()
        notes = None
        if category == 'bus_stop' and t.get('ref'):
            # The stop's number, as it is signed at the stop — "#34148",
            # which reads the same in Hebrew and English.
            notes = f"#{t['ref']}"
        rows.append({
            'category': category,
            'name': name,
            'name_en': (t.get('name:en') or '').strip() or None,
            'address': f'{street} {number}'.strip() or None,
            'phone': (t.get('phone') or t.get('contact:phone') or '').strip() or None,
            'notes': notes,
            'latitude': lat,
            'longitude': lon,
            'source': 'osm',
            'source_ref': f"{e['type']}/{e['id']}",
        })
    return rows


if '--undo' in sys.argv:
    ids = load_registry()
    for i in ids:
        db('DELETE', f'municipal_places?id=eq.{i}')
    left = [i for i in ids if db('GET', f'municipal_places?id=eq.{i}&select=id')]
    os.remove(REGISTRY)
    print(f'removed {len(ids) - len(left)} rows, {len(left)} left')
elif '--emergency' in sys.argv:
    add([
        {'category': 'emergency', 'name': he, 'name_en': en, 'phone': phone,
         'sort_order': order, 'source': 'national', 'source_ref': ref}
        for ref, he, en, phone, order in EMERGENCY
    ])
elif '--osm' in sys.argv:
    rows = osm_rows()
    from collections import Counter
    print('from OpenStreetMap:', dict(Counter(r['category'] for r in rows)))
    add(rows)
else:
    print(__doc__)
