# Deploying the web build

The admin panel and the resident web app are the same Flutter web build.
There is no backend here: the browser talks to Supabase directly, so the
server's whole job is to hand out static files.

Nothing in this folder has been run against a server yet.

## What you need first

| | |
|---|---|
| Server | Kamatera, 1 vCPU / 1GB / 20GB SSD, Ubuntu 22.04 LTS, **Israel (Tel Aviv)** region |
| DNS | An `A` record at **uPress**, not Kamatera — `app` → the server's IP |
| Supabase | `https://app.modiin4u.co.il/auth/callback` added to the redirect allow-list |

The DNS point matters: `modiin4u.co.il` uses `ns1.upress.io`, so the record
goes in uPress's panel. Kamatera has no say in it.

## One-time setup on the server

```bash
# as root
apt update && apt install -y nginx rsync certbot python3-certbot-nginx

mkdir -p /var/www/modiin4u
chown -R www-data:www-data /var/www/modiin4u

# the site config from this repo
cp deploy/nginx/app.modiin4u.co.il.conf /etc/nginx/sites-available/
ln -s /etc/nginx/sites-available/app.modiin4u.co.il.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
```

Then, **once the DNS record has propagated** — certbot proves ownership over
port 80, so it fails if the name does not resolve to this machine yet:

```bash
certbot --nginx -d app.modiin4u.co.il
```

That rewrites the site config to add the TLS block and installs a renewal
timer. Check it with `systemctl status certbot.timer`.

## Deploying

Put the server in `.env.local` (which is gitignored):

```
DEPLOY_HOST=<the IP>
DEPLOY_USER=root
DEPLOY_PATH=/var/www/modiin4u
```

Then:

```bash
tool/deploy_web.sh --dry-run   # see what would change
tool/deploy_web.sh             # build and upload
```

## Things that will bite

**The auth callback needs real paths.** `lib/main.dart` calls
`usePathUrlStrategy()`, so the app's URLs are `/admin`, not `/#/admin`. That
is required for `https://app.modiin4u.co.il/auth/callback` to work at all —
with hash routing the browser would fetch that path, get `index.html`, and
the app would then read an empty hash and open the home screen instead of
the callback. Someone confirming their address would see the home page with
no word that it had worked.

It also means nginx must serve `index.html` for any path it has no file for.
That is the `try_files` line in the site config. Remove it and every route
except `/` returns 404 on refresh.

**The redirect URL is compiled in.** It is a `--dart-define` at build time,
not something the server sets. `tool/deploy_web.sh` passes the default; to
use a different address, set `AUTH_REDIRECT_URL` before running it — and add
that address to Supabase's allow-list too, or the link in the e-mail is
refused.

**index.html and the service worker must not be cached.** They are excluded
in the site config. Cache them and a deploy does not reach anyone until
their cache expires. Even so, a browser holding the old service worker may
need one hard reload after a deploy.

**`rsync --delete` is deliberate.** A file dropped from a build is dropped
from the server, so an old `main.dart.js` cannot linger and be served.

**Brotli is not configured.** It compresses this kind of payload better than
gzip, but it needs a module Ubuntu's nginx does not ship
(`libnginx-mod-http-brotli` on some builds, otherwise a rebuild). gzip is on
and is enough to start with.

## Open question

The web build contains **the whole app** — every resident screen as well as
the admin panel, because the admin area is gated on `kIsWeb` rather than
built separately. So `app.modiin4u.co.il` serves both. If that subdomain is
meant to be the admin panel only, that needs a separate build flag and is
not done.
