#!/usr/bin/env python3
"""A real HTML page for every address Google should know, from the database.

The website is a Flutter app: it draws its text on a canvas, and every
address used to be the same empty index.html until the app loaded. A search
engine reading that sees no headline, no article and no business — and the
old WordPress site's search traffic is, in the client's words, "this site's
strongest income source". So after each build this writes, for each
address, the app's own index.html with that page's:

  <title> and description  the SEO title and description from the panel
                           (copied from Yoast by tool/seo_fill.py), else
                           the name with the old site's " - מודיעין בשבילך"
  canonical                the old site's address form, on www.modiin4u.co.il,
                           so nothing changes for Google when the domain moves
  Open Graph, JSON-LD      NewsArticle, LocalBusiness, WebSite — the site name
                           WordPress's Site Title, מודיעין בשבילך, as the
                           client chose, with Modiin4u as its alternate
                           (tool/seo/site.json)
  the text itself          headline, article, address, phone, links — in a
                           block hidden from the eye (the app draws the same
                           thing over it), present in the HTML for crawlers

The app then loads over it as before. Addresses written:

  /                                  /news/<slug>/        every published article
  /news/ /businesses/ /restaurants/  /business/<slug>/    every active business and park
  /events/ /deals/ /realestate/      /business-cat/<slug>/ every business category
  /municipal/ /parks/ /shabbat/      /new/<slug>/         every news category
  /community/

plus sitemap.xml and robots.txt. Everything else gets shell.html — the app
with noindex — through nginx's fallback (deploy/nginx/snippets).

Until launch the site is a copy of live content on other addresses, which
Google must not index next to the WordPress site: so by default every page
says noindex and robots.txt disallows everything. With --live, both open.
With --write-redirects it also writes deploy/nginx/seo-redirects.conf from
tool/seo/url_map.csv: a 301 for each old address that moved.

    python3 tool/build_seo_pages.py                 # into build/web, noindex
    python3 tool/build_seo_pages.py --live          # at launch
    python3 tool/build_seo_pages.py --write-redirects

Reads only public content, with the app's public key (lib/core/supabase/
supabase_config.dart), or SUPABASE_URL and SUPABASE_ANON_KEY if set — so it
can run on the server to refresh the pages as content changes.
"""
import argparse
import csv
import html
import json
import os
import re
import sys
import urllib.parse
import urllib.request
from datetime import datetime, timezone

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MARK = '<meta name="generator" content="modiin4u-seo">'
CITY = 'מודיעין-מכבים-רעות'

SITE = json.load(open(os.path.join(ROOT, 'tool', 'seo', 'site.json'), encoding='utf-8')) \
    if os.path.exists(os.path.join(ROOT, 'tool', 'seo', 'site.json')) else {}
SUFFIX = SITE.get('title_suffix', ' - מודיעין בשבילך')

# The sections a visitor reaches from the navbar, with the app's own Hebrew
# names for them. Titles and descriptions from site.json where the old site
# had a page for the same thing; otherwise the name, and no description
# (Google writes its own snippet rather than read one made up here).
SECTIONS = [
    ('/news/', 'חדשות'), ('/businesses/', 'עסקים'), ('/restaurants/', 'מסעדות'),
    ('/events/', 'אירועים'), ('/deals/', 'מבצעים'), ('/realestate/', 'נדל״ן'),
    ('/municipal/', 'עירייה'), ('/parks/', 'פארקים'), ('/shabbat/', 'שבת וחגים'),
    ('/community/', 'קהילה'),
]


def config():
    url = os.environ.get('SUPABASE_URL')
    key = os.environ.get('SUPABASE_ANON_KEY')
    if not (url and key):
        src = open(os.path.join(ROOT, 'lib', 'core', 'supabase', 'supabase_config.dart'),
                   encoding='utf-8').read().replace('\n', '')
        url = url or re.search(r"supabaseUrl\s*=\s*'([^']+)'", src).group(1)
        key = key or re.search(r"anonKey\s*=\s*'([^']+)'", src).group(1)
    return url.rstrip('/'), key


URL, KEY = config()


def db(path):
    rows, start = [], 0
    while True:
        req = urllib.request.Request(
            f'{URL}/rest/v1/{path}',
            headers={'apikey': KEY, 'Authorization': 'Bearer ' + KEY,
                     'Range': f'{start}-{start + 999}'})
        with urllib.request.urlopen(req, timeout=90) as r:
            page = json.loads(r.read())
        rows += page
        if len(page) < 1000:
            return rows
        start += 1000


def esc(s):
    return html.escape(s or '', quote=True)


def plain(s, limit=None):
    """Text from stored HTML, whitespace folded."""
    t = html.unescape(re.sub(r'<[^>]+>', ' ', s or ''))
    t = re.sub(r'\s+', ' ', t).strip()
    if limit and len(t) > limit:
        t = t[:limit].rsplit(' ', 1)[0] + '…'
    return t


def safe_body(s):
    """An article's HTML without what a hidden block must not run or load."""
    s = re.sub(r'(?is)<(script|style|iframe|noscript|form)\b.*?</\1>', '', s or '')
    s = re.sub(r'(?i)\son\w+="[^"]*"', '', s)
    return s


def link_path(*parts):
    """`/news/<slug>/`, percent-encoded as it goes into an href."""
    return '/' + '/'.join(urllib.parse.quote(p, safe='') for p in parts) + '/'


class Builder:
    def __init__(self, out, site, live):
        self.out, self.site, self.live = out, site.rstrip('/'), live
        self.urls = []      # (path, lastmod) for the sitemap
        self.skipped = []
        index = os.path.join(out, 'index.html')
        shell = os.path.join(out, 'shell.html')
        template = open(index, encoding='utf-8').read()
        if MARK in template:
            # A rerun over its own output: the pristine copy is the shell.
            template = open(shell, encoding='utf-8').read().replace(
                '<meta name="robots" content="noindex">', '')
        self.template = template
        self.write_shell()

    # ── the page ──

    def head_bits(self, title, description, path, image, jsonld, index):
        canonical = self.site + path
        robots = 'index, follow, max-image-preview:large' if (self.live and index) else 'noindex, nofollow'
        bits = [
            MARK,
            f'<link rel="canonical" href="{esc(canonical)}">',
            f'<meta name="robots" content="{robots}">',
            f'<meta property="og:locale" content="he_IL">',
            f'<meta property="og:site_name" content="{esc(SITE.get("og_site_name", "מודיעין בשבילך"))}">',
            f'<meta property="og:title" content="{esc(title)}">',
            f'<meta property="og:url" content="{esc(canonical)}">',
            '<meta property="og:type" content="website">',
            '<meta name="twitter:card" content="summary_large_image">',
        ]
        if description:
            bits.append(f'<meta property="og:description" content="{esc(description)}">')
        if image:
            bits.append(f'<meta property="og:image" content="{esc(image)}">')
        for block in jsonld:
            data = json.dumps(block, ensure_ascii=False).replace('</', '<\\/')
            bits.append(f'<script type="application/ld+json">{data}</script>')
        return '\n  '.join(bits)

    def page(self, path, title, description, body, image=None, jsonld=(), index=True, lastmod=None):
        rel = urllib.parse.unquote(path).strip('/')
        target_dir = os.path.join(self.out, rel) if rel else self.out
        if any(len(part.encode()) > 240 for part in rel.split('/')):
            self.skipped.append(path)
            return
        doc = self.template
        doc = re.sub(r'<html[^>]*>', '<html lang="he" dir="rtl">', doc, count=1)
        doc = re.sub(r'<title>.*?</title>', f'<title>{esc(title)}</title>', doc, count=1, flags=re.S)
        doc = re.sub(r'<meta name="description"[^>]*>',
                     f'<meta name="description" content="{esc(description)}">' if description else '',
                     doc, count=1)
        doc = doc.replace('<meta charset="UTF-8">',
                          '<meta charset="UTF-8">\n  ' + self.head_bits(title, description, path, image, jsonld, index), 1)
        block = (
            '<style>.seo{position:absolute;width:1px;height:1px;margin:-1px;'
            'overflow:hidden;clip:rect(0 0 0 0);clip-path:inset(50%);border:0}</style>\n'
            f'<main class="seo">\n{self.nav()}\n{body}\n</main>\n'
        )
        doc = doc.replace('<script src="flutter_bootstrap.js"', block + '  <script src="flutter_bootstrap.js"', 1)
        os.makedirs(target_dir, exist_ok=True)
        with open(os.path.join(target_dir, 'index.html'), 'w', encoding='utf-8') as f:
            f.write(doc)
        if index:
            self.urls.append((path, lastmod))

    def nav(self):
        links = ''.join(f'<li><a href="{p}">{esc(n)}</a></li>' for p, n in SECTIONS)
        return f'<nav><a href="/">{esc(SITE.get("og_site_name", "מודיעין בשבילך"))}</a><ul>{links}</ul></nav>'

    def write_shell(self):
        doc = self.template.replace('<meta charset="UTF-8">',
                                    '<meta charset="UTF-8">\n  <meta name="robots" content="noindex">', 1)
        with open(os.path.join(self.out, 'shell.html'), 'w', encoding='utf-8') as f:
            f.write(doc)

    # ── structured data ──

    def org(self):
        return {'@type': 'Organization', 'name': SITE.get('site_name', 'מודיעין בשבילך'),
                'alternateName': SITE.get('alternate_name', 'Modiin4u'),
                'url': self.site + '/', 'logo': self.site + '/icons/Icon-512.png'}

    def breadcrumb(self, *items):
        return {'@context': 'https://schema.org', '@type': 'BreadcrumbList', 'itemListElement': [
            {'@type': 'ListItem', 'position': i + 1, 'name': n, 'item': self.site + p}
            for i, (n, p) in enumerate(items)]}

    # ── sitemap, robots ──

    def write_sitemap(self):
        rows = []
        for path, lastmod in self.urls:
            lm = f'<lastmod>{lastmod[:10]}</lastmod>' if lastmod else ''
            rows.append(f'<url><loc>{esc(self.site + path)}</loc>{lm}</url>')
        with open(os.path.join(self.out, 'sitemap.xml'), 'w', encoding='utf-8') as f:
            f.write('<?xml version="1.0" encoding="UTF-8"?>\n'
                    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
                    + '\n'.join(rows) + '\n</urlset>\n')
        with open(os.path.join(self.out, 'robots.txt'), 'w', encoding='utf-8') as f:
            if self.live:
                f.write('User-agent: *\nAllow: /\n'
                        'Disallow: /admin\nDisallow: /login\nDisallow: /join/\n'
                        'Disallow: /search\nDisallow: /steps\n'
                        f'\nSitemap: {self.site}/sitemap.xml\n')
            else:
                f.write('# Not launched yet: this copy of the site must not be indexed\n'
                        '# beside the live one. tool/build_seo_pages.py --live opens it.\n'
                        'User-agent: *\nDisallow: /\n')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=os.path.join(ROOT, 'build', 'web'))
    ap.add_argument('--site', default='https://www.modiin4u.co.il')
    ap.add_argument('--live', action='store_true')
    ap.add_argument('--write-redirects', action='store_true')
    a = ap.parse_args()

    if a.write_redirects:
        write_redirects()
        if not os.path.exists(os.path.join(a.out, 'index.html')):
            return

    b = Builder(a.out, a.site, a.live)
    site_name = SITE.get('og_site_name', 'מודיעין בשבילך')

    articles = db('articles?select=id,slug,title,subtitle,excerpt,body,featured_image,og_image,'
                  'seo_title,meta_description,published_at,updated_at,noindex'
                  '&status=eq.published&order=published_at.desc.nullslast')
    businesses = db('businesses?select=id,slug,name,kind,short_description,full_description,'
                    'address,phone,website,cover_url,og_image_url,meta_title,meta_description,'
                    'latitude,longitude,rating,review_count,noindex,updated_at'
                    '&status=eq.active&order=name')
    categories = db('categories?select=id,slug,name,scope,parent_id,meta_title,meta_description,'
                    'description,is_active,updated_at&is_active=eq.true&order=sort_order')
    links = db('entity_categories?select=entity_type,entity_id,category_id')

    cats_of = {}
    members = {}
    for l in links:
        cats_of.setdefault((l['entity_type'], l['entity_id']), []).append(l['category_id'])
        members.setdefault(l['category_id'], []).append(l['entity_id'])
    cat_by_id = {c['id']: c for c in categories}
    art_by_id = {r['id']: r for r in articles if r.get('slug')}
    biz_by_id = {r['id']: r for r in businesses if r.get('slug')}

    def art_href(r): return link_path('news', r['slug'])
    def biz_href(r): return link_path('business', r['slug'])
    def cat_href(c): return link_path('business-cat' if c['scope'] == 'business' else 'new', c['slug'])

    def art_list(rows, n=None):
        rows = rows[:n] if n else rows
        return '<ul>' + ''.join(f'<li><a href="{art_href(r)}">{esc(r["title"])}</a></li>' for r in rows) + '</ul>'

    def biz_list(rows):
        return '<ul>' + ''.join(
            f'<li><a href="{biz_href(r)}">{esc(r["name"])}</a>'
            + (f' — {esc(r["address"])}' if r.get('address') else '') + '</li>' for r in rows) + '</ul>'

    def cat_list(scope):
        return '<ul>' + ''.join(f'<li><a href="{cat_href(c)}">{esc(c["name"])}</a></li>'
                                for c in categories if c['scope'] == scope and c.get('slug')) + '</ul>'

    restaurant_ids = {c['id'] for c in categories if c['slug'] in ('restaurants', 'cafe-bakery')}
    restaurant_ids |= {c['id'] for c in categories if c.get('parent_id') in restaurant_ids}
    restaurants = [r for r in businesses if r['kind'] != 'park'
                   and set(cats_of.get(('business', r['id']), [])) & restaurant_ids]
    parks = [r for r in businesses if r['kind'] == 'park']
    shops = [r for r in businesses if r['kind'] != 'park']

    # ── home ──
    home = SITE.get('home', {})
    b.page('/', home.get('title') or site_name, home.get('description', ''),
           f'<h1>{esc(home.get("title") or site_name)}</h1>'
           f'<h2>חדשות</h2>{art_list(articles, 20)}'
           f'<h2>עסקים</h2>{cat_list("business")}'
           f'<h2>מסעדות</h2>{biz_list(restaurants[:30])}',
           jsonld=[{'@context': 'https://schema.org', '@type': 'WebSite',
                    'name': SITE.get('site_name', 'מודיעין בשבילך'),
                    'alternateName': SITE.get('alternate_name', 'Modiin4u'),
                    'url': a.site.rstrip('/') + '/'},
                   dict({'@context': 'https://schema.org'}, **b.org())])

    # ── sections ──
    section_body = {
        '/news/': f'{art_list(articles, 100)}<h2>קטגוריות</h2>{cat_list("article")}',
        '/businesses/': f'{cat_list("business")}{biz_list(shops)}',
        '/restaurants/': biz_list(restaurants),
        '/parks/': biz_list(parks),
    }
    for path, name in SECTIONS:
        meta = SITE.get('sections', {}).get(path, {})
        title = meta.get('title') or name + SUFFIX
        b.page(path, title, meta.get('description', ''),
               f'<h1>{esc(name)}</h1>{section_body.get(path, "")}',
               jsonld=[b.breadcrumb((site_name, '/'), (name, path))])

    # ── articles ──
    for r in articles:
        if not r.get('slug'):
            continue
        path = art_href(r)
        title = r.get('seo_title') or r['title'] + SUFFIX
        desc = r.get('meta_description') or plain(r.get('excerpt') or r.get('body'), 160)
        image = r.get('og_image') or r.get('featured_image')
        cats = [cat_by_id[c] for c in cats_of.get(('article', r['id']), []) if c in cat_by_id]
        date = (r.get('published_at') or '')[:10]
        body = (f'<article><h1>{esc(r["title"])}</h1>'
                + (f'<p>{esc(r["subtitle"])}</p>' if r.get('subtitle') else '')
                + (f'<time datetime="{date}">{date}</time>' if date else '')
                + safe_body(r.get('body'))
                + ''.join(f'<a href="{cat_href(c)}">{esc(c["name"])}</a> ' for c in cats if c.get('slug'))
                + '</article>')
        ld = {'@context': 'https://schema.org', '@type': 'NewsArticle', 'headline': r['title'][:110],
              'mainEntityOfPage': a.site.rstrip('/') + path, 'publisher': b.org()}
        if r.get('published_at'):
            ld['datePublished'] = r['published_at']
        if r.get('updated_at'):
            ld['dateModified'] = r['updated_at']
        if image:
            ld['image'] = [image]
        b.page(path, title, desc, body, image=image, index=not r.get('noindex'),
               lastmod=r.get('updated_at') or r.get('published_at'),
               jsonld=[ld, b.breadcrumb((site_name, '/'), ('חדשות', '/news/'), (r['title'], path))])

    # ── businesses and parks ──
    for r in businesses:
        if not r.get('slug'):
            continue
        path = biz_href(r)
        title = r.get('meta_title') or r['name'] + SUFFIX
        desc = r.get('meta_description') or plain(r.get('short_description') or r.get('full_description'), 160)
        image = r.get('og_image_url') or r.get('cover_url')
        cats = [cat_by_id[c] for c in cats_of.get(('business', r['id']), []) if c in cat_by_id]
        body = (f'<article><h1>{esc(r["name"])}</h1>'
                + (f'<p>{esc(r["short_description"])}</p>' if r.get('short_description') else '')
                + (f'<p>{esc(r["address"])}</p>' if r.get('address') else '')
                + (f'<p><a href="tel:{esc(r["phone"])}">{esc(r["phone"])}</a></p>' if r.get('phone') else '')
                + (f'<div>{safe_body(r["full_description"])}</div>' if r.get('full_description') else '')
                + ''.join(f'<a href="{cat_href(c)}">{esc(c["name"])}</a> ' for c in cats if c.get('slug'))
                + '</article>')
        ld = {'@context': 'https://schema.org',
              '@type': 'Park' if r['kind'] == 'park' else 'LocalBusiness',
              'name': r['name'], 'url': a.site.rstrip('/') + path}
        if r.get('address'):
            ld['address'] = {'@type': 'PostalAddress', 'streetAddress': r['address'],
                             'addressLocality': CITY, 'addressCountry': 'IL'}
        if r.get('phone') and r['kind'] != 'park':
            ld['telephone'] = r['phone']
        if r.get('latitude') and r.get('longitude'):
            ld['geo'] = {'@type': 'GeoCoordinates', 'latitude': r['latitude'], 'longitude': r['longitude']}
        if image:
            ld['image'] = image
        if (r.get('review_count') or 0) > 0 and r.get('rating'):
            ld['aggregateRating'] = {'@type': 'AggregateRating', 'ratingValue': r['rating'],
                                     'reviewCount': r['review_count']}
        section = ('פארקים', '/parks/') if r['kind'] == 'park' else ('עסקים', '/businesses/')
        b.page(path, title, desc, body, image=image, index=not r.get('noindex'),
               lastmod=r.get('updated_at'),
               jsonld=[ld, b.breadcrumb((site_name, '/'), section, (r['name'], path))])

    # ── categories ──
    for c in categories:
        if not c.get('slug') or c['scope'] not in ('business', 'article'):
            continue
        path = cat_href(c)
        title = c.get('meta_title') or c['name'] + SUFFIX
        desc = c.get('meta_description') or plain(c.get('description'), 160)
        ids = members.get(c['id'], [])
        # A category's page lists its subcategories' rows too, as the app does.
        for child in categories:
            if child.get('parent_id') == c['id']:
                ids += members.get(child['id'], [])
        if c['scope'] == 'business':
            rows = sorted({i: biz_by_id[i] for i in ids if i in biz_by_id}.values(), key=lambda r: r['name'])
            listing, parent = biz_list(rows), ('עסקים', '/businesses/')
        else:
            rows = [art_by_id[i] for i in dict.fromkeys(ids) if i in art_by_id]
            rows.sort(key=lambda r: r.get('published_at') or '', reverse=True)
            listing, parent = art_list(rows, 100), ('חדשות', '/news/')
        b.page(path, title, desc, f'<h1>{esc(c["name"])}</h1>{listing}', lastmod=c.get('updated_at'),
               jsonld=[b.breadcrumb((site_name, '/'), parent, (c['name'], path))])

    b.write_sitemap()
    print(f'{len(b.urls)} pages written into {a.out} ({"live" if a.live else "noindex until launch"});'
          f' sitemap.xml, robots.txt, shell.html')
    if b.skipped:
        print('skipped (path too long for a file name):', len(b.skipped))


def write_redirects():
    """deploy/nginx/seo-redirects.conf: a 301 for each old address that moved."""
    rows = list(csv.DictReader(open(os.path.join(ROOT, 'tool', 'seo', 'url_map.csv'), encoding='utf-8-sig')))
    lines = [
        '# Old WordPress addresses that moved, each to its new page — written by',
        '# tool/build_seo_pages.py --write-redirects from tool/seo/url_map.csv.',
        '# Addresses that kept their path (every article and business) are not',
        '# here: the new site serves them as they were. Installed next to',
        '# modiin4u-site.conf, which includes it.',
        '',
    ]
    seen = set()
    for r in rows:
        old = r['old_path']
        new = r['new_path'].rstrip('/') + '/'
        if new == old or old in seen:
            continue
        seen.add(old)
        target = urllib.parse.quote(new, safe='/-')
        for variant in {old, old.rstrip('/') or '/'}:
            if variant == '/':
                continue
            quoted = variant.replace('\\', '\\\\').replace('"', '\\"')
            lines.append(f'location = "{quoted}" {{ return 301 {target}; }}')
    path = os.path.join(ROOT, 'deploy', 'nginx', 'seo-redirects.conf')
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')
    print('redirects:', len(seen), 'addresses →', os.path.relpath(path, ROOT))


main()
