# Launch test — every journey, once, on the real thing

Run on the **deployed** website (desktop 1440 px and a phone browser) and a
**release** build of the app (Android and iPhone), signed in as throwaway
accounts made for the test (`tool/tmp_admin.py`, test residents) and removed
after. Mark each line ✅ / ❌ with a note. A ❌ goes to PLAN.md with the fix.

## Resident — app

- [x] Onboarding, notifications prompt ("Not now" and "Allow") — iOS sim 7 Oct ✅
- [x] Sign up with phone, neighbourhood, family status, pet, date of birth → confirm e-mail → sign in → Edit Profile shows every field — iOS sim 7 Oct ✅ (fixed: account-type card overflow on Android)
- [ ] Forgot password → e-mail → reset page → sign in with the new one
- [ ] Edit profile (photo, neighbourhood) → saved after closing the app
- [ ] Change password; change language Hebrew ↔ English (every tab follows) — language ✅ iOS 7 Oct; password not yet
- [ ] Delete account (Settings) → signed out, account gone — deleted elsewhere → signed out on resume ✅ Realme 7 Oct; in-app delete not yet
- [ ] Home: Ask opens the chat; search; Discover tiles; nearby restaurants (location on and off)
- [ ] Businesses: category grid → category → filters (kosher, delivery) → business page
- [ ] Business page: call, website, WhatsApp, directions, share, Instagram → each recorded in the panel's Statistics
- [x] Write a review → approved in the panel → shows; reply to a review → shows at once (00063) — iOS + Realme + panel 7 Oct ✅
- [ ] Favourite a business, event, apartment → Favourites tabs — business and article ✅ Realme 7 Oct; event, apartment not yet
- [ ] Restaurants: cuisines (incl. the old site's), map, café/restaurant pins
- [ ] News: list, category, article; Events: list, category, map, event page, RSVP, share
- [x] Deals: list, category, deal page, claim → code; slide to use; an ended deal refused (00066) — Realme 7 Oct ✅
- [x] Real estate: search, listing page; a broker posts (3 steps, photo) → My Apartments → approved in the panel → public "Via Broker" — iOS sim + panel 7 Oct ✅ (fixed: My Apartments stayed "Pending")
- [ ] Municipal: parking (Google details, Waze, Google Maps), Shabbat times, places, forms
- [ ] Step counter: Health Connect / Apple Health, today, week/month, groups (create, invite link, join, leave), leaderboards, a running challenge, banners — challenge card, View Challenge, leaderboard ✅ Realme 7 Oct; the rest not yet
- [x] Notifications: settings switches; pushes from the database (closed, background); tap opens the review/reply; bell and unread — iOS sim + Realme 7 Oct ✅
- [ ] English everywhere our own text appears

## Visitor — website (desktop and phone width)

- [ ] Home, language switch EN/עב (kept after reload; phone width follows)
- [ ] Every navbar menu and footer link (About, Contact, Terms, Privacy, Accessibility, Delete account, Get notifications)
- [ ] Businesses (10 main categories; "All categories"), category pages, business page and its buttons — Next.js 9 Oct: Contact menus show over the cards ✅, directory search suggests and opens results ✅, category filters follow the list ✅
- [ ] Old addresses: `/news/<slug>`, `/business/<slug>`, `/business-cat/<old slug>` (e.g. sushi, ברים), redirects in `seo-redirects.conf`
- [ ] Restaurants, map, news, article, events, deals, real estate, municipal, step counter (read-only)
- [ ] Ask opens the chat; no floating bubble
- [x] Notifications: allow in the browser, receive one, the bell — Next.js site (localhost), Chrome, 9 Oct ✅: Turn on → device registered; one test device only (`audience_type = device`), each kind sent and received in the background: manual, new article, event, business, deal, listing, step competition; in the foreground the in-page banner; bell showed 8 unread, cleared on opening the list; a notification's link opened its page and counted "opened". Test content, notifications and device deleted after. Not yet: on the deployed site (the sender's `SITE_URL` still points at the Flutter server)
- [ ] No account actions anywhere (hearts, RSVP, claim, sign-up) except `/login` for admins
- [ ] Page titles in the tab; `view-source` shows the SEO title and description

## Client — admin panel

- [ ] Sign in (his account); forgot password works
- [ ] Each section opens: create, edit, publish/unpublish, archive/hide, restore from Trash — and the change shows on the site and in the app — every section opens after the redesign ✅ 7 Oct; create/edit/restore per section not yet
- [ ] Articles and events: "send a notification" box → the automatic push arrives
- [ ] Businesses: edit, hours, gallery, menu, categories; ⋮ → Statistics (day / week / month)
- [ ] Categories: "Shown in menus" switch
- [ ] Deals: claim counts and the max-claims limit
- [ ] Campaigns: a banner in each slot (home, deals, steps top / inline …) shows, and stops at its end date
- [ ] Push: write, schedule, send, cancel; opened count
- [ ] Challenges: create, run, end
- [ ] Info pages: publish Terms, Privacy, Accessibility, Delete account → visible on the site
- [x] Team: a limited role sees only its sections and cannot write others (00050); Roles & rights editable by the main admin only (00066) — 7 Oct ✅
- [ ] Reviews / comments moderation; Activity log records each action — reviews, replies, reports (Hide it) ✅ 7 Oct; activity log not checked

## Before going live

- [ ] Sample and test data removed (incl. four August drafts set to notify); leftover temporary admins removed
- [ ] Old images copied on the server (`tool/copy_wp_uploads.py`), then the domain moved (`tool/enable_domain.sh`), `SEO_LIVE=1`
- [ ] His password changed; legal texts published
