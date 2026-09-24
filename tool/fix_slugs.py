#!/usr/bin/env python3
"""Repairs the slugs the WordPress import mangled.

The site's URLs carry percent-encoded Hebrew — `%d7%9e%d7%a2…`. Somewhere in
the import the per cent signs became hyphens, so the slug arrived as
`d7-9e-d7-a2…`: not Hebrew, not valid encoding, and shown as-is in the admin
list under each business name.

Turning the hyphens back into per cent signs and decoding gives the Hebrew
the site meant. A word break arrives as a double hyphen, because the original
had a real hyphen between two encoded words.

    python3 tool/fix_slugs.py            # dry run, writes nothing
    python3 tool/fix_slugs.py --apply
"""

import json
import os
import re
import sys
import urllib.parse
import urllib.request

URL = os.environ["SUPABASE_URL"]
KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
HEAD = {
    "apikey": KEY,
    "Authorization": f"Bearer {KEY}",
    "Content-Type": "application/json",
}

# A run of encoded bytes: d7-9e-d7-a2-…
HEBREW = "[" + chr(0x0590) + "-" + chr(0x05FF) + "]"


def looks_mangled(slug: str) -> bool:
    return bool(slug) and bool(re.search(r"\bd[0-9a-f]-[0-9a-f]{2}\b", slug))


# A Hebrew character is two UTF-8 bytes beginning d6 or d7, so a run of them
# is what an encoded word looks like. Anchoring on that keeps a latin token
# such as "et" — which is not hex — and a stray digit out of the decode.
RUN = re.compile(r"(?:d[67]-[0-9a-f]{2})(?:-[0-9a-f]{2})*")


def decode(slug):
    """Decodes the encoded runs and leaves anything else as it is.

    A slug can be mixed — `et--d7-97-…`, or a digit in the middle of a name —
    so this replaces each run in place rather than requiring the whole slug to
    be one run. Returns None when the result still carries encoding or has no
    Hebrew in it, which means the guess was wrong and it is better left alone.
    """

    def swap(m):
        try:
            return bytes.fromhex(m.group(0).replace("-", "")).decode("utf-8")
        except (ValueError, UnicodeDecodeError):
            return m.group(0)

    # A double hyphen was a real hyphen between two encoded words.
    decoded = RUN.sub(swap, slug).replace("--", "-").strip("-")

    if not re.search(HEBREW, decoded):
        return None
    if re.search(r"\bd[67]-[0-9a-f]{2}\b", decoded):
        return None
    return decoded


def get(path: str):
    req = urllib.request.Request(URL + "/rest/v1/" + path, headers=HEAD)
    return json.load(urllib.request.urlopen(req))


def patch(path: str, body):
    req = urllib.request.Request(
        URL + "/rest/v1/" + path,
        method="PATCH",
        data=json.dumps(body).encode(),
        headers=HEAD,
    )
    urllib.request.urlopen(req).read()


def main() -> None:
    apply = "--apply" in sys.argv

    rows = get("businesses?select=id,name,slug&limit=500")
    fixes, skipped = [], []

    for r in rows:
        slug = r.get("slug") or ""
        if not looks_mangled(slug):
            continue
        decoded = decode(slug)
        (fixes if decoded else skipped).append((r, decoded))

    print(f"{len(rows)} businesses, {len(fixes) + len(skipped)} with a mangled slug")
    print(f"  {len(fixes)} can be decoded, {len(skipped)} cannot\n")

    for r, decoded in fixes[:12]:
        print(f"  {r['name'][:26]:28} {r['slug'][:30]:32} -> {decoded}")
    if len(fixes) > 12:
        print(f"  … and {len(fixes) - 12} more")

    if skipped:
        print("\n  left alone:")
        for r, _ in skipped[:5]:
            print(f"    {r['name'][:26]:28} {r['slug'][:40]}")

    # A slug is unique, so a collision has to be caught before writing.
    existing = {r["slug"] for r in rows if r.get("slug")}
    planned: dict[str, str] = {}
    collisions = []
    for r, decoded in fixes:
        if decoded in existing or decoded in planned:
            collisions.append((r, decoded))
        else:
            planned[decoded] = r["id"]

    if collisions:
        print(f"\n  {len(collisions)} would collide with an existing slug:")
        for r, d in collisions[:5]:
            print(f"    {r['name'][:26]:28} -> {d}")

    if not apply:
        print("\ndry run — nothing written. Pass --apply to write.")
        return

    written = 0
    for decoded, bid in planned.items():
        patch(f"businesses?id=eq.{bid}", {"slug": decoded})
        written += 1
    print(f"\nwrote {written} slugs")


if __name__ == "__main__":
    main()
