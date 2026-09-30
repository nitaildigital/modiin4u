#!/usr/bin/env python3
"""Adds the Community page's three settings to `remote_config`, where the
client edits them in the panel (דגלים והגדרות › Remote Config).

They are his, taken from his WordPress site, not written for him:
  community_facebook_url   the "הצטרפות לקבוצה" page's button
                           (www.modiin4u.co.il/facebookgruop)
  community_share_url      his "שתפו אותנו" form (www.modiin4u.co.il/share-with-us)
  community_news_category  the news category the page lists; "people" (אנשים)
                           until he picks another — there is no community
                           category among the articles

A key that already exists is left as it is. What this adds is recorded in
tool/community_settings_registry.json, and --undo removes exactly that.

    python3 tool/seed_community_settings.py --apply
    python3 tool/seed_community_settings.py --undo

Reads SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY from .env.local.
"""
import json
import os
import sys
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY = os.path.join(ROOT, 'tool', 'community_settings_registry.json')

SETTINGS = [
    ('community_facebook_url', 'https://www.facebook.com/groups/modiinourhome',
     'עמוד קהילה: הקישור לקבוצת הפייסבוק (כפתור "הצטרף עכשיו"). ריק = הכרטיס מוסתר.'),
    ('community_share_url', 'https://www.modiin4u.co.il/share-with-us/',
     'עמוד קהילה: הקישור לטופס "שתפו אותנו". ריק = הכרטיס מוסתר.'),
    ('community_news_category', 'people',
     'עמוד קהילה: ה-slug של קטגוריית החדשות שמוצגת (למשל people, city-updates).'),
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
        with urllib.request.urlopen(req, timeout=30) as r:
            raw = r.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        raise SystemExit(f'{method} {path.split("?")[0]} -> {e.code}: {e.read().decode()[:300]}')


if '--undo' in sys.argv:
    added = json.load(open(REGISTRY, encoding='utf-8'))
    for key in added:
        db('DELETE', f'remote_config?key=eq.{key}')
        print('removed', key)
    os.remove(REGISTRY)
elif '--apply' in sys.argv:
    if os.path.exists(REGISTRY):
        raise SystemExit('already applied — run --undo first')
    added = []
    for key, value, description in SETTINGS:
        if db('GET', f'remote_config?key=eq.{key}&select=key'):
            print('kept existing', key)
            continue
        db('POST', 'remote_config', {'key': key, 'value': value, 'description': description})
        added.append(key)
        print('added', key)
    with open(REGISTRY, 'w', encoding='utf-8') as f:
        json.dump(added, f, indent=2)
else:
    print(__doc__)
