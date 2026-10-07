"""English names for the businesses and categories (migration 00062).

  python3 tool/fill_english_names.py            # says what it would write
  python3 tool/fill_english_names.py --apply    # writes them
  python3 tool/fill_english_names.py --undo     # takes back what it wrote

With English chosen the website and the app showed Hebrew names in English
menus (7 Oct). `tool/english_names_registry.json` holds an English name for
each of the 102 categories and 297 businesses that had only a Hebrew one,
drafted for the client to review: chains under their own English names, names
that carry an English part under that part, the rest transliterated with the
ordinary words ("branch", "park") translated.

A name is written only where the row's Hebrew name is still the one the draft
was made for and its `name_en` is empty, so nothing the client has typed in
the panel is overwritten. --undo clears `name_en` only where it still holds
the draft. Run 00062 first.

Reads SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY from .env.local.
"""
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY = os.path.join(ROOT, 'tool', 'english_names_registry.json')

env = {}
for line in open(os.path.join(ROOT, '.env.local'), encoding='utf-8'):
    line = line.rstrip('\n')
    if line.strip() and not line.lstrip().startswith('#'):
        k, _, v = line.partition('=')
        env[k] = v
URL = env['SUPABASE_URL'].rstrip('/')
KEY = env['SUPABASE_SERVICE_ROLE_KEY']


def http(method, path, body=None):
    headers = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY,
               'Content-Type': 'application/json', 'Prefer': 'return=minimal'}
    req = urllib.request.Request(URL + path, method=method, headers=headers,
                                 data=None if body is None else json.dumps(body).encode())
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        raise SystemExit(f'{method} {path.split("?")[0]} -> {e.code}: {e.read().decode()[:200]}')


def rows(table):
    return {r['id']: r for r in http('GET', f'/rest/v1/{table}?select=id,name,name_en&limit=5000')}


apply = '--apply' in sys.argv
undo = '--undo' in sys.argv
registry = json.load(open(REGISTRY, encoding='utf-8'))

for table, key in (('categories', 'categories'), ('businesses', 'businesses')):
    live = rows(table)
    write, skip = [], []
    for entry in registry[key]:
        row = live.get(entry['id'])
        if row is None:
            skip.append((entry['name'], 'row gone'))
        elif undo:
            if row.get('name_en') == entry['name_en']:
                write.append((entry, None))
        elif row['name'] != entry['name']:
            skip.append((entry['name'], 'Hebrew name changed since the draft'))
        elif (row.get('name_en') or '').strip():
            skip.append((entry['name'], 'already has an English name'))
        else:
            write.append((entry, entry['name_en']))

    verb = 'clear' if undo else 'write'
    print(f'{table}: {len(write)} to {verb}, {len(skip)} left alone')
    for name, why in skip:
        print(f'  left alone: {name} — {why}')
    if not (apply or undo):
        for entry, value in write[:5]:
            print(f'  {entry["name"]} → {value}')
        continue
    for entry, value in write:
        http('PATCH', f'/rest/v1/{table}?id=eq.{urllib.parse.quote(entry["id"])}', {'name_en': value})
    print(f'  done')

if not (apply or undo):
    print('Nothing written. --apply to write.')
