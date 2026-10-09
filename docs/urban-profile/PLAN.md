# Urban Profile — implementation plan

From the client's spec "Modiin4U_Urban_Profile_Onboarding_Spec_EN_v2.docx"
(8 Oct 2026). **Built 9 Oct** — migrations 00077 and 00079 (run), the app
(`lib/features/urban_profile/`), the website's `/u/<username>`, the panel's
user window; see PLAN.md, "Urban Profile and job messages". The design's
frames (9 Oct) set the screens; the sections below are the plan as it was.

## 0. Waiting on the client (before building)

**His answers (9 Oct):** 1 — yes, on the first sign-in after confirmation.
2 — not visible by default; he asked for a suggestion (an indication or a
prompt) that needs no privacy-policy change. Proposed: private by default,
the resident turns it on themselves (see "Visibility" below). 3–6 still open.
No further items will be added to this phase.

**Visibility (proposed):** `profile_visibility` defaults to `private`. On the
"ready" screen and in Privacy Settings, a switch, off: "Let other residents
see my Urban Profile", with one line saying exactly what others will see
(photo, name, neighbourhood, bio, interests, places — never phone, e-mail or
birth date). Sharing the share-card image needs nothing turned on (it is the
resident's own picture, sent by them). Sharing the profile link asks first:
"To open your link, others must be able to see your profile — turn it on?".
A private profile's link shows "This profile is private".

1. **When the onboarding opens.** Registration requires confirming the e-mail,
   so there is no session right after "Register" and nothing can be saved.
   Proposal: open it on the first sign-in after confirmation.
2. **Who sees a profile by default.** Today a profile is readable by its owner
   only. Spec: "viewable inside Modiin4U by default". That is a privacy change —
   the privacy policy may need a line (his lawyer). Proposal if he agrees:
   `residents` (signed-in users) by default, a switch to `private`.
3. **The profile link's domain.** `modiin4u.co.il/u/<name>` only works once
   www.modiin4u.co.il points at our server (the move). Until then the link has
   nowhere to open on the web. Use the www address from the start, or wait?
4. **Can a username be changed later?** The spec wants the link stable. Proposal:
   chosen once in onboarding (pre-filled, editable there), not changeable in V1.
5. **Hebrew texts.** The spec is English. The Hebrew below is our draft — he
   should approve it.
6. **Moderation.** A bio and a photo are content other residents see. Proposal:
   residents can report a profile (existing Reports), the panel can clear a bio
   or a photo.

## 1. Data (migration `00077_urban_profile.sql`)

On `profiles`:

| Column | Type | Notes |
|---|---|---|
| `bio` | text, ≤ 160 chars | optional |
| `interests` | text[] | keys from the fixed list (§3); 0, or 3–8 |
| `profile_visibility` | text `residents` \| `private` | default per answer 2 |
| `username` | text, unique, lower-case `[a-z0-9_.]{3,30}` | the link: `/u/<username>` |
| `urban_profile_seen_at` | timestamptz | onboarding shown once; never forced again |
| `urban_profile_completed_at` | timestamptz | all three steps done |

`profile_photo` = the existing `avatar_url` (Edit Profile already uploads to
`avatars/<id>/`). `profile_url` is not stored — it is derived from `username`.

New table `profile_places`: `profile_id` → profiles (cascade), `business_id` →
businesses (cascade), `position` (1–5), `top_pick` (`coffee` \| `restaurant` \|
`city` \| null — at most one of each). Max 5 rows per person, max 3 top picks.
Own-row RLS for writing.

Places = the `businesses` table: 227 businesses + 70 parks, which covers the
spec's examples (פארק ענבה, פארק הדגים, ג׳ויה, פינולי — all exist). There is no
single "Modiin City Center" place — only businesses in it. 96 businesses have no
cover photo: their card shows the logo, else a plain tile (never an invented
image).

Reading someone else's profile: a SECURITY DEFINER function
`urban_profile(p_username text)` returning only public fields — name,
avatar, neighbourhood name, bio, interests, places with name/image/slug, top
picks, member since — and only when visibility allows (`residents`: caller
signed in; owner: always). Never e-mail, phone, birth date, family status, pet.

Username helpers: `username_available(text)` and `suggest_usernames(text)` →
3 free alternatives (name transliterated, + neighbourhood, + digits).

Account deletion: `profile_places` cascades with the profile; nothing else.

## 2. App (Flutter)

Routes: `/urban-profile/1`, `/2`, `/3`, `/urban-profile/done`, and `/u/:username`
(a profile, own or another's).

- **Trigger.** After sign-in, when `urban_profile_seen_at` is null: set it and
  open step 1. Never again automatically.
- **Step 1 — photo + bio.** Reuse Edit Profile's photo picker/upload. Bio field
  with the spec's placeholder, counter to 160. Continue / Skip for now.
- **Step 2 — interests.** 16 chips with emoji, 3–8; Continue enabled at 3,
  chips disabled at 8. Skip for now (UX rule: optional steps can be skipped).
- **Step 3 — places.** Search field (name, English name), suggestions under it
  (recommended first, then parks and most-viewed), image cards with a heart,
  up to 5. "Finish & Build My Profile" / Skip for now.
- **Done — "Your Urban Profile is ready 🎉".** The profile card (photo or
  initials, name, neighbourhood, bio, interest chips, "My places"), then
  "Enter Modiin4U" and "Share Your Urban Profile".
- **Share.** A share card image (the profile card rendered to PNG) + the
  text "This is my Urban Profile on Modiin4U." + the link, through `share_plus`.
- **Profile screen.** An "Urban Profile" block: the card, completion
  ("Your Urban Profile is 70% complete" — photo, bio, interests, places,
  username = 20% each), "Complete your Urban Profile" going to the first
  incomplete step (hidden when complete), Copy Profile Link, Share Profile,
  "Privacy Settings" (the visibility switch).
- **Top Picks.** From the profile: pick up to 3 of the favourite places and
  label them My Coffee Spot / My Restaurant / My Place in the City. The section
  is hidden while there are fewer than 3 places.
- **Another resident's profile** (`/u/:username`, also from a deep link):
  read-only card; "Report" through the existing report flow.
- Hebrew and English, the phone layout only (accounts are the app's).

Deep links (needs a new app build): add `/u/*` to `web/.well-known/assetlinks`
and `apple-app-site-association`, the Android intent filter and the iOS
associated domains — for the domain chosen in answer 3.

## 3. Interests (fixed list, stored as keys)

| Key | Emoji | English | Hebrew (draft) |
|---|---|---|---|
| cafes | ☕ | Cafés | בתי קפה |
| restaurants | 🍽️ | Restaurants | מסעדות |
| brunch | 🥐 | Breakfast & Brunch | ארוחות בוקר ובראנץ׳ |
| asian | 🍣 | Asian Food | אוכל אסייתי |
| nightlife | 🍷 | Bars & Nightlife | ברים וחיי לילה |
| nature | 🌳 | Parks & Nature | פארקים וטבע |
| running | 🏃 | Running | ריצה |
| cycling | 🚴 | Cycling | רכיבה על אופניים |
| fitness | 🏋️ | Fitness & Sports | כושר וספורט |
| family | 👨‍👩‍👧 | Family & Kids | משפחה וילדים |
| culture | 🎭 | Culture | תרבות |
| music | 🎵 | Music | מוזיקה |
| pets | 🐶 | Pets | חיות מחמד |
| shopping | 🛍️ | Shopping | קניות |
| events | 🎉 | Events | אירועים |
| local_business | 💼 | Local Businesses | עסקים מקומיים |

Screen texts (Hebrew drafts, for the client to approve):
- "Let's build your Urban Profile" — בואו נבנה את הפרופיל העירוני שלכם
- "Help us get to know you a little better…" — ספרו לנו קצת על עצמכם כדי שנתאים את מודיעין בשבילך אליכם
- "Tell us in a few words what you love about the city…" — ספרו במילים ספורות מה אתם אוהבים בעיר…
- "What do you love about the city?" — מה אתם אוהבים בעיר?
- "Choose at least 3 interests" — בחרו לפחות 3 תחומי עניין
- "Which places do you love most in the city?" — אילו מקומות בעיר אתם הכי אוהבים?
- "Choose 3 places you are always happy to return to" — בחרו 3 מקומות שתמיד כיף לחזור אליהם
- "Finish & Build My Profile" — סיום ובניית הפרופיל
- "Your Urban Profile is ready 🎉" — הפרופיל העירוני שלכם מוכן 🎉
- "Enter Modiin4U" — כניסה למודיעין בשבילך
- "Share Your Urban Profile" — שיתוף הפרופיל העירוני
- "This is my Urban Profile on Modiin4U." — זה הפרופיל העירוני שלי במודיעין בשבילך.
- "Skip for now" — דלג בינתיים · "Continue" — המשך

## 4. Website (after the app)

`/u/<username>`: a light read-only profile page (photo, name, neighbourhood,
bio, interests, places linking to their business pages) with "Open in the app"
and the store badges. `noindex` — a resident's profile is not for search
engines. Built in the Next.js site; if the Flutter site is still the live one
then, also as a Flutter web route. Shows only what `urban_profile()` returns,
and "This profile is private" otherwise.

## 5. Admin panel

User details: show bio, interests, places, username; "Clear bio" and "Remove
photo" (moderation). Reports on a profile land in the existing Reports section.

## 6. Out of scope (spec §13)

Friends, feed, posts, comments on profiles, messages, badges, City Taste,
advanced privacy, social notifications. Interests are stored now; personalising
Home with them is a later phase.

## 7. Test plan

- Throwaway accounts on the OnePlus and the Realme, the iOS simulator.
- First sign-in opens step 1 once; a second sign-in does not.
- Each step skipped and completed; interests limits (2 → disabled, 9 → blocked);
  places limit 5; search in Hebrew and English.
- Done screen in both languages; share card image and link.
- Completion %, "Complete your Urban Profile" goes to the first missing step and
  disappears when complete.
- Top Picks hidden under 3 places; labels unique.
- Visibility: another account sees a `residents` profile, not a `private` one;
  signed out sees nothing; no private field ever in the function's answer.
- Username taken → suggestions; invalid characters refused.
- Deep link opens the app on `/u/<name>`; without the app, the web page.
- Deleting the account removes places and the profile.
- Delete every test account, photo and row after.
