#!/usr/bin/env python3
"""Brings the business photo galleries across from the WordPress site.

The export was parsed and the galleries were in it — `photos-gallery`, 513
photographs across 108 businesses, sitting in assets/data/wp_business.json —
but nothing ever loaded them into the database. `media` and `entity_media`
held no rows at all, so every business page showed its cover and nothing
else, and the Photos tab said there were no photos. The client noticed.

For each photograph this:

  1. downloads it from the WordPress site,
  2. shrinks it if it is over 10MB or wider than 2000px,
  3. puts it in the `media` bucket — because modiin4u.co.il sends no CORS
     header, a browser will not load its images into the web app at all,
  4. writes a `media` row for the file and an `entity_media` row tying it to
     the business as `role = 'gallery'`, in the order WordPress had them.

Businesses are matched by the last segment of their WordPress permalink,
which is the slug the import gave them; all 108 match.

Safe to run more than once: the storage path is derived from the source URL,
and a photograph already linked to its business is skipped.

    python3 tool/import_business_galleries.py            # dry run
    python3 tool/import_business_galleries.py --apply
    python3 tool/import_business_galleries.py --undo     # remove what it made
"""

import json
import os
import sys
import urllib.parse

# The download, resize and upload helpers are the ones the logo and cover
# migration already uses, so a gallery photo is treated exactly like them.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import migrate_images as mi  # noqa: E402

FOLDER = 'businesses/gallery'
SOURCE = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'data', 'wp_business.json'
)


def insert(table, row):
    """POST one row and get it back — the shared helper does not ask for it."""
    import urllib.request
    req = urllib.request.Request(
        f'{mi.URL}/rest/v1/{table}',
        method='POST',
        data=json.dumps(row).encode(),
        headers={**mi.REST, 'Prefer': 'return=representation'},
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode())[0]


def heic_to_jpeg(data):
    """iPhone photographs arrive as HEIC, which the bucket refuses and most
    browsers cannot draw. Four of the gallery photos are HEIC. Pillow cannot
    read the format without a plugin; macOS's own `sips` can."""
    import subprocess
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        src, out = os.path.join(d, 'in.heic'), os.path.join(d, 'out.jpg')
        open(src, 'wb').write(data)
        subprocess.run(
            ['sips', '-s', 'format', 'jpeg', src, '--out', out],
            check=True, capture_output=True,
        )
        return open(out, 'rb').read()


def slug_of(link):
    return urllib.parse.unquote((link or '').rstrip('/').split('/')[-1])


def image_size(data):
    try:
        from io import BytesIO
        from PIL import Image
        return Image.open(BytesIO(data)).size
    except Exception:
        return None, None


def undo(apply):
    links = mi.rest('GET', "entity_media?entity_type=eq.business&role=eq.gallery&select=media_id") or []
    ids = sorted({l['media_id'] for l in links})
    print(f'{len(links)} gallery links, {len(ids)} media rows')
    if not apply:
        print('dry run — re-run with --undo --apply to remove them')
        return
    mi.rest('DELETE', 'entity_media?entity_type=eq.business&role=eq.gallery')
    for i in range(0, len(ids), 100):
        chunk = ','.join(ids[i:i + 100])
        mi.rest('DELETE', f'media?id=in.({chunk})')
    print('removed (the files stay in the bucket; they are harmless there)')


def main():
    apply = '--apply' in sys.argv
    if '--undo' in sys.argv:
        undo(apply)
        return

    source = json.load(open(SOURCE))
    db = mi.rest('GET', 'businesses?select=id,slug&limit=2000') or []
    by_slug = {b['slug']: b['id'] for b in db}

    have = {
        (l['entity_id'], l['media']['file_path'])
        for l in (mi.rest(
            'GET',
            'entity_media?entity_type=eq.business&role=eq.gallery'
            '&select=entity_id,media(file_path)',
        ) or [])
        if l.get('media')
    }

    work = []
    for b in source:
        gallery = b.get('gallery') or []
        if not gallery:
            continue
        business_id = by_slug.get(slug_of(b.get('link')))
        if not business_id:
            print(f"  no match for {b.get('link')}")
            continue
        for order, src in enumerate(gallery):
            path, mime = mi.storage_path(FOLDER, src)
            if (business_id, path) in have:
                continue
            work.append((business_id, order, src, path, mime))

    print(f'{len(work)} photographs to bring across '
          f'({len(have)} already linked)')
    if not apply:
        print('dry run — nothing written. Re-run with --apply')
        return

    done = failed = 0
    for business_id, order, src, path, mime in work:
        try:
            data, served = mi.download(src)
            if src.lower().endswith('.heic') or 'heic' in (served or '').lower():
                data, served = heic_to_jpeg(data), 'image/jpeg'
            data, mime = mi.shrink(data, served or mime)
            url = mi.upload(path, data, mime)
            w, h = image_size(data)
            media = insert('media', {
                'file_name': os.path.basename(path),
                'file_path': path,
                'url': url,
                'mime_type': mime,
                'size_bytes': len(data),
                'width': w,
                'height': h,
                'folder': FOLDER,
            })
            media_id = media['id']
            insert('entity_media', {
                'media_id': media_id,
                'entity_type': 'business',
                'entity_id': business_id,
                'role': 'gallery',
                'sort_order': order,
            })
            done += 1
            if done % 25 == 0:
                print(f'  {done}/{len(work)}')
        except Exception as e:
            failed += 1
            print(f'  failed: {src[:80]} — {type(e).__name__}: {str(e)[:80]}')

    print(f'done: {done} brought across, {failed} failed')


if __name__ == '__main__':
    main()
