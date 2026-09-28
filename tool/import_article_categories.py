#!/usr/bin/env python3
"""Brings the news categories across from the WordPress site.

The article import carried the 669 articles and left their filing behind, so
`entity_categories` held business links only and not one article was in a
category. That is why the news page has no category headings and why the
"Modiin News" menu in the design could not be built: every entry would have
opened an empty list.

The categories were never missing — they are on the client's site, in a
taxonomy called `new`, and they are the nine the Figma menu shows:

    עדכוני עירייה 388   עירוני 189   עסקים 63   אנשים 27
    קולינריה 22   אטרקציות וטיולים במודיעין 18   ספורט וכושר 12
    נדל״ן 11   חדשות מודיעין 4

An article can sit in more than one, so the totals come to more than 669.

Existing rows are matched by name before anything is created, so running this
twice does not produce a second copy of a category, and a link that is already
there is left alone.

    python3 tool/import_article_categories.py            # dry run
    python3 tool/import_article_categories.py --apply
    python3 tool/import_article_categories.py --undo     # remove what it made
"""

import json
import os
import re
import sys
import urllib.parse
import urllib.request

WP = 'https://www.modiin4u.co.il/wp-json/wp/v2'
TAXONOMY = 'new'


def env(key):
    """Read one value from .env.local without disturbing the rest."""
    for line in open('.env.local', encoding='utf-8'):
        line = line.rstrip('\n')
        if line.strip() and not line.lstrip().startswith('#'):
            k, _, v = line.partition('=')
            if k == key:
                return v
    raise SystemExit(f'{key} is not in .env.local')


SUPABASE = env('SUPABASE_URL')
SERVICE_KEY = env('SUPABASE_SERVICE_ROLE_KEY')


def wp(path):
    req = urllib.request.Request(
        f'{WP}/{path}', headers={'User-Agent': 'modiin4u-app-import/1.0'}
    )
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.load(r), dict(r.headers)


def rest(path, method='GET', body=None, prefer=None):
    headers = {
        'apikey': SERVICE_KEY,
        'Authorization': f'Bearer {SERVICE_KEY}',
        'Content-Type': 'application/json',
    }
    if prefer:
        headers['Prefer'] = prefer
    req = urllib.request.Request(
        f'{SUPABASE}/rest/v1/{path}',
        data=json.dumps(body).encode() if body is not None else None,
        headers=headers,
        method=method,
    )
    with urllib.request.urlopen(req, timeout=90) as r:
        raw = r.read()
        return json.loads(raw) if raw else []


def slugify(name):
    """A slug the database will accept, from a Hebrew name."""
    s = re.sub(r'[^\w\s-]', '', name, flags=re.UNICODE).strip().lower()
    return re.sub(r'[\s_]+', '-', s)


def norm(name):
    """For comparing two names that mean the same thing.

    The site writes נדל״ן with a gershayim and the database has it with an
    ASCII quote, so an exact match makes a second copy of a category that is
    already there — and then fails on the slug, which does collide.
    """
    return re.sub(r'\s+', ' ', (name or '').replace('\u05f4', '"').replace('\u05f3', "'")).strip()


def fetch_terms():
    terms, _ = wp(f'{TAXONOMY}?per_page=100')
    return {t['id']: t for t in terms}


def fetch_article_terms():
    """{wordpress slug: [term ids]} for every article on the site."""
    out, page = {}, 1
    while True:
        rows, headers = wp(f'{TAXONOMY and "news"}?per_page=100&page={page}')
        if not rows:
            break
        for p in rows:
            out[p['slug']] = p.get(TAXONOMY) or []
        total_pages = int(headers.get('X-WP-TotalPages', 1))
        if page >= total_pages:
            break
        page += 1
    return out


def main():
    apply = '--apply' in sys.argv
    undo = '--undo' in sys.argv

    if undo:
        links = rest('entity_categories?entity_type=eq.article&select=id')
        print(f'removing {len(links)} article links')
        if apply or input('type yes to remove: ').strip() == 'yes':
            rest('entity_categories?entity_type=eq.article', method='DELETE')
            print('removed')
        return

    terms = fetch_terms()
    print(f'{len(terms)} categories on the site')

    # What the database already holds, so nothing is duplicated. Keyed by a
    # normalised name, because the two spellings of נדל״ן are the same word.
    rows = rest('categories?scope=eq.article&select=id,name,slug')
    existing = {norm(c['name']): c for c in rows}
    # Slugs are unique across the whole table, not per scope.
    taken = {c['slug'] for c in rest('categories?select=slug')}
    articles = {a['slug']: a['id'] for a in rest('articles?select=id,slug')}
    print(f'{len(existing)} article categories here, {len(articles)} articles')

    by_slug = fetch_article_terms()
    print(f'{len(by_slug)} articles on the site carry their filing')

    # ─── categories ───
    to_create, term_to_name = [], {}
    for tid, t in terms.items():
        name = t['name']
        term_to_name[tid] = norm(name)
        if norm(name) in existing:
            continue
        slug = slugify(t.get('slug') or name)
        if slug in taken:
            slug = f'{slug}-news'
        n = 2
        while slug in taken:
            slug, n = f'{slugify(t.get("slug") or name)}-{n}', n + 1
        taken.add(slug)
        to_create.append({
            'name': name,
            'slug': slug,
            'scope': 'article',
            'is_active': True,
            'sort_order': t.get('count', 0),
        })

    print(f'\ncategories to create: {len(to_create)}')
    for c in to_create:
        print(f"  {c['name']}  ({c['slug']})")

    if apply and to_create:
        made = rest('categories', 'POST', to_create, prefer='return=representation')
        for c in made:
            existing[norm(c['name'])] = c
        print(f'created {len(made)}')

    # ─── links ───
    have = {
        (l['entity_id'], l['category_id'])
        for l in rest('entity_categories?entity_type=eq.article&select=entity_id,category_id')
    }
    links, missing_cat = [], set()
    for slug, tids in by_slug.items():
        article_id = articles.get(slug)
        if not article_id:
            continue
        for tid in tids:
            name = term_to_name.get(tid)
            cat = existing.get(name)
            if not cat:
                missing_cat.add(name)
                continue
            key = (article_id, cat['id'])
            if key in have:
                continue
            have.add(key)
            links.append({
                'entity_type': 'article',
                'entity_id': article_id,
                'category_id': cat['id'],
            })

    # On a dry run the seven new categories do not exist yet, so their links
    # cannot be counted. Say what the real number will be rather than a
    # number that is only true of a run that does nothing.
    would = sum(len(t) for s2, t in by_slug.items() if s2 in articles)
    print(f'\nlinks to write: {len(links)}'
          + ('' if apply else f'  (after the categories exist: about {would})'))
    if missing_cat:
        print(f'  (no category row yet for: {", ".join(sorted(missing_cat))})')

    if not apply:
        print('\ndry run — nothing written. Re-run with --apply')
        return

    for i in range(0, len(links), 500):
        chunk = links[i:i + 500]
        rest('entity_categories', 'POST', chunk, prefer='return=minimal')
        print(f'  wrote {i + len(chunk)}/{len(links)}')
    print('done')


if __name__ == '__main__':
    os.chdir(os.path.dirname(os.path.abspath(__file__)) + '/..')
    main()
