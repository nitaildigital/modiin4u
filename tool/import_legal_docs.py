#!/usr/bin/env python3
"""Puts the client's lawyer's Terms of Use and Privacy Policy into the panel's
information pages, as drafts.

The client sent them on 5 Oct as two Word documents:
  תקנון ותנאי שימוש – מודיעין בשבילך (Modiin4u).docx  → site_pages 'terms'
  מדיניות פרטיות – מודיעין בשבילך (Modiin4u).docx    → site_pages 'privacy'

The words are the lawyer's and go in as they are — not edited, not
translated, the template's brackets included — into `body_he`, unpublished.
The client and his lawyer finish them in the panel (עמודי מידע) and
publish; until then the site says the page is coming. Only the layout is
turned into the pages' conventions: "## " headings, "- " list items, a blank
line between paragraphs; the document's own title line is left to the page.

'terms' held the old WordPress page (tool/import_site_pages.py); 'privacy' is
added if 00046 has not run yet. Whatever a row held before is written to
tool/legal_docs_registry.json, and --undo puts exactly that back.

    python3 tool/import_legal_docs.py            # show what would be written
    python3 tool/import_legal_docs.py --apply
    python3 tool/import_legal_docs.py --undo

Reads the two .docx files from the repository's root (they are gitignored),
and SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY from .env.local.
"""

import json
import os
import re
import sys
import urllib.error
import urllib.request
import zipfile
from xml.etree import ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY = os.path.join(ROOT, 'tool', 'legal_docs_registry.json')
W = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'

# slug -> (document, Hebrew title, English title). The titles are the
# documents' own and the footer's link names, not translations.
DOCS = {
    'terms': ('תקנון ותנאי שימוש – מודיעין בשבילך (Modiin4u).docx',
              'תקנון ותנאי שימוש', 'Terms of Use'),
    'privacy': ('מדיניות פרטיות – מודיעין בשבילך (Modiin4u).docx',
                'מדיניות פרטיות', 'Privacy Policy'),
}

env = {}
for line in open(os.path.join(ROOT, '.env.local'), encoding='utf-8'):
    line = line.rstrip('\n')
    if line.strip() and not line.lstrip().startswith('#'):
        k, _, v = line.partition('=')
        env[k] = v
URL = env['SUPABASE_URL'].rstrip('/')
KEY = env['SUPABASE_SERVICE_ROLE_KEY']


def db(method, path, body=None):
    headers = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY,
               'Content-Type': 'application/json', 'Prefer': 'return=representation'}
    req = urllib.request.Request(URL + '/rest/v1/' + path, method=method, headers=headers,
                                 data=None if body is None else json.dumps(body).encode())
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            raw = r.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        raise SystemExit(f'{method} {path.split("?")[0]} -> {e.code}: {e.read().decode()[:300]}')


def to_text(path):
    """A Word document in the pages' plain-text conventions."""
    z = zipfile.ZipFile(path)
    doc = ET.fromstring(z.read('word/document.xml'))
    styles = {}
    if 'word/styles.xml' in z.namelist():
        for s in ET.fromstring(z.read('word/styles.xml')).iter(W + 'style'):
            n = s.find(W + 'name')
            styles[s.get(W + 'styleId')] = n.get(W + 'val') if n is not None else ''

    blocks = []
    for p in doc.iter(W + 'p'):
        ppr = p.find(W + 'pPr')
        style, is_list = '', False
        if ppr is not None:
            ps = ppr.find(W + 'pStyle')
            if ps is not None:
                style = styles.get(ps.get(W + 'val'), ps.get(W + 'val')) or ''
            is_list = ppr.find(W + 'numPr') is not None
        text, all_bold = '', True
        for r in p.iter(W + 'r'):
            t = ''.join((x.text or '') for x in r.iter(W + 't'))
            if not t:
                continue
            rpr = r.find(W + 'rPr')
            b = rpr is not None and rpr.find(W + 'b') is not None \
                and rpr.find(W + 'b').get(W + 'val') not in ('0', 'false')
            all_bold = all_bold and (b or not t.strip())
            text += t
        text = re.sub(r'\s+', ' ', text).strip()
        if not text or text == '.':
            continue
        heading = re.match(r'(?i)heading\s*\d', style) or style.lower() == 'title' \
            or (all_bold and len(text) < 120)
        if heading:
            blocks.append('## ' + text)
        elif is_list:
            blocks.append('- ' + text)
        else:
            blocks.append(text)

    # The page prints its own title: the document's first line is that title.
    if blocks and blocks[0].startswith('## '):
        blocks = blocks[1:]

    out = []
    for b in blocks:
        # List items sit together; everything else is its own paragraph.
        if out and b.startswith('- ') and out[-1].split('\n')[-1].startswith('- '):
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
        raise SystemExit('already applied: run --undo first')

    registry = {}
    for slug, (name, title_he, title_en) in DOCS.items():
        body = to_text(os.path.join(ROOT, name))
        before = current(slug)
        print(f'{slug}: {len(body.split())} words, '
              f'{body.count(chr(10) + chr(10) + "## ") + 1} headings; '
              f'{"replaces the draft there" if before else "a new page"}'
              f'{" (PUBLISHED — left alone)" if before and before["is_published"] else ""}')
        if not apply or (before and before['is_published']):
            continue
        registry[slug] = before
        fields = {'title_he': title_he, 'title_en': title_en, 'body_he': body, 'is_published': False}
        if before:
            db('PATCH', f'site_pages?slug=eq.{slug}', fields)
        else:
            db('POST', 'site_pages', {'slug': slug, **fields})
        json.dump(registry, open(REGISTRY, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    if not apply:
        print('dry run: pass --apply to write')


main()
