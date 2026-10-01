#!/usr/bin/env bash
# Builds the Android app with its Google Places key.
#
# The car park page fetches Google's details for a car park (hours, rating,
# photos) with the Android Places key from .env.local
# (GOOGLE_PLACES_ANDROID_KEY). That key is restricted in Google Cloud to the
# app's package and signing certificate, and Google checks both on every
# request, so the certificate's SHA-1 is compiled in too: the debug
# keystore's by default, or the release one's with ANDROID_CERT_SHA1 set.
#
#   tool/build_android.sh              # debug APK
#   tool/build_android.sh --release    # release APK
#
# The website's Maps key is never used here (CLAUDE.md).
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

MODE=debug
[ "${1:-}" = "--release" ] && MODE=release

CERT="${ANDROID_CERT_SHA1:-}"
if [ -z "$CERT" ]; then
  CERT=$(keytool -list -v -keystore "$HOME/.android/debug.keystore" \
    -alias androiddebugkey -storepass android -keypass android 2>/dev/null \
    | sed -n 's/.*SHA1: //p' | head -1)
fi

flutter build apk --"$MODE" \
  --dart-define=PLACES_ANDROID_KEY="$(get GOOGLE_PLACES_ANDROID_KEY)" \
  --dart-define=PLACES_ANDROID_CERT="$CERT"
