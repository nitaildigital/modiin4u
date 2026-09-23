# Modiin4u — Implementation Plan

Working plan for connecting the app to the live backend. Internal document —
not for the client.

- **Branch:** `feat/live-data`
- **Supabase project:** `zbtgietqoxkglfxfocrb` (client's org, PRO, marked PRODUCTION)
- **Last updated:** 23 September 2026

---

## 1. Where we are

| Component | State |
|---|---|
| Mobile app | 44 screens built. News list now on live data; everything else still on content packed inside the build. |
| Website | 17 screens built, reading a frozen JSON export in `assets/data/`. Not deployed anywhere. |
| Backend | Live. 51 tables deployed. Demo seed loaded (`seed_remote.sql`). Real site content **not** loaded. |
| Auth | None. `profiles` = 0 rows, `admin_users` = 0 rows. |
| Admin area | 23 sections built, no entry point from the app, not on live data. |

### Live table row counts

Tables with data: `admin_role_permissions` 102, `categories` 29, `businesses` 20,
`articles` 10, `neighborhoods` 10, `tags` 10, `home_blocks` 10, `events` 9,
`admin_roles` 8, `ad_placements` 8, `feature_flags` 8, `point_rules` 8.

Everything else is 0 — including `profiles`, `admin_users`, `business_hours`,
`reviews`, `media`, `offers`, `favorites`, `daily_steps`.

---

## 2. Blocked — request these now

These unblock whole phases, so they should be chased in parallel with Phase A.

| Needed | Unblocks | Priority |
|---|---|---|
| Supabase **service role key** or database password | RLS fix, loading real content, creating the first admin user | **Highest** — Phase B is entirely blocked |
| Google Maps API key + billing enabled | Map provider swap, proximity features | Medium |
| Persona AI API details and credentials | Chat on the home search bar | Medium |
| Apple account access | Signing certificates, release builds | Requested |

With the anon key we can **read** everything but **write** nothing.

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
- [ ] **A5** Business detail on live data
- [ ] **A6** Restaurants — filtered from `businesses` by category rather than a
      separate hard-coded list
- [ ] **A7** Events list and detail
- [ ] **A8** Home screen rows — popular businesses, deals, events, news
- [ ] **A9** Search across businesses, articles and events, server side
- [ ] **A10** Map pins from `businesses` (`latitude` / `longitude` are already
      populated)
- [ ] **A11** Fix the inactive controls, the `מסעדות` route pointing at
      `/businesses`, the deals overflow, the home status bar overlap and the
      sign-in keyboard overlay
- [ ] **A12** Loading, error and empty states across the app — largely falls out
      of the provider pattern

---

## 4. Phase B — needs the service role key

- [ ] **B1** Close the RLS hole — `businesses` and `articles` currently accept
      writes from the anon key, which ships inside every build
- [ ] **B2** Load the real site content: 200 businesses, 659 articles,
      professionals and property listings, and around 980 images into storage,
      replacing the demo seed
- [ ] **B3** Create the first admin user and verify `is_admin()` resolves
- [ ] **B4** Populate `entity_categories` — it is empty, so no business is
      linked to any category. 15 business categories and 20 businesses exist,
      but nothing joins them, which leaves every category count at zero and
      every category filter empty. The content load must write these links.

---

## 5. Phase C — authentication

- [ ] **C1** Email sign-in with a one-time code, session persistence, password
      reset, profile row on first sign-in
- [ ] **C2** **Account deletion** — client priority, and required by both Apple
      and Google for any app that allows account creation
- [ ] **C3** Favourites actually saving (`favorites` table)
- [ ] **C4** Admin area entry point, behind a role check

---

## 6. Phase D — needs client keys

- [ ] **D1** Google Maps in place of the current open-source map; location
      permission; distance and "near you"
- [ ] **D2** Persona AI chat on the home search bar, including the conversation
      screen, which does not exist in the design set

---

## 7. Phase E — admin panel on live data

- [ ] **E1** **Notifications and access** — client priority. The screens
      (`admin_push_screen.dart`, `admin_team_screen.dart`) and the tables
      (`push_campaigns`, `push_automations`, `admin_roles`,
      `admin_role_permissions`, `admin_users`) already exist
- [ ] **E2** Businesses and articles: create, edit, publish, delete, media library
- [ ] **E3** The remaining 21 sections

---

## 8. Phase F — language, quality, release

- [ ] **F1** Hebrew and English across every screen with an app-wide switch;
      32 mobile screens are currently English-only while the app is locked to
      Hebrew RTL
- [ ] **F2** Device and browser testing, analytics, performance
- [ ] **F3** Signed release builds, store listings, submission

---

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
