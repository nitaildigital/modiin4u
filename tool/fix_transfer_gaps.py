#!/usr/bin/env python3
"""Closes the gaps the 14 Oct check of WordPress against the new site found
(PLAN.md, "WordPress → new site, checked end to end").

  1. The accessibility statement: copied from WordPress into `site_pages` on
     30 Sep and left a draft for the client to review, so /accessibility/
     said it was coming while WordPress shows it. Published as it stands —
     WordPress's own words; the panel (עמודי מידע) still edits it.
  2. /news/modiin-parking/: its text came from the WordPress export, which
     predates WordPress's 18 Sep rewrite (a new title, a fifth of the text).
     The title, text and excerpt are taken from WordPress now. Its search
     title and description already match WordPress and are left alone.
  3. Articles WordPress files under a news category and we file nowhere:
     tool/import_article_categories.py matched articles by slug, and ten with
     Hebrew addresses did not match. Matched here through the address each
     had on WordPress (tool/seo/url_map.csv), as the rest of the move does.

Only what still differs is written, and what it was before is kept in
tool/transfer_gaps_registry.json, which --undo puts back.

    python3 tool/fix_transfer_gaps.py            # dry run: what would change
    python3 tool/fix_transfer_gaps.py --apply
    python3 tool/fix_transfer_gaps.py --undo

Reads SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY from .env.local.
"""
import csv
import html
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY = os.path.join(ROOT, 'tool', 'transfer_gaps_registry.json')
WP = 'https://www.modiin4u.co.il/wp-json/wp/v2/'
UA = {'User-Agent': 'Mozilla/5.0 (compatible; modiin4u-migration; +https://www.modiin4u.co.il)'}
PARKING = '/news/modiin-parking/'

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
        headers={'apikey': KEY, 'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json',
                 'Prefer': 'return=representation'},
        data=None if body is None else json.dumps(body).encode())
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            t = r.read()
            return json.loads(t) if t else None
    except urllib.error.HTTPError as e:
        sys.exit(f'{method} {path.split("?")[0]}: {e.code} {e.read()[:300]!r}')


def wp(path):
    """Every page of a WordPress REST list."""
    out, page = [], 1
    while True:
        req = urllib.request.Request(f'{WP}{path}&per_page=100&page={page}', headers=UA)
        with urllib.request.urlopen(req, timeout=90) as r:
            out += json.loads(r.read())
            if page >= int(r.headers.get('X-WP-TotalPages', '1')):
                return out
        page += 1


def path_of(link):
    return urllib.parse.unquote(urllib.parse.urlsplit(link).path)


def text(s):
    return html.unescape(re.sub(r'<[^>]+>', '', s or '')).strip()


def url_map():
    with open(os.path.join(ROOT, 'tool', 'seo', 'url_map.csv'), encoding='utf-8-sig') as f:
        return {urllib.parse.unquote(r['old_path']): r for r in csv.DictReader(f)}


def plan():
    umap = url_map()
    changes = []

    page = db('GET', 'site_pages?slug=eq.accessibility&select=slug,is_published,body_he')
    if page and not page[0]['is_published'] and (page[0]['body_he'] or '').strip():
        changes.append({'what': 'publish /accessibility/', 'table': 'site_pages', 'match': 'slug=eq.accessibility',
                        'before': {'is_published': False}, 'after': {'is_published': True}})

    news = wp('news?_fields=id,link,title,content,excerpt,new')
    parking = next(n for n in news if path_of(n['link']) == PARKING)
    aid = umap[PARKING]['id']
    row = db('GET', f'articles?id=eq.{aid}&select=title,body,excerpt')[0]
    after = {'title': text(parking['title']['rendered']),
             'body': parking['content']['rendered'].strip(),
             'excerpt': text(parking['excerpt']['rendered'])[:400]}
    diff = {k: v for k, v in after.items() if (row[k] or '').strip() != v}
    if diff:
        changes.append({'what': f'{PARKING}: {", ".join(diff)} from WordPress', 'table': 'articles',
                        'match': f'id=eq.{aid}', 'before': {k: row[k] for k in diff}, 'after': diff})

    # The category by its name, as import_article_categories.py found it: the
    # address will not do — /new/municipal/ is filed in url_map.csv under the
    # older, empty עירייה, while WordPress's עירוני is ours under that name.
    terms = {t['id']: text(t['name']) for t in wp('new?_fields=id,name')}
    cats = {c['name']: c['id'] for c in db('GET', 'categories?scope=eq.article&select=id,name')}
    have = {(l['entity_id'], l['category_id'])
            for l in db('GET', 'entity_categories?entity_type=eq.article&select=entity_id,category_id')}
    for n in news:
        m = umap.get(path_of(n['link']))
        if not m or not m['id']:
            continue
        for tid in n.get('new') or []:
            name = terms.get(tid)
            cid = cats.get(name)
            if cid and (m['id'], cid) not in have:
                changes.append({'what': f'{path_of(n["link"])} → {name}', 'table': 'entity_categories',
                                'insert': {'entity_type': 'article', 'entity_id': m['id'], 'category_id': cid}})
    return changes


def main():
    if '--undo' in sys.argv:
        if not os.path.exists(REGISTRY):
            sys.exit('nothing to undo')
        done = json.load(open(REGISTRY, encoding='utf-8'))
        for c in reversed(done):
            if 'insert' in c:
                i = c['insert']
                db('DELETE', f"entity_categories?entity_type=eq.article&entity_id=eq.{i['entity_id']}"
                             f"&category_id=eq.{i['category_id']}")
            else:
                db('PATCH', f"{c['table']}?{c['match']}", c['before'])
            print('undone:', c['what'])
        os.remove(REGISTRY)
        return

    apply = '--apply' in sys.argv
    changes = plan()
    for c in changes:
        print(('writing: ' if apply else 'would write: ') + c['what'])
    if not changes:
        print('nothing differs')
        return
    if not apply:
        print('\ndry run — nothing written. Re-run with --apply')
        return
    if os.path.exists(REGISTRY):
        sys.exit(f'{REGISTRY} exists — undo that run first')
    done = []
    try:
        for c in changes:
            if 'insert' in c:
                db('POST', 'entity_categories', c['insert'])
            else:
                db('PATCH', f"{c['table']}?{c['match']}", c['after'])
            done.append(c)
    finally:
        with open(REGISTRY, 'w', encoding='utf-8') as f:
            json.dump(done, f, ensure_ascii=False, indent=1)
    print(f'done: {len(done)} changes, recorded in {os.path.relpath(REGISTRY, ROOT)}')


main()
