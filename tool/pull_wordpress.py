#!/usr/bin/env python3
"""Pull content from the modiin4u.co.il WordPress site.

The site stores its content in JetEngine custom post types, not in plain
WP posts (/wp-json/wp/v2/posts is empty), so this walks the real types:

    news (659)   business (200)   professionals (6)
    apartments (4)                real-estate-agents (4)

ACF fields are not exposed over REST, so a business comes back with a
title, photo and categories but no phone or address. Getting those needs
`show_in_rest` on the ACF field groups, or the ACF to REST API plugin.

Writes one JSON file per type into wp/ next to this script. To refresh the
bundled snapshot the app reads, run this and then rebuild
assets/data/wp_news.json from the result.

Usage:  python3 tool/pull_wordpress.py
"""

import json, re, html, urllib.request, os

BASE = 'https://www.modiin4u.co.il/wp-json/wp/v2'
OUT = os.path.dirname(os.path.abspath(__file__)) + '/wp'

def get(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'modiin4u-app-import/1.0'})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)

def clean(s):
    if not s: return ''
    s = re.sub(r'<[^>]+>', '', s)
    s = html.unescape(s)
    return re.sub(r'\s+', ' ', s).strip()

def pull(kind, pages):
    items = []
    for page in range(1, pages + 1):
        url = '%s/%s?per_page=100&page=%d&_embed' % (BASE, kind, page)
        try:
            batch = get(url)
        except Exception as e:
            print('  page %d stopped: %s' % (page, e)); break
        if not batch: break
        for p in batch:
            emb = p.get('_embedded') or {}
            media = emb.get('wp:featuredmedia') or []
            img = media[0].get('source_url') if media and isinstance(media[0], dict) else None
            terms = []
            for grp in emb.get('wp:term') or []:
                for t in grp:
                    if isinstance(t, dict) and t.get('name'):
                        terms.append(t['name'])
            items.append({
                'id': p['id'],
                'title': clean(p.get('title', {}).get('rendered')),
                'excerpt': clean(p.get('excerpt', {}).get('rendered'))[:400],
                'date': p.get('date'),
                'link': p.get('link'),
                'image': img,
                'terms': terms,
            })
        print('  page %d -> %d items' % (page, len(batch)))
        if len(batch) < 100: break
    path = '%s/%s.json' % (OUT, kind)
    json.dump(items, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('%-20s %4d items -> %s' % (kind, len(items), path))
    return items

for kind, pages in [('news', 7), ('business', 2), ('professionals', 1),
                    ('apartments', 1), ('real-estate-agents', 1)]:
    print('=== %s ===' % kind)
    pull(kind, pages)
