#!/usr/bin/env python3
"""Turn a WordPress WXR export into the JSON the app bundles.

The REST API hides JetEngine's meta fields, so a business comes back from
/wp-json with nothing but a title and a photo. The WXR export (Tools →
Export → All content) carries every postmeta row instead, which is where
the phone, address, opening hours and coordinates actually live.

Usage:  python3 tool/parse_wxr.py ~/Downloads/WordPress.2026-09-16.xml
Writes: assets/data/wp_business.json, assets/data/wp_professionals.json
"""

import collections
import html
import json
import os
import re
import sys
import xml.etree.ElementTree as ET

NS = {
    'wp': 'http://wordpress.org/export/1.2/',
    'content': 'http://purl.org/rss/1.0/modules/content/',
    'excerpt': 'http://wordpress.org/export/1.2/excerpt/',
}

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'data')

# JetEngine stores a map field as <hash>_lat / <hash>_lng.
LATLNG = re.compile(r'^[0-9a-f]{32}_(lat|lng)$')


def text(s):
    """Strip tags and entities out of a WP content blob."""
    if not s:
        return ''
    s = re.sub(r'<(script|style)[^>]*>.*?</\1>', ' ', s, flags=re.S | re.I)
    s = re.sub(r'<[^>]+>', ' ', s)
    s = html.unescape(s)
    return re.sub(r'\s+', ' ', s).strip()


def clean_phone(v):
    """Strip the RTL/LTR marks WordPress stores around Hebrew-entered numbers."""
    return re.sub(r'[‎‏‪-‮\s]', '', v or '')


def parse(src):
    attachments = {}   # post id -> url
    items = collections.defaultdict(list)

    for _, el in ET.iterparse(src, events=('end',)):
        if el.tag != 'item':
            continue
        ptype = el.findtext('wp:post_type', '', NS)
        pid = el.findtext('wp:post_id', '', NS)

        if ptype == 'attachment':
            url = el.findtext('wp:attachment_url', '', NS)
            if pid and url:
                attachments[pid] = url
            el.clear()
            continue

        if ptype not in ('business', 'professionals') or el.findtext('wp:status', '', NS) != 'publish':
            el.clear()
            continue

        meta, lat, lng = {}, None, None
        for pm in el.findall('wp:postmeta', NS):
            k = pm.findtext('wp:meta_key', '', NS)
            v = (pm.findtext('wp:meta_value', '', NS) or '').strip()
            if not v:
                continue
            m = LATLNG.match(k)
            if m:
                if m.group(1) == 'lat':
                    lat = v
                else:
                    lng = v
            elif not k.startswith(('_elementor', '_edit', '_yoast', '_oembed', '_wp_old')):
                meta[k] = v

        terms = [t.text for t in el.findall('category') if t.text]
        items[ptype].append({
            'id': int(pid),
            'title': text(el.findtext('title', '')),
            'link': el.findtext('link', ''),
            'date': el.findtext('wp:post_date', '', NS),
            'meta': meta,
            'lat': lat,
            'lng': lng,
            'terms': terms,
            'thumb': meta.get('_thumbnail_id'),
            'logo': meta.get('business-logo'),
            'gallery': meta.get('photos-gallery', ''),
        })
        el.clear()

    return attachments, items


def as_bool(v):
    return str(v).strip().lower() == 'true'


def build_business(raw, attachments):
    out = []
    for b in raw:
        m = b['meta']
        gallery = [attachments[i] for i in b['gallery'].split(',')
                   if i.strip() in attachments][:6]
        image = attachments.get(b['thumb'] or '') or (gallery[0] if gallery else '')
        rating = m.get('_jet_reviews_average_rating')
        views = m.get('jet_engine_store_count_views')
        out.append({
            'id': b['id'],
            'title': m.get('business-name') or b['title'],
            'description': text(m.get('_description', '')),
            'about': text(m.get('business-incloud', ''))[:400],
            'address': m.get('address') or m.get('adress') or '',
            'phone': clean_phone(m.get('phone', '')),
            'site': m.get('business-site', ''),
            'hours': m.get('activity-time', ''),
            'kosher': as_bool(m.get('kosher-unkosher')),
            'delivery': as_bool(m.get('delivery')),
            'lat': float(b['lat']) if b['lat'] else None,
            'lng': float(b['lng']) if b['lng'] else None,
            'rating': float(rating) if rating else None,
            'views': int(views) if views and views.isdigit() else 0,
            'image': image,
            'logo': attachments.get(b['logo'] or '', ''),
            'gallery': gallery,
            'terms': [t for t in b['terms'] if t != 'עסקים באתר'],
            'link': b['link'],
        })
    # Busiest first — view count is the only popularity signal the site keeps.
    out.sort(key=lambda x: x['views'], reverse=True)
    return out


def build_professionals(raw, attachments):
    out = []
    for p in raw:
        m = p['meta']
        out.append({
            'id': p['id'],
            'title': m.get('business-name') or p['title'],
            'description': text(m.get('_description', '')),
            'phone': clean_phone(m.get('phone', '')),
            'address': m.get('address') or '',
            'image': attachments.get(p['thumb'] or '', ''),
            'terms': [t for t in p['terms'] if t != 'עסקים באתר'],
            'link': p['link'],
        })
    return out


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    src = os.path.expanduser(sys.argv[1])
    attachments, items = parse(src)
    print('attachments: %d' % len(attachments))

    for name, raw, builder in [
        ('wp_business', items['business'], build_business),
        ('wp_professionals', items['professionals'], build_professionals),
    ]:
        data = builder(raw, attachments)
        path = os.path.abspath(os.path.join(OUT_DIR, name + '.json'))
        json.dump(data, open(path, 'w', encoding='utf-8'),
                  ensure_ascii=False, separators=(',', ':'))
        print('%-18s %4d items -> %s' % (name, len(data), path))
        if data:
            f = lambda k: sum(1 for x in data if x.get(k))
            print('   with phone %d | address %d | image %d | coords %d'
                  % (f('phone'), f('address'), f('image'),
                     sum(1 for x in data if x.get('lat'))))


if __name__ == '__main__':
    main()
