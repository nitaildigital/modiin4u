#!/usr/bin/env python3
"""Copies the old site's Yoast SEO titles and descriptions into the database.

The client (1 Oct): "Also, the SEO title, the site name on Google, etc."
Each article, business and category the WordPress site had carries the
title and description Yoast gave Google. tool/seo_inventory.py matched them
to our rows (tool/seo/yoast.json); this writes them into the SEO fields the
panel already edits:

  articles     seo_title, meta_description
  businesses   meta_title, meta_description
  categories   meta_title, meta_description

Only into empty fields: anything the client has written in the panel stays.
Every field set is recorded in tool/seo/fill_registry.json, and --undo
empties exactly those again.

    python3 tool/seo_fill.py            # dry run: what would be set
    python3 tool/seo_fill.py --apply
    python3 tool/seo_fill.py --undo

Reads SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY from .env.local.
"""
import json
import os
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEO = os.path.join(ROOT, 'tool', 'seo')
REGISTRY = os.path.join(SEO, 'fill_registry.json')

FIELDS = {
    'articles': ('seo_title', 'meta_description'),
    'businesses': ('meta_title', 'meta_description'),
    'categories': ('meta_title', 'meta_description'),
}

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
                 'Content-Type': 'application/json', 'Prefer': 'return=minimal',
                 'Range': '0-9999'},
        data=None if body is None else json.dumps(body).encode())
    with urllib.request.urlopen(req, timeout=60) as r:
        raw = r.read()
        return json.loads(raw) if raw else None


def main():
    if '--undo' in sys.argv:
        reg = json.load(open(REGISTRY, encoding='utf-8'))
        for e in reg:
            db('PATCH', f"{e['table']}?id=eq.{e['id']}", {f: None for f in e['fields']})
        os.remove(REGISTRY)
        print('emptied', len(reg), 'rows again')
        return

    if os.path.exists(REGISTRY):
        raise SystemExit('already applied — run --undo first')
    apply = '--apply' in sys.argv
    yoast = json.load(open(os.path.join(SEO, 'yoast.json'), encoding='utf-8'))
    registry, counts = [], {}

    for table, (title_f, desc_f) in FIELDS.items():
        found = yoast.get(table, {})
        if not found:
            continue
        current = {r['id']: r for r in db('GET', f'{table}?select=id,{title_f},{desc_f}')}
        for row_id, y in found.items():
            row = current.get(row_id)
            if not row:
                continue
            patch = {}
            if not (row.get(title_f) or '').strip() and y.get('seo_title'):
                patch[title_f] = y['seo_title'][:300]
            if not (row.get(desc_f) or '').strip() and y.get('description'):
                patch[desc_f] = y['description'][:500]
            if not patch:
                continue
            counts[table] = counts.get(table, 0) + 1
            if apply:
                db('PATCH', f'{table}?id=eq.{row_id}', patch)
                registry.append({'table': table, 'id': row_id, 'fields': list(patch)})
                with open(REGISTRY, 'w', encoding='utf-8') as fh:
                    json.dump(registry, fh, indent=1)

    print(('set' if apply else 'would set'), counts or 'nothing')


main()
