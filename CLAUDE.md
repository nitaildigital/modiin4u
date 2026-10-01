# Working on Modiin4u

Read **HANDOVER.md** first (where things stand, what is next), then
**README.md** (setup, layout, deploy). **PLAN.md** is the record of every
decision and why — when you make one, add it there in the same plain style.

## The client's rules — keep them

- **Never invent content.** Names, prices, dates, ratings, counts, reviews,
  hours, translations of legal text: from the database or not at all. If a
  design needs data the database lacks, leave it out and say so.
- **Accounts are the app's.** The website has no resident sign-up, favourites,
  RSVP, reviews or comments; `/login` exists for admins only.
- **The client runs the content from the panel** (`lib/features/admin/`), so
  anything the site shows must be editable there.
- **Removal in the panel is reversible** (cancel / expire / hide) — he asked for
  a trash, not permanent deletion.
- Hebrew and English both; maps are Google's (his choice).

## How to work here

- **Stay in scope.** Do what was asked; list other findings instead of fixing
  them unasked.
- **Verify in a browser or on a device** before calling anything done —
  `flutter analyze` is not a check. The website's phone layout is what a
  browser under 1100 px wide shows.
- **Git:** don't commit or push unless asked; propose the commands. Group
  commits by feature and keep each one compiling.
- **Secrets:** `.env.local` and the other ignored key files are read by
  scripts, never printed, never pasted into chat or commits.
- **The database is shared and holds the client's real content.** Test on rows
  you create and delete them after; open real rows but never save them.
  `tool/tmp_admin.py` makes and removes a temporary admin.
- Comments explain why, in plain prose; match the surrounding code.

## Things that have bitten us

- `web_*_screen.dart` is the desktop website (> 1100 px); `<name>_screen.dart`
  is the phone layout, used by the app and by narrow browsers.
- Asset folders in pubspec are not recursive — register each folder.
  flutter_svg ignores SVG filters.
- On the web the theme drops Material 3's line height and letter spacing so
  text measures as designed (`app_theme.dart`).
- The web Maps key is referrer-restricted to the site's addresses; locally the
  maps show pins without map tiles. Never put it in a mobile build.
- Never run `certbot --nginx` on the server; use `tool/enable_domain.sh`.
- Homebrew's `python3` has no Pillow — image scripts need
  `/Library/Frameworks/Python.framework/Versions/3.13/bin/python3`.
- Deploy: `AUTH_REDIRECT_URL=http://45.93.94.49/auth/callback tool/deploy_web.sh`.
- Figma file `4mO5MlsuSDY2E0A7JFqqQx`: web page `0:1`, mobile page `412:6567`.
  Figma asset URLs expire after 7 days — download what you use.
- With the Playwright MCP, open your own browser context for each check and
  close it; the viewport setting does not follow the window.
