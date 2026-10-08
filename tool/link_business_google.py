#!/usr/bin/env python3
"""Links businesses with no opening hours to their place on Google Maps.

The client (8 Oct): take the hours from Google, or from WordPress.
tool/import_wp_hours.py brought the old site's hours to 171 businesses; the
rest had none there. Google's terms let us keep a place's ID, not its
details, so this stores only `businesses.google_place_id` (00073) and the
business page asks Google for the hours live, with Google's credit — as the
car parks do (tool/link_parking_google.py).

Each business is searched by its name and the city. A result is linked only
when it is plainly the same place:

  * Google's name and ours match closely (after dropping "מודיעין",
    punctuation and spacing), and
  * it is within 300 m of our location — or, for a business with no
    location, its address is in Modi'in.

Anything less is listed as "unsure" and left for the client, who can paste
a place ID in the panel's business editor. Only businesses with no hours of
any kind (day-by-day or text) and no place ID are searched, so nothing set
by hand is touched.

Everything linked is recorded in tool/business_google_registry.json, and
--undo clears exactly those links again (where they are still the same).

    python3 tool/link_business_google.py            # dry run
    python3 tool/link_business_google.py --apply
    python3 tool/link_business_google.py --undo

Reads SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY and GOOGLE_PLACES_SERVER_KEY
from .env.local. The website's key will not do: it is restricted to the
site's addresses, and a script that claimed to be the site would defeat that.
The server key is one for scripts — restricted to the Places API and to the
address it is run from, or deleted after the run.
"""

import difflib
import json
import math
import os
import re
import sys
import time
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY = os.path.join(ROOT, 'tool', 'business_google_registry.json')

env = {}
for line in open(os.path.join(ROOT, '.env.local'), encoding='utf-8'):
    line = line.rstrip('\n')
    if line.strip() and not line.lstrip().startswith('#'):
        k, _, v = line.partition('=')
        env[k] = v
URL = env['SUPABASE_URL'].rstrip('/')
KEY = env['SUPABASE_SERVICE_ROLE_KEY']
PLACES = env.get('GOOGLE_PLACES_SERVER_KEY')
if not PLACES and '--undo' not in sys.argv:
    raise SystemExit('GOOGLE_PLACES_SERVER_KEY is not in .env.local (see the note at the top)')

# Modi'in-Maccabim-Re'ut's centre; searches lean towards it.
CENTRE = (31.8969, 35.0095)
NEAR_M = 300
NAME_MATCH = 0.75


def db(method, path, body=None):
    req = urllib.request.Request(
        f'{URL}/rest/v1/{path}', method=method,
        headers={'apikey': KEY, 'Authorization': 'Bearer ' + KEY,
                 'Content-Type': 'application/json', 'Prefer': 'return=representation'},
        data=None if body is None else json.dumps(body).encode())
    with urllib.request.urlopen(req, timeout=60) as r:
        raw = r.read()
        return json.loads(raw) if raw else None


def search(text):
    req = urllib.request.Request(
        'https://places.googleapis.com/v1/places:searchText', method='POST',
        data=json.dumps({
            'textQuery': text, 'pageSize': 3, 'languageCode': 'he',
            'locationBias': {'circle': {'center': {'latitude': CENTRE[0], 'longitude': CENTRE[1]},
                                        'radius': 15000}},
        }).encode(),
        headers={'Content-Type': 'application/json', 'X-Goog-Api-Key': PLACES,
                 'X-Goog-FieldMask': 'places.id,places.displayName,places.location,'
                                     'places.formattedAddress,places.regularOpeningHours.weekdayDescriptions'})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r).get('places', [])


def dist(a, b, c, d):
    return math.hypot((a - c) * 110540, (b - d) * 111320 * math.cos(math.radians(a)))


CITY_WORDS = re.compile(r"מודיעין|מכבים|רעות|modi'?in|maccabim|re'?ut", re.I)


def norm(name):
    name = CITY_WORDS.sub(' ', name.lower())
    name = re.sub(r'[^\w֐-׿]+', ' ', name)
    return ' '.join(name.split())


def similar(a, b):
    a, b = norm(a), norm(b)
    if not a or not b:
        return 0.0
    if a == b or (len(a) >= 4 and (a in b or b in a)):
        return 1.0
    return difflib.SequenceMatcher(None, a, b).ratio()


def in_city(address):
    return bool(CITY_WORDS.search(address or ''))


def main():
    if '--undo' in sys.argv:
        linked = json.load(open(REGISTRY, encoding='utf-8'))
        done = 0
        for row in linked:
            q = f"id=eq.{row['id']}&google_place_id=eq.{urllib.parse.quote(row['google_place_id'])}"
            done += len(db('PATCH', f'businesses?{q}', {'google_place_id': None}) or [])
        os.remove(REGISTRY)
        print(f'cleared {done} of {len(linked)}; registry removed')
        return

    # Every column, so a dry run works before 00073 adds google_place_id.
    rows = db('GET', 'businesses?select=*,business_hours(id)&status=eq.active&kind=eq.business')
    todo = [b for b in rows
            if not (b.get('hours_text') or '').strip() and not b['business_hours']
            and not b.get('google_place_id')]

    linked, unsure, none = [], [], []
    for b in todo:
        try:
            found = search(f"{b['name']} מודיעין")
        except Exception as e:
            # A refused key fails every search the same way; say it once.
            raise SystemExit(f'Google refused the search: {e}')
        best, why = None, 'no result'
        for p in found:
            g_name = p['displayName']['text']
            score = max(similar(b['name'], g_name), similar(b.get('name_en') or '', g_name))
            loc = p.get('location') or {}
            if b.get('latitude') is not None and loc:
                d = dist(b['latitude'], b['longitude'], loc['latitude'], loc['longitude'])
                near, where = d <= NEAR_M, f'{d:.0f} m'
            else:
                near, where = in_city(p.get('formattedAddress')), p.get('formattedAddress', '')
            if score >= NAME_MATCH and near:
                best, why = p, f'{score:.2f}, {where}'
                break
            if best is None and why == 'no result':
                why = f'"{g_name}" {score:.2f}, {where}'
        if best:
            linked.append((b, best, why))
        elif found:
            unsure.append((b, found[0], why))
        else:
            none.append(b)
        time.sleep(0.1)

    with_hours = sum(1 for _, p, _ in linked if (p.get('regularOpeningHours') or {}).get('weekdayDescriptions'))
    print(f'{len(todo)} with no hours: {len(linked)} matched ({with_hours} of them have hours on Google), '
          f'{len(unsure)} unsure, {len(none)} not on Google')
    for b, p, why in linked:
        print(f"  match  {b['name']}  →  {p['displayName']['text']}  ({why})")
    for b, p, why in unsure:
        print(f"  unsure {b['name']}  ({why})")
    for b in none:
        print(f"  none   {b['name']}")
    if '--apply' not in sys.argv:
        print('dry run — pass --apply to write')
        return

    registry = json.load(open(REGISTRY, encoding='utf-8')) if os.path.exists(REGISTRY) else []
    for b, p, _ in linked:
        db('PATCH', f"businesses?id=eq.{b['id']}&google_place_id=is.null", {'google_place_id': p['id']})
        registry.append({'id': b['id'], 'google_place_id': p['id']})
    json.dump(registry, open(REGISTRY, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(f'linked {len(linked)}; registry: {os.path.relpath(REGISTRY, ROOT)}')


if __name__ == '__main__':
    main()
