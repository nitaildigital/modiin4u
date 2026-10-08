#!/usr/bin/env bash
# Builds the public website (site/, Next.js) and puts it on the server.
#
#   tool/deploy_site.sh              # build and upload, restart the service
#   tool/deploy_site.sh --build-only
#   tool/deploy_site.sh --live       # from launch: business statistics on
#
# The browser keys for Google's map tiles and Places (GOOGLE_MAPS_WEB_KEY,
# GOOGLE_PLACES_WEB_KEY in .env.local) are compiled into the page; they are
# restricted in Google Cloud to the site's addresses. SEO_LIVE is not set
# here: it lives on the server, in /etc/modiin4u-site.env, from launch.
#
# Reads DEPLOY_HOST and DEPLOY_USER from .env.local, like deploy_web.sh.
set -euo pipefail
cd "$(dirname "$0")/.."

get() {
  python3 -c "
import sys
for line in open('.env.local', encoding='utf-8'):
    line = line.rstrip('\n')
    if line.strip() and not line.lstrip().startswith('#'):
        k, _, v = line.partition('=')
        if k == sys.argv[1]:
            print(v.strip()); break
" "$1"
}

BUILD_ONLY=false
STATS=0
for arg in "$@"; do
  case "$arg" in
    --build-only) BUILD_ONLY=true ;;
    # The live site, from launch: count business views and clicks. Before it
    # every visit is a test and must not land in the client's statistics.
    --live) STATS=1 ;;
  esac
done

echo "── building site/"
# Read here, at the repo root, where .env.local is — not inside site/.
MAPS_KEY=$(get GOOGLE_MAPS_WEB_KEY)
PLACES_KEY=$(get GOOGLE_PLACES_WEB_KEY)
[ -n "$MAPS_KEY" ] || { echo "GOOGLE_MAPS_WEB_KEY is not in .env.local" >&2; exit 1; }
(cd site && NEXT_PUBLIC_RECORD_STATS=$STATS NEXT_PUBLIC_MAPS_WEB_KEY="$MAPS_KEY" \
  NEXT_PUBLIC_PLACES_WEB_KEY="$PLACES_KEY" npm run build)

# The standalone server, with its static files and public/ beside it.
OUT=site/.next/standalone
cp -R site/.next/static "$OUT/.next/static"
cp -R site/public "$OUT/public"
echo "   $(du -sh "$OUT" | cut -f1) to upload"
$BUILD_ONLY && { echo "── built only, server untouched"; exit 0; }

HOST=$(get DEPLOY_HOST); USR=$(get DEPLOY_USER)
echo "── uploading to $USR@$HOST:/srv/modiin4u-site"
rsync -az --delete "$OUT/" "$USR@$HOST:/srv/modiin4u-site/"
ssh "$USR@$HOST" "chown -R www-data:www-data /srv/modiin4u-site && systemctl restart modiin4u-site && sleep 2 && systemctl is-active modiin4u-site"
echo "── done"
