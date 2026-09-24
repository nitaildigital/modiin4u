#!/usr/bin/env python3
"""Moves the photography off the WordPress site and into Supabase storage.

Two reasons, and the first is not optional:

1. **The web build cannot show them.** `modiin4u.co.il` sends no
   `Access-Control-Allow-Origin` header, so a browser refuses to load its
   images into the Flutter web app. Every business photograph is blank on the
   web — in the public directory and in the admin panel. Supabase storage
   sends `Access-Control-Allow-Origin: *`, so moving them fixes it.

2. **They are not ours.** If the WordPress site is ever taken down, every
   picture in the app goes with it.

Safe to run more than once: a URL already pointing at storage is skipped, and
the same source URL used by two records is uploaded once and shared.

    python3 tool/migrate_images.py                    # dry run
    python3 tool/migrate_images.py --apply
    python3 tool/migrate_images.py --apply --limit 20 # a slice, to try it
"""

import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

URL = os.environ["SUPABASE_URL"]
KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
BUCKET = "media"
SOURCE = "modiin4u.co.il"

REST = {
    "apikey": KEY,
    "Authorization": f"Bearer {KEY}",
    "Content-Type": "application/json",
}

# What the app reads for each record, and where the file lands in the bucket.
JOBS = [
    ("businesses", "cover_url", "businesses/cover"),
    ("businesses", "logo_url", "businesses/logo"),
    ("articles", "featured_image", "articles"),
]

MIME = {
    ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png",
    ".webp": "image/webp", ".gif": "image/gif",
}


def rest(method, path, body=None):
    req = urllib.request.Request(
        f"{URL}/rest/v1/{path}",
        method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers=REST,
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        text = r.read().decode()
        return json.loads(text) if text.strip() else None


def encoded(src):
    """Percent-encodes the path.

    Many of the article images have Hebrew in the filename, stored raw. An
    HTTP request cannot carry those bytes, so it has to be encoded first —
    and encoding an already-encoded URL would double it, hence the unquote.
    """
    parts = urllib.parse.urlsplit(src)
    path = urllib.parse.quote(urllib.parse.unquote(parts.path), safe="/")
    return urllib.parse.urlunsplit(
        (parts.scheme, parts.netloc, path, parts.query, parts.fragment)
    )


def download(src):
    req = urllib.request.Request(
        encoded(src), headers={"User-Agent": "Mozilla/5.0"}
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read(), r.headers.get("content-type", "")


def upload(path, data, content_type):
    req = urllib.request.Request(
        f"{URL}/storage/v1/object/{BUCKET}/{path}",
        method="POST",
        data=data,
        headers={
            "apikey": KEY,
            "Authorization": f"Bearer {KEY}",
            "Content-Type": content_type,
            # Re-running should overwrite rather than fail on a name in use.
            "x-upsert": "true",
        },
    )
    urllib.request.urlopen(req, timeout=120).read()
    return f"{URL}/storage/v1/object/public/{BUCKET}/{path}"


def storage_path(folder, src):
    """A stable name, so the same source always lands in the same place.

    Derived from the URL rather than the record, because two businesses can
    share a photograph and it should be stored once.
    """
    name = urllib.parse.unquote(src.rsplit("/", 1)[-1])
    ext = os.path.splitext(name)[1].lower()
    if ext not in MIME:
        ext = ".jpg"
    digest = hashlib.sha1(src.encode()).hexdigest()[:16]
    return f"{folder}/{digest}{ext}", MIME[ext]


def main():
    apply = "--apply" in sys.argv
    limit = None
    if "--limit" in sys.argv:
        limit = int(sys.argv[sys.argv.index("--limit") + 1])

    # One upload per distinct source URL, however many records point at it.
    uploaded: dict[str, str] = {}
    total = moved = shared = failed = 0
    started = time.time()

    for table, column, folder in JOBS:
        rows = rest("GET", f"{table}?select=id,{column}&limit=2000")
        todo = [r for r in rows if r.get(column) and SOURCE in r[column]]
        if limit is not None:
            todo = todo[:limit]

        print(f"\n{table}.{column}: {len(todo)} to move")
        if not apply:
            for r in todo[:3]:
                path, _ = storage_path(folder, r[column])
                print(f"  {r[column][:64]}…")
                print(f"    -> {BUCKET}/{path}")
            total += len(todo)
            continue

        for i, r in enumerate(todo, 1):
            src = r[column]
            total += 1
            try:
                if src in uploaded:
                    public = uploaded[src]
                    shared += 1
                else:
                    path, mime = storage_path(folder, src)
                    data, ctype = download(src)
                    if not data:
                        raise ValueError("empty response")
                    public = upload(path, data, ctype or mime)
                    uploaded[src] = public
                    moved += 1

                rest("PATCH", f"{table}?id=eq.{r['id']}", {column: public})
            except Exception as e:
                failed += 1
                print(f"  ! {src[:58]}… {type(e).__name__}")

            if i % 25 == 0:
                print(f"  {i}/{len(todo)}  ({round(time.time() - started)}s)")

    print()
    if apply:
        print(f"moved {moved} files, {shared} records shared one already moved,"
              f" {failed} failed, in {round(time.time() - started)}s")
        if failed:
            print("failed records keep their original URL, so re-running "
                  "retries only those")
    else:
        print(f"{total} files would move. Dry run — nothing written.")


if __name__ == "__main__":
    main()
