#!/usr/bin/env python3
"""Every WordPress page against the new site, as a search engine reads them.

Reads tool/seo/wp_pages.json (tool/snapshot_wp_seo.py) and asks the new site
for each old address, the way Googlebot would, without following redirects:

  answers    200 at the same address — or, where WordPress redirects the
             address, the same 301 to the same page
  canonical  points at the same address on www.modiin4u.co.il
  title      the same <title>
  desc       the same meta description
  h1         the same first H1
  menu       carries every link of the old header menu

Before launch the new site says noindex everywhere; that is not counted.
Prints a table and every difference, and exits 1 if there are any.

    python3 tool/check_seo_parity.py                         # the server by IP
    python3 tool/check_seo_parity.py https://www.modiin4u.co.il   # after the move
"""
import concurrent.futures as cf
import html
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CANON = 'https://www.modiin4u.co.il'
UA = {'User-Agent': 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'}


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *a, **k):
        return None


OPENER = urllib.request.build_opener(NoRedirect)


def norm(s):
    s = html.unescape(s or '')
    for a, b in (('״', '"'), ('”', '"'), ('“', '"'), ('׳', "'"), ('’', "'"), ('–', '-'), ('—', '-')):
        s = s.replace(a, b)
    return ' '.join(s.split()).strip()


def text(s):
    return norm(re.sub(r'<[^>]+>', ' ', s or ''))


def fetch(base, path):
    url = base + urllib.parse.quote(path, safe='/')
    try:
        r = OPENER.open(urllib.request.Request(url, headers=UA), timeout=40)
        return r.status, r.read().decode('utf-8', 'replace')
    except urllib.error.HTTPError as e:
        return e.code, ''
    except Exception as e:
        return str(e)[:40], ''


def check(base, path, wp, menu):
    if wp.get('redirect_to'):
        try:
            OPENER.open(urllib.request.Request(base + urllib.parse.quote(path, safe='/'), headers=UA), timeout=40)
            return {'answers': 'no redirect (WordPress redirects it)'}
        except urllib.error.HTTPError as e:
            loc = urllib.parse.unquote(urllib.parse.urlsplit(e.headers.get('Location') or '').path)
            ok = e.code == 301 and loc == wp['redirect_to']
            return {} if ok else {'answers': f'HTTP {e.code} → {loc}, WordPress → {wp["redirect_to"]}'}
    status, h = fetch(base, path)
    if status != 200:
        return {'answers': f'HTTP {status}'}
    head = h.split('</head>')[0]
    first = lambda pat, s=head: (re.search(pat, s, re.I) or [None, None])[1]
    diff = {}
    canon = first(r'<link rel="canonical" href="([^"]+)"')
    if urllib.parse.unquote(canon or '') != CANON + path:
        diff['canonical'] = urllib.parse.unquote(canon or '(none)')
    if norm(first(r'<title[^>]*>([\s\S]*?)</title>')) != norm(wp['title']):
        diff['title'] = (wp['title'], text(first(r'<title[^>]*>([\s\S]*?)</title>')))
    if wp.get('description') and norm(first(r'<meta name="description" content="([^"]*)"')) != norm(wp['description']):
        diff['desc'] = (wp['description'][:70], norm(first(r'<meta name="description" content="([^"]*)"'))[:70])
    h1 = text(first(r'<h1[^>]*>([\s\S]*?)</h1>', h))
    if wp.get('h1') and h1 != norm(wp['h1']):
        diff['h1'] = (wp['h1'], h1)
    links = {urllib.parse.unquote(x) for x in re.findall(r'<a href="([^"]+)"', h)}
    missing = [p for p in menu if p not in links]
    if missing:
        diff['menu'] = f'{len(missing)} of {len(menu)} menu links missing'
    return diff


def main():
    base = (sys.argv[1] if len(sys.argv) > 1 else 'http://45.93.94.49').rstrip('/')
    snap = json.load(open(os.path.join(ROOT, 'tool', 'seo', 'wp_pages.json'), encoding='utf-8'))
    pages, menu = snap['pages'], [p for p, _ in snap['menu']]
    with cf.ThreadPoolExecutor(8) as ex:
        results = dict(zip(pages, ex.map(lambda p: check(base, p, pages[p], menu), pages)))

    kinds = {}
    for p, d in results.items():
        k = p.strip('/').split('/')[0] or 'home'
        row = kinds.setdefault(k, {'pages': 0, **{f: 0 for f in ('answers', 'canonical', 'title', 'desc', 'h1', 'menu')}})
        row['pages'] += 1
        for f in d:
            row[f] += 1
    print(f'{base} against the WordPress snapshot of {snap["taken"]} — differences per field')
    print(f'{"":22}{"pages":>6}{"answers":>9}{"canon":>7}{"title":>7}{"desc":>6}{"h1":>5}{"menu":>6}')
    for k, r in sorted(kinds.items(), key=lambda x: -x[1]['pages']):
        print(f'{k[:22]:22}{r["pages"]:6}{r["answers"]:9}{r["canonical"]:7}{r["title"]:7}{r["desc"]:6}{r["h1"]:5}{r["menu"]:6}')
    bad = {p: d for p, d in results.items() if d}
    print(f'\n{len(pages) - len(bad)} of {len(pages)} pages the same; {len(bad)} differ')
    for p, d in list(bad.items())[:60]:
        print(' ', p, d)
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
