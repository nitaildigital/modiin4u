#!/usr/bin/env python3
"""Puts the Terms of Use and Privacy Policy from the client's WordPress site
into the panel's information pages, in place of the lawyer's drafts.

The lawyer's documents (tool/import_legal_docs.py) still carry some sixty
template brackets and notes, so they cannot go live. What the client has
published is the page on www.modiin4u.co.il (page 2065, "תקנון תנאי שימוש
ומדיניות פרטיות", last edited August 2025). It is one document covering both
— privacy in sections 1–5, terms in section 6, one introduction and one
"last updated" line — so the same text goes into both rows, 'terms' and
'privacy', word for word: not split, not edited, not translated. Each row
keeps its own title.

Whatever the rows held before (the lawyer's drafts) is written to
tool/wp_legal_registry.json, and --undo puts exactly that back. The rows stay
unpublished unless --publish is given.

    python3 tool/import_wp_legal.py                     # show what would be written
    python3 tool/import_wp_legal.py --apply             # write, unpublished
    python3 tool/import_wp_legal.py --apply --publish   # write and publish
    python3 tool/import_wp_legal.py --undo

Reads SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY from .env.local.
"""
import html
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from import_site_pages import ROOT, current, db, to_text, wordpress  # noqa: E402

REGISTRY = os.path.join(ROOT, 'tool', 'wp_legal_registry.json')
PAGE_ID = 2065
SLUGS = ('terms', 'privacy')


def main():
    if '--undo' in sys.argv:
        reg = json.load(open(REGISTRY, encoding='utf-8'))
        for slug, before in reg.items():
            db('PATCH', f'site_pages?slug=eq.{slug}',
               {k: before[k] for k in ('body_he', 'is_published')})
            print('restored', slug)
        os.remove(REGISTRY)
        return

    apply = '--apply' in sys.argv
    publish = '--publish' in sys.argv
    if apply and os.path.exists(REGISTRY):
        raise SystemExit('already imported — run --undo first to import again')

    page = wordpress(PAGE_ID)
    title = html.unescape(page['title']['rendered']).strip()
    body = to_text(page['content']['rendered'], title)
    print(f'WordPress {PAGE_ID} "{title}", edited {page["modified"][:10]}: {len(body)} chars')

    registry = {}
    for slug in SLUGS:
        before = current(slug)
        if before is None:
            raise SystemExit(f"no '{slug}' row — run migration 00046 first")
        print(f'== {slug} ("{before["title_he"]}"): replaces {len(before["body_he"] or "")} chars, '
              f'{"published" if publish else "unpublished"}')
        if not apply:
            continue
        registry[slug] = before
        db('PATCH', f'site_pages?slug=eq.{slug}', {'body_he': body, 'is_published': publish})

    if not apply:
        print('\n' + body)
        return
    with open(REGISTRY, 'w', encoding='utf-8') as f:
        json.dump(registry, f, ensure_ascii=False, indent=2)
    print('registry:', os.path.relpath(REGISTRY, ROOT))


main()
