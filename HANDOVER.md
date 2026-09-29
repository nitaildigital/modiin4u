# Modiin4u — handover (29 September 2026)

For Harshit, taking over from Arvindra. PLAN.md is the long record of every
decision and why; this is the short map of where things stand and what is
next. Client: Nitai Levy.

## Where to look

| What | Where |
|---|---|
| Website (dev server) | http://45.93.94.49 |
| Same, over https (browser location works here) | https://45-93-94-49.sslip.io |
| Management panel | /admin on either address (admins are rows in `admin_users`) |
| Real domain | app.modiin4u.co.il — waits for one DNS record (below) |
| Repo | branch `feat/live-data` |
| Figma | file `4mO5MlsuSDY2E0A7JFqqQx` — web page `0:1`, mobile page `412:6567` |
| Secrets | `.env.local` (gitignored): Supabase URL/service key/access token/DB, Brevo SMTP, deploy host/user/path, Kamatera API, `GOOGLE_MAPS_WEB_KEY`. Never print or commit them. |
| Deploy key | `~/.ssh/modiin4u_deploy` → root@45.93.94.49 |

## Access to hand over

Setup is in README.md. What Harshit needs from Arvindra, privately — none of
it is in git:

- **Files:** `.env.local`, `android/local.properties` (its `MAPS_API_KEY`),
  `ios/Flutter/Maps.xcconfig`, and the deploy SSH key `~/.ssh/modiin4u_deploy`.
- **Accounts:** the GitHub repo `nitaildigital/modiin4u` (push access; the
  current remote pushes as `arv-gts-020`); the Supabase project
  `zbtgietqoxkglfxfocrb` (invite to the organisation); the Google Cloud project
  `modiin4u-509510` (IAM — it holds both Maps keys and billing); the Kamatera
  server; Brevo (SMTP for sign-up and reset mail); the Figma file.
- **The client's own:** uPress (DNS), the WordPress site, Apple developer and
  Google Play accounts — requested from him, not ours to share.

## How things run

- **Deploy the web:** `AUTH_REDIRECT_URL=http://45.93.94.49/auth/callback tool/deploy_web.sh`
  (`--build-only` to build without uploading). It compiles the Google Maps key
  in from `.env.local`; without it the maps fall back to OpenStreetMap.
- **Switch on the domain:** once `app` A → 45.93.94.49 exists at uPress, run
  `tool/enable_domain.sh`. Never `certbot --nginx` (it would move the bare IP's
  port 80). nginx config lives in `deploy/nginx/`, identical to the server.
- **Migrations:** `supabase/migrations/`, applied with `tool/run_migrations.py`.
- **Sample content:** the demo events, deals, listings, reviews, banners and
  neighbourhood photos come out with `python3 tool/seed_sample_content.py --undo`
  — **before launch**. Real imports (article bodies, professionals) have their
  own `--undo` and stay.
- **Python:** Homebrew's `python3` is first on PATH and has no Pillow; image
  scripts need `/Library/Frameworks/Python.framework/Versions/3.13/bin/python3`.
- **Testing the panel:** `tool/tmp_admin.py --create` makes a temporary
  super_admin (credentials in the system temp folder, never printed);
  `--delete` removes it. Test only on rows you create, delete everything
  after. A previous audit saved a real article by mistake — open real rows,
  never save them.
- **Release builds:** not set up. Android release signing
  (`android/key.properties` + keystore) does not exist yet; builds use the
  debug key. iOS signing needs the client's Apple team.

## Rules the client set (keep them)

- Accounts are **app-only**: the website has no resident sign-up, favourites,
  RSVP, reviews or comments. `/login` stays for admins.
- The client enters all content himself through the panel.
- Removal in the panel is **reversible** (cancel / expire / hide) — he asked for
  a trash, not permanent deletion.
- No invented content: no fake counts, reviews, hours or legal text. If the
  design needs data the database lacks, leave it out and ask.
- Maps: Google Maps (his choice). Languages: Hebrew and English.

## The client's handover points (29 Sep)

1. **Step counter** — "as I showed you a few days ago". Not specified in
   writing; ask him for the behaviour he showed. `lib/features/steps/`,
   challenges are managed in the panel (אתגרים, works).
2. **Category pages: the filter isn't working.** Not reproduced yet — ask which
   page (web or app, which category, which filter). Being looked at in today's
   mobile pass (businesses list).
3. **Mobile hamburger menu missing My Profile, Support, Step Counter.** In the
   app the ☰ on home went straight to /profile. The Figma "Side Menu" is being
   built today (see "Mobile" below).
4. **Municipality page — categories he can manage from the panel:**
   - Parking lots: every lot in the city, with location. There is a
     `parking` screen but no managed data source.
   - Shabbat: candle-lighting and Havdalah times for Modi'in from a calendar
     API (e.g. Hebcal). Today there is none — the old invented time was removed.
   - Parks: every park he enters, with photos, description and resident
     reviews, like a business page. Could reuse the business model (a "parks"
     category) or a new table; decide with him.
   All three need a table (or category) + panel screens + the app/web screens.

## Status

**Website** — rebuilt against every Figma web frame, all buttons audited and
fixed, Google map on, "near me" on https. Details in PLAN.md (28 Sep sections).

**Panel — verified on the deployed build (create/edit/reload/delete, 29 Sep):**
articles, businesses (incl. gallery, hours), categories, neighbourhoods, events,
deals, banners, home notice, listings, reviews. Users, analytics, challenges and
settings work.

**Panel — still broken (audit 29 Sep, file:line in the audit notes below):**
- *Everywhere:* `asyncData.whenData(...).value` in toolbars rethrows on a load
  error and greys the whole section until reload (33 places, 24 screens) — use
  `valueOrNull`. Many row actions are not awaited and fail silently.
- *Media (מדיה):* wrong columns (`filename`/`file_size` vs `file_name`/
  `size_bytes`), "upload" has no picker and inserts invented values, no
  thumbnails, only 500 of 516 rows. Deleting a media row also removes it from
  a business gallery — needs a warning. **Matters: galleries are public.**
- *Team (צוות ניהול):* reads/writes columns that don't exist; roles hard-coded;
  the active switch could lock the client out of his own panel.
- *Agreements, Revenue:* save/filters use wrong columns and enum values.
- *Comments, Reports:* RLS blocks admin updates (needs an admin policy);
  columns wrong; nothing on the site uses them yet.
- *Push:* writes wrong columns and marks "sent" without sending — there is no
  Firebase set-up; needs the client's Firebase keys.
- *Audit log:* nothing writes it; search errors. *Trash:* empty by design;
  "deleted after 30 days" is untrue. *Flags / remote config:* saved but read by
  nothing; no error handling. *Tags:* no effect anywhere.
- *Security:* `home_blocks` drafts are publicly readable —
  `home_blocks_read_all USING (true)` from `00014_rls_hardening.sql` overrides
  the published-only policy. Drop it for home_blocks.
- *Smaller:* replaced images stay in storage (shared `image_upload_field.dart`,
  11 call sites); events/offers menus have two items doing the same thing; every
  business save rewrites its menu rows; marking closed doesn't set `closed_at`.
- *Website side:* admin replies to reviews (`admin_response`) are saved but not
  shown on the business page — the label wording is the client's call.

**Mobile app** — being matched to the Figma mobile page today; see below.

## Waiting on the client

1. DNS at uPress: `app` A → 45.93.94.49 (then `tool/enable_domain.sh`).
2. If mail moves to an @modiin4u.co.il sender: Brevo's DKIM records, SPF
   include, a DMARC record.
3. Text for "About Us" and the "Accessibility Statement" (legally required in
   Israel); footer links open the help page until then.
4. Firebase keys (push), Apple developer access for signing.
5. The step counter behaviour; which category filter fails.
6. Wording for the review-reply label.

## Waiting on Arvindra's decisions

- Sample article `light-rail-update` had its date changed by a test on 28 Sep
  (2026-08-17 06:27:19.667537+00 → 2026-09-28): restore with approval.
- Keep or drop the navbar language button and "Powered by PersonaAI" (neither is
  in the design).
- The app's Google Maps key has no app restriction and was pasted in chat —
  restrict it to the Android/iOS apps or rotate it before launch.

## Mobile app (29 Sep)

Seven time-boxed passes against the Figma mobile page (412:6567), each on its
own files, checked at phone width in a web build (the phone layout is what a
browser under 1100 px shows) and by `flutter analyze` (61 issues, none new).
App-only screens — the side menu and the account screens — cannot be seen on
the web and need a device check.

- **Side menu (client's point 3).** `lib/shared/widgets/app_side_menu.dart`,
  opened from the ☰ on home in the app (the web keeps its own site menu):
  profile header with Edit, then Home, Favorites, Step Counter, My Apartments,
  Settings, Help & Support (added for the client; not in the frame), Logout.
  Signed out: a Sign In entry.
- **Home, Step Counter:** header, "Explore Modiin" shortcuts, cards to the
  frame. Step Counter's kcal/hours and "Walk Modiin" routes have no data.
- **Restaurants / businesses (client's point 2):** the phone category page had
  no filter at all and the Restaurants search/filter icons did nothing. The
  category page now has search and a Kosher/Delivery filter sheet (the same two
  the website has). Restaurant detail, lists, Businesses tiles, the category
  ("Bars") page and the map card to the frames. The website's category filter
  code looks right; if the client meant the website, check it in a browser.
- **Deals:** list and detail to the frames; Redeem keeps the claim flow. The
  old card printed the claim **code** where the badge goes — fixed. The heart on
  a deal saves its business (favourites have no "offer" kind).
- **Events:** list with category filter circles, detail with Organized by,
  What's Included, map and "You May Also Like"; RSVP restyled, same flow. Share
  and "View on Map" now work. RSVP is hidden on the phone-width website.
- **News, Municipal:** article bodies (WordPress HTML) render through the
  shared parser instead of printing tags; list and Municipal to the frames.
- **Real estate:** apartment detail, sale/rent lists, neighbourhood detail to
  the frames; the neighbourhood heart now saves; "Step X of 3" in Hebrew.
  (The mobile neighbourhood page shows one photo; the website already reads a
  neighbourhood gallery from `entity_media` — reuse `detail_providers.dart`.)
- **Account:** Profile, Settings, Help, Edit Profile, Sign In/Up, Change
  Password/Language, Terms, Favorites, Splash, Get Started restyled; every flow
  (sign-in, confirmation, reset, delete account, switches) kept. Profile keeps
  its account menu below the design's card.

**What the design shows with no data source** (leave out or build the data):
distance ("2.1 km away" — needs device location), view counts, resident photo
uploads with moderation, walking routes, steps kcal/hours, parks/schools counts
per neighbourhood, deal "valid days & hours", brand rewards, and on Municipal:
candle-lighting/Havdalah times, parking lots with locations and live
availability, and the eight service tiles (Shabbat & Holidays, Institutions,
Health, Education, Transportation, Emergency, Parks, Forms) — the client's
point 4.

**Checked on an Android phone (29 Sep, signed out, Hebrew):** home, the ☰
side menu with all its rows, Step Counter and Help & Support open from it.
Not yet on a device: signed-in Profile/Settings/Edit Profile, the account
screens' English, iPhone.

**Not yet done: a side-by-side check against the frames.** The website was
compared page by page with its Figma frames; the mobile screens were built from
Figma's design data and assets, but each pass had 45 minutes and nobody has yet
laid a device screenshot beside its frame. Expect small spacing and size
differences. `get_screenshot` on a frame beside
`adb exec-out screencap -p > shot.png` (Android) is the quickest way.

**Loose ends:** the Step Counter's back arrow points the wrong way in Hebrew
(Help's is right); a few new UI strings are inline (English/Hebrew) rather than
in the ARB files; events on the home cards show no category (the website gets
it from `eventCategoriesByEventProvider`); no mobile filter screen for real
estate; the Events map view frame (604:5832) was not done.
