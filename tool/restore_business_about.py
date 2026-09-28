#!/usr/bin/env python3
"""Puts back the part of each business's "About" that the import cut off.

tool/parse_wxr.py read the JetEngine field `business-incloud` and kept the
first 400 characters — `text(...)[:400]` — so every longer description landed
in `businesses.full_description` stopped mid-sentence. 49 rows sat at exactly
400. The client opened one and found the About section was missing most of
itself. The REST API does not expose that field at all, so the only source is
a fresh WordPress export (Tools → Export → Businesses).

Only rows the import truncated are touched: a row is replaced when what the
database holds is exactly the first 400 characters of the full text as the
parser would have flattened it. Anything edited since in the admin panel does
not match that, and is left alone. Empty rows are filled.

The restored text keeps its paragraphs. The old parser folded every newline
into a space, which was tolerable at 400 characters and is not at 3,000.

    python3 tool/restore_business_about.py EXPORT.xml            # dry run
    python3 tool/restore_business_about.py EXPORT.xml --apply
"""

import html
import json
import os
import re
import sys
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

NS = {'wp': 'http://wordpress.org/export/1.2/'}


def env(key):
    for line in open('.env.local', encoding='utf-8'):
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


def flattened(s):
    """What tool/parse_wxr.py made of the field — to recognise its output."""
    if not s:
        return ''
    s = re.sub(r'<(script|style)[^>]*>.*?</\1>', ' ', s, flags=re.S | re.I)
    s = re.sub(r'<[^>]+>', ' ', s)
    s = html.unescape(s)
    return re.sub(r'\s+', ' ', s).strip()


def with_paragraphs(s):
    """The same text, keeping the breaks between its paragraphs."""
    if not s:
        return ''
    s = re.sub(r'<(script|style)[^>]*>.*?</\1>', ' ', s, flags=re.S | re.I)
    s = re.sub(r'<br\s*/?>', '\n', s, flags=re.I)
    s = re.sub(r'</(p|div|li|h[1-6])\s*>', '\n\n', s, flags=re.I)
    s = re.sub(r'<li[^>]*>', '• ', s, flags=re.I)
    s = re.sub(r'<[^>]+>', ' ', s)
    s = html.unescape(s)
    lines = [re.sub(r'[ \t ]+', ' ', line).strip() for line in s.split('\n')]
    out = re.sub(r'\n{3,}', '\n\n', '\n'.join(lines)).strip()
    return out


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    export, apply = sys.argv[1], '--apply' in sys.argv

    root = ET.parse(export).getroot()
    source = {}
    for item in root.iter('item'):
        if item.findtext('wp:post_type', '', NS) != 'business':
            continue
        meta = {
            m.findtext('wp:meta_key', '', NS): m.findtext('wp:meta_value', '', NS) or ''
            for m in item.findall('wp:postmeta', NS)
        }
        raw = meta.get('business-incloud', '')
        # WordPress exports a Hebrew slug percent-encoded; the import stored
        # it decoded. Compared raw, nineteen businesses never matched.
        slug = urllib.parse.unquote(item.findtext('wp:post_name', '', NS))
        if slug and raw.strip():
            source[slug] = raw

    rows = rest('GET', 'businesses?select=id,slug,full_description&limit=2000') or []
    fix, skipped_edited = [], 0
    for r in rows:
        raw = source.get(r['slug'])
        if not raw:
            continue
        full_flat = flattened(raw)
        now = (r.get('full_description') or '').strip()
        truncated = len(full_flat) > 400 and now == full_flat[:400].strip()
        if truncated or not now:
            fix.append((r['id'], r['slug'], len(now), with_paragraphs(raw)))
        elif now != full_flat and now != full_flat[:400].strip():
            skipped_edited += 1

    print(f'{len(source)} businesses in the export carry an About text')
    print(f'{len(fix)} to restore · {skipped_edited} left alone (edited since)')
    for _, slug, before, after in fix[:8]:
        print(f'  {slug[:32]:32} {before:>4} → {len(after)} chars')

    if not apply:
        print('dry run — nothing written. Re-run with --apply')
        return
    for business_id, _, _, text in fix:
        rest('PATCH', f'businesses?id=eq.{business_id}', {'full_description': text})
    print(f'restored {len(fix)}')


if __name__ == '__main__':
    os.chdir(os.path.dirname(os.path.abspath(__file__)) + '/..')
    main()
