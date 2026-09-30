#!/usr/bin/env python3
"""Copies the client's Accessibility Statement and Terms from his WordPress
site into the panel's information pages (site_pages), as drafts.

The words are his: the Accessibility Statement (page 2095) and the Terms of
Use and Privacy Policy (page 2065) on www.modiin4u.co.il. They are copied as
they stand — not edited, not translated — into `body_he`, and left
unpublished: the client reads them in the panel (עמודי מידע), changes what
is out of date for the new site, and publishes. Until then the site keeps
saying the page is coming, as it does now.

"accessibility" already has a row (migration 00037); "terms" is added here.
Whatever a row held before is written to tool/site_pages_registry.json, and
--undo puts exactly that back and removes the "terms" row if this added it.

    python3 tool/import_site_pages.py            # show what would be written
    python3 tool/import_site_pages.py --apply
    python3 tool/import_site_pages.py --undo

Reads SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY from .env.local.
"""
import html
import json
import os
import re
import sys
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY = os.path.join(ROOT, 'tool', 'site_pages_registry.json')
WP = 'https://www.modiin4u.co.il/wp-json/wp/v2/pages/'

# slug in site_pages -> (WordPress page id, English title for the row).
# The English titles are the footer's own link names, not a translation of
# the pages; the bodies stay Hebrew only.
PAGES = {
    'accessibility': (2095, None),
    'terms': (2065, 'Terms of Use & Privacy Policy'),
}

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


def wordpress(page_id):
    req = urllib.request.Request(f'{WP}{page_id}?_fields=title,content,modified,link',
                                 headers={'User-Agent': 'modiin4u-import'})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def to_text(markup, title):
    """WordPress HTML to the pages' plain-text conventions: "## " headings,
    "- " list items, a blank line between paragraphs."""
    s = markup
    s = re.sub(r'(?is)<(script|style)\b.*?</\1>', '', s)
    s = re.sub(r'(?i)<br\s*/?>', '\n', s)
    s = re.sub(r'(?is)<h[1-6][^>]*>(.*?)</h[1-6]>', lambda m: f'\n\n## {m.group(1)}\n\n', s)
    # A list item can wrap its text in <p>; that must not split the item.
    s = re.sub(r'(?is)<li[^>]*>(.*?)</li>',
               lambda m: '\n- ' + re.sub(r'(?is)</?(p|div|br)[^>]*>', ' ', m.group(1)) + '\n', s)
    s = re.sub(r'(?is)</?(p|div|ul|ol|table|tr)[^>]*>', '\n\n', s)
    s = re.sub(r'<[^>]+>', '', s)
    s = html.unescape(s).replace('\xa0', ' ')

    blocks, para = [], []
    for raw in s.split('\n'):
        line = re.sub(r'[ \t]+', ' ', raw).strip()
        if not line:
            if para:
                blocks.append(' '.join(para))
                para = []
            continue
        if line.startswith('## ') or line.startswith('- '):
            if para:
                blocks.append(' '.join(para))
                para = []
            blocks.append(line)
        else:
            para.append(line)
    if para:
        blocks.append(' '.join(para))

    # The page prints its own title; a first heading repeating it goes.
    if blocks and blocks[0].lstrip('# ').strip() == title.strip():
        blocks = blocks[1:]

    out = []
    for b in blocks:
        # List items sit together; everything else is its own paragraph.
        if out and b.startswith('- ') and out[-1].startswith('- '):
            out[-1] += '\n' + b
        else:
            out.append(b)
    return '\n\n'.join(out).strip()


def current(slug):
    rows = db('GET', f'site_pages?slug=eq.{slug}&select=slug,title_he,title_en,body_he,is_published')
    return rows[0] if rows else None


def main():
    if '--undo' in sys.argv:
        reg = json.load(open(REGISTRY, encoding='utf-8'))
        for slug, before in reg.items():
            if before is None:
                db('DELETE', f'site_pages?slug=eq.{slug}')
                print('removed', slug)
            else:
                db('PATCH', f'site_pages?slug=eq.{slug}',
                   {k: before[k] for k in ('title_he', 'title_en', 'body_he', 'is_published')})
                print('restored', slug)
        os.remove(REGISTRY)
        return

    apply = '--apply' in sys.argv
    if apply and os.path.exists(REGISTRY):
        raise SystemExit('already imported — run --undo first to import again')

    registry = {}
    for slug, (page_id, title_en) in PAGES.items():
        page = wordpress(page_id)
        title = html.unescape(page['title']['rendered']).strip()
        body = to_text(page['content']['rendered'], title)
        before = current(slug)
        print(f'== {slug}: "{title}" (WordPress {page_id}, edited {page["modified"][:10]}) '
              f'{len(body)} chars, {"row exists" if before else "new row"}')
        if not apply:
            print('   ' + body[:400].replace('\n', '\n   ') + ('…' if len(body) > 400 else ''))
            continue
        registry[slug] = before
        values = {'title_he': title, 'body_he': body, 'is_published': False}
        if title_en and not (before or {}).get('title_en'):
            values['title_en'] = title_en
        if before:
            db('PATCH', f'site_pages?slug=eq.{slug}', values)
        else:
            db('POST', 'site_pages', {'slug': slug, 'title_en': title_en or '', **values},
               prefer='return=minimal')
        print('   written, unpublished')

    if apply:
        with open(REGISTRY, 'w', encoding='utf-8') as f:
            json.dump(registry, f, ensure_ascii=False, indent=2)
        print('registry:', os.path.relpath(REGISTRY, ROOT))


main()
