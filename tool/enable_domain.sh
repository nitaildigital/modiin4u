#!/usr/bin/env bash
#
# Switches on https for one of the site's names, once that name reaches the
# server.
#
# Browsers keep some things to secure pages. The one this app needs is the
# visitor's location, for "businesses near me": on http://45.93.94.49 the
# browser refuses without asking. So each name the site is reached by gets
# https, with a certificate from Let's Encrypt.
#
#   tool/enable_domain.sh                        # app.modiin4u.co.il
#   tool/enable_domain.sh 45-93-94-49.sslip.io   # the interim address
#
# Let's Encrypt proves we control a name by fetching a file from it over
# port 80, so this can only work once the name points here. For
# app.modiin4u.co.il that means the client adding an A record at uPress —
# `app` → the server's IP — which we have no access to do. Until then this
# stops at the first check, says so, and changes nothing. It checks before it
# asks Let's Encrypt, not after, because failed attempts count against Let's
# Encrypt's limits (a handful per name per hour) and a name that does not
# resolve here can only fail.
#
# In order:
#   1. the name's A record, on two public resolvers, is exactly the server's
#      IP, and it has no AAAA record (Let's Encrypt tries IPv6 first when
#      there is one, and this server has no IPv6 address)
#   2. deploy/nginx is on the server — a file that differs is backed up
#      under /root first — then `nginx -t` and a reload
#   3. a test file put where certbot puts its own comes back over http from
#      the name: the same path Let's Encrypt will take
#   4. `certbot certonly --webroot` for the name. An existing certificate
#      that is not near expiry is kept; certbot.timer renews it and reloads
#      nginx
#   5. deploy/nginx/https-<name>.conf linked into sites-enabled — https for
#      the name, and its http sent there — `nginx -t` (the link is removed
#      again if that fails) and a reload
#   6. checked from here: a trusted certificate and a 200 on https, a deep
#      link answered with the app, http redirected, http://<IP> unchanged
#
# Safe to run again: unchanged files are left alone, a valid certificate is
# kept, an enabled name stays enabled, and the checks run every time.
#
# Why certonly --webroot rather than `certbot --nginx`: see the top of
# deploy/nginx/app.modiin4u.co.il.conf. In short, the nginx plugin rewrites
# the site config and would take plain http away from the bare IP.
#
# Reads the server from .env.local, like tool/deploy_web.sh:
#
#   DEPLOY_HOST=203.0.113.10
#   DEPLOY_USER=root
#   DEPLOY_SSH_KEY=~/.ssh/modiin4u_deploy   # optional, same fallback
#
set -euo pipefail

cd "$(dirname "$0")/.."

NAME=app.modiin4u.co.il
for arg in "$@"; do
  case "$arg" in
    -*) echo "unknown option: $arg" >&2; exit 2 ;;
    *)  NAME="$arg" ;;
  esac
done

SITE_CONF="https-$NAME.conf"
if [ ! -f "deploy/nginx/$SITE_CONF" ]; then
  echo "no deploy/nginx/$SITE_CONF — a name needs its https block written" >&2
  echo "before it can be switched on (copy https-app.modiin4u.co.il.conf)." >&2
  exit 2
fi

# Where certbot puts its proof files. Outside the site's folder, which every
# deploy rsyncs with --delete; nginx serves it for /.well-known/acme-challenge/.
WEBROOT=/var/www/letsencrypt

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

if [ ! -f .env.local ]; then
  echo "no .env.local — cannot find the server. See the header of this file." >&2
  exit 1
fi

SERVER=$(get DEPLOY_HOST)
SSH_USER=$(get DEPLOY_USER)
KEY=$(get DEPLOY_SSH_KEY)
KEY="${KEY/#\~/$HOME}"
if [ -z "$KEY" ] && [ -f "$HOME/.ssh/modiin4u_deploy" ]; then
  KEY="$HOME/.ssh/modiin4u_deploy"
fi
if [ -z "$SERVER" ] || [ -z "$SSH_USER" ]; then
  echo "DEPLOY_HOST and DEPLOY_USER must be in .env.local" >&2
  exit 1
fi

SSH_CMD=(ssh -o ConnectTimeout=15)
[ -n "$KEY" ] && SSH_CMD=(ssh -i "$KEY" -o IdentitiesOnly=yes -o ConnectTimeout=15)
remote() { "${SSH_CMD[@]}" "$SSH_USER@$SERVER" "$@"; }

# ─── 1. The name points here ───
echo "── 1. does $NAME point at $SERVER?"
if ! command -v dig >/dev/null; then
  echo "needs \`dig\` to look the name up (macOS has it; on Linux: dnsutils)" >&2
  exit 1
fi
for resolver in 1.1.1.1 8.8.8.8; do
  # +short follows a CNAME and prints it before the addresses; keep addresses.
  a=$(dig +short +time=5 +tries=2 @"$resolver" "$NAME" A \
        | grep -E '^[0-9]+(\.[0-9]+){3}$' | sort -u | tr '\n' ' ' | sed 's/ $//' || true)
  aaaa=$(dig +short +time=5 +tries=2 @"$resolver" "$NAME" AAAA \
        | grep ':' | sort -u | tr '\n' ' ' | sed 's/ $//' || true)
  echo "   $resolver: A ${a:-none}${aaaa:+, AAAA $aaaa}"
  if [ "$a" != "$SERVER" ]; then
    echo >&2
    echo "$NAME does not point at this server (yet), so Let's Encrypt could" >&2
    echo "not check it. Nothing has been changed. It needs exactly one A record:" >&2
    echo >&2
    echo "    $NAME.   A   $SERVER" >&2
    if [ "$NAME" = app.modiin4u.co.il ]; then
      echo >&2
      echo "That is the client's to add, in uPress's DNS panel for modiin4u.co.il" >&2
      echo "(the domain's nameservers are ns1/ns2.upress.io): name \`app\`, type A," >&2
      echo "value $SERVER. The records for modiin4u.co.il and www stay as they are." >&2
      echo "Resolvers may remember \"no such name\" for up to half an hour after" >&2
      echo "the record is added; run this again after that." >&2
    fi
    exit 1
  fi
  if [ -n "$aaaa" ]; then
    echo >&2
    echo "$NAME also has an AAAA (IPv6) record: $aaaa. This server has no IPv6" >&2
    echo "address, and Let's Encrypt tries IPv6 first, so it would fail. The" >&2
    echo "AAAA record for $NAME needs removing. Nothing has been changed." >&2
    exit 1
  fi
done

# ─── 2. The nginx files ───
echo "── 2. nginx files from deploy/nginx"
STAGE=/root/modiin4u-nginx-incoming
remote "rm -rf '$STAGE' && mkdir -p '$STAGE'"
rsync -a --delete -e "${SSH_CMD[*]}" deploy/nginx/ "$SSH_USER@$SERVER:$STAGE/"

# Each file that differs from what is installed is backed up under /root,
# replaced, and put back if `nginx -t` then fails. Files that match are left
# alone, so a second run changes nothing here.
remote bash -s -- "$STAGE" "$WEBROOT" <<'REMOTE'
set -euo pipefail
STAGE=$1 WEBROOT=$2
TS=$(date +%Y%m%d%H%M%S)
changed=()   # "installed-path|backup-path" (backup empty for a new file)

put() {
  local src=$1 dst=$2 bak=""
  if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
    echo "   unchanged  $dst"
    return 0
  fi
  if [ -f "$dst" ]; then
    bak="/root/$(basename "$dst").bak-$TS"
    cp -p "$dst" "$bak"
    echo "   backed up  $dst → $bak"
  fi
  install -m 644 "$src" "$dst"
  echo "   installed  $dst"
  changed+=("$dst|$bak")
}

put "$STAGE/snippets/modiin4u-site.conf" /etc/nginx/snippets/modiin4u-site.conf
for f in "$STAGE"/*.conf; do
  put "$f" "/etc/nginx/sites-available/$(basename "$f")"
done
rm -rf "$STAGE"

if [ ! -e /etc/nginx/sites-enabled/app.modiin4u.co.il.conf ]; then
  ln -s /etc/nginx/sites-available/app.modiin4u.co.il.conf /etc/nginx/sites-enabled/
  echo "   enabled    app.modiin4u.co.il.conf"
  changed+=("/etc/nginx/sites-enabled/app.modiin4u.co.il.conf|")
fi

install -d -m 755 "$WEBROOT/.well-known/acme-challenge"

if [ ${#changed[@]} -eq 0 ]; then
  exit 0
fi
if out=$(nginx -t 2>&1); then
  echo "$out" | sed 's/^/   /'
  systemctl reload nginx
  echo "   nginx reloaded"
else
  echo "$out" | sed 's/^/   /' >&2
  echo "   nginx -t failed — putting the previous files back" >&2
  for c in "${changed[@]}"; do
    dst=${c%%|*} bak=${c#*|}
    if [ -n "$bak" ]; then cp -p "$bak" "$dst"; else rm -f "$dst"; fi
  done
  nginx -t >/dev/null 2>&1 && echo "   restored; nginx was not reloaded" >&2
  exit 1
fi
REMOTE

# ─── 3. Let's Encrypt's path works ───
#
# Pinned to the server's IP: step 1 has shown public DNS gives that IP, and
# this machine's own resolver may still remember the name as missing.
echo "── 3. can http://$NAME/.well-known/acme-challenge/ be read from outside?"
TOKEN="modiin4u-check-$(date +%s)-$RANDOM"
remote "echo '$TOKEN' > '$WEBROOT/.well-known/acme-challenge/$TOKEN' && chmod 644 '$WEBROOT/.well-known/acme-challenge/$TOKEN'"
got=$(curl -s --max-time 15 --resolve "$NAME:80:$SERVER" \
        "http://$NAME/.well-known/acme-challenge/$TOKEN" || true)
remote "rm -f '$WEBROOT/.well-known/acme-challenge/$TOKEN'"
if [ "$got" != "$TOKEN" ]; then
  echo "   the test file did not come back (got: ${got:0:80}). Let's Encrypt would" >&2
  echo "   fail the same way, so it has not been asked. Is port 80 open?" >&2
  exit 1
fi
echo "   yes"

# ─── 4. The certificate ───
echo "── 4. certificate for $NAME"
# --keep-until-expiring: a second run neither asks Let's Encrypt again nor
# replaces a certificate that is not near expiry. The deploy hook is saved
# with the certificate and runs after each renewal, so nginx picks it up.
remote "certbot certonly --webroot -w '$WEBROOT' -d '$NAME' --cert-name '$NAME' \
  --non-interactive --agree-tos --register-unsafely-without-email \
  --keep-until-expiring --deploy-hook 'systemctl reload nginx'" 2>&1 | sed 's/^/   /'

# ─── 5. https on ───
echo "── 5. https for $NAME"
remote bash -s -- "$NAME" "$SITE_CONF" <<'REMOTE'
set -euo pipefail
NAME=$1 SITE_CONF=$2
AVAILABLE=/etc/nginx/sites-available/$SITE_CONF
ENABLED=/etc/nginx/sites-enabled/$SITE_CONF
if [ ! -f "/etc/letsencrypt/live/$NAME/fullchain.pem" ]; then
  echo "   no certificate in /etc/letsencrypt/live/$NAME — not enabling" >&2
  exit 1
fi
if [ -L "$ENABLED" ]; then
  echo "   already enabled"
  exit 0
fi
ln -s "$AVAILABLE" "$ENABLED"
if out=$(nginx -t 2>&1); then
  echo "$out" | sed 's/^/   /'
  systemctl reload nginx
  echo "   enabled $SITE_CONF, nginx reloaded"
else
  echo "$out" | sed 's/^/   /' >&2
  rm -f "$ENABLED"
  echo "   nginx -t failed — link removed, nginx not reloaded" >&2
  exit 1
fi
REMOTE

# ─── 6. Check it from here ───
echo "── 6. checking from here"
PIN=(--resolve "$NAME:443:$SERVER" --resolve "$NAME:80:$SERVER")
FAILED=false
check() {  # description, expected, actual
  if [ "$2" = "$3" ]; then
    echo "   ok      $1"
  else
    echo "   FAILED  $1 — expected '$2', got '$3'" >&2
    FAILED=true
  fi
}

# curl refuses an untrusted or mismatched certificate, so a 200 here means
# the certificate is good as well as the page.
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "${PIN[@]}" "https://$NAME/" || true)
check "https://$NAME/ with a trusted certificate" 200 "$code"

echo "$(echo | openssl s_client -connect "$SERVER:443" -servername "$NAME" 2>/dev/null \
  | openssl x509 -noout -subject -issuer -enddate 2>/dev/null | sed 's/^/           /')"

body=$(curl -s --max-time 20 "${PIN[@]}" "https://$NAME/deals" || true)
if echo "$body" | grep -q flutter_bootstrap.js; then served=app; else served=other; fi
check "https://$NAME/deals answered with the app (index.html)" app "$served"

redirect=$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' --max-time 20 "${PIN[@]}" \
  "http://$NAME/deals" || true)
check "http://$NAME/deals sent to https" "301 https://$NAME/deals" "$redirect"

code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "http://$SERVER/" || true)
check "http://$SERVER/ still plain http" 200 "$code"

if [ "$FAILED" = true ]; then
  exit 1
fi
echo "── done: https://$NAME/"
