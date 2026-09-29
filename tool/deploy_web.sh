#!/usr/bin/env bash
#
# Builds the web app and copies it to the server.
#
# The build is static: nginx hands out files, and everything the app does
# goes straight to Supabase from the browser. So a deploy is a build and an
# rsync, with nothing to restart.
#
#   tool/deploy_web.sh              # build and upload
#   tool/deploy_web.sh --build-only # build, do not touch the server
#   tool/deploy_web.sh --dry-run    # show what rsync would change
#
# Reads the server from .env.local so no address or user is written down in
# the repository:
#
#   DEPLOY_HOST=203.0.113.10
#   DEPLOY_USER=root
#   DEPLOY_PATH=/var/www/modiin4u
#   DEPLOY_SSH_KEY=~/.ssh/modiin4u_deploy   # optional; see below
#
# The server takes a key of its own rather than the one `ssh` reaches for by
# default, and offering the wrong key looks exactly like having no access:
# "Permission denied (publickey,password)". If DEPLOY_SSH_KEY is not set this
# falls back to ~/.ssh/modiin4u_deploy when that file exists, which is where
# the deploy key was put.
#
set -euo pipefail

cd "$(dirname "$0")/.."

BUILD_ONLY=false
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --build-only) BUILD_ONLY=true ;;
    --dry-run)    DRY_RUN=true ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

# ─── Where the confirmation e-mail sends people back to ───
#
# Compiled in, so it has to be right at build time rather than set on the
# server. It must also be listed in Supabase's redirect allow-list, or the
# link in the e-mail is refused.
AUTH_REDIRECT_URL="${AUTH_REDIRECT_URL:-https://app.modiin4u.co.il/auth/callback}"

# Read .env.local directly: a value containing a # would be truncated by the
# shell. Empty when the file or the name is missing.
get() {
  [ -f .env.local ] || return 0
  python3 -c "
import sys
for line in open('.env.local', encoding='utf-8'):
    line = line.rstrip('\n')
    if line.strip() and not line.lstrip().startswith('#'):
        k, _, v = line.partition('=')
        if k == sys.argv[1]:
            print(v); break
" "$1"
}

# ─── The website's maps ───
#
# GOOGLE_MAPS_WEB_KEY is a browser key for the Map Tiles API, restricted to
# the site's addresses (see lib/shared/widgets/web_map_tiles.dart). Compiled
# into the page, where any Maps key on a website can be read; its referrer
# restriction is what protects it. Without it the maps draw OpenStreetMap.
MAPS_WEB_KEY=$(get GOOGLE_MAPS_WEB_KEY)

echo "── building"
echo "   redirect: $AUTH_REDIRECT_URL"
if [ -n "$MAPS_WEB_KEY" ]; then
  echo "   maps: Google (key from .env.local)"
else
  echo "   maps: OpenStreetMap — no GOOGLE_MAPS_WEB_KEY in .env.local"
fi
flutter build web --release \
  --dart-define=AUTH_REDIRECT_URL="$AUTH_REDIRECT_URL" \
  --dart-define=MAPS_WEB_KEY="$MAPS_WEB_KEY"

SIZE=$(du -sh build/web | cut -f1)
echo "   build/web is $SIZE (nginx serves it gzipped, so the transfer is far less)"

if [ "$BUILD_ONLY" = true ]; then
  echo "── built only, server untouched"
  exit 0
fi

# ─── The server ───
if [ ! -f .env.local ]; then
  echo "no .env.local — cannot find the server. See the header of this file." >&2
  exit 1
fi

HOST=$(get DEPLOY_HOST)
USER=$(get DEPLOY_USER)
REMOTE_PATH=$(get DEPLOY_PATH)
KEY=$(get DEPLOY_SSH_KEY)
KEY="${KEY/#\~/$HOME}"
if [ -z "$KEY" ] && [ -f "$HOME/.ssh/modiin4u_deploy" ]; then
  KEY="$HOME/.ssh/modiin4u_deploy"
fi

# IdentitiesOnly so the agent does not offer every other key first; a server
# that has seen too many refusals closes the connection before reaching this
# one.
SSH_CMD=(ssh)
[ -n "$KEY" ] && SSH_CMD=(ssh -i "$KEY" -o IdentitiesOnly=yes)

if [ -z "$HOST" ] || [ -z "$USER" ] || [ -z "$REMOTE_PATH" ]; then
  echo "DEPLOY_HOST, DEPLOY_USER and DEPLOY_PATH must all be in .env.local" >&2
  exit 1
fi

RSYNC_FLAGS=(-az --delete --human-readable -e "${SSH_CMD[*]}")
$DRY_RUN && RSYNC_FLAGS+=(--dry-run --itemize-changes)

echo "── uploading to $USER@$HOST:$REMOTE_PATH"
# --delete so a file removed from a build is removed from the server too;
# without it, an old main.dart.js can sit there being served from a cache.
rsync "${RSYNC_FLAGS[@]}" build/web/ "$USER@$HOST:$REMOTE_PATH/"

if [ "$DRY_RUN" = true ]; then
  echo "── dry run, nothing written"
  exit 0
fi

# nginx reads from disk on each request, so there is nothing to reload — but
# the permissions have to let it.
"${SSH_CMD[@]}" "$USER@$HOST" "chown -R www-data:www-data '$REMOTE_PATH' && chmod -R a+rX '$REMOTE_PATH'"

echo "── done: http://$HOST/"
echo "   the domain answers here too once its A record exists"
echo "   a browser holding the old service worker may need one hard reload"
