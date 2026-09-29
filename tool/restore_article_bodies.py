#!/usr/bin/env python3
"""Puts the full text back into the news articles, with their photographs.

659 of the published articles hold only their excerpt as the body — three
hundred-odd characters ending in "[…]" — because they came in through the
REST API, which hands out the excerpt, not the story. The whole story is in
the WordPress export that tool/build_seed.py turned into
supabase/seed_content.sql, so this reads it from there.

What WordPress stores is not quite what it shows. A story written in the
classic editor keeps its paragraphs as blank lines and its line breaks as
newlines, and WordPress's `wpautop` turns them into <p> and <br> on the way
out; a story from the block editor carries `<!-- wp:… -->` markers that the
site strips. The article page reads the HTML (lib/features/news/models/
article_body.dart) and treats whitespace the way a browser does, so the
export is turned into the HTML the site actually served: paragraphs made,
block markers removed, a [caption] made a <figure>. Nothing is reworded.

The 334 photographs inside the stories sit on modiin4u.co.il, which sends no
CORS header, so a browser will not hand them to the web app. Each is copied
into our `media` bucket (media/articles/inline/…), at full size where
WordPress has it and no wider than 1600 pixels, and the <img> is pointed
there, with its width and height set to the copy's.

A body is replaced only when it still equals the imported excerpt — one
somebody has edited since is left alone — and the article is matched by its
slug, or failing that by the address it had on the old site, and only when
the title agrees too.

Every body replaced and every photograph uploaded is recorded in
tool/article_bodies_registry.json, with the body it replaced, so --undo can
put things back: it restores a body only if it is still the one this script
wrote.

    python3 tool/restore_article_bodies.py              # what it would do (same as --dry-run)
    python3 tool/restore_article_bodies.py --apply
    python3 tool/restore_article_bodies.py --verify     # read a few back with the public key
    python3 tool/restore_article_bodies.py --undo
"""

import hashlib
import html
import io
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, 'supabase', 'seed_content.sql')
REGISTRY = os.path.join(ROOT, 'tool', 'article_bodies_registry.json')
BUCKET = 'media'
FOLDER = 'articles/inline'
MAX_EDGE = 1600


def env():
    """Read .env.local directly: the shell would cut a value at a #."""
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


def http(method, url, body=None, headers=None, raw=None, key=KEY):
    h = {'apikey': key, 'Authorization': f'Bearer {key}'}
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


def sha(text):
    return hashlib.sha1(text.encode('utf-8')).hexdigest()


# ═══════════════════════════════════════════════════════════
# The export
# ═══════════════════════════════════════════════════════════

HEAD = ('insert into articles (id, title, slug, body, excerpt, featured_image, status, '
        'published_at) values (')
COLUMNS = ['id', 'title', 'slug', 'body', 'excerpt', 'featured_image', 'status', 'published_at']


def _literals(text, i):
    """The SQL literals of one VALUES tuple, starting just after its '('.
    Strings are quoted with '' for a quote, as build_seed.py writes them."""
    out = []
    while True:
        while text[i] in ' \n':
            i += 1
        if text[i] == "'":
            j, buf = i + 1, []
            while True:
                k = text.index("'", j)
                if text[k + 1:k + 2] == "'":
                    buf.append(text[j:k + 1])
                    j = k + 2
                else:
                    buf.append(text[j:k])
                    i = k + 1
                    break
            out.append(''.join(buf))
        else:
            m = re.match(r'(null|true|false|-?[0-9.]+)', text[i:])
            out.append(None if m.group(1) == 'null' else m.group(1))
            i += len(m.group(1))
        while text[i] in ' \n':
            i += 1
        if text[i] == ',':
            i += 1
        elif text[i] == ')':
            return out, i + 1
        else:
            raise ValueError(f'unexpected {text[i:i + 40]!r}')


def exported_articles():
    text = open(SOURCE, encoding='utf-8').read()
    found, pos = [], 0
    while True:
        p = text.find(HEAD, pos)
        if p < 0:
            return found
        values, pos = _literals(text, p + len(HEAD))
        found.append(dict(zip(COLUMNS, values)))


def slug_of(link):
    """As build_seed.py derives a slug from the post's address."""
    m = re.search(r'/([^/]+)/?$', (link or '').rstrip('/'))
    s = urllib.parse.unquote(m.group(1)) if m else ''
    return re.sub(r'[\s/]+', '-', s).strip('-')[:120]


def same_title(a, b):
    """Equal once WordPress's typography is set aside: the live site curls
    quotes and turns ' - ' into an en dash (wptexturize), the export does not."""
    def norm(s):
        s = html.unescape(s or '')
        for fancy, plain in (('\u2013', '-'), ('\u2014', '-'), ('\u2011', '-'), ('\u2018', "'"),
                             ('\u2019', "'"), ('\u201c', '"'), ('\u201d', '"'), ('\u05f4', '"'),
                             ('\u05f3', "'"), ('\u2026', '...'), ('\u00a0', ' ')):
            s = s.replace(fancy, plain)
        s = re.sub('[\u200e\u200f\u200b\u200c\u200d]', '', s)
        return re.sub(r'\s+', ' ', s).strip()
    return norm(a) == norm(b)


# ═══════════════════════════════════════════════════════════
# From what WordPress stores to what it served
# ═══════════════════════════════════════════════════════════

ALLBLOCKS = (r'(?:table|thead|tfoot|caption|col|colgroup|tbody|tr|td|th|div|dl|dd|dt|ul|ol|li|pre|'
             r'form|map|area|blockquote|address|math|style|p|h[1-6]|hr|fieldset|legend|section|'
             r'article|aside|hgroup|header|footer|nav|figure|figcaption|details|menu|summary)')


def wpautop(text):
    """WordPress's wpautop(), in Python: blank lines become paragraphs and
    single newlines <br />, except where block-level HTML already decides."""
    if not text.strip():
        return ''
    text = text.replace('\r\n', '\n').replace('\r', '\n') + '\n'
    text = re.sub(r'<br\s*/?>\s*<br\s*/?>', '\n\n', text)
    text = re.sub(r'(<' + ALLBLOCKS + r'[\s/>])', r'\n\n\1', text)
    text = re.sub(r'(</' + ALLBLOCKS + r'>)', r'\1\n\n', text)
    text = re.sub(r'(<hr\s*?/?>)', r'\1\n\n', text)
    # A newline inside a tag's attributes is not a line break.
    text = re.sub(r'<[^>]+>', lambda m: m.group(0).replace('\n', ' '), text)
    text = re.sub(r'\s*<option', '<option', text)
    text = re.sub(r'\n\n+', '\n\n', text)
    out = ''
    for part in re.split(r'\n\s*\n', text):
        if part.strip():
            out += '<p>' + part.strip('\n') + '</p>\n'
    text = out
    text = re.sub(r'<p>\s*</p>', '', text)
    text = re.sub(r'<p>([^<]+)</(div|address|form)>', r'<p>\1</p></\2>', text)
    text = re.sub(r'<p>\s*(</?' + ALLBLOCKS + r'[^>]*>)\s*</p>', r'\1', text)
    text = re.sub(r'<p>(<li.+?)</p>', r'\1', text)
    text = re.sub(r'<p><blockquote([^>]*)>', r'<blockquote\1><p>', text, flags=re.I)
    text = text.replace('</blockquote></p>', '</p></blockquote>')
    text = re.sub(r'<p>\s*(</?' + ALLBLOCKS + r'[^>]*>)', r'\1', text)
    text = re.sub(r'(</?' + ALLBLOCKS + r'[^>]*>)\s*</p>', r'\1', text)
    text = re.sub(r'<br\s*/?>', '<br />', text)
    text = re.sub(r'(?<!<br />)\s*\n', '<br />\n', text)
    text = re.sub(r'(</?' + ALLBLOCKS + r'[^>]*>)\s*<br />', r'\1', text)
    text = re.sub(r'<br />(\s*</?(?:p|li|div|dl|dd|dt|th|pre|td|ul|ol)[^>]*>)', r'\1', text)
    text = re.sub(r'\n</p>$', '</p>', text)
    return text


CAPTION = re.compile(r'\[caption[^\]]*\](.*?)\[/caption\]', re.S)
# An address alone on its line, which WordPress turns into an embedded card.
# The card is another site's page in a frame, which the article page does not
# draw, so the address becomes a plain link instead of being lost.
BARE_URL = re.compile(r'^[ \t]*(https?://[^\s<>"]+)[ \t]*$', re.M)


def served_html(body):
    """The HTML WordPress served for a stored post body."""
    if '<!-- wp:' in body:
        # Block editor: already paragraphs; the markers are for the editor.
        html = re.sub(r'<!--.*?-->', '', body, flags=re.S)
    else:
        def figure(m):
            inner = m.group(1).strip()
            img = re.match(r'(<img[^>]*>)\s*(.*)$', inner, re.S)
            if not img:
                return inner
            caption = img.group(2).strip()
            return (f'<figure class="wp-caption">{img.group(1)}'
                    + (f'<figcaption>{caption}</figcaption>' if caption else '') + '</figure>')
        body = BARE_URL.sub(lambda m: f'<a href="{m.group(1)}">{m.group(1)}</a>', CAPTION.sub(figure, body))
        html = wpautop(body)
        html = re.sub(r'<!--.*?-->', '', html, flags=re.S)
    return re.sub(r'\n{3,}', '\n\n', html).strip()


# ═══════════════════════════════════════════════════════════
# Photographs
# ═══════════════════════════════════════════════════════════

IMG = re.compile(r'<img\b[^>]*>', re.I)
WP_SIZE = re.compile(r'-\d+x\d+(?=\.[a-zA-Z]+$)')


def attr(tag, name):
    m = re.search(r'\s' + name + r'\s*=\s*("([^"]*)"|\'([^\']*)\')', tag, re.I)
    return (m.group(2) if m.group(2) is not None else m.group(3)) if m else None


def set_attr(tag, name, value):
    pattern = re.compile(r'(\s' + name + r'\s*=\s*)("[^"]*"|\'[^\']*\')', re.I)
    if pattern.search(tag):
        return pattern.sub(lambda m: f'{m.group(1)}"{value}"', tag, count=1)
    return re.sub(r'\s*/?>$', lambda m: f' {name}="{value}"' + m.group(0), tag, count=1)


def fetch(url):
    parts = urllib.parse.urlsplit(url)
    path = urllib.parse.quote(urllib.parse.unquote(parts.path), safe='/')
    req = urllib.request.Request(urllib.parse.urlunsplit(parts._replace(path=path)),
                                 headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=90) as r:
        return r.read()


def heic_to_jpeg(data):
    with tempfile.TemporaryDirectory() as d:
        src, out = os.path.join(d, 'in.heic'), os.path.join(d, 'out.jpg')
        open(src, 'wb').write(data)
        subprocess.run(['sips', '-s', 'format', 'jpeg', src, '--out', out], check=True, capture_output=True)
        return open(out, 'rb').read()


def prepare(data, src):
    """(bytes, extension, mime, width, height) for storage: JPEG, or WebP
    where the picture has transparency, or the GIF itself if it moves."""
    from PIL import Image
    if src.lower().endswith('.heic'):
        data = heic_to_jpeg(data)
    im = Image.open(io.BytesIO(data))
    if im.format == 'GIF' and getattr(im, 'n_frames', 1) > 1 and len(data) < 8 * 1024 * 1024:
        return data, 'gif', 'image/gif', im.width, im.height
    im.load()
    if max(im.size) > MAX_EDGE or im.width > MAX_EDGE:
        scale = MAX_EDGE / im.width if im.width >= im.height else MAX_EDGE / im.height
        im = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
    out = io.BytesIO()
    has_alpha = im.mode in ('RGBA', 'LA') or (im.mode == 'P' and 'transparency' in im.info)
    if has_alpha:
        im.convert('RGBA').save(out, 'WEBP', quality=82)
        return out.getvalue(), 'webp', 'image/webp', im.width, im.height
    im.convert('RGB').save(out, 'JPEG', quality=82, optimize=True, progressive=True)
    return out.getvalue(), 'jpg', 'image/jpeg', im.width, im.height


def rehost(src, reg, apply):
    """Our copy of one WordPress photograph, uploading it the first time."""
    known = reg['images'].get(src)
    if known:
        return known
    if not apply:
        return None
    full = WP_SIZE.sub('', src)
    data, used = None, None
    for candidate in ([full, src] if full != src else [src]):
        try:
            data, used = fetch(candidate), candidate
            break
        except Exception:
            continue
    if data is None:
        raise RuntimeError('not reachable')
    data, ext, mime, w, h = prepare(data, used)
    path = f'{FOLDER}/{hashlib.sha1(src.encode()).hexdigest()[:20]}.{ext}'
    http('POST', f'{URL}/storage/v1/object/{BUCKET}/{path}', raw=data,
         headers={'Content-Type': mime, 'x-upsert': 'true', 'Cache-Control': 'max-age=604800'})
    entry = {
        'path': path,
        'url': f'{URL}/storage/v1/object/public/{BUCKET}/{path}',
        'width': w, 'height': h, 'from': used, 'bytes': len(data),
    }
    reg['images'][src] = entry
    save_registry(reg)
    return entry


def with_photos(html, reg, apply, problems):
    def swap(m):
        tag = m.group(0)
        src = attr(tag, 'src')
        if not src or 'modiin4u.co.il' not in src:
            return tag
        try:
            copy = rehost(src, reg, apply)
        except Exception as e:
            problems.append(f'{src[:90]} — {type(e).__name__}: {str(e)[:60]}')
            return tag
        if copy is None:          # dry run
            return tag
        tag = set_attr(tag, 'src', copy['url'])
        tag = set_attr(tag, 'width', str(copy['width']))
        tag = set_attr(tag, 'height', str(copy['height']))
        # srcset/sizes would point back at WordPress.
        tag = re.sub(r'\s(srcset|sizes)\s*=\s*("[^"]*"|\'[^\']*\')', '', tag)
        return tag
    return IMG.sub(swap, html)


# ═══════════════════════════════════════════════════════════
# Registry
# ═══════════════════════════════════════════════════════════

def load_registry():
    if os.path.exists(REGISTRY):
        with open(REGISTRY, encoding='utf-8') as f:
            reg = json.load(f)
    else:
        reg = {}
    reg.setdefault('note', 'Written by tool/restore_article_bodies.py. The body each article '
                           'had before, and every photograph copied; --undo reads this file.')
    reg.setdefault('articles', {})
    reg.setdefault('images', {})
    return reg


def save_registry(reg):
    tmp = REGISTRY + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(reg, f, ensure_ascii=False, indent=1)
    os.replace(tmp, REGISTRY)


# ═══════════════════════════════════════════════════════════
# Run
# ═══════════════════════════════════════════════════════════

def restore(apply):
    reg = load_registry()
    source = exported_articles()
    by_slug = {a['slug']: a for a in source}
    rows = rest('GET', 'articles?select=id,slug,title,canonical_url,body,excerpt&limit=5000')

    todo, edited, done, unmatched, mismatched = [], [], [], [], []
    for r in rows:
        a = by_slug.get(r['slug'])
        if not a and r.get('canonical_url'):
            a = by_slug.get(slug_of(r['canonical_url']))
        if not a:
            unmatched.append(r)
            continue
        if not same_title(a['title'], r['title']):
            mismatched.append(r)
            continue
        entry = reg['articles'].get(r['id'])
        if entry and sha(r['body']) == entry['restored_sha1']:
            done.append(r)
        elif (r['body'] or '').strip() == (r['excerpt'] or '').strip():
            todo.append((r, a))
        else:
            edited.append(r)

    print(f'{len(rows)} articles in the table; {len(source)} in the export.')
    print(f'  to restore: {len(todo)}   already restored: {len(done)}   '
          f'edited since import (left alone): {len(edited)}')
    print(f'  not in the export: {len(unmatched)}   title disagrees (left alone): {len(mismatched)}')
    for r in unmatched:
        print(f'    not in export: {r["slug"]}')
    for r in mismatched:
        print(f'    title disagrees: {r["slug"]}')
    photos = sum(len(IMG.findall(a['body'])) for _, a in todo)
    print(f'  photographs in the bodies to restore: {photos}')
    if not apply:
        if todo:
            r, a = todo[0]
            print(f'\nFirst one, {r["slug"]}: {len(r["body"])} characters now, '
                  f'{len(served_html(a["body"]))} restored.')
        print('Dry run — nothing written. Re-run with --apply.')
        return

    problems, n = [], 0
    for r, a in todo:
        html = with_photos(served_html(a['body']), reg, True, problems)
        rest('PATCH', f'articles?id=eq.{r["id"]}', {'body': html}, prefer='return=minimal')
        reg['articles'][r['id']] = {
            'slug': r['slug'],
            'previous_body': r['body'],
            'restored_sha1': sha(html),
        }
        save_registry(reg)
        n += 1
        if n % 50 == 0:
            print(f'  {n}/{len(todo)}')
    print(f'Restored {n} bodies; {len(reg["images"])} photographs in {BUCKET}/{FOLDER}/.')
    if problems:
        print(f'{len(problems)} photographs could not be copied and still point at WordPress:')
        for p in problems:
            print('  ' + p)


def undo():
    reg = load_registry()
    if not reg['articles'] and not reg['images']:
        print('Nothing recorded — nothing to undo.')
        return
    back = kept = 0
    for aid, entry in list(reg['articles'].items()):
        rows = rest('GET', f'articles?id=eq.{aid}&select=body')
        if rows and sha(rows[0]['body']) == entry['restored_sha1']:
            rest('PATCH', f'articles?id=eq.{aid}', {'body': entry['previous_body']}, prefer='return=minimal')
            back += 1
        else:
            kept += 1          # edited since, or gone: that stands
        del reg['articles'][aid]
        save_registry(reg)
    paths = [e['path'] for e in reg['images'].values()]
    for i in range(0, len(paths), 100):
        http('DELETE', f'{URL}/storage/v1/object/{BUCKET}', {'prefixes': paths[i:i + 100]})
    reg['images'] = {}
    save_registry(reg)
    os.remove(REGISTRY)
    print(f'Put back {back} bodies ({kept} changed since and left as they are); '
          f'removed {len(paths)} photographs.')


def verify():
    cfg = open(os.path.join(ROOT, 'lib', 'core', 'supabase', 'supabase_config.dart'), encoding='utf-8').read()
    anon = re.search(r"anonKey\s*=\s*'([^']+)'", cfg).group(1)
    reg = load_registry()
    ids = list(reg['articles'])
    if not ids:
        print('Nothing restored yet.')
        return
    rows = []
    for i in range(0, len(ids), 100):
        chunk = ','.join(ids[i:i + 100])
        rows += http('GET', f'{URL}/rest/v1/articles?id=in.({chunk})&select=id,slug,body,status', key=anon)
    wp_left = [r for r in rows if re.search(r'<img[^>]+src="https?://(www\.)?modiin4u\.co\.il', r['body'])]
    ours = [r for r in rows if f'{URL}/storage/v1/object/public/{BUCKET}/{FOLDER}/' in r['body']]
    print(f'Public reads (anon key): {len(rows)}/{len(ids)} restored articles readable; '
          f'{len(ours)} carry re-hosted photos; {len(wp_left)} still point a photo at WordPress.')
    sample = ours[:3] + [r for r in rows if r not in ours][:2]
    for r in sample:
        srcs = re.findall(r'<img[^>]+src="([^"]+)"', r['body'])
        ok = 0
        for s in srcs:
            try:
                with urllib.request.urlopen(urllib.request.Request(s, method='HEAD'), timeout=30) as resp:
                    ok += resp.status == 200
            except Exception:
                pass
        print(f'  {r["slug"][:42]:42s} {len(r["body"]):6d} chars, '
              f'{len(re.findall(r"<p[ >]", r["body"]))} paragraphs, {len(srcs)} photos ({ok} load)')


def main():
    args = set(sys.argv[1:])
    if '--undo' in args:
        undo()
    elif '--verify' in args:
        verify()
    else:
        restore(apply='--apply' in args)


if __name__ == '__main__':
    main()
