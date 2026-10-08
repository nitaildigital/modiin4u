#!/usr/bin/env python3
"""What Google reads on the WordPress site, page by page — kept for the move.

The client (8 Oct): when www.modiin4u.co.il moves to the new site, nothing
Google ranks may change — addresses, titles, headings, menus. This reads the
live WordPress site as a crawler does and writes tool/seo/wp_pages.json:

  pages   every address in WordPress's sitemaps and every address its menu
          links to, each with its <title>, meta description, robots and the
          first H1 — or, where WordPress redirects it, `redirect_to`
  menu    the header menu's links, in order, with their text — the internal
          links every WordPress page carries

tool/build_seo_pages.py reads it: the old addresses are served as they were
(no redirect), with WordPress's title, description and H1, and every page
carries the same menu links. tool/check_seo_parity.py compares the two sites
against it.

Run it again right before the move, once WordPress is frozen, so the last
edits there are in. It only reads public pages, a few at a time.

    python3 tool/snapshot_wp_seo.py
"""
import concurrent.futures as cf
import html
import json
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'tool', 'seo', 'wp_pages.json')
SITE = 'https://www.modiin4u.co.il'
UA = {'User-Agent': 'Mozilla/5.0 (compatible; modiin4u-migration; +https://www.modiin4u.co.il)'}


def get(url, final=None):
    for attempt in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
                if final is not None:
                    final.append(r.geturl())
                return r.read().decode('utf-8', 'replace')
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None
            time.sleep(3)
        except Exception:
            time.sleep(3)
    return None


def text(s):
    return ' '.join(html.unescape(re.sub(r'<[^>]+>', ' ', s or '')).split())


def path_of(url):
    """`/news/<slug>/`, decoded, with the trailing slash WordPress uses."""
    p = urllib.parse.unquote(urllib.parse.urlsplit(url).path) or '/'
    return p if p.endswith('/') else p + '/'


def read_page(url):
    final = []
    h = get(url, final)
    if h is None:
        return None
    # WordPress's own redirect rules: the address answers with another page.
    # Kept as a redirect to that page's address, not as a page here.
    if final and path_of(final[-1]) != path_of(url):
        return {'redirect_to': path_of(final[-1])}
    head = h.split('</head>')[0]
    first = lambda pat: (re.search(pat, head, re.I) or [None, None])[1]
    h1s = [text(x) for x in re.findall(r'<h1[^>]*>([\s\S]*?)</h1>', h, re.I)]
    return {
        'title': text(first(r'<title[^>]*>([\s\S]*?)</title>')),
        'description': html.unescape(first(r'<meta name="description" content="([^"]*)"') or ''),
        'robots': first(r'<meta name="robots" content="([^"]*)"') or '',
        'h1': next((x for x in h1s if x), ''),
    }


def main():
    home = get(SITE + '/')
    header = (re.search(r'<header[\s\S]*?</header>', home, re.I) or [''])[0]
    menu, seen = [], set()
    for href, label in re.findall(r'<a[^>]+href="([^"#]+)"[^>]*>([\s\S]*?)</a>', header, re.I):
        u = urllib.parse.urlsplit(html.unescape(href))
        if u.netloc not in ('', 'www.modiin4u.co.il', 'modiin4u.co.il'):
            continue
        p, t = path_of(href), text(label)
        if t and p not in seen:
            seen.add(p)
            menu.append([p, t])

    urls = {}
    for sm in re.findall(r'<loc>([^<]+)</loc>', get(SITE + '/sitemap_index.xml') or ''):
        for loc in re.findall(r'<loc>([^<]+)</loc>', get(sm) or ''):
            if not re.search(r'\.(jpe?g|png|webp|gif)$', loc, re.I):
                urls[path_of(loc)] = loc
    for p, _ in menu:
        urls.setdefault(p, SITE + urllib.parse.quote(p))

    pages = {}
    with cf.ThreadPoolExecutor(4) as ex:
        for p, page in zip(urls, ex.map(read_page, urls.values())):
            if page:
                pages[p] = page
    json.dump({'taken': time.strftime('%Y-%m-%d %H:%M'), 'menu': menu, 'pages': pages},
              open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(f'{len(pages)} pages, {len(menu)} menu links → {os.path.relpath(OUT, ROOT)}'
          + (f'; {len(urls) - len(pages)} did not answer' if len(urls) > len(pages) else ''))


if __name__ == '__main__':
    main()
