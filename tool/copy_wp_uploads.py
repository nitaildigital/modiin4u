#!/usr/bin/env python3
"""Copies the old WordPress site's uploads, every size of every image, into a
folder the new server serves at the same addresses.

Google Images lists the old site's pictures under /wp-content/uploads/…, and
those links stop working when the domain moves to the new server. The client
agreed (2 Oct) to copy them over. nginx serves them from
/var/www/modiin4u-uploads (deploy/nginx/snippets/modiin4u-site.conf), outside
the web build, so a deploy never removes them.

Run it on the server, before the domain moves — afterwards the old site no
longer answers to www.modiin4u.co.il. It reads the media library from the
WordPress API (about 2,100 items, 13,500 files with their sizes, 2 GB or
more) and downloads straight from the old site, eight at a time. Standard
library only, so it runs on the server as it is.

Safe to stop and run again: a file already there with the same size is
skipped. Files are saved under their real (decoded) names, which is what
nginx looks for.

    scp tool/copy_wp_uploads.py root@45.93.94.49:/root/
    ssh root@45.93.94.49 'python3 /root/copy_wp_uploads.py --dry-run'
    ssh root@45.93.94.49 'nohup python3 /root/copy_wp_uploads.py > /root/wp_uploads.log 2>&1 &'
    ssh root@45.93.94.49 'tail -3 /root/wp_uploads.log'

--target DIR copies somewhere else, and --limit N only the first N files —
for trying it out.
"""

import concurrent.futures
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

SITE = 'https://www.modiin4u.co.il'
TARGET = '/var/www/modiin4u-uploads'
PREFIX = '/wp-content/uploads/'
AGENT = {'User-Agent': 'modiin4u-migration'}


def get(url, timeout=60):
    with urllib.request.urlopen(urllib.request.Request(url, headers=AGENT), timeout=timeout) as r:
        return r.read(), r.headers


def media_files():
    """Every upload address the media library knows: the original and each size."""
    urls, page = set(), 1
    while True:
        body, headers = get(f'{SITE}/wp-json/wp/v2/media?per_page=100&page={page}'
                            '&_fields=source_url,media_details')
        for m in json.loads(body):
            src = m.get('source_url') or ''
            if PREFIX not in src:
                continue
            urls.add(src)
            folder = src.rsplit('/', 1)[0]
            for size in ((m.get('media_details') or {}).get('sizes') or {}).values():
                name = size.get('file')
                if name:
                    urls.add(f'{folder}/{name}')
        if page >= int(headers.get('X-WP-TotalPages', '1')):
            return sorted(urls)
        page += 1


def local_path(url):
    path = urllib.parse.unquote(urllib.parse.urlsplit(url).path)
    if not path.startswith(PREFIX) or '..' in path:
        return None
    return os.path.join(TARGET, path.lstrip('/'))


def fetch(url):
    dest = local_path(url)
    if dest is None:
        return 'skipped'
    quoted = urllib.parse.quote(urllib.parse.unquote(url), safe=':/%')
    for attempt in range(3):
        try:
            req = urllib.request.Request(quoted, headers=AGENT)
            with urllib.request.urlopen(req, timeout=120) as r:
                length = r.headers.get('Content-Length')
                if length and os.path.exists(dest) and os.path.getsize(dest) == int(length):
                    return 'kept'
                data = r.read()
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            tmp = dest + '.part'
            with open(tmp, 'wb') as f:
                f.write(data)
            os.replace(tmp, dest)
            return 'copied'
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return 'missing'
        except Exception:
            pass
        time.sleep(2 * (attempt + 1))
    return 'failed'


def option(name, default):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else default


def main():
    global TARGET
    TARGET = option('--target', TARGET)
    urls = media_files()
    limit = int(option('--limit', 0))
    if limit:
        urls = urls[:limit]
    print(f'{len(urls)} files in the media library', flush=True)
    if '--dry-run' in sys.argv:
        for u in urls[:5]:
            print('  ', u, '→', local_path(u))
        return
    counts, failed = {}, []
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        for i, (url, result) in enumerate(zip(urls, pool.map(fetch, urls)), 1):
            counts[result] = counts.get(result, 0) + 1
            if result == 'failed':
                failed.append(url)
            if i % 500 == 0 or i == len(urls):
                print(f'{i}/{len(urls)} {counts}', flush=True)
    if failed:
        with open(os.path.join(TARGET, 'failed.txt'), 'w', encoding='utf-8') as f:
            f.write('\n'.join(failed) + '\n')
        print(f'{len(failed)} failed — listed in {TARGET}/failed.txt; run again to retry')


main()
