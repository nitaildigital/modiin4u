#!/usr/bin/env python3
"""Removes the sample content supabase/seed_remote.sql put in the live
database — before launch (PLAN.md, "What seed_remote.sql put in the live
database"): 19 placeholder businesses with invented phone numbers (a dentist
and a lawyer among them), 8 articles with invented view counts, and the 9
sample events. seed_sample_content.py --undo removes its own content but
never this.

The rows are found by the slugs written in seed_remote.sql, and a business
only when it also carries the seed's signature — created before 2026, while
the WordPress import is all 23 Sep 2026 — so a real business that happened
to take one of those slugs is left alone.

    python3 tool/remove_seed_remote.py            # list what would go (default)
    python3 tool/remove_seed_remote.py --apply    # remove it

It refuses to remove anything while other content still points at a row —
deals, reviews, favourites, comments, events of a business — and lists it;
remove those first (seed_sample_content.py --undo takes its own). Category
links go with the rows. Reads .env.local; never prints a key.
"""
import json
import os
import re
import sys
import urllib.parse
import urllib.request

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SEED = os.path.join(ROOT, 'supabase', 'seed_remote.sql')


def env():
    out = {}
    for line in open(os.path.join(ROOT, '.env.local'), encoding='utf-8'):
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            k, _, v = line.partition('=')
            out[k.strip()] = v.strip().strip('"\'')
    return out


E = env()
URL = E['SUPABASE_URL'].rstrip('/')
KEY = E['SUPABASE_SERVICE_ROLE_KEY']


def rest(method, path, body=None):
    req = urllib.request.Request(
        f'{URL}/rest/v1/{path}', method=method,
        data=None if body is None else json.dumps(body).encode(),
        headers={'apikey': KEY, 'Authorization': 'Bearer ' + KEY,
                 'Content-Type': 'application/json', 'Prefer': 'return=minimal'})
    with urllib.request.urlopen(req, timeout=60) as r:
        text = r.read().decode()
        return json.loads(text) if text else None


def q(v):
    return urllib.parse.quote(str(v), safe='')


def seeded_slugs():
    """The slug of each row the seed inserts into businesses, articles and
    events: the second quoted value of each tuple in that insert."""
    sql = open(SEED, encoding='utf-8').read()
    out = {}
    for table in ('businesses', 'articles', 'events'):
        m = re.search(rf'insert into {table} \((.*?)\) values(.*?);', sql, re.S)
        if not m:
            out[table] = []
            continue
        cols = [c.strip() for c in m.group(1).split(',')]
        at = cols.index('slug')
        slugs = []
        for row in re.findall(r"^\s*\((.*)\)\s*,?\s*$", m.group(2), re.M):
            values = re.findall(r"'((?:[^']|'')*)'|(\bnull\b|\b[\w.-]+\b)", row)
            flat = [a if a else b for a, b in values]
            if len(flat) > at:
                slugs.append(flat[at])
        out[table] = slugs
    return out


def main():
    apply = '--apply' in sys.argv
    slugs = seeded_slugs()
    found = {}
    for table, names in slugs.items():
        if not names:
            continue
        inlist = ','.join(f'"{s}"' for s in names)
        cols = 'id,slug,created_at' + (',name,website,cover_url' if table == 'businesses' else ',title')
        rows = rest('GET', f'{table}?slug=in.({q(inlist)})&select={cols}') or []
        if table == 'businesses':
            # The seed's signature: an import row is never older than 2026.
            rows = [r for r in rows if (r.get('created_at') or '') < '2026-01-01']
        found[table] = rows
        print(f'{table}: {len(rows)} of the {len(names)} seeded slugs found')
        for r in rows:
            print(f"   {r['slug']}  {r.get('name') or r.get('title') or ''}")

    biz = [r['id'] for r in found.get('businesses', [])]
    ids = biz + [r['id'] for t in ('articles', 'events') for r in found.get(t, [])]
    blockers = []
    if biz:
        chunk = ','.join(biz)
        for table in ('offers', 'reviews', 'events', 'jobs'):
            try:
                hits = rest('GET', f'{table}?business_id=in.({chunk})&select=id') or []
            except urllib.error.HTTPError:
                # A table without business_id where this one was written.
                continue
            if hits:
                blockers.append(f'{len(hits)} {table} of these businesses')
    if ids:
        chunk = ','.join(ids)
        for table in ('favorites', 'comments'):
            hits = rest('GET', f'{table}?entity_id=in.({chunk})&select=id') or []
            if hits:
                blockers.append(f'{len(hits)} {table} on these rows')

    if blockers:
        print('\nStill pointing at them — remove first (seed_sample_content.py --undo takes its own):')
        for b in blockers:
            print('   ' + b)
        if apply:
            sys.exit('Nothing removed.')

    if not apply:
        print('\nList only. Run with --apply to remove them.')
        return
    if not ids:
        print('Nothing to remove.')
        return

    for table, entity in (('businesses', 'business'), ('articles', 'article'), ('events', 'event')):
        rows = found.get(table, [])
        if not rows:
            continue
        chunk = ','.join(r['id'] for r in rows)
        rest('DELETE', f'entity_categories?entity_type=eq.{entity}&entity_id=in.({chunk})')
        # "Send a notification" off first: an update with it on could queue
        # one, and removal must not announce anything.
        rest('PATCH', f'{table}?id=in.({chunk})', {'notify_on_publish': False})
        rest('DELETE', f'{table}?id=in.({chunk})')
        print(f'removed {len(rows)} {table}')

    left = []
    for table, rows in found.items():
        if rows:
            chunk = ','.join(r['id'] for r in rows)
            left += rest('GET', f'{table}?id=in.({chunk})&select=id') or []
    print('Done.' if not left else f'{len(left)} rows are still there — check them.')


if __name__ == '__main__':
    main()
