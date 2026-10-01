#!/usr/bin/env python3
"""Gives back ten articles the Hebrew slugs they had on WordPress.

The first import turned their slugs into the percent-encoding with the
percent signs dropped — /news/חורבת-נכס/ became /news/d7-97-d7-95-…/ — so
the new site would have had to redirect the address Google knows to an
unreadable one. Each article still carries its WordPress address in
`canonical_url`; this sets the slug back to the last part of it, for the
articles tool/seo_inventory.py found with a different slug, when no other
article has it.

The slugs replaced are kept in tool/seo/slug_registry.json; --undo puts
them back.

    python3 tool/seo_restore_slugs.py            # dry run
    python3 tool/seo_restore_slugs.py --apply
    python3 tool/seo_restore_slugs.py --undo

Reads SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY from .env.local.
"""
import csv
import json
import os
import sys
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY = os.path.join(ROOT, 'tool', 'seo', 'slug_registry.json')

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
        f'{URL}/rest/v1/{path}', method=method,
        headers={'apikey': KEY, 'Authorization': 'Bearer ' + KEY,
                 'Content-Type': 'application/json', 'Prefer': 'return=minimal'},
        data=None if body is None else json.dumps(body).encode())
    with urllib.request.urlopen(req, timeout=60) as r:
        raw = r.read()
        return json.loads(raw) if raw else None


def main():
    if '--undo' in sys.argv:
        reg = json.load(open(REGISTRY, encoding='utf-8'))
        for e in reg:
            db('PATCH', f"articles?id=eq.{e['id']}", {'slug': e['was']})
        os.remove(REGISTRY)
        print('put back', len(reg), 'slugs')
        return
    if os.path.exists(REGISTRY):
        raise SystemExit('already applied — run --undo first')

    apply = '--apply' in sys.argv
    rows = [r for r in csv.DictReader(open(os.path.join(ROOT, 'tool', 'seo', 'url_map.csv'), encoding='utf-8-sig'))
            if r['kind'] == 'news' and r['how'].startswith('redirect to its slug')]
    registry = []
    for r in rows:
        a = db('GET', f"articles?select=id,slug,canonical_url&id=eq.{r['id']}")[0]
        wanted = urllib.parse.unquote(urllib.parse.urlparse(a['canonical_url'] or '').path).strip('/').split('/')[-1]
        if not wanted or wanted == a['slug']:
            continue
        if db('GET', 'articles?select=id&slug=eq.' + urllib.parse.quote(wanted)):
            print('taken, left as is:', wanted)
            continue
        print(f"{a['slug'][:30]}… → {wanted}")
        if apply:
            db('PATCH', f"articles?id=eq.{a['id']}", {'slug': wanted})
            registry.append({'id': a['id'], 'was': a['slug'], 'now': wanted})
            with open(REGISTRY, 'w', encoding='utf-8') as fh:
                json.dump(registry, fh, ensure_ascii=False, indent=1)
    print(('restored' if apply else 'would restore'), len(registry) if apply else len(rows))


main()
