# Launch test — every journey, once, on the real thing

Run on the **deployed** website (desktop 1440 px and a phone browser) and a
**release** build of the app (Android and iPhone), signed in as throwaway
accounts made for the test (`tool/tmp_admin.py`, test residents) and removed
after. Mark each line ✅ / ❌ with a note. A ❌ goes to PLAN.md with the fix.

## Resident — app

- [x] Onboarding, notifications prompt ("Not now" and "Allow") — iOS sim 7 Oct ✅
- [x] Sign up with phone, neighbourhood, family status, pet, date of birth → confirm e-mail → sign in → Edit Profile shows every field — iOS sim 7 Oct ✅ (fixed: account-type card overflow on Android)
- [ ] Forgot password → e-mail → reset page → sign in with the new one
- [ ] Edit profile (photo, neighbourhood) → saved after closing the app — neighbourhood ✅ OnePlus 15 Oct (נופים, kept after a force-stop and restart); photo not tried. The side menu's "עריכה" opens the job CV profile, not Edit Profile
- [x] Change password; change language Hebrew ↔ English (every tab follows) — language ✅ iOS 7 Oct, OnePlus 15 Oct (every tab, kept after restart); password ✅ OnePlus 15 Oct (old refused, new signs in)
- [x] Delete account (Profile, since 14 Oct) → signed out, account gone — deleted elsewhere → signed out on resume ✅ Realme 7 Oct; in-app delete ✅ iOS sim 14 Oct (account, profile and reports gone; signing in again refused); from Settings ✅ OnePlus 15 Oct (account, profile, favourites, places gone)
- [ ] Home: Ask opens the chat; search; Discover tiles; nearby restaurants (location on and off) — OnePlus 15 Oct: Ask ✅, search ✅, tiles ✅; location on/off not tried. **Home's news cards print the UTC time** (09:50 for an article the News tab shows at 12:50 Israel) — home_screen.dart `_NewsData.from` lacks `.toLocal()`
- [x] Businesses: category grid → category → filters (kosher, delivery) → business page — OnePlus 15 Oct ✅ (Restaurants 56 → Kosher 44 → + Delivery 28). **Category and cuisine cards count closed businesses** (Restaurants 63 vs 56 listed; Asian 7 = 5 active + 2 closed)
- [ ] Business page: call, website, WhatsApp, directions, share, Instagram → each recorded in the panel's Statistics — OnePlus 15 Oct ✅ view, call (dialer), website (Chrome tab), share (share sheet), directions — each a `business_events` row, platform app (test rows deleted); WhatsApp and Instagram not on the businesses tried. **Hebrew opening hours read backwards in the English app** ("22:00–11:30 יום ראשון", no space)
- [x] Write a review → approved in the panel → shows; reply to a review → shows at once (00063) — iOS + Realme + panel 7 Oct ✅
- [x] Apple 1.2: Terms (EULA) box at sign-in and sign-up; Report → hide; Block a user from a comment, review or reply → their content gone, a "user" report in the panel; Profile → Blocked users → Unblock — iOS sim 14 Oct ✅ (reference recordings; the physical-device ones still to make)
- [ ] Favourite a business, event, apartment → Favourites tabs — business and article ✅ Realme 7 Oct, business ✅ OnePlus 15 Oct; event, apartment: none published to favourite
- [x] Restaurants: cuisines (incl. the old site's), map, café/restaurant pins — OnePlus 15 Oct ✅ (cuisine cards, Asian list, map with restaurant and café pins, View as List)
- [ ] News: list, category, article; Events: list, category, map, event page, RSVP, share — News ✅ OnePlus 15 Oct; Events shows "No upcoming events" (none published), so the event page and RSVP are untested. News opens on the placeholder "רכבת קלה למודיעין — עדכון מצב" (17 Aug)
- [x] Deals: list, category, deal page, claim → code; slide to use; an ended deal refused (00066) — Realme 7 Oct ✅
- [x] Real estate: search, listing page; a broker posts (3 steps, photo) → My Apartments → approved in the panel → public "Via Broker" — iOS sim + panel 7 Oct ✅ (fixed: My Apartments stayed "Pending")
- [x] Municipal: parking (Google details, Waze, Google Maps), Shabbat times, places, forms — OnePlus 15 Oct ✅ (26 car parks, map, a car park page, Navigate with Waze → Play Store when not installed, Google Maps → the Maps app; Shabbat & holidays from Hebcal; Public Institutions 10; Forms → the municipality's page)
- [ ] Step counter: Health Connect / Apple Health, today, week/month, groups (create, invite link, join, leave), leaderboards, a running challenge, banners — challenge card, View Challenge, leaderboard ✅ Realme 7 Oct; OnePlus 15 Oct: today/week ✅, a running challenge's prize banner ✅ (the app reads it at start, so a challenge started later shows after a restart), group create → share sheet with the invite → group page (code, today/week/month, comparison) → leave (last member: the group goes) ✅; join with a second account and Health Connect not tried
- [x] Notifications: settings switches; pushes from the database (closed, background); tap opens the review/reply; bell and unread — iOS sim + Realme 7 Oct ✅; OnePlus 15 Oct ✅ to this one device: in the tray in English (the phone's language), tap opens the link and counts "opened"; app open → in-app banner, tap opens the link and counts; the bell's unread
- [ ] English everywhere our own text appears

## Visitor — website (desktop and phone width)

- [x] Home, language switch EN/עב (kept after reload; phone width follows) — live 14–15 Oct: desktop leads with restaurants ✅; phone home, footer and bottom menu ✅; language switch ✅ 15 Oct (desktop header pill; phone: first item in ☰; a year's cookie; kept after reload; resize follows). Seen once: the English home showed "This page is not available right now" after the switch — not reproduced in 6 tries
- [x] Every navbar menu and footer link (About, Contact, Terms, Privacy, Accessibility, Delete account, Get notifications) — 15 Oct ✅ all 75 same-site links 200; the info pages have content. **Defects:** on a phone the ☰ drawer's last link ("צור קשר") sits under the bottom tab bar and can't be tapped; `/terms/` shows raw `**` Markdown 12 times in the EULA section; the App Store badge has no link; header menus and the drawer stay Hebrew in English (no English names in the content)
- [x] Businesses (10 main categories; "All categories"), category pages, business page and its buttons — Next.js 9 Oct ✅; 15 Oct ✅ directory (phone 10 tiles; desktop 8 + "כל 77 הקטגוריות"), three category pages, four business pages: website, WhatsApp, Instagram, Google Maps, share menu, call menu. **Defects:** אודי ויפ's phone link is broken (an invisible U+2069 inside the number, `tel:522071905⁩0`); the phone "ניווט" goes to Waze, not Google Maps, and for דקר בן ימין only to the city
- [x] Old addresses: `/news/<slug>`, `/business/<slug>`, `/business-cat/<old slug>` (e.g. sushi, ברים), redirects in `seo-redirects.conf` — all 992 of WordPress's on the live domain 14 Oct ✅ (`check_seo_parity.py`; two intended differences)
- [x] Restaurants, map, news, article, events, deals, real estate, municipal, step counter (read-only) — 25 page kinds at 390 and 360 px live 15 Oct ✅: no sideways scroll, no broken picture, no page error; the map draws (51 s → 4.9 s from India after BBR)
- [x] Ask opens the chat; no floating bubble — 15 Oct ✅ (PersonaAI's invisible `#personaai-btn-wrap` over the phone's Home tab hidden; Ask still opens the chat)
- [x] Notifications: allow in the browser, receive one, the bell — Next.js site (localhost), Chrome, 9 Oct ✅: Turn on → device registered; one test device only (`audience_type = device`), each kind sent and received in the background: manual, new article, event, business, deal, listing, step competition; in the foreground the in-page banner; bell showed 8 unread, cleared on opening the list; a notification's link opened its page and counted "opened". Test content, notifications and device deleted after. Not yet: on the deployed site (the sender's `SITE_URL` points at www since 14 Oct)
- [x] No account actions anywhere (hearts, RSVP, claim, sign-up) except `/login` for admins — 15 Oct ✅ on business and article pages and the (empty) events, deals, apartments and jobs lists: no hearts, RSVP, claim, review form or sign-up; the only sign-in is `/signin/` (Messages, Urban Profile), which sends sign-up to the app. Event, deal, listing and job pages not seen — none published
- [x] Page titles in the tab; `view-source` shows the SEO title and description — live 14 Oct ✅ (title, description, canonical, H1 on every old address; `index, follow` since `SEO_LIVE=1`)

## Client — admin panel

- [ ] Sign in (his account); forgot password works
- [x] Each section opens: create, edit, publish/unpublish, archive/hide, restore from Trash — and the change shows on the site and in the app — every section opens after the redesign ✅ 7 Oct; 15 Oct on panel.modiin4u.co.il ✅ all 35 sections open with no error; an article and an event each created, edited, published (live on www at once), taken down (gone from www within ~2.5 min, the page cache), archived/cancelled, restored from Trash (to the state before removal, as the log recorded it); a business and a category likewise. Not seen in the app (no device this pass)
- [ ] Articles and events: "send a notification" box → the automatic push arrives — 15 Oct: with the box off nothing is queued (article, event); with it on, approving a business queued "עסק חדש בעיר" for 5 min later (cancelled by the test's watcher before sending). Arrival on a phone not checked this pass
- [ ] Businesses: edit, hours, gallery, menu, categories; ⋮ → Statistics (day / week / month) — 15 Oct ✅ edit, hours (Sun–Thu via "א׳–ה׳ בלבד"), gallery upload, category, Statistics (day/week/month, chart), approve → live on www with hours and photo, close → Trash → restore; **menu not verified** — the item's name field would not take input from the test browser, so nothing saved; check by hand
- [x] Categories: "Shown in menus" switch — 15 Oct ✅ saved off → on → off on a test category; disable works
- [ ] Deals: claim counts and the max-claims limit
- [ ] Campaigns: a banner in each slot (home, deals, steps top / inline …) shows, and stops at its end date — 15 Oct ✅ in the GAMES_HOME slot (drawn on no page, so no visitor saw it): draft not served, active served by `active_banners()`, an end date in the past stops it. Not seen drawn in each slot
- [x] Push: write, schedule, send, cancel; opened count — 15 Oct ✅ write (draft), schedule (1 Jan 2027, picker), cancel with confirmation; the list shows sent/opened. Sending: three pushes to one device (the OnePlus, `audience_type = device` — the panel offers no single-device audience) arrived and their opens were counted; the panel's "Send now" to everyone not pressed (it reaches every resident)
- [x] Challenges: create, run, end — 15 Oct ✅ create (goal, prize, dates, notification off) and deactivate; run: a challenge for today (notification off) for ~5 minutes — the prize banner on the OnePlus and on www's /steps/, then ended; nothing was sent
- [x] Info pages: publish Terms, Privacy, Accessibility, Delete account → visible on the site — all five published and visible on the site and in the app 15 Oct ✅ (Accessibility published 14 Oct, About from WordPress 15 Oct)
- [x] Team: a limited role sees only its sections and cannot write others (00050); Roles & rights editable by the main admin only (00066) — 7 Oct ✅
- [x] Reviews / comments moderation; Activity log records each action — reviews, replies, reports (Hide it) ✅ 7 Oct; activity log ✅ 15 Oct: every create, edit, status change and restore, with who and the before/after

## Before going live

- [ ] Sample and test data removed (incl. four August drafts set to notify); leftover temporary admins removed — sample content removed 14 Oct ✅; no temporary admins ✅; `seed_remote.sql`'s 19 placeholder businesses, 10 articles and 10 events kept (the client's call)
- [x] Old images copied on the server (`tool/copy_wp_uploads.py`), then the domain moved (`tool/enable_domain.sh`), `SEO_LIVE=1` — 14 Oct ✅ (www, the bare domain, then panel. and app. on 15 Oct)
- [ ] His password changed; legal texts published — legal texts ✅ (Terms with EULA, Privacy, Accessibility); his password not yet
