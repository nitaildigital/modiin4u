# Modiin4u

The city app and website for Modi'in (מודיעין בשבילך): businesses and
restaurants, news, events, deals, real estate, a map, a step counter and the
municipality's services — plus the management panel the client runs the
content from. Flutter for the Android/iOS app and the website, Supabase for
everything behind them.

- **HANDOVER.md** — where things stand now and what is next. Start there.
- **PLAN.md** — the long record: every decision and why, day by day.
- **deploy/README.md** — the server (nginx, https, certificates).
- **CLAUDE.md** — the client's rules and the project's gotchas, which Claude
  Code reads on its own when opened in this repo.

## Stack

- Flutter 3.35.7 (stable), Dart 3; Riverpod for state, go_router for routes.
- Supabase (project `zbtgietqoxkglfxfocrb`): Postgres with row level security,
  auth, storage (`media` bucket), RPCs such as `active_banners()` and
  `is_admin()`.
- Maps: every map is Google's, through `lib/shared/widgets/app_map.dart` —
  `google_maps_flutter` in the app, and on the website `flutter_map` drawing
  Google's roadmap through the Map Tiles API. Without a key a map shows its
  background and pins; OpenStreetMap was removed (1 Oct).
- The website is the same Flutter code built for the web, served as static
  files by nginx on a Kamatera server.

## Getting started

1. `flutter pub get`
2. Get these files from Arvindra — they hold keys and are never committed:
   | File | What it holds |
   |---|---|
   | `.env.local` | Supabase URL, service-role key, access token and DB URL; Brevo SMTP; deploy host/user/path; Kamatera API; `GOOGLE_MAPS_WEB_KEY` |
   | `android/local.properties` | your `sdk.dir`/`flutter.sdk`, plus `MAPS_API_KEY` for the app's Google map |
   | `ios/Flutter/Maps.xcconfig` | `MAPS_API_KEY=…` for iOS |
   | `~/.ssh/modiin4u_deploy` | the SSH key the deploy uses (root@45.93.94.49) |
   The app's public Supabase URL and anon key are in
   `lib/core/supabase/supabase_config.dart` (public by design; RLS protects the
   data). Never print or commit the others.
3. Run it:
   - **Android:** `flutter run -d <device>` (`flutter devices` lists them).
   - **iOS:** `flutter run -d <device>`; signing needs the client's Apple
     developer team (pending).
   - **Web:** `flutter run -d chrome`. Below 1100 px wide the website shows the
     phone layout; above it, the `web_*` desktop screens. Locally the maps show
     no map tiles, only pins: the web Maps key only works from the site's
     addresses.
   - **Admin panel:** `/admin` on the web build. An admin is a row in
     `admin_users`; `tool/tmp_admin.py --create` makes a temporary one for
     testing, `--delete` removes it.

## How the code is laid out

```
lib/
  core/        router (app_router.dart), theme, Supabase config, providers
  shared/      widgets and providers used across features
               web_chrome.dart   the website's navbar, footer, gutters, language
               web_*_menu.dart   share and contact menus; web_map_tiles.dart maps
               app_side_menu.dart the app's ☰ menu
  features/<feature>/
    models/ providers/ repositories/
    screens/   <name>_screen.dart  the phone layout (and web < 1100 px)
               web_<name>_screen.dart  the desktop website layout
    widgets/
  features/admin/  the management panel (web only; compiled out of the app)
supabase/migrations/  the schema, numbered; applied with tool/run_migrations.py
tool/        deploy, domain, imports and data scripts (each with --undo)
deploy/      nginx configuration, identical to the server
assets/web/  the website's images and icons; assets/icons/m_* the app's
```

## Deploying

- **Website:** `AUTH_REDIRECT_URL=http://45.93.94.49/auth/callback tool/deploy_web.sh`
  builds and uploads (`--build-only` to only build). It compiles the Google
  Maps key in from `.env.local`.
- **Domain:** once the client adds `app` A → 45.93.94.49, run
  `tool/enable_domain.sh`. Never run `certbot --nginx` (see deploy/README.md).
- **App stores:** not set up yet — release signing (`android/key.properties`)
  does not exist and the builds use the debug key; Apple access is pending.

## Data

- Migrations are numbered in `supabase/migrations/`; check PLAN.md for which
  are applied.
- Imports from the client's WordPress (`tool/import_*`, `tool/restore_*`) and
  the demo content (`tool/seed_sample_content.py`) each keep a registry and
  have `--undo`. **The demo content must be removed before launch:**
  `python3 tool/seed_sample_content.py --undo`.
- Homebrew's `python3` has no Pillow; the image scripts need
  `/Library/Frameworks/Python.framework/Versions/3.13/bin/python3` (or
  `pip install pillow`).

## House rules

- **Content comes from the database.** Never write names, prices, dates,
  ratings, counts, reviews or legal text into code; if the design needs data
  the database lacks, leave it out and ask.
- **Accounts are the app's.** The website has no resident sign-up, favourites,
  RSVP or reviews; `/login` is for admins.
- **Removal in the panel is reversible** (the client asked for a trash).
- **Test on your own rows.** On the database, create test rows, check them,
  delete them; open real rows but never save them.
- **Comments explain why,** in plain prose — the code already says what.
- **Check in a browser or on a device** before calling something done;
  `flutter analyze` alone is not a check.
