#!/usr/bin/env python3
"""Fills businesses.hours_text from the old site's opening hours.

No business had hours: the old WordPress site kept them as free text in each
business (assets/data/wp_business.json, `hours`), and the import never read
them. They are written as people write them — "א-ה 8:00-23:00", "9:00-15:00,
17:00-22:00 מ-א׳-ה׳", holiday notes — so they are kept as text (00071), not
guessed into day-by-day rows.

A business is matched by its exact name. Only empty hours_text is filled, so
anything the client typed in the panel since is left alone. What was written
is recorded in tool/wp_hours_registry.json, which --undo reads to empty
exactly those rows again, and only where the text is still what was written.

    python3 tool/import_wp_hours.py            # dry run
    python3 tool/import_wp_hours.py --apply
    python3 tool/import_wp_hours.py --undo
"""

import html
import json
import os
import sys
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY = os.path.join(ROOT, 'tool', 'wp_hours_registry.json')


def env(key):
    for line in open(os.path.join(ROOT, '.env.local'), encoding='utf-8'):
        k, _, v = line.rstrip('\n').partition('=')
        if k == key:
            return v
    raise SystemExit(f'{key} is not in .env.local')


URL = env('SUPABASE_URL')
KEY = env('SUPABASE_SERVICE_ROLE_KEY')
HEADERS = {'apikey': KEY, 'Authorization': f'Bearer {KEY}', 'Content-Type': 'application/json'}


def rest(method, path, body=None):
    req = urllib.request.Request(
        f'{URL}/rest/v1/{path}', method=method, headers=HEADERS,
        data=json.dumps(body).encode() if body is not None else None,
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        raw = r.read().decode()
        return json.loads(raw) if raw.strip() else None


def clean(text):
    """Tidy without changing what it says: the old site's tabs to spaces,
    trailing spaces and empty lines gone."""
    lines = [' '.join(l.replace('\t', ' ').split()) for l in text.replace('\r', '').split('\n')]
    return '\n'.join(l for l in lines if l)


def main():
    if '--undo' in sys.argv:
        written = json.load(open(REGISTRY, encoding='utf-8'))
        done = 0
        for row in written:
            q = f"id=eq.{row['id']}&hours_text=eq.{urllib.parse.quote(row['hours_text'])}"
            req = urllib.request.Request(
                f'{URL}/rest/v1/businesses?{q}', method='PATCH',
                headers={**HEADERS, 'Prefer': 'return=representation'},
                data=json.dumps({'hours_text': None}).encode())
            with urllib.request.urlopen(req, timeout=60) as resp:
                done += len(json.loads(resp.read().decode() or '[]'))
        os.remove(REGISTRY)
        print(f'emptied {done} of {len(written)}; registry removed')
        return

    wp = json.load(open(os.path.join(ROOT, 'assets', 'data', 'wp_business.json'), encoding='utf-8'))
    rows = rest('GET', 'businesses?select=id,name,hours_text')
    by_name = {}
    for b in rows:
        by_name.setdefault(b['name'].strip(), []).append(b)

    plan, unmatched, ambiguous, kept = [], [], [], 0
    for w in wp:
        text = clean(w.get('hours') or '')
        if not text:
            continue
        found = by_name.get(html.unescape(w['title']).strip(), [])
        if not found:
            unmatched.append(w['title'])
            continue
        if len(found) > 1:
            ambiguous.append(w['title'])
            continue
        b = found[0]
        if (b.get('hours_text') or '').strip():
            kept += 1
            continue
        plan.append({'id': b['id'], 'name': b['name'], 'hours_text': text})

    print(f'{len(plan)} to fill, {kept} already have hours, '
          f'{len(unmatched)} not found by name, {len(ambiguous)} name used twice')
    for t in unmatched:
        print('  not found:', t)
    for t in ambiguous:
        print('  ambiguous:', t)
    if '--apply' not in sys.argv:
        print('dry run — pass --apply to write')
        return

    written = []
    if os.path.exists(REGISTRY):
        written = json.load(open(REGISTRY, encoding='utf-8'))
    for p in plan:
        rest('PATCH', f"businesses?id=eq.{p['id']}", {'hours_text': p['hours_text']})
        written.append({'id': p['id'], 'hours_text': p['hours_text']})
    json.dump(written, open(REGISTRY, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(f'filled {len(plan)}; registry: {os.path.relpath(REGISTRY, ROOT)}')


if __name__ == '__main__':
    main()
