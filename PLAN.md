# Modiin4u — Implementation Plan

Working plan for connecting the app to the live backend. Internal document —
not for the client.

- **Branch:** `feat/live-data`
- **Supabase project:** `zbtgietqoxkglfxfocrb` (client's org, PRO, marked PRODUCTION)
- **Last updated:** 24 September 2026

---

## 1. Where we are

| Component | State |
|---|---|
| Mobile app | 44 screens built. News, businesses, restaurants, events, map, search and sign-in are on live data. Deals, real estate, steps, community and games still carry content packed inside the build. |
| Website | 17 screens built, reading a frozen JSON export in `assets/data/`. Not deployed anywhere. |
| Backend | Live. 51 tables deployed. Real site content loaded — 220 businesses, 669 articles, 71 tags. Two migrations written and **not yet run**: `00014` (security) and `00015` (sign-in). |
| Auth | Wired to Supabase — email code, session restore, profile row, account deletion. Waiting on two dashboard settings (C1b) before a resident can actually sign in. `profiles` = 0 rows, `admin_users` = 0 rows. |
| Admin area | 23 sections built, no entry point from the app, not on live data. |

### Live table row counts

`articles` 669, `businesses` 220, `admin_role_permissions` 102, `tags` 71,
`categories` 29, `events` 10, `neighborhoods` 10, `home_blocks` 10,
`admin_roles` 8, `ad_placements` 8, `feature_flags` 8, `point_rules` 8.

Everything else is 0 — including `profiles`, `admin_users`, `business_hours`,
`reviews`, `media`, `offers`, `favorites`, `daily_steps`.

---

## 1b. How the app is meant to work

Written down because the plan below only makes sense against it.

**Two kinds of account**, chosen at sign-up:

| | |
|---|---|
| **Regular user** (`resident`) | A resident. Browses, saves favourites, posts an apartment of their own, counts steps. |
| **Real estate broker** (`broker`) | Lists property professionally. Same app, and the listing is marked as coming from an agent. |

The choice is carried in the account's metadata as `is_broker` and lands on
`listings.is_broker`, which is what the card means when it says a listing came
through an agent rather than from the person who lives there.

**What a resident can create.** Only property: `/add-apartment` and
`/new-listing` write to `listings`, and `/my-apartments` lists what they
posted. Row level security ties each listing to `owner_id`, so someone edits
their own and nobody else's.

**What a resident cannot create.** A business. `businesses.owner_id` exists
and nothing in the app writes it — there is no "claim my shop" flow, and the
client enters every business from the panel. That matches his answer: he
manages the directory himself.

**Who manages everything else.** The client, from the control centre — the
directory, the news, categories, offers, events, and the property listings
residents post.

**The chain, end to end**

```
sign up  →  confirm the address  →  signed in
                                      │
                  ┌───────────────────┼───────────────────┐
             save favourites     post an apartment    count steps
                                      │
                             appears in the property
                             section and on the map
                                      │
                          client reviews it in the panel
```

Every step after "signed in" needs the session to be real. That is why the
authentication work below is first: nothing downstream of it can be finished,
or even tested, until it holds.

---

## 2. Blocked — request these now

These unblock whole phases, so they should be chased in parallel with Phase A.

| Needed | Unblocks | Priority |
|---|---|---|
| ~~Supabase **service role key**~~ | Received. Content is loaded; the key should be rotated, since it was shared in chat | Done |
| Google Maps API key + billing enabled | Map provider swap, proximity features | Medium |
| Persona AI API details and credentials | Chat on the home search bar | Medium |
| Apple account access | Signing certificates, release builds | Requested |

With the anon key we can **read** everything but **write** nothing.

### Blocking gap — real estate has no table

The schema has 50 tables and not one of them holds a property, listing or
apartment. The app meanwhile carries nine real-estate routes, including one of
the five bottom-navigation tabs, plus `/listing/:id`, `/new-listing`,
`/my-apartments`, `/add-apartment`, `/realestate-map`, `/neighborhood/:id`,
`/apartments-sale` and `/apartments-rent`, and the site export contains four
apartments and four agents.

So the whole real-estate section cannot be put on live data, and the client
cannot manage properties from the admin panel, until a table is designed and
added. This needs raising before the section is promised as working.

### Open questions for the client

- "Manage notifications" — does this mean sending push campaigns from the admin
  area, or users controlling their own notification preferences? Likely the
  former, given it was paired with "access".
- Does the WordPress site stay, or does the new build replace it? If it stays,
  content has two homes and needs a sync story.
- Where does the web build get deployed? `modiin4u.co.il` is taken by WordPress,
  and the Flutter web build renders through CanvasKit, which search engines do
  not read the way they read the current site.

---

## 3. Phase A — unblocked, in progress

Everything here works with the anon key alone. This is the largest single chunk
and it transforms how the app behaves.

- [x] **A1** News list on live data — featured hero plus the rest, Hebrew dates,
      loading / error / empty states, pull to refresh
- [x] **A2** Article detail on live data — hero, real view count, body,
      working share, related articles
- [x] **A3** Business model, repository and providers; real categories on the
      Businesses screen. Counts stay hidden until `entity_categories` is
      populated (B4)
- [x] **A4** Business list screen at `/businesses/category/:id` and
      `/businesses/all`; the category cards now navigate instead of doing
      nothing
- [x] **A5** Business detail on live data — name, description, rating, address,
      kosher certification, contact actions. Buttons with nothing to open are
      dimmed rather than inert, and the open/closed tag and distance stay hidden
      until there are hours and a device location to work from
- [x] **A5b-1** **Reviews are no longer invented.** The page carried four
      made-up reviews under made-up names — Daniel Cohen, Maya Levi and two
      others — attached to a real, named restaurant, in two separate places,
      beside a summary reading 4.6 with a rating distribution while the line
      under it said "based on 0 reviews". Anyone reading it would have taken
      them for real customers of a real business. Both lists now read the
      `reviews` table and share one widget, the summary is derived from the
      rows rather than written in, and a business with none shows an empty
      state. Verified on the device
- [x] **A5b-2** The join was ambiguous and failed at runtime, showing an error
      where the empty state belonged: `reviews` has two foreign keys into
      `profiles` — the author and whoever replied — so it has to name which
      one it means. The same shape as the `neighborhoods` join on businesses
- [x] **A5b-3** **Opening hours were invented for every business.** The page
      stated Mon-Sat 12:00-9:30 and closed Sunday for all 220 of them — hours
      a resident would act on and turn up to a shut shop. Two faults stacked:
      `Business.hours` existed, the repository already joined `business_hours`
      and `isOpenNow` was built on it, but the screen ignored all of that and
      drew a fixed block; and the table has no rows anyway. It reads the real
      field now, in Hebrew, and the section hides when there are none
- [x] **A5b-4** The Photos tab drew ten coloured squares — a "Business
      Gallery" and "Pictures from our Users", the same ten for every business.
      Replaced with an empty state until `media` has rows
- [x] **A5b-5** Two headings named a business that was not on screen:
      "Reviews for Shipudey Hatikva" and "Have you visited Shipudey Hatikva?"
      appeared on every business page. They use the real name now
- [ ] **A5b** The Menu tab is still hard-coded — there is no menu table in
      the schema at all. Raise it with the client
- [x] **A6** Restaurants comes from the database: the cuisine row is the
      sub-categories of "restaurants", and each section names a category by
      slug rather than carrying its own list. A best-rated row replaces the
      "lunch nearby" one, which needs a device location the app cannot ask
      for yet. Sections with nothing in them are hidden rather than shown
      empty
- [x] **A7** Events list and detail on live data, with Hebrew date badges.
      The RSVP button still only flips local state — saving it needs auth (C3)
- [x] **A8** Home screen — the businesses, events and news rows come from the
      database and their cards now open the matching detail page instead of
      doing nothing. Each row loads independently, so one slow table does not
      hold up the page
- [x] **A7b** "You may also like" on the event page listed four invented
      events — a Community Festival, a Family Fun Day, a Jazz Evening — under
      a real one, each linking to `/event/related_0`, a route that does not
      exist. It lists real events now, minus the one being read, and hides
      when there are none
- [x] **A7c** "What's Included" is gone. It listed live music, food and
      outdoor seating for every event; no column backs it
- [ ] **A8b** The deals row and the apartments row on Home are still
      hard-coded: `offers` has no rows, and there is no property table at all
      (see the blocking gap above)
- [x] **A9** Search runs against the database across businesses, events and
      news, with the filtering done server side rather than over a ten-entry
      list held in the screen
- [x] **A10** Map pins come from the database. The Businesses and Events
      layers are live — pins, their cards and the routes behind them. Parking
      and Real Estate stay empty because neither has a table
- [x] **A10b** The bottom navigation was sitting under the system navigation
      bar on a Redmi running Android 16, clipping the labels. `ShellScaffold`
      now pads by `MediaQuery.padding.bottom`
- [ ] **A11** Inactive controls and the home status bar overlap. What remains
      sits on screens that have no table behind them — professionals,
      community, deals — plus the dead `brand_header.dart`, which nothing
      renders
- [x] **A11h** Four more controls on live screens. The second share button on
      the business page did nothing while the first worked — both now send the
      same thing. "See More" sat under a full, unclipped paragraph; the text
      is clamped to four lines and the control only appears when something is
      actually hidden behind it. "Show all photos" opened nothing and is gone
      until there is a gallery. "View All" on each restaurant section now
      opens that category's full list — verified on the device
- [x] **A11f** The sign-in keyboard no longer covers the button. The
      photograph at the foot of the screen is 200px of decoration and that was
      exactly the room the button needed, so it stands down while someone is
      typing
- [x] **A11g** A third runtime overflow, again only visible in the device log:
      the type badge on the home business card carries the shop's own
      description, which runs longer than the placeholder did. It now takes
      what room is left and ellipsizes
- [x] **A11c** The `מסעדות` shortcut on the home screen opened `/businesses`;
      it opens `/restaurants` now
- [x] **A11d** Two runtime overflows fixed, both found by reading the device
      log rather than by static analysis. The deals row overflowed by two
      pixels; the text block under the image now takes the space left over.
      The restaurants row then overflowed by one, because real descriptions
      are longer than the placeholder strings were — the name and type lines
      are bounded to one line each, with headroom on the row
- [x] **A11e** The share controls on the business page do something
- [x] **A11a** Back button no longer leaves the app. `context.go` throws the
      whole stack away, and it was used for ten destinations that are not
      bottom-navigation tabs — so Home → Events → back landed on the phone's
      launcher. Added `context.goOrPush` in the router, which switches tab for
      the six shell destinations and pushes for everything else, and moved
      those call sites onto it
- [x] **A11b** Back from a tab other than Home now returns to Home instead of
      leaving the app, via a `PopScope` in `ShellScaffold`
- [x] **A13** Photography now renders everywhere. The cards were all drawing a
      gradient with a glyph on it, so even records that carry a photo looked
      empty. `lib/shared/widgets/network_photo.dart` wraps `CachedNetworkImage`
      with a 250ms fade and falls back to that same gradient at the same size,
      so a record with no picture looks deliberate and nothing shifts either
      way. Wired into the home business, event and news rows, the business
      cards, all three restaurant cards, the events list, the event hero, the
      map card and the search results. Coverage in the live data: businesses
      129/220, articles 642/669, events 0/10, categories 0/29 — so events and
      the cuisine tiles show the fallback until B5 fills them
- [x] **A13a** The restaurant card linked to `/business/restaurant_<hashCode>`,
      an id that does not exist; it uses the business id now

- [x] **A12** Loading, error and empty states across the app. The generic
      three-shape shimmer is gone; every screen now has a skeleton built to the
      geometry of the widget it stands in for — the same card widths, image
      sizes, line positions and corner radii — so nothing shifts when the
      content lands. Card chrome stays solid while only its contents shimmer,
      since a shimmering border reads as a glitch. Primitives live in
      `lib/shared/widgets/skeleton.dart`

---

## 4. Phase B — needs the service role key

- [ ] **B1** Close the RLS hole — `businesses` and `articles` currently accept
      writes from the anon key, which ships inside every build
- [x] **B2** The site export is loaded: 200 businesses and 659 articles, plus
      61 taxonomy terms as tags. Rows are keyed on the canonical link, so the
      loader can be run again to update rather than duplicate. Images are still
      served from modiin4u.co.il rather than from storage — see B5
- [ ] **B5a** Checked against the live site before assuming the import lost
      anything: it did not. `modiin4u.co.il` publishes 200 businesses and only
      128 of them carry a featured image, which matches the 129 in our table
      (one more comes from `og_image_url`). The site has no events post type at
      all — its content types are news, business, professionals, apartments and
      real-estate-agents — so the 10 events and 29 categories showing the
      fallback are rows we seeded ourselves and never gave a picture. The
      missing photography has to come from the client, not from a re-import
- [x] **B5a** **The web build cannot show a single business photograph, and
      this is why.** `modiin4u.co.il` sends no `Access-Control-Allow-Origin`
      header, so a browser refuses to load its images into the Flutter web
      app — the directory and the admin panel both come up blank. It only
      shows in a browser: on a phone there is no such rule, which is why
      months of testing on a device never surfaced it. Supabase storage sends
      `*`, so moving the files fixes it. Found by opening the admin panel in
      Chrome for the first time
- [x] **B5b** 908 files moved into the `media` bucket — 129 business covers,
      137 logos, 642 article images — and the records repointed.
      `tool/migrate_images.py` is idempotent: a URL already in storage is
      skipped, and one photograph used by two records is uploaded once and
      shared. Article filenames carry raw Hebrew, which an HTTP request cannot
      send, so the path is percent-encoded first
- [x] **B5c** 96 of the 220 business slugs were unusable — the import turned
      percent-encoded Hebrew into `d7-9e-d7-a2-…`, which the admin list showed
      under each business name. All 96 decoded back to Hebrew, no collisions.
      `tool/fix_slugs.py`, dry run by default
- [ ] **B5** Move the photography into Supabase storage. 129 of the 200
      businesses carry an image URL pointing at the WordPress site, so the app
      depends on that site staying up
- [ ] **B3** Create the first admin user and verify `is_admin()` resolves.
      Needs an email address to own it
- [ ] **B6** Decide what happens to the 20 demo businesses and 10 demo
      articles from the original seed. They sit alongside the real content now
- [x] **B4** `entity_categories` is populated: 210 links, so category counts
      and filters work. The 61 site terms are mapped to the curated categories
      by hand rather than by keyword — a first pass matched substrings and put
      every petrol station under shopping, because "חנות" sits inside
      "תחנות". 44 businesses carry no category; their terms are situational
      ("open during the war", "kosher for Passover") and stay as tags only

---

## 5. Phase C — authentication

- [x] **C1** Email sign-in with a one-time code. Sign-in was a local object
      that fabricated a person out of whatever was typed — any address and any
      password let you in, and it was forgotten on the next launch. It is now
      the real Supabase session: `AuthNotifier` listens to `onAuthStateChange`,
      restores the stored session on launch and reads the `profiles` row.
      Password fields are gone from both screens, because there is no password
      in this model. Sign-up carries the name into the account's metadata so
      the profile is created with it. Proven on the device end to end — the
      request reaches Supabase and its rate-limit reply comes back as a
      sentence a resident can read
- [x] **C1a** Migration `00015_auth_bootstrap.sql` — **not yet run.** Nothing
      ever created the `profiles` row, and `full_name` is NOT NULL, so the
      first thing a new account did was fail. Adds the trigger on
      `auth.users`, backfills anyone already there, and adds the missing
      INSERT policy
- [x] **C1c** **Corrected: sign-in follows the design.** It had been built as
      a one-time code, which the design does not have — `Sign In.png` shows a
      password field with "Remember Me" and "Forgot Password?", and
      `Sign Up.png` a password and a confirmation, plus a **Real Estate
      Broker** account type that had been dropped. All of it is back and
      matches. Change Password works, and verifies the current password by
      signing in with it first, because Supabase has no check of its own — a
      borrowed unlocked phone could otherwise change it without knowing it
- [ ] **C1b** Two dashboard settings, and no resident can sign in until both
      are done:
      **(a)** **Site URL** is still `http://localhost:3000`, so the
      confirmation link in the sign-up email goes nowhere;
      **(b)** **custom SMTP**, because the built-in sender allows a couple of
      messages an hour — the live test hit `over_email_send_rate_limit` on the
      second attempt
- [x] **C1d** Email confirmation handled properly. The link now lands on
      `/auth/callback`, a page in this same build that says the address is
      confirmed — a web address rather than the app's own scheme, because an
      email is often opened in a desktop browser where no app scheme exists,
      and a page works everywhere with no per-platform setup. The custom
      scheme stays registered on both platforms, so a link opened on the phone
      can be switched to it later without another release. Signing up also
      offers to send the confirmation again, since someone who loses the email
      is otherwise stuck — they cannot sign in, and signing up again with the
      same address is refused
- [x] **C1e** A password-reset link gets its own screen. It signs the person
      in, so without one the app would open as normal and the password they
      had forgotten would still be the one on the account
- [x] **C2** **Account deletion** — client priority, and required by both Apple
      and Google. The button existed and only signed out. It now calls
      `delete_own_account()`, which removes the `auth.users` row; the foreign
      keys already say what follows, so a listing or an article is detached
      and survives while the person's own reviews, comments, favourites and
      steps go with them. Confirmed twice before it runs
- [x] **C3** Favourites save to the `favorites` table. Every heart in the app
      was decoration — a white circle with nothing behind the tap — and the
      Favourites screen listed six invented rows. One `FavoriteButton` now
      backs all of them, so the same heart appears filled wherever the item
      turns up. The saved keys are held as a single set rather than a query
      per card, since a list of twenty businesses would otherwise be twenty
      round trips to colour twenty hearts; the write is optimistic and reverts
      if it fails. Wired into the home business and event cards, the events
      list, the event hero, both restaurant cards, the business page and the
      Favourites screen itself
- [x] **C3a** The Favourites screen reads the saved rows back out of their own
      tables — one query per kind, and a kind with nothing saved is not
      queried. Real photographs, real ratings, Hebrew dates, and filter chips
      that match what can actually be saved: Bars and Apartments are gone,
      because a bar is a business like any other and there is no property
      table to save from
- [ ] **C3b** Verified as far as it can be without a session: tapping a heart
      while signed out offers sign-in rather than doing nothing, and that
      button opens the sign-in screen. The saved state itself cannot be
      exercised until C1b is done
- [x] **C4** Admin area entry point, behind a role check. `/admin` was an
      ordinary route with nothing in front of it, so anyone who typed the path
      opened the whole control centre — and there was no way in from the app
      at all, so the client could not reach it either. `AdminGate` now asks who
      is there first, and an administrator gets a "Control Center" row in the
      profile menu that a resident never sees. Admin status is resolved through
      the same `is_admin()` the row level security policies use, so the screen
      and the database cannot disagree about who is one
- [x] **C4a** Three tests in `test/admin_gate_test.dart` pin the boundary — a
      resident turned away, an administrator let through, and the gate waiting
      rather than deciding while the session is still being restored. Written
      as tests because this cannot be exercised on a device until C1b is done

---

## 6. Phase D — needs client keys

- [x] **D1** Google Maps on the main map screen, on the client's key. The
      pins are the same ones the app drew before — Google takes bitmaps for
      markers rather than widgets, so the white disc, the coloured inner
      circle and the glyph are drawn to an image and cached per pin, and the
      design is unchanged. Verified on the device: real Google tiles, our
      pins, tap selects and opens the card, and the map pans so the card does
      not cover the pin
- [x] **D1a** The key is **not in git.** Android reads it from
      `local.properties` through a manifest placeholder, iOS from a gitignored
      `Flutter/Maps.xcconfig` by way of Info.plist. Confirmed by unzipping the
      built APK: the key is in the packaged manifest, the placeholder is
      resolved, and nothing tracked contains it. A build without the key still
      compiles — only the map stays blank
- [x] **D1b** Billing is working. The map draws normally, with no "for
      development purposes only" watermark, which is what an unbilled project
      renders
- [ ] **D1c** Three further map screens — restaurants, events and real estate
      — plus the small map on the event page are still on `flutter_map`, so
      they draw open-source tiles. They work; they just do not match. The
      package stays until they are moved
- [ ] **D1d** Location itself: `geolocator` is added and the permissions are
      declared, but nothing asks for it yet. "Near you" and distance need it,
      and it should be gated on the Access switch from E1a
- [ ] **D1e** Before release, one key per platform. A key carries only one
      application restriction — Android, iOS or referrer — so a single shared
      key cannot be locked down. Also rotate this one: it was pasted in chat
- [ ] **D2** Persona AI chat on the home search bar, including the conversation
      screen, which does not exist in the design set

---

## 7. Phase E — admin panel on live data

- [x] **E1a** The person's own half of **notifications and access**, which is
      what the client's phrasing points at: the four notification switches were
      held in the widget and forgotten the moment the screen closed. They write
      to the profile now, behind a master switch — with notifications off the
      topics below dim, because they cannot apply. A new Access section
      exposes the `location_enabled` and `health_enabled` columns that were
      already on `profiles` and had nothing driving them. Signed out, the
      switches dim and say why rather than pretending to remember. Four
      switches flipped quickly are four state changes and one write, not four
      writes racing each other to the same row
- [x] **E1b** Migration `00016_notification_preferences.sql` — **not yet run.**
      Adds the four topic columns to `profiles` and a `device_tokens` table:
      there was nowhere to record a device, so a push campaign had no one to
      send to. Booleans rather than one jsonb column, so an audience can be
      narrowed with an ordinary indexed WHERE
- [ ] **E1c** Actual delivery — Firebase/APNs credentials, registering the
      token on sign-in, and the admin side that composes a campaign. Blocked
      the same way Google Maps is: it needs keys from the client
- [ ] **E1** **Notifications and access** — client priority. The screens
      (`admin_push_screen.dart`, `admin_team_screen.dart`) and the tables
      (`push_campaigns`, `push_automations`, `admin_roles`,
      `admin_role_permissions`, `admin_users`) already exist
- [x] **E2** Businesses and articles: create, edit, publish, delete, with
      image upload to the `media` bucket. Businesses gained an opening-hours
      tab with a fill-the-week shortcut and a category picker
- [x] **E3** Twenty-one of twenty-three sections on live data. Fifteen were
      the same four operations against invented rows, so that shape is written
      once in `AdminTableNotifier`. The two left are `flags`, which has no
      table, and `data`, which is only the dashboard's aggregates
- [x] **E4** The control centre is web only. All 23 of its screens had been
      compiled into the mobile app that goes to Play

---

## 8. Phase F — language, quality, release

- [x] **F1a** The groundwork for both languages: ARB files, a locale kept on
      the device so it holds before anyone signs in, and the switch. Sign-in,
      settings and the language screen are translated. The language screen had
      offered eight languages, six of which did not exist and did nothing when
      chosen
- [ ] **F1** The remaining strings — roughly a thousand across the mobile
      screens, in the same shape as the ones already done;
      32 mobile screens are currently English-only while the app is locked to
      Hebrew RTL
- [x] **F2a** The admin panel opened in a browser for the first time, at
      desktop width. It renders as intended — sidebar, tabs, live list reading
      "220 עסקים" — and two faults showed that a phone cannot show: the
      images (B5a) and the slugs (B5c)
- [x] **F2b** Sign-in, sign-up and reset stretched their fields across the
      whole window on a desktop browser. They were drawn for a phone and
      never constrained. All three now hold to 430px and centre
- [ ] **F2c** Flutter's service worker caches the whole bundle, so a
      deployment can leave someone on the previous version until they clear
      it. Worth settling before the first deploy to Kamatera
- [ ] **F2** Device and browser testing, analytics, performance
- [ ] **F3** Signed release builds, store listings, submission

---

## 8b. Performance

- [x] **Fonts are bundled.** The app was downloading 1.6 MB of Rubik, Inter and
      Nunito over the network on first launch, because 1,937 `GoogleFonts.*`
      calls had nothing to resolve against locally. Text rendered in a fallback
      until the files landed, then re-rendered. The eleven weights actually used
      now sit in `assets/google_fonts/`, named the way the package looks them up
      (`Family-Variant.ttf`, not a weight number), and
      `GoogleFonts.config.allowRuntimeFetching = false` in `main.dart` keeps it
      that way. Verified: a fresh install downloads nothing.
- [x] **Home screen rebuilds are scoped.** Each row is a `_ProviderRow` widget
      that watches its own provider, so one table changing no longer rebuilds
      the whole page.
- [x] **Text styles no longer go through google_fonts.** All 1,937
      `GoogleFonts.rubik|inter|nunito(...)` calls across 94 files became
      `TextStyle(fontFamily: AppFonts.x, ...)`. The package resolved the family
      and built a style on every call, and those calls sit in `build` methods
      that run every frame. The families are declared in `pubspec.yaml`, so
      `fontFamily` resolves directly and nothing imports `google_fonts` any
      more. This also dropped the profile APK from 132 MB to 116 MB, because
      the font files were being bundled twice.
- [x] **Home scrolls lazily.** It was a `Column` inside a
      `SingleChildScrollView`, so every section laid out whether or not it was
      on screen; it is a `ListView` now.
- [x] **Display refresh rate.** The handset runs at 90 Hz for every other app
      but was giving this one 60 Hz — `mActiveModeId=1` with the app open,
      `mActiveModeId=2` on the launcher. ColorOS leaves an app at 60 Hz unless
      it asks, so `MainActivity` now requests the fastest mode, before
      `super.onCreate` so the engine reads the new rate at start-up.
- [x] **Release builds work again.** R8 was failing on the Play Core classes
      the Flutter embedding references for deferred components, which this app
      does not use. Added `-dontwarn com.google.android.play.core.**` and the
      matching keeps to `proguard-rules.pro`. Release APK is 74.5 MB against
      116 MB for profile.
- [x] **Renderer.** Impeller and Skia measured within noise of each other on
      this device, so Impeller stays — it is where Flutter is heading.

### What the measurements said

A frame-timing probe on `SchedulerBinding.addTimingsCallback`, scrolling the
home screen in a release build at 90 Hz:

| | median |
|---|---|
| UI thread (build and layout) | **0.7 ms** |
| Raster thread (painting) | **16.6 ms** |
| Total | 27.1 ms, about 37 fps |

The UI thread is free — there is nothing left to win in Dart. The raster cost
is identical on the home screen and on a plain list, under Impeller and under
Skia, in profile and in release, which makes it a fixed per-frame cost rather
than anything in the widget tree.

For context, the phone's own launcher reports 56% janky frames on the same
run. It is a 2019 mid-range handset at 30% battery.

**Confirmed on a second device.** The same release build, the same scroll,
measured on a Redmi running Android 16:

| Device | Frames over budget, same test |
|---|---|
| Realme XT, 2019, Snapdragon 712 | 381 |
| Redmi, Android 16 | 0 – 2 |

So the app scrolls smoothly on current hardware. The jank was the old handset,
not the widget tree — which the 0.7 ms UI thread already suggested. Nothing
further to do here; revisit only if a current device shows jank.
- [ ] Measure properly with DevTools in profile mode before doing more. Frame
      timing through `dumpsys gfxinfo` and SurfaceFlinger returned nothing
      usable on this handset, because Flutter renders to its own surface.

## 9. How the data layer is built

The pattern established in A1. Everything else follows it.

```
live table  →  model (fromJson)  →  repository  →  provider  →  screen
```

- **Model** — `lib/features/<feature>/models/`. `fromJson` maps the live table
  defensively: every field null-checked, dates parsed with a fallback.
- **Repository** — `lib/features/<feature>/repositories/`. Thin wrapper over
  `SupabaseConfig.client`, returns `List<Map<String, dynamic>>`.
- **Provider** — `lib/features/<feature>/providers/`. `FutureProvider` that maps
  rows to models. `FutureProvider.family` for by-id lookups.
- **Screen** — `ConsumerWidget`, `provider.when(loading:, error:, data:)`, with
  `ShimmerLoading`, `ErrorRetry` and `EmptyState` from `lib/shared/widgets/`.
  `RefreshIndicator` calling `ref.invalidate(...)`.

### Schema mismatches to watch for

The models in the repo were written against an imagined schema, not the live
one. Check every field against the live table before wiring a screen.

Found so far in `Article`:

| Model expected | Live table has |
|---|---|
| `image_url` | `featured_image`, `mobile_image`, `og_image` |
| `author` (required String) | `author_id` (uuid, currently null) |
| `category` | no column — categories come through `entity_categories` |
| `related_business_ids` | a separate `article_businesses` table |

Found in `Business`:

| Model expected | Live table has |
|---|---|
| `category` | no column — via `entity_categories` |
| `neighborhood` (String) | `neighborhood_id` (uuid), joined as an object |
| `description` | `short_description`, `full_description` |
| `image_url` | `cover_url`, `og_image_url` |
| `kosher_status` | `kosher_level` |
| `has_outdoor_seating` | `has_outdoor` |
| `hours` inline | separate `business_hours` table |

`Review` has not been checked yet.

### Verifying a change

Build and drive the app on a real handset rather than trusting a green analyze:

```bash
flutter run -d <device>
adb shell input tap <x> <y>
adb exec-out screencap -p > shot.png
```

Read the runtime log for exceptions — a `RenderFlex overflowed` only ever shows
up there, never in static analysis.
