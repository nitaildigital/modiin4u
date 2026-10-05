#!/usr/bin/env python3
"""Brings the old site's business categories back, each as its own category.

The client, 2 Oct: "it's important that all categories transfer over for SEO
purposes." The WordPress site had 63 business categories with businesses in
them; the new site had 22, and the SEO map (tool/seo/url_map.csv) sent the
other addresses to the nearest of those. This gives each its own category
again, at its old address (`/business-cat/<old slug>`), with its old name,
its Yoast title and description, and the businesses the old site listed in
it.

- Three of the 63 are categories the new site already has under an English
  slug (בריאות → health, ספורט וכושר → sports-fitness, רכב → automotive).
  Their address keeps its redirect; they only gain the businesses the old
  site had in them and the new one lacks.
- The others are added under the main category the SEO map chose for them
  ("nearest category by hand") — under its top-level parent, so the tree
  stays two deep.
- Four were lists rather than categories ("עסקים באתר", two wartime lists,
  "פתוח בשבת"); the map sent them to /businesses. They become top-level
  categories kept out of the menus (LANDING below).

Businesses are matched by slug: all 205 kept their address. Links are only
ever added; none is removed or changed. Everything this writes is listed in
tool/old_categories_registry.json, and --undo removes exactly that.

    python3 tool/import_old_categories.py            # show what would be written
    python3 tool/import_old_categories.py --apply
    python3 tool/import_old_categories.py --undo

Then tool/seo/url_map.csv is updated (each address now its own page), and
`python3 tool/build_seo_pages.py --write-redirects` drops their redirects.

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
REGISTRY = os.path.join(ROOT, 'tool', 'old_categories_registry.json')
URL_MAP = os.path.join(ROOT, 'tool', 'seo', 'url_map.csv')
WP = 'https://www.modiin4u.co.il/wp-json/wp/v2/'

# The four lists the map sent to /businesses: top-level, out of the menus.
LANDING = {'site-bussines-modiin', 'open-lion-war-modiin', 'lion-war', 'open-on-saturday'}

env = {}
for line in open(os.path.join(ROOT, '.env.local'), encoding='utf-8'):
    line = line.rstrip('\n')
    if line.strip() and not line.lstrip().startswith('#'):
        k, _, v = line.partition('=')
        env[k] = v
URL = env['SUPABASE_URL'].rstrip('/')
KEY = env['SUPABASE_SERVICE_ROLE_KEY']


def db(method, path, body=None, prefer=None):
    headers = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY,
               'Content-Type': 'application/json'}
    if prefer:
        headers['Prefer'] = prefer
    req = urllib.request.Request(URL + '/rest/v1/' + path, method=method, headers=headers,
                                 data=None if body is None else json.dumps(body).encode())
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            raw = r.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        raise SystemExit(f'{method} {path.split("?")[0]} -> {e.code}: {e.read().decode()[:300]}')


def wordpress(path):
    """Every row of a WordPress listing, page by page."""
    out, page = [], 1
    while True:
        sep = '&' if '?' in path else '?'
        req = urllib.request.Request(f'{WP}{path}{sep}per_page=100&page={page}',
                                     headers={'User-Agent': 'modiin4u-import'})
        with urllib.request.urlopen(req, timeout=60) as r:
            out += json.load(r)
            if page >= int(r.headers.get('X-WP-TotalPages', '1')):
                return out
        page += 1


def plain(markup):
    s = re.sub(r'<[^>]+>', ' ', markup or '')
    return re.sub(r'\s+', ' ', html.unescape(s)).strip()


def undo():
    reg = json.load(open(REGISTRY, encoding='utf-8'))
    # The SEO map as it was, so its addresses redirect again.
    if reg.get('url_map'):
        with open(URL_MAP, 'w', encoding='utf-8-sig', newline='') as f:
            f.write(reg['url_map'])
        print('url_map.csv restored — run: python3 tool/build_seo_pages.py --write-redirects')
    else:
        print('url_map.csv: this registry predates its backup — restore it from git '
              '(git log -- tool/seo/url_map.csv, the commit before the import)')
    for link in reg['links']:
        db('DELETE', 'entity_categories?entity_type=eq.business'
                     f'&entity_id=eq.{link["entity_id"]}&category_id=eq.{link["category_id"]}')
    for cid in reg['categories']:
        db('DELETE', f'categories?id=eq.{cid}')
    print(f'removed {len(reg["links"])} links and {len(reg["categories"])} categories')
    os.remove(REGISTRY)


def main():
    if '--undo' in sys.argv:
        return undo()
    apply = '--apply' in sys.argv
    if apply and os.path.exists(REGISTRY):
        raise SystemExit('already applied: run --undo first')
    # The four lists are written with in_menus off, which 00047 adds.
    db('GET', 'categories?select=in_menus&limit=1')

    terms = [t for t in wordpress('business-cat?_fields=id,slug,name,description,count,yoast_head_json')
             if t['count'] > 0]
    posts = wordpress('business?_fields=id,slug,business-cat')
    mapped = {r['old_path']: r for r in csv.DictReader(open(URL_MAP, encoding='utf-8-sig'))
              if r['kind'] == 'business-cat'}

    cats = db('GET', 'categories?scope=eq.business&select=id,slug,name,parent_id,sort_order')
    by_slug = {c['slug']: c for c in cats}
    by_id = {c['id']: c for c in cats}
    ours = {b['slug']: b['id'] for b in db('GET', 'businesses?select=id,slug&limit=5000')}
    links = db('GET', 'entity_categories?entity_type=eq.business&select=entity_id,category_id&limit=10000')
    linked = {(l['entity_id'], l['category_id']) for l in links}
    next_order = max([c['sort_order'] or 0 for c in cats] + [0]) + 1

    new_categories, new_links, url_updates = [], [], []
    for t in sorted(terms, key=lambda t: -t['count']):
        slug = urllib.parse.unquote(t['slug'])
        old_path = f'/business-cat/{slug}/'
        row = mapped.get(old_path)
        if row is None:
            raise SystemExit(f'not in the SEO map: {old_path}')
        members = [ours[urllib.parse.unquote(p['slug'])] for p in posts
                   if t['id'] in (p.get('business-cat') or [])]

        if row['how'] == 'redirect to its slug':
            # Already a category of ours, under its English slug.
            category_id, label = row['id'], f'existing  {row["name"]} ({by_id[row["id"]]["slug"]})'
        else:
            if slug in by_slug:
                raise SystemExit(f'slug already taken: {slug}')
            if t['slug'] in LANDING:
                parent = None
            else:
                target = by_slug[row['new_path'].strip('/').split('/')[-1]]
                parent = target['parent_id'] or target['id']
            yoast = t.get('yoast_head_json') or {}
            category = {
                'scope': 'business', 'slug': slug, 'name': html.unescape(t['name']),
                'parent_id': parent, 'description': plain(t.get('description')) or None,
                'meta_title': yoast.get('title'), 'meta_description': yoast.get('description'),
                'sort_order': next_order, 'is_active': True,
                'in_menus': t['slug'] not in LANDING,
            }
            next_order += 1
            new_categories.append((category, members, old_path))
            label = f'new       {category["name"]}  under ' + (
                by_id[parent]['name'] if parent else '(top level, out of the menus)')
            category_id = None
        if category_id:
            for b in members:
                if (b, category_id) not in linked:
                    new_links.append({'entity_type': 'business', 'entity_id': b,
                                      'category_id': category_id, 'is_primary': False})
        print(f'{label}  · {len(members)} businesses')

    print(f'\n{len(new_categories)} categories to add; '
          f'{sum(len(m) for _, m, _ in new_categories) + len(new_links)} business links to add')
    if not apply:
        print('dry run: pass --apply to write')
        return

    registry = {'categories': [], 'links': [],
                'url_map': open(URL_MAP, encoding='utf-8-sig').read()}
    try:
        for category, members, old_path in new_categories:
            made = db('POST', 'categories', category, prefer='return=representation')[0]
            registry['categories'].append(made['id'])
            url_updates.append((old_path, made['id'], made['name']))
            for b in members:
                new_links.append({'entity_type': 'business', 'entity_id': b,
                                  'category_id': made['id'], 'is_primary': False})
        for i in range(0, len(new_links), 200):
            chunk = new_links[i:i + 200]
            db('POST', 'entity_categories', chunk, prefer='resolution=ignore-duplicates')
            registry['links'] += [{'entity_id': l['entity_id'], 'category_id': l['category_id']}
                                  for l in chunk]
    finally:
        json.dump(registry, open(REGISTRY, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)

    # The SEO map: each address is now its own page, so it is no longer redirected.
    rows = list(csv.DictReader(open(URL_MAP, encoding='utf-8-sig')))
    done = {p: (cid, name) for p, cid, name in url_updates}
    for r in rows:
        if r['kind'] == 'business-cat' and r['old_path'] in done:
            r['table'], r['id'] = 'categories', done[r['old_path']][0]
            r['new_path'], r['how'] = r['old_path'], 'its own category again (5 Oct)'
    with open(URL_MAP, 'w', encoding='utf-8-sig', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    print(f'added {len(registry["categories"])} categories and {len(registry["links"])} links; '
          f'url_map.csv updated — now run: python3 tool/build_seo_pages.py --write-redirects')


main()
