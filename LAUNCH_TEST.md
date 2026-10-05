# Launch test — every journey, once, on the real thing

Run on the **deployed** website (desktop 1440 px and a phone browser) and a
**release** build of the app (Android and iPhone), signed in as throwaway
accounts made for the test (`tool/tmp_admin.py`, test residents) and removed
after. Mark each line ✅ / ❌ with a note. A ❌ goes to PLAN.md with the fix.

## Resident — app

- [ ] Onboarding, notifications prompt ("Not now" and "Allow")
- [ ] Sign up with phone, neighbourhood, family status, pet, date of birth → confirm e-mail → sign in → Edit Profile shows every field
- [ ] Forgot password → e-mail → reset page → sign in with the new one
- [ ] Edit profile (photo, neighbourhood) → saved after closing the app
- [ ] Change password; change language Hebrew ↔ English (every tab follows)
- [ ] Delete account (Settings) → signed out, account gone
- [ ] Home: Ask opens the chat; search; Discover tiles; nearby restaurants (location on and off)
- [ ] Businesses: category grid → category → filters (kosher, delivery) → business page
- [ ] Business page: call, website, WhatsApp, directions, share, Instagram → each recorded in the panel's Statistics
- [ ] Write a review → approved in the panel → shows; reply to a review → approved → shows
- [ ] Favourite a business, event, apartment → Favourites tabs
- [ ] Restaurants: cuisines (incl. the old site's), map, café/restaurant pins
- [ ] News: list, category, article; Events: list, category, map, event page, RSVP, share
- [ ] Deals: list, category, deal page, claim → code; claim again (refused); a full deal (refused)
- [ ] Real estate: search, filters, listing page, contact; post an apartment (photos, save draft, submit) → My Apartments status → approved in the panel → public
- [ ] Municipal: parking (Google details, Waze, Google Maps), Shabbat times, places, forms
- [ ] Step counter: Health Connect / Apple Health, today, week/month, groups (create, invite link, join, leave), leaderboards, a running challenge, banners
- [ ] Notifications: settings switches; a manual push (closed, background, open); tap opens the right page; bell and unread
- [ ] English everywhere our own text appears

## Visitor — website (desktop and phone width)

- [ ] Home, language switch EN/עב (kept after reload; phone width follows)
- [ ] Every navbar menu and footer link (About, Contact, Terms, Privacy, Accessibility, Delete account, Get notifications)
- [ ] Businesses (10 main categories; "All categories"), category pages, business page and its buttons
- [ ] Old addresses: `/news/<slug>`, `/business/<slug>`, `/business-cat/<old slug>` (e.g. sushi, ברים), redirects in `seo-redirects.conf`
- [ ] Restaurants, map, news, article, events, deals, real estate, municipal, step counter (read-only)
- [ ] Ask opens the chat; no floating bubble
- [ ] Notifications: allow in the browser, receive one, the bell
- [ ] No account actions anywhere (hearts, RSVP, claim, sign-up) except `/login` for admins
- [ ] Page titles in the tab; `view-source` shows the SEO title and description

## Client — admin panel

- [ ] Sign in (his account); forgot password works
- [ ] Each section opens: create, edit, publish/unpublish, archive/hide, restore from Trash — and the change shows on the site and in the app
- [ ] Articles and events: "send a notification" box → the automatic push arrives
- [ ] Businesses: edit, hours, gallery, menu, categories; ⋮ → Statistics (day / week / month)
- [ ] Categories: "Shown in menus" switch
- [ ] Deals: claim counts and the max-claims limit
- [ ] Campaigns: a banner in each slot (home, deals, steps top / inline …) shows, and stops at its end date
- [ ] Push: write, schedule, send, cancel; opened count
- [ ] Challenges: create, run, end
- [ ] Info pages: publish Terms, Privacy, Accessibility, Delete account → visible on the site
- [ ] Team: add a member with a limited role → they see only their sections and cannot write others (00050)
- [ ] Reviews / comments moderation; Activity log records each action

## Before going live

- [ ] Sample and test data removed (incl. four August drafts set to notify); leftover temporary admins removed
- [ ] Old images copied on the server (`tool/copy_wp_uploads.py`), then the domain moved (`tool/enable_domain.sh`), `SEO_LIVE=1`
- [ ] His password changed; legal texts published
