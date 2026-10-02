# Modiin4u — handover (29 September 2026)

For Harshit, taking over from Arvindra. PLAN.md is the long record of every
decision and why; this is the short map of where things stand and what is
next. Client: Nitai Levy.

## The main goal, and the order

**Finish the app, the website and the panel — first what already exists, then
the new features.** In this order:

1. **Panel:** the sections still broken (listed under Status) and the
   `home_blocks` security fix. The client runs everything from the panel.
2. **Mobile:** compare each screen with its Figma frame on a device and fix
   the differences; check the signed-in screens (Profile, Settings, Edit
   Profile) and an iPhone.
3. **Loose ends** listed under Status and Mobile.
4. **New features the client asked for:** Shabbat times (smallest), the
   pedometer groups, parking lots, parks — see "The client's handover points".
5. **Launch:** the domain and https, removing the sample content, release
   signing, rotating the keys that were pasted in chat.

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
  in from `.env.local`; without it the maps show pins but no map tiles
  (OpenStreetMap was removed on 1 Oct).
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

1. **Step counter — groups.** His words: "there should be an option to create
   a group with people who have the app and invite them to it — for example,
   by sending them an invitation — and then view group stats/activity
   together. Quite similar to StepsApp." **Built 1 Oct** (health data,
   groups, invitation links, panel moderation) — see PLAN.md, "The step
   counter: health data, groups, and invitation links". The guide below was
   the plan it followed.
2. **Category pages: the filter isn't working — found and fixed (29 Sep).**
   Checked in a browser: the website's filters work (restaurants category
   page 54 → Kosher 46 → Delivery 35, matching the database; the restaurants
   listing's cuisine, kosher and delivery filters too). The failure was the
   **phone layout**, which he was using (the same visit reported the ☰ opening
   a sign-in, which only happened on a phone): its category page had no
   filter at all, and the Restaurants search and filter icons did nothing. The
   phone category page now has search and a Kosher/Delivery sheet; checked on
   the deployed site at phone width (54 → 46).
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
   How to build them is under "Guide: municipality" below.

## Guide: pedometer groups (client's point 1)

**What exists.** Steps come from the phone's sensor (`pedometer` package) and
are stored per person per day in `daily_steps (profile_id, date, steps)`
(migration 00011). Leaderboards read them through two SECURITY DEFINER
functions in 00022 (`steps_leaderboard_people`, `…_neighborhoods`), because
profiles are private — one resident may not read another's row. City
challenges are `challenges` / `challenge_participants`, managed in the panel.
The Step Counter screen is `lib/features/steps/` (app only; the website has
no accounts).

**What to build** (StepsApp-like groups):
- Tables: `step_groups (id, name, owner_id, invite_code unique, created_at)`
  and `step_group_members (group_id, profile_id, role, joined_at, unique)`.
  RLS: a member reads their groups and fellow members' names; only the owner
  renames, removes members or deletes; anyone may leave.
- **Inviting:** a link, not a people search — profiles are private, and a
  search would expose who uses the app. "Invite" opens the share sheet
  (WhatsApp etc.) with `https://app.modiin4u.co.il/join/<code>`; the app opens
  that link (Android App Links / iOS Universal Links, or a custom scheme first)
  and shows "Join <group>?". Someone without the app lands on the website,
  which can point to the stores. Push invitations would need Firebase (not set
  up).
- **Stats and activity:** a SECURITY DEFINER function
  `step_group_stats(group_id, from, to)` that first checks the caller is a
  member, then returns per member name, avatar, steps per day and totals —
  never raw profile rows. From it: the group's total, a ranking, a week chart,
  and an activity line ("Dana walked 12,400 today") derived from
  `daily_steps`, not stored separately.
- **Screens:** a Groups tab on Step Counter (my groups, create), a group page
  (ranking, chart, activity, invite, leave), and the join screen.
- **Check first** that steps are uploaded reliably: the sensor counts since
  boot, so the daily figure and a regular upload to `daily_steps` decide
  whether a group's numbers are right. The Access switch `health_enabled` on
  the profile is the resident's consent.
- Ask the client for the screens he showed from StepsApp; the Figma file has
  no group frames.

## Guide: municipality (client's point 4)

**What exists.** `lib/features/municipal/` — the Municipal page (restyled to
Figma 643:5751 on 29 Sep) with a Shabbat card, a Parking card and eight
service tiles, of which only Parking leads anywhere; a parking screen with no
managed data. Nothing in the panel manages any of it.

**Shabbat and holiday times — do first, no table needed.** Hebcal's API,
by coordinates so the city is exact:
`https://www.hebcal.com/shabbat?cfg=json&latitude=31.8969&longitude=35.0095&tzid=Asia/Jerusalem&M=on&lg=he`
(candle lighting, Havdalah, the parasha; `lg=s` for English). Holidays:
`https://www.hebcal.com/hebcal?v=1&cfg=json&maj=on&min=on&mod=on&...` with the
same location. Fetch in a provider, cache for the week, show on the Shabbat
card and the "Shabbat & Holidays" tile; credit Hebcal as its licence asks.
Never write a time into code — an invented "starts 18:42" was removed once.

**Parking lots — a table and a panel screen.** `parking_lots (name, name_en,
address, latitude, longitude, capacity, is_free, price_note, hours, notes,
image_url, is_active, sort_order)`, RLS: public reads active rows, admins
write. Panel: a "Municipality" section with the list and an editor (pick the
point on a map, as the events editor fills coordinates). App and website: the
parking screen lists them with a map. The design's "high availability" needs a
live source the city does not provide — leave it out.

**Parks — like a business page.** Photos, description and resident reviews
already exist for businesses (gallery in `entity_media`, reviews, map, panel
editor). The least work: file parks as businesses under a "Parks" category and
keep that category out of the business directory lists, or add a `kind` column
on businesses. A separate table would mean rebuilding the gallery, reviews and
editor. Decide with the client; reviews are written in the app (accounts).

**Service tiles.** A small `municipal_services (title_he, title_en, icon,
link or phone, sort_order, is_active)` table with a panel editor, so the
client decides which tiles appear and where they lead, instead of eight fixed
"coming soon" tiles.

## Status

**Website** — rebuilt against every Figma web frame, all buttons audited and
fixed, Google map on, "near me" on https. Details in PLAN.md (28 Sep sections).

**Panel — verified on the deployed build (create/edit/reload/delete, 29 Sep):**
articles, businesses (incl. gallery, hours), categories, neighbourhoods, events,
deals, banners, home notice, listings, reviews. Users, analytics, challenges and
settings work.

**Panel — fixed 29–30 Sep** (details in PLAN.md, "The panel, section by
section, and who may write what"; migrations 00031–00035). Every section loads
with no page error, checked as a temporary admin: error states with retry,
awaited actions, refused writes reported; media library, image clean-up,
business menus and `closed_at`; team, agreements, revenue, push, flags, tags on
their real columns; comments/reports moderation, the audit log, an honest
trash with Restore; `home_blocks` drafts private; column guards so residents
cannot approve their own content or change bans and points.

**Panel — still to do:**
- *Clicked through 1 Oct* (PLAN.md, "Small items"): info pages publish and
  unpublish, Team's self-guards, agents and challenges deactivate and
  reactivate. Not reachable without demoting a real admin: the
  last-super-admin guard (code read only).
- *Roles:* only a super admin can change the team or the roles (00042, 1
  Oct). What each other role may do section by section is the client's
  decision and is not built.
- *Fixed 1 Oct* (PLAN.md, "Panel bugs"): article and event edits now reach
  the audit log; removing a gallery photo checks `media_usage()` first; hours
  are saved in place; the businesses list is no longer cut at 500.
- *Municipal service tiles:* built 30 Sep — the panel's "מוסדות עירוניים" (`municipal_places`), parking ("חניונים") and parks (a business set to "פארק"); see PLAN.md.
- *Decisions:* media files and tags are deleted permanently (only when unused,
  after a warning) because neither table has a hidden flag; push sending is
  built (2 Oct, PLAN.md "Push notifications") and waits on the client's
  Firebase keys and migration 00045; nothing on the site creates comments or reports
  yet, so those queues stay empty.
- *Website side:* admin replies to reviews (`admin_response`) are saved but not
  shown on the business page yet (label chosen: "תגובת העסק" / "Response from
  the business").

**Mobile app** — being matched to the Figma mobile page today; see below.

## Waiting on the client

1. DNS at uPress: `app` A → 45.93.94.49 (then `tool/enable_domain.sh`).
2. If mail moves to an @modiin4u.co.il sender: Brevo's DKIM records, SPF
   include, a DMARC record.
3. Text for "About Us" and the "Accessibility Statement" (legally required in
   Israel); footer links open the help page until then.
4. Firebase keys (push), Apple developer access for signing and the APNs
   key. Then: `flutterfire configure`, the web config in
   `web/firebase-messaging-sw.js` and the VAPID key in
   `lib/core/push/push_config.dart`, migration 00045, and
   `tool/setup_push.py --service-account <key.json>`.
5. The step counter behaviour; which category filter fails.
6. Wording for the review-reply label.
7. Push conversions: does "converted" mean a call, directions or the website
   after opening the notification?

## Waiting on Arvindra's decisions

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
