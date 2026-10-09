#!/usr/bin/env bash
# Builds the iPhone app with its Google Places key, as build_android.sh
# does for Android.
#
# The car park page fetches Google's details for a car park (hours, rating,
# photos) with the iOS Places key from .env.local (GOOGLE_PLACES_IOS_KEY),
# restricted in Google Cloud to the app's bundle ID, which the app sends
# with each request (google_place.dart). An Xcode archive alone compiled
# none in, and the details were silently left out of iPhone builds.
#
#   tool/build_ios.sh            # release IPA for App Store Connect
#   tool/build_ios.sh --debug    # debug build for a connected iPhone
#
# Flutter keeps these values in ios/Flutter/Generated.xcconfig, so an
# archive made in Xcode right after this script has the key too. Signing
# needs the client's Apple team in Xcode. The website's keys are never used
# here (CLAUDE.md).
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

KEY="$(get GOOGLE_PLACES_IOS_KEY)"
if [ -z "$KEY" ]; then
  echo "GOOGLE_PLACES_IOS_KEY is missing from .env.local" >&2
  exit 1
fi

if [ "${1:-}" = "--debug" ]; then
  flutter build ios --debug --dart-define=PLACES_IOS_KEY="$KEY"
else
  flutter build ipa --release --dart-define=PLACES_IOS_KEY="$KEY"
fi
