#!/usr/bin/env python3
"""Brings the client's professionals across from WordPress, under Services.

The home page's "Find a Professional" row shows whoever is filed under the
Services category, with one filter pill per category beneath it. Services
had no categories beneath it, and what was filed there was a bank, money
changers and a laundry — so the row had no tradespeople and no pills.

The old site keeps tradespeople apart, as a `professionals` post type with a
`professionals-cat` taxonomy of trades. There are six, all real. This:

  1. creates a category under Services for each trade at least one of them
     practises, named as the old site names it (טכנאי מקררים, חשמלאי, …);
  2. adds each professional as a business — name, description, phone and
     photograph from the site's export (assets/data/wp_professionals.json,
     made by tool/parse_wxr.py; the REST API hides those fields), the trade
     and the slug from the live REST API — with the photograph copied into
     our `media` bucket, since the old site sends no CORS header;
  3. files each one under Services and under its trade.

One of the six, "לק ג׳ל במודיעין – sk nails", is already a business here
(modiin-lak-gel — same salon, same phone). It is not added twice: the
existing business is only filed under Services and its trade as well.

The old site gives no street address for any of them, so the address is the
city, as the business import did when an address was missing.

Everything it adds is recorded in tool/professionals_registry.json, and
--undo removes exactly that: the links, the businesses, the categories and
the photographs. Safe to run more than once.

    python3 tool/import_professionals.py              # what it would do (same as --dry-run)
    python3 tool/import_professionals.py --apply
    python3 tool/import_professionals.py --undo
"""

import hashlib
import html
import io
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXPORT = os.path.join(ROOT, 'assets', 'data', 'wp_professionals.json')
REGISTRY = os.path.join(ROOT, 'tool', 'professionals_registry.json')
WP = 'https://www.modiin4u.co.il/wp-json/wp/v2'
BUCKET = 'media'
FOLDER = 'businesses/professionals'

# Latin slugs, like the directory's own categories; the names are the old
# site's.
TRADE_SLUGS = {
    'טכנאי מקררים': 'fridge-technician',
    'חשמלאי': 'electrician',
    'לק ג׳ל': 'gel-nails',
    'עורך דין': 'lawyer',
    'הנדימן': 'handyman',
    'שיפוצניק': 'renovations',
    'בונה אתרים': 'web-design',
    'אינסטלטור': 'plumber',
    'חברת ניקיון': 'cleaning',
    'טכנאי דודים': 'boiler-technician',
    'טכנאי מזגנים': 'ac-technician',
    'טכנאי מחשבים': 'computer-technician',
    'מדביר': 'pest-control',
    'מעצב גרפי': 'graphic-design',
    'משרד פרסום': 'advertising',
    'ספר': 'barber',
}

# The WordPress post already here as a business, by the post's WordPress id.
ALREADY_HERE = {4142: 'modiin-lak-gel'}


def env():
    values = {}
    with open(os.path.join(ROOT, '.env.local'), encoding='utf-8') as f:
        for line in f:
            line = line.rstrip('\n')
            if line.strip() and not line.lstrip().startswith('#'):
                key, _, value = line.partition('=')
                values[key] = value
    return values


ENV = env()
URL = ENV['SUPABASE_URL'].rstrip('/')
KEY = ENV['SUPABASE_SERVICE_ROLE_KEY']


class HttpError(Exception):
    pass


def http(method, url, body=None, headers=None, raw=None):
    h = {'apikey': KEY, 'Authorization': f'Bearer {KEY}'}
    data = raw
    if raw is None and body is not None:
        data = json.dumps(body).encode()
        h['Content-Type'] = 'application/json'
    h.update(headers or {})
    req = urllib.request.Request(url, method=method, data=data, headers=h)
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            text = r.read().decode()
            return json.loads(text) if text.strip() else None
    except urllib.error.HTTPError as e:
        raise HttpError(f'{method} {url.replace(URL, "")} -> {e.code}: {e.read().decode()[:300]}')


def rest(method, path, body=None, prefer=None):
    return http(method, f'{URL}/rest/v1/{path}', body, {'Prefer': prefer} if prefer else None)


def q(v):
    return urllib.parse.quote(str(v), safe='')


def wp_get(path):
    req = urllib.request.Request(f'{WP}/{path}', headers={'User-Agent': 'modiin4u-app-import/1.0'})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read())


def clean_phone(p):
    """Bidi marks and spaces out; the digits and dashes as the site had them."""
    return re.sub(r'[‎‏‪-‮⁦-⁩\s]', '', p or '') or None


# ─── registry ───

def load_registry():
    if os.path.exists(REGISTRY):
        with open(REGISTRY, encoding='utf-8') as f:
            reg = json.load(f)
    else:
        reg = {}
    reg.setdefault('note', 'Written by tool/import_professionals.py. What it added; --undo reads this file.')
    reg.setdefault('categories', {})
    reg.setdefault('businesses', {})
    reg.setdefault('links', [])
    reg.setdefault('storage', [])
    return reg


def save_registry(reg):
    tmp = REGISTRY + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(reg, f, ensure_ascii=False, indent=1)
    os.replace(tmp, REGISTRY)


# ─── photographs ───

def rehost(src, reg):
    parts = urllib.parse.urlsplit(src)
    path_q = urllib.parse.quote(urllib.parse.unquote(parts.path), safe='/')
    req = urllib.request.Request(urllib.parse.urlunsplit(parts._replace(path=path_q)),
                                 headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=90) as r:
        data = r.read()
    from PIL import Image
    im = Image.open(io.BytesIO(data))
    im.load()
    if max(im.size) > 1200:
        im.thumbnail((1200, 1200), Image.LANCZOS)
    out = io.BytesIO()
    if im.mode in ('RGBA', 'LA') or (im.mode == 'P' and 'transparency' in im.info):
        im.convert('RGBA').save(out, 'PNG', optimize=True)
        ext, mime = 'png', 'image/png'
    else:
        im.convert('RGB').save(out, 'JPEG', quality=85, optimize=True, progressive=True)
        ext, mime = 'jpg', 'image/jpeg'
    path = f'{FOLDER}/{hashlib.sha1(src.encode()).hexdigest()[:16]}.{ext}'
    http('POST', f'{URL}/storage/v1/object/{BUCKET}/{path}', raw=out.getvalue(),
         headers={'Content-Type': mime, 'x-upsert': 'true'})
    if path not in reg['storage']:
        reg['storage'].append(path)
        save_registry(reg)
    return f'{URL}/storage/v1/object/public/{BUCKET}/{path}'


# ─── run ───

def gather():
    posts = wp_get('professionals?per_page=100')
    trades = {t['id']: html.unescape(t['name']) for t in wp_get('professionals-cat?per_page=100')}
    export = {p['id']: p for p in json.load(open(EXPORT, encoding='utf-8'))}
    people = []
    for p in posts:
        if p.get('status') != 'publish':
            continue
        x = export.get(p['id'])
        if not x:
            print(f'  {p["id"]} is not in the export — skipped')
            continue
        people.append({
            'wp_id': p['id'],
            'slug': urllib.parse.unquote(p['slug']),
            'name': html.unescape(x['title']).replace(' - ', ' – '),
            'description': x.get('description') or None,
            'phone': clean_phone(x.get('phone')),
            'image': x.get('image') or None,
            'link': p['link'],
            'trades': [trades[t] for t in p.get('professionals-cat', []) if t in trades],
        })
    return people


def apply_or_plan(apply):
    reg = load_registry()
    people = gather()
    services = rest('GET', "categories?scope=eq.business&slug=eq.services&parent_id=is.null&select=id")
    if not services:
        raise SystemExit('No Services category (slug `services`) — nothing to file them under.')
    services = services[0]['id']
    needed = sorted({t for p in people for t in p['trades']}, key=lambda t: list(TRADE_SLUGS).index(t))

    print(f'{len(people)} professionals on the old site; trades with someone in them: {", ".join(needed)}')
    for p in people:
        where = f'already here as {ALREADY_HERE[p["wp_id"]]}' if p['wp_id'] in ALREADY_HERE else 'new business'
        print(f'  {p["name"]} — {", ".join(p["trades"])} — {p["phone"]} — {where}')
    if not apply:
        print('Dry run — nothing written. Re-run with --apply.')
        return

    # 1. The trades, under Services.
    cat_ids = {}
    for order, name in enumerate(needed, 1):
        slug = TRADE_SLUGS[name]
        payload = {'scope': 'business', 'parent_id': services, 'name': name, 'slug': slug,
                   'sort_order': order, 'is_active': True}
        known = reg['categories'].get(slug)
        found = rest('GET', f'categories?scope=eq.business&slug=eq.{q(slug)}&select=id,parent_id')
        if found and not known and found[0]['parent_id'] != services:
            raise SystemExit(f'category slug {slug!r} is taken by something else — stopping')
        if found:
            cat_ids[name] = found[0]['id']
            rest('PATCH', f'categories?id=eq.{found[0]["id"]}', payload, prefer='return=minimal')
        else:
            cat_ids[name] = rest('POST', 'categories', payload, prefer='return=representation')[0]['id']
        reg['categories'][slug] = cat_ids[name]
        save_registry(reg)

    # 2. The people, as businesses.
    for p in people:
        if p['wp_id'] in ALREADY_HERE:
            row = rest('GET', f'businesses?slug=eq.{q(ALREADY_HERE[p["wp_id"]])}&select=id')
            if not row:
                raise SystemExit(f'expected business {ALREADY_HERE[p["wp_id"]]} is missing')
            bid = row[0]['id']
        else:
            photo = rehost(p['image'], reg) if p['image'] else None
            payload = {
                'name': p['name'],
                'slug': p['slug'],
                'short_description': p['description'],
                'full_description': p['description'],
                'phone': p['phone'],
                'whatsapp': p['phone'],
                'address': 'מודיעין',
                'logo_url': photo,
                'cover_url': photo,
                'status': 'active',
                # Imported, not newly published: no push notification (00045).
                'notify_on_publish': False,
                'is_verified': True,
                'canonical_url': p['link'],
            }
            bid = reg['businesses'].get(p['slug'])
            if bid and not rest('GET', f'businesses?id=eq.{bid}&select=id'):
                bid = None
            if not bid:
                clash = rest('GET', f'businesses?slug=eq.{q(p["slug"])}&select=id')
                if clash:
                    raise SystemExit(f'a business already has the slug {p["slug"]!r} — stopping')
                bid = rest('POST', 'businesses', payload, prefer='return=representation')[0]['id']
            else:
                rest('PATCH', f'businesses?id=eq.{bid}', payload, prefer='return=minimal')
            reg['businesses'][p['slug']] = bid
            save_registry(reg)

        # 3. Filed under Services and under each trade.
        for i, cat in enumerate([services] + [cat_ids[t] for t in p['trades']]):
            link = ['business', bid, cat]
            exists = rest('GET', f'entity_categories?entity_type=eq.business&entity_id=eq.{bid}'
                                 f'&category_id=eq.{cat}&select=entity_id')
            if exists:
                continue
            rest('POST', 'entity_categories',
                 {'entity_type': 'business', 'entity_id': bid, 'category_id': cat, 'is_primary': False},
                 prefer='return=minimal')
            if link not in reg['links']:
                reg['links'].append(link)
                save_registry(reg)

    print(f'Done: {len(reg["categories"])} trades under Services, {len(reg["businesses"])} businesses added, '
          f'{len(reg["links"])} category links added, {len(reg["storage"])} photographs.')


def undo():
    reg = load_registry()
    for et, eid, cid in list(reg['links']):
        rest('DELETE', f'entity_categories?entity_type=eq.{et}&entity_id=eq.{eid}&category_id=eq.{cid}')
        reg['links'].remove([et, eid, cid])
        save_registry(reg)
    for slug, bid in list(reg['businesses'].items()):
        rest('DELETE', f'businesses?id=eq.{bid}')
        del reg['businesses'][slug]
        save_registry(reg)
    for slug, cid in list(reg['categories'].items()):
        # Anything someone filed under the trade since goes with it (the
        # link table cascades); the businesses themselves stay.
        rest('DELETE', f'categories?id=eq.{cid}')
        del reg['categories'][slug]
        save_registry(reg)
    if reg['storage']:
        http('DELETE', f'{URL}/storage/v1/object/{BUCKET}', {'prefixes': reg['storage']})
        reg['storage'] = []
    os.remove(REGISTRY)
    print('Professionals import removed.')


def main():
    args = set(sys.argv[1:])
    if '--undo' in args:
        undo()
    else:
        apply_or_plan('--apply' in args)


if __name__ == '__main__':
    main()
