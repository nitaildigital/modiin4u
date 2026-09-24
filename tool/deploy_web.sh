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

echo "── building"
echo "   redirect: $AUTH_REDIRECT_URL"
flutter build web --release \
  --dart-define=AUTH_REDIRECT_URL="$AUTH_REDIRECT_URL"

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

# Read it directly: a value containing a # would be truncated by the shell.
get() { python3 -c "
import sys
for line in open('.env.local', encoding='utf-8'):
    line = line.rstrip('\n')
    if line.strip() and not line.lstrip().startswith('#'):
        k, _, v = line.partition('=')
        if k == sys.argv[1]:
            print(v); break
" "$1"; }

HOST=$(get DEPLOY_HOST)
USER=$(get DEPLOY_USER)
REMOTE_PATH=$(get DEPLOY_PATH)

if [ -z "$HOST" ] || [ -z "$USER" ] || [ -z "$REMOTE_PATH" ]; then
  echo "DEPLOY_HOST, DEPLOY_USER and DEPLOY_PATH must all be in .env.local" >&2
  exit 1
fi

RSYNC_FLAGS=(-az --delete --human-readable)
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
ssh "$USER@$HOST" "chown -R www-data:www-data '$REMOTE_PATH' && chmod -R a+rX '$REMOTE_PATH'"

echo "── done: https://app.modiin4u.co.il"
echo "   a browser holding the old service worker may need one hard reload"
