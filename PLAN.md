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
| Mobile app | 44 screens built. News, businesses, restaurants, events, map, search, sign-in, favourites, settings, **real estate**, **deals** and **steps** are on live data. Community, games and the municipal services list still carry content packed inside the build. |
| Website | 17 screens built. The desktop layouts are reached through the same routes as mobile (>1100px), so they ship in the web build. Deployment assets are ready — see §1e — but no server exists yet. |
| Backend | Live. 58 tables deployed. Migrations `00014`–`00025` all applied. |
| Auth | Working end to end on a device: sign up, e-mail confirmation, sign in, password reset, profile row, account deletion. Blocked only on SMTP for the client's own first sign-in. |
| Admin area | 23 sections on live data, reachable from the app for an administrator (web build only). A moderation queue for resident-posted listings was added on 24 September. |

### The tables that are empty

Counted on 24 September. This is the single biggest thing standing between
the app and a demo, and it is content, not code.

`listings` 0 · `offers` 0 · `reviews` 0 · `challenges` 0 ·
`real_estate_agents` 0 · `business_hours` 0 · `business_menu_items` 0

Every one of those sections is built and reads its table. Each shows an
honest empty state. None of them can show anything until the client supplies
content — see §2.

### Live table row counts

`articles` 669, `businesses` 220, `entity_categories` 210,
`admin_role_permissions` 102, `tags` 71, `categories` 29, `events` 10,
`neighborhoods` 10, `home_blocks` 10, `admin_roles` 8, `ad_placements` 8,
`feature_flags` 8, `point_rules` 8, `profiles` 2.

Still empty: `offers`, `reviews`, `business_hours`, `listings`,
`real_estate_agents`, `challenges`, `daily_steps`, `games`, `media`,
`app_settings`, `campaigns`.

An empty table is not the same problem in each case. `listings` and `reviews`
are empty because nobody has posted one yet, which is correct. `offers`,
`challenges` and `business_hours` are empty because **nothing can create
them** — there is no admin form and no import — so the screens that read them
would show nothing even once wired.

---

## 1a. What is still made up

Audited 24 September by grepping every feature for database access and for
hardcoded lists, then fixing down the list. This is what the app *asserts*
that is not true, and what has been dealt with.

### Fixed this session

| Screen | What it was claiming | Now |
|---|---|---|
| **Real estate** (whole feature) | One invented flat — ₪3,650,000, agent "Zeev Schumacher" — on every listing page whatever the id; three invented Tel Aviv flats in My Apartments; a form whose fields had no controllers and whose Submit wrote nothing | On `listings`. Posting works, arrives `pending`, photographs upload |
| **Deals** (both screens) | Offers on shops that are not in Modiin — Nike, mCaffeine, "Urban Plate Kitchen & Bar" — with countdowns that were fixed strings; category counts of 62/48/31; eight "Upto 80% Off" tiles with nothing behind them | On `offers`. Claiming writes `offer_claims` and shows the real code |
| **Steps** | Three people who do not exist on a leaderboard — "Daniel Cohen", "Maya Levi", "Amit May" — plus a fabricated step count, streak, weekly chart, calorie figure and four walking routes | Reads the phone's pedometer, writes `daily_steps`; leaderboards from two SECURITY DEFINER functions, opt-in only |
| **Profile** | A "Real Estate Broker" badge on every resident; family status, pet and date of birth pre-filled with "Married", "Yes", "12 May 1990" and then discarded on save | Badge reads the real flag; the three fields save |
| **Municipal** | A fixed Shabbat date; a "High availability" parking claim; eight tiles that did nothing at all when tapped | Shabbat computed; parking claim removed; dead tiles greyed "coming soon" |
| **Business menus** | The Menu tab showed the same invented menu — hummus, lamb chops, Israeli beer — on all 220 businesses | `business_menu_items` (migration 00023); tab hidden when empty; admin editor gained a Menu tab |
| **Every sorted list** | `.order()` in postgrest-dart defaults to `ascending: false`. Seventeen calls relied on it meaning ascending, so categories, neighbourhoods, tags, events and admin lists were all in reverse | All seventeen made explicit |
| **Admin › real estate** | Creating a listing always failed — it wrote a column `type` that does not exist and a text `neighborhood` where the column is a foreign key, and never collected the NOT NULL `title`. Sale/let filters matched nothing. Rentals showed ₪0 | Fixed; adds approve / reject for the resident queue |

### Still to do

| Screen | What it shows now | Table | Blocker |
|---|---|---|---|
| **Games** | Placeholder screen | `games`, `game_sessions` | No content, and no admin form to create one |
| **Community** | Placeholder screen | `comments`, `reports` | Needs a product decision on what community *is* here |
| **Professionals** | Placeholder detail screen | `businesses` by category | Small — wire to the existing provider |
| **Business hours** | Nothing shown on a business page | `business_hours` | Table empty. The admin form exists (businesses › 2nd tab); needs the client to fill it, or an import |
| **Menus** | Tab hidden everywhere | `business_menu_items` | Table empty. The admin form now exists (businesses › Menu tab); needs the client to fill it |
| **Reviews** | Nothing shown | `reviews` | Table empty by nature — needs residents, and sign-in now works |
| **Web screens** (17) | A frozen JSON export in `assets/data/`, plus the hardcoded map pins | various | Separate track; not deployed anywhere yet |

### Translations

Roughly 400 hardcoded English strings remain on mobile screens, and ~600 more
on the `web_*` screens. Done so far: profile, edit profile, favourites,
change password, the whole real-estate feature, both deals screens, steps,
municipal. Biggest remaining: `business_detail_screen` (36),
`signup_screen` (27), `events_map_screen` (45), `restaurants_map_screen` (39).

## 1c. Design audit — 24 September

47 Figma exports in `~/Downloads/M4U/` compared screen by screen against the
code by six parallel read-only passes. Roughly 120 findings; grouped by cause
below, worst first. Nothing here has been fixed yet.

### A. Screens that are still entirely invented

These were never converted. Each shows the same fiction to every user.

| Screen | What it serves | File |
|---|---|---|
| **Real Estate tab** — the main one | 8 hardcoded flats. `listingsProvider` exists and this file imports nothing | `realestate/screens/realestate_screen.dart:55` |
| **Real-estate map** | 14 invented pins; every "View Full Details" pushes `/listing/1`, which cannot resolve | `realestate/screens/realestate_map_screen.dart:25` |
| **Neighbourhood detail** | Takes a `neighborhoodId` and never uses it — every neighbourhood renders as "Moriah" with invented counts | `realestate/screens/neighborhood_detail_screen.dart:39` |
| **Restaurants map** | 24 invented places; details push `/business/restaurant_<hashCode>` | `restaurants/screens/restaurants_map_screen.dart:45` |
| **Unearned ratings, on screen** | Business cards, restaurant cards and the business page all printed a gold star beside "0.0 (0)" — truthful, but it reads as a bad score rather than as no score. The restaurant card also carried "👁 0 Views", in English, against a column the table does not have | Reads "אין דירוג עדיין" until a review earns a score; the views figure is gone |
| **City map** | `/map` is one of five bottom-nav tabs. The desktop layout read a frozen WordPress export and, whenever that was empty, fell back to pins written into the source — "Cafe Greg", "Pizza Prego", four car parks, three apartments — each with a rating and review count nobody had given, each routing to `/business/demo_2` or `/listing/demo_0`, which match no row. The Events, Parking and Real Estate layers came from that list **always**, even after the export loaded. A generator then wrote a description for any pin lacking one: every property got the same paragraph about a "mini penthouse 6 rooms in Avni Chen, 140 m², balcony 18 m², payment schedule 20/80", every car park was declared open around the clock, and a business with no reviews was described as "rated - by 0 residents". "Property Type: Apartment" was printed for every listing whatever it was | Both layouts read `mapPoisProvider`: businesses, events and listings, all live, each pin opening its own row. The generator is gone — no description means no About section. Parking is dropped: there is no table and could not be one |
| **Community feed** | The worst of them. The screen opened with a feed written into the source: named residents holding conversations, a plumber and an electrician given as **real-looking telephone numbers** ("מוטי שרברב — 050-1234567"), a named restaurant recommended by a "resident" with a claim about its kashrut, and a pothole reported at a real street address with a note that the municipality had been told. Two composers offered to post; both wrote into a list held in the widget, so a post vanished on the next rebuild. Search and notification buttons had empty handlers | The feed is empty and says so — there is no `posts` table in the schema, so nothing can fill it. Both composers say the same rather than opening. The dead buttons are gone |
| **Events and Deals on the desktop layouts** | The same routes told a different story above 1100px. 16 invented events with venues, prices and interest counts; a "Load More" that re-showed the same pool as if it were new; category circles reading 157 / 32 / 24 / 45 / 15 / 41. The event detail page took an id and read nothing with it — every id rendered "Summer Music Night", the same two paragraphs, a five-line "What's Included", four coloured circles as attendee faces, an organiser named "Modiin Community Events" and a map pinned to one constant coordinate. Deals carried 8 offers on businesses that are not in Modiin, with discount badges, a "Residents Only" shield no column backs, and a countdown that was the literal string "2d : 14h" | All four on live providers. RSVP writes `event_attendees`; Save writes `favorites`; Share works; sort is a real menu over `start_date`. Category filters removed — `events` has no category column — while the Deals ones were wired, because `offer_categories` does back them. Counts are counted from rows in hand |
| **Admin dashboard** | It read four lists written into the source — six invented people, four businesses, four articles, three reviews — as `StateNotifier`s. So banning someone, approving a business or deleting a review **changed a list in memory and wrote nothing**. The client would have believed he had acted | On the live tables. `setBanned` writes `profiles.is_banned`; review moderation writes `reviews.status`, which migration 00025 then rolls into the business's rating. Businesses and articles use the live providers the panel's own sections already had. ~2,000 lines of dead widgets removed with it |
| **"Contact Us", everywhere on the web** | The header CTA on every web page had `onContactTap ?? () {}` — drawn on all of them, doing nothing. The footer published a phone, an e-mail and a WhatsApp number as plain text nobody could tap | The details are named once in `web_chrome.dart` and the header opens the e-mail. All three footer rows act. The address is `modiin4uoffice@gmail.com`, corroborated as the client's — it is the same account that owns the Kamatera server |
| **Two zero-counts on mobile** | Events printed "0 מתעניינים" on every row; the Deals banner sat under three page dots claiming it was one of three and could be paged, when it is a single box that does not scroll | Both gone |
| **Notifications** | The bell in the header opens this from every screen. It listed six notifications written into the source: a 20% offer from פיצה פרגו, a four-room property "matching your search" at ₪2,450,000 — with `listings` empty — fifty points awarded for a review nobody had written, roadworks on a named street, and a street-food festival tomorrow that told the reader **"you confirmed you were coming"**. The schema has `admin_notifications` and nothing for residents | Empty, and it says so. "Mark all as read" went with the list it was marking |
| **Help & Support** | Entirely hardcoded English, and two answers described screens that do not exist. One sent people to "Settings → Notifications" to toggle News, Deals, Neighbourhood Updates and Real Estate Alerts: Settings has no such row, nothing reads the `NotificationPreferences` model, and there is no preferences screen anywhere. Another listed the Favourites filters as Restaurants, Events, Bars, Apartments and News. "Contact Us" was an empty TODO | Translated, both languages. The notifications question is gone rather than answered wrongly; the Favourites answer names the real filters. Each remaining answer was checked against the screen it describes. Contact Us opens the address the footer publishes. A search with no match says so instead of leaving the page blank |
| **Professionals** | `/professional/:id` rendered the same invented person whatever id it carried: "יוסי רביבו", a plumber, 4.8 from 43 reviews, "available now", "replies within ~15 min", a 15 km service radius, six specialisms and two named reviews with quoted text. The feature was one orphan file — no list, no provider, no model, no table — and its only caller pushed `/professional/demo_$i` from a web screen | Screen and route deleted. A professional here is a business in a service category, which is what the web navbar's own "Professionals" link already pointed at |
| **Restaurant card "Contact"** | Empty handler, and drawn even for a business with no number on record | Dials the number, and is not drawn without one |
| **Events map** | 14 invented events; details push `/event/map_<hashCode>` | `events/screens/events_map_screen.dart:45` |
| **Home — "Deal Near You" / "Apartment Near You"** | Hardcoded tiles routing to `/deal/demo_0`, `/listing/demo_N` | `home/screens/home_screen.dart:390,455` |

### B. Invented values on screens that are otherwise live

- **Every event** is labelled "Music" (`event_detail_screen.dart:280`), attributed
  to "Modiin Community Events" (`:490`), pinned at one fixed coordinate
  (`:573`) while its real lat/long are parsed and ignored, and has a paragraph
  about "Summer Music Night" appended to its description (`:549`).
- **Shabbat candle-lighting** still prints `'Starts 18:42'`
  (`municipal_screen.dart:306`) — the same class of unknowable claim removed
  from the parking card the same day. Missed.
- **The challenge card** prints 82,450 / 150,000 / 55% regardless of the
  challenge (`steps_screen.dart:507`), now that a real one can exist.

### C. Controls that are drawn and do nothing

- **RSVP writes nothing.** `event_attendees` is untouched anywhere in `lib/`;
  the button is a local `setState` and the state is lost on re-entry.
  `event_detail_screen.dart:772`
- **Reviews, replies and photo uploads on a business are in-memory only** and
  show a success toast. `business_detail_screen.dart:1022, 1817, 783`
- **"Continue with Google"** is an empty TODO; no OAuth anywhere.
  `onboarding_screen.dart:150`
- **Sign-up discards** date of birth, family status and pet — the same bug
  fixed on Edit Profile, still present here. `signup_screen.dart:29` vs `:77`
- **Edit Profile discards an edited email** and never uploads the chosen
  avatar. `edit_profile_screen.dart:90`
- **Seven search fields are `Text`, not `TextField`** — restaurants, events,
  municipal, both maps, real estate, category lists.
- Hearts on browse and neighbourhood cards, the My Apartments kebab,
  "Contact Us", "View Challenge", "View on Map".

### D. Written screens nobody can reach

`/change-password`, `/change-language`, `/help-support`, `/terms` — all exist
and are routed; Settings links to none of them and opens hardcoded bottom
sheets instead. Also unreachable: `/events-map`, `/realestate-map`,
`/neighborhood/:id`, and the side menu has no Logout.

### E. Defects in the 24 September work itself

- Weekly chart Y-axis is a fixed `['12K'…'0']` while bars scale to the week's
  best day — bars do not line up with their own axis.
  `steps_screen.dart:444` vs `:402`
- Nearby-listing cards print "null m²", "4.0 Rooms", "Floor null".
  `listing_detail_screen.dart:1162`
- Nearby-listing cards ignore `coverUrl` and draw a gradient. `:1012`
- Municipal quick-info row is lopsided after the parking card changed.

### Correction to record

An earlier summary said the real-estate feature was "entirely on live data".
That was wrong. Three screens were converted — add apartment, my apartments,
listing detail. The main Real Estate tab, its map and neighbourhood detail
were not, and are listed in section A above.

---

## 1d. Fixed since the audit — 24 September

Worked through the audit in the order agreed: own defects first, then
controls that lie, then invented values, then whole screens. All verified on
a device against the live database, with every test row deleted afterwards.

| Area | Was | Now |
|---|---|---|
| **Own defects** | Step chart axis fixed at 12K while bars scaled; nearby cards printed "null m²" and "4.0 Rooms"; Shabbat card printed "Starts 18:42" every week | Axis follows the data on whole thousands; absent figures are left out; the lighting time is gone (no zmanim source) |
| **RSVP** | A local `setState`. Wrote nothing, forgot itself on re-entry, and the count beside it never moved | Writes `event_attendees`; migration 00024 keeps `rsvp_count` in step; state reads back; cancelling marks rather than deletes |
| **Reviews** | Inserted into a list held in memory, with "Review submitted! Thank you 🎉" | Writes `reviews` as `pending`; migration 00025 rolls an approved review into the business's rating |
| **78 business ratings** | "4.5 (87 reviews)" on businesses where `reviews` is empty — seeded with the import | Zeroed. Visible change; one revert if the figures are wanted for a demo |
| **Photo upload / reply** | Toasted success, wrote nothing | Removed — both need a product decision (moderation; and a resident reply has no home in the schema) |
| **Home rows** | "20% Off All Pizzas" and four invented flats, routing to `/deal/demo_N` and `/listing/demo_N` | On `offers` and `listings`; heading hides with the row when empty |
| **Real Estate tab** | 8 invented flats; dead search, dead chips, untappable cards, a button reading "Sign up with Email" | On `listings`; search, chips and tabs all filter; cards open; button opens the map |
| **Real-estate map** | 14 invented pins; "view details" pushed `/listing/1` | On `listings`; opens the right listing; pin is a house, not a person |
| **Listing detail map** | A flat pastel box with a faint glyph | A real map at the listing's coordinates; the button opens the phone's maps app |
| **Events list + map** | Search was a `Text`; pill read "Add to Calendar" with no handler; map served 14 invented events whose details pushed `/event/map_<hashCode>` | Search filters; pill opens the map; map reads `events` and opens the right one |
| **Event detail** | Every event labelled "Music", attributed to "Modiin Community Events", pinned at one fixed coordinate, with a "Summer Music Night" paragraph appended | All four gone; map uses the event's own coordinates |
| **Business menus** | The same invented menu on all 220 businesses | `business_menu_items` (00023); tab hidden when empty; admin editor added |
| **Sign-up** | Discarded date of birth, family status and pet; English form with two Hebrew fields; untappable terms links; "Business" contradicting its own subtitle | All saved; translated; links open `/terms`; reads "broker" |
| **Settings** | Four rows opened hardcoded bottom sheets while the real screens were reachable from nowhere | Opens change-password, change-language, terms and help |
| **Municipal** | Fixed Shabbat date, a "High availability" parking claim, eight tiles that did nothing | Shabbat computed; claim removed; dead tiles greyed "coming soon" |
| **Admin** | No section for `challenges` or `real_estate_agents`; creating a listing always failed (wrote a column that does not exist) | Both sections added; editor fixed; approve/reject queue for resident listings |
| **Sorting, everywhere** | `.order()` in postgrest-dart defaults to descending; 17 calls assumed ascending | All explicit |
| **Restaurants map** | 24 invented places — several addressed in Tel Aviv and Jerusalem, sharing a handful of copied ratings; "View Full Details" pushed `/business/restaurant_<hashCode>`; the list's "View on Map" went to `/map`, so the screen had no way in. The desktop layout of the same route carried 8 more, every row and pin pushing `/restaurant/1`, three of its five cuisine filters naming categories the database does not have, a "Sort by" chevron with no handler, and a "Contact" button with an empty one | 60 real food businesses from `businesses`, at their own coordinates, coloured by category; search filters; rating shown only where reviews earned it; cuisines come from the admin's sub-categories; sort works; Contact dials the number and is not drawn without one; every click opens the business it names |

### Migrations added: 00021–00025

Listing photo policies, steps leaderboard functions, business menus, RSVP
count trigger, review rating rollup. All applied.

### Still outstanding

- **Neighbourhood detail** — every neighbourhood renders as "Moriah";
  unreachable on mobile.
- **Notification preferences** — `lib/features/settings/models/notification_preferences.dart`
  exists with flags for news, deals, neighbourhood and real estate, and
  **nothing reads it**. There is no preferences screen. Either build one or
  delete the model; leaving it invites another wrong FAQ answer.
- **`web_events_category_screen.dart`** — converted to live data, but nothing
  in `lib` constructs `WebEventsCategoryContent`. `/events` resolves to
  `EventsScreen`, so the three-panel category layout is unreachable. Route it
  or delete it.
- **The Deals banner** — a 200px gradient box with a faded icon, on both
  layouts. No source, no content, decorative filler. Needs a product decision
  rather than a fix.
- **News list** — the design's per-category sections replaced by one flat
  list. Confirmed blocked on 24 September, not merely unfinished: `articles`
  has no category column, and `entity_categories` holds 210 rows of which
  **every one is `entity_type = 'business'`** — no article is linked to a
  category anywhere. The `categories` table does carry news categories
  (municipal, business-news, sports, education-news, culture, safety), so the
  fix is a data job: link the 669 articles, then the sections follow. Nothing
  can group them until then.
- **Google sign-in** — an empty TODO on the first screen; no OAuth anywhere.
- **The 19 seeded businesses** — see §1f. Kept deliberately for now; must go
  before launch.
- **~300 English strings** on mobile screens, ~600 on `web_*`.
- **Games** — a placeholder, waiting on a product decision.
- **Community** — the invented feed is gone (see above), but the feature
  still needs a `posts` table and a moderation story before it can open. It
  is also reachable only from the **web** home screen; nothing on mobile
  links to `/community`.
- **Two orphaned widgets deleted** — `news_preview.dart` (pushed
  `/article/demo_0`) and `category_row.dart`. Neither was referenced from
  anywhere; both carried routes that match no row.
- **"Contact Us"** in the web header — still an empty handler, on the same
  footing as Help & Support above: there is no destination decided yet, and
  inventing one would be worse than leaving the button plainly unfinished.
- **Dine-in and take-away filters** — dropped from the restaurants map.
  `has_takeaway` is false on all 220 rows and there is no dine-in column, so
  one checkbox would have emptied the list and the other narrowed nothing.
  They come back when the data does.
- **The heart on a web listing row** — local `setState`; favourites are live
  elsewhere in the app but this row is not wired to them.

---

## 1e. Web deployment — Kamatera

No server exists yet. Nothing here has been run against one. The files are
written so that provisioning is the only remaining step, and so the shape of
the server is decided before it is paid for.

### What was written

| File | What it does |
|---|---|
| `tool/deploy_web.sh` | Builds with the redirect URL compiled in, rsyncs `build/web/` to the server, fixes ownership. `--build-only` and `--dry-run` supported. |
| `deploy/nginx/app.modiin4u.co.il.conf` | gzip, cache rules, the SPA fallback, security headers. |
| `deploy/README.md` | One-time server setup, the `.env.local` keys, and what will bite. |

### The bug this found

`lib/main.dart` had no `usePathUrlStrategy()`, so web URLs were `/#/…`. That
would have broken `AUTH_REDIRECT_URL` outright: the browser fetches
`/auth/callback`, nginx returns `index.html`, go_router reads an empty hash
and opens the home screen. Someone confirming their e-mail address would
have landed on the home page with no word that it had worked, and no way to
tell the confirmation had gone through. Fixed, with the reason in a comment —
it is the kind of line that looks removable.

It also makes the nginx `try_files … /index.html` fallback load-bearing
rather than a nicety: without it every route but `/` 404s on refresh.

### Recommendation, for the client to approve before anything is bought

| | |
|---|---|
| Size | 1 vCPU / 1GB RAM / 20GB SSD |
| Region | **Israel (Tel Aviv)** — the audience is in Modiin |
| OS | Ubuntu 22.04 LTS |
| Cost | roughly $4–6/month |

That is enough because the server only hands out static files. No Dart, no
Node, no database on it — every query goes from the browser to Supabase. If
traffic ever justifies more, the honest next step is a CDN in front, not a
bigger box.

**DNS is at uPress, not Kamatera.** `modiin4u.co.il` uses `ns1.upress.io`, so
the `A` record `app` → server IP is added in uPress's panel. Kamatera's DNS
settings have no effect on this domain.

**Kamatera's panel cannot be driven from here.** It would need the client's
login and almost certainly a second factor. The server gets created by hand;
what is needed back is the IP and SSH access, after which the deploy is one
command.

### After the server exists

1. `A` record at uPress: `app` → the IP.
2. nginx + certbot per `deploy/README.md`. Certbot must run *after* DNS has
   propagated — it proves ownership over port 80.
3. Add `https://app.modiin4u.co.il/auth/callback` to Supabase's redirect
   allow-list. Until then the confirmation link is refused.
4. `tool/deploy_web.sh --dry-run`, then for real.

### Open question

The web build contains the **whole** app. The admin area is gated on
`kIsWeb`, not built separately, so every resident screen ships with it. If
`app.modiin4u.co.il` is meant to be the admin panel only, that needs a
separate build flag — not done, and not guessed at.

SMTP is a separate matter and deliberately untouched here.

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

## 1g. The web build, looked at — 25 September

Built it, served it and opened it in a browser at 1440, 1600 and 1920. Until
now the desktop layouts had only been checked by the analyser.

**What holds.** The home page and the businesses page render real data:
genuine Hebrew headlines with their own photographs and real datelines, and
category tiles reading 54 / 37 / 19 / 18 businesses, which match the database
exactly. The eight desktop screens converted on 24 September work.

**The navbar did not.** The design is drawn at 1920 with a 160px gutter, and
that gutter was fixed. On a 1440 laptop it took a fifth of the window, the
seven links were each given an equal share, and every one ellipsised at
once — the bar read `Profess…  Modiin …  Real Estat…  Restauran…  Busine…`.
Three fixes, all in `web_chrome.dart`, so they land on every page:

- the gutter shrinks with the window, 160 down to 24
- each link takes the width its own label needs instead of an equal share,
  and the row scrolls if they genuinely do not fit
- below 1700 the three "… in Modiin" labels drop those two words. The whole
  site is Modiin; the long forms stay where there is room for them

Most laptops are 1440 or 1536, so this was the common case, not the edge.

**Onboarding.** Every word on the first screen anyone sees was hardcoded
English while the app opens in Hebrew, so English sat inside a right-to-left
layout and the punctuation landed on the wrong side: `,Everything in Modiin`,
`.in one place`, `?Don't have an account`. Translated.

### Desktop layouts, started

The Figma file has 17 web frames and all 17 are built. The screens below had
no web design at all, so they follow the pattern the existing ones
established — `WebNavbar`, a 1600px content column, `WebFooter` — rather than
anything invented.

**Business detail is done.** It mattered most: every business card on every
desktop page opens it, and it was drawing the phone column stretched across
the window, with no navbar and no footer. It is one file with two
arrangements rather than a second copy — `build` switches at 1100 and both
call the same builders, so the tabs, menu, photographs and reviews have one
implementation. The photograph runs across the top; the page sits in the
left column; rating, address, neighbourhood and the actions stay in a card
beside it instead of being scrolled past.

Two things found while looking at it in a browser:

- the action row is laid out for a phone's full width, and in a 440px column
  the call button's label ran past the card's edge. It stacks now, the four
  icons on their own line.
- the reviews panel drew "0.0", five hollow stars and five 0% bars for a
  business nobody has reviewed — which reads as rated badly rather than not
  rated. It says so instead, matching the rest of the app.

**A caching note for anyone verifying a web build locally.** Flutter
registers a service worker, so a rebuild keeps serving the old bundle even
after a reload with a changed query string. Serve each build on a fresh port,
or clear `caches` and unregister the worker first. Two rounds were lost to
this.

**Still true of the desktop layouts:** they are laid out for 1920 and only
the navbar was hardened. Content columns are capped at 1600 and centre, which
holds down to about 1100, but nothing below that has been looked at.

---

## 1f. Nineteen invented businesses, in the live database

**Decision on 24 September: leave them for now, remove before launch.**
Recorded here so nobody has to rediscover it.

`businesses` holds two populations, and they are easy to tell apart:

| | 200 rows | 19 rows |
|---|---|---|
| `created_at` | all `2026-09-23` — the WordPress import | spread over 2022–2025, **every one on the 18th of a month** |
| `website` | 120 have one | **none** |
| `cover_url` | 129 have one | **none** |
| `neighborhood_id` | none set | **all 19 set** |

The nineteen are seeded placeholders. Their telephone numbers give it away:

```
08-9711111  08-9712222  08-9713333  08-9714444  08-9715555
08-9716666  08-9717777  08-9718888  08-9712345  08-9714567
```

Repeating and sequential digits. Their names are generic — Modiin Laundry,
Eli's Garage, Modiin Flowers, Modiin Pet Shop, Vision Optics — and three of
them are the same names that were written into the old map pin list: קפה גרג
(Cafe Greg), פיצה פרגו (Pizza Prego), Japan Japan.

Two are worse than filler: **ד"ר שלומי כהן — רופא שיניים**, a dentist, and
**עורך דין דנה לוי**, a lawyer. Invented professionals with invented numbers.

### What they affect

- They appear in the app as ordinary businesses, with a call button that
  reaches nobody.
- They are counted in the category tiles — the "54 מסעדות" on the
  businesses screen includes them.
- **They are the only rows with `neighborhood_id`**, so the neighbourhood
  link added on 24 September, and the neighbourhood page's own counts, are
  driven entirely by them. When they go, both go quiet until the client
  files real businesses under neighbourhoods.

### Removing them

Identify by the signature, not by name — `created_at < '2026-01-01'` picks
exactly these nineteen and nothing from the import. Take the
`entity_categories` links with them. Count first, delete second.

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

### ~~Blocking gap — real estate has no table~~ → now an empty-table gap

`listings` and `real_estate_agents` exist and the whole section reads them.
The gap moved: the tables are **empty**, and so are `offers`, `challenges`
and `reviews`. Counted against the live database on 24 September:

| Table | Rows | What depends on it |
|---|---|---|
| `articles` | 669 | News — fine |
| `businesses` | 220 | Businesses, restaurants, the maps — fine |
| `neighborhoods` | 10 | Filters throughout — fine |
| `events` | 9 | Events tab — thin but real |
| `profiles` | 2 | Us |
| **`listings`** | **0** | Real Estate — a bottom-nav tab, showing its empty state |
| **`offers`** | **0** | Deals — a whole section, empty |
| **`challenges`** | **0** | Steps challenges |
| **`real_estate_agents`** | **0** | Broker directory |
| **`reviews`** | **0** | Every rating on every business |

The screens are right and the empty states are honest. But a demo of Real
Estate or Deals shows nothing, which reads as broken rather than as new.
Either the client supplies the content or a seed is agreed — that is a
decision, not a task, and it is the one worth putting in front of him
first.

### Open questions for the client

- "Manage notifications" — does this mean sending push campaigns from the admin
  area, or users controlling their own notification preferences? Likely the
  former, given it was paired with "access".
- Does the WordPress site stay, or does the new build replace it? If it stays,
  content has two homes and needs a sync story.
- Where does the web build get deployed? `modiin4u.co.il` is taken by WordPress,
  and the Flutter web build renders through CanvasKit, which search engines do
  not read the way they read the current site. Working assumption:
  `app.modiin4u.co.il`, per §1e.
- Is `app.modiin4u.co.il` the admin panel only, or the resident web app too?
  The admin area is gated on `kIsWeb` rather than built separately, so today
  one build serves both.

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
