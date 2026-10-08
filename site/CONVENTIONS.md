# The public website (Next.js) — how it is built

The public site of www.modiin4u.co.il. It replaces the Flutter web build for
everything a visitor or a search engine reads; the admin panel stays the
Flutter web build, the phone apps stay Flutter. One Supabase behind all three.
Decided 8 Oct 2026 (PLAN.md, "The public website moves to Next.js").

## Rules that come before anything else

- **Never invent content.** Every name, number, date, price, hour and review
  comes from the database (or from the WordPress snapshot, for SEO text).
  If a design needs data the database lacks, leave it out.
- **The website has no resident accounts.** Signing in, sign-up, favourites,
  writing reviews or comments, RSVP: the app's. The site shows, read-only.
- **Same design as the current site** — the Flutter `web_*_screen.dart`
  pages (desktop, ≥ 1100 px) and the phone screens `<name>_screen.dart`
  (below 1100 px). Reference screenshots of the current site are the target.
- **Hebrew first.** Pages render in Hebrew (`lang="he" dir="rtl"`) unless the
  reader chose English (cookie `lang`, the header's switch). Use
  `const lang = await getLang(); const t = tr(lang);` then `t('עברית', 'English')`.

## SEO — the reason this site exists

The client's Google traffic is his income. `tool/check_seo_parity.py`
compares every page with the WordPress site (address, canonical, title,
description, H1, menu links) and must stay at 992/992.

- **Every page exports `generateMetadata`** returning `pageMetadata({...})`
  from `@/lib/seo` — never hand-written metadata. It sets the canonical on
  www.modiin4u.co.il, robots (noindex until `SEO_LIVE=1`), Open Graph and
  Twitter. Title: the panel's SEO field (`seo_title` / `meta_title`), else
  `name + SUFFIX`; description: `meta_description`, else
  `plain(text, 160)`. For an old WordPress address with no row of its own,
  pass only `path` — the WordPress title and description are used.
- **Exactly one `<h1>`, and it is `h1For(path, name)`** — WordPress's H1
  where the address existed there.
- **Addresses end in a slash** (`trailingSlash: true`). Links:
  `href('/news/' + slug + '/')` encodes Hebrew slugs. Use `next/link`.
- **Structured data** with `<JsonLd data={...} />`: `breadcrumb([...])` on
  every inner page, and the page's own type (NewsArticle, LocalBusiness,
  Event, Offer, Place …) where it applies.
- **Content is in the HTML.** Server components fetch and render; client
  components only for interaction (tabs, carousels, maps). Never fetch the
  main content in the browser.
- **Old addresses** (`/modiin-news/`, `/professionals/…`, …) are pages of
  their own that render the replacing page's content with their own `path`
  for metadata and H1 — no redirect.

## Code

- Next.js 15 App Router, TypeScript, Tailwind v4 (tokens in
  `src/app/globals.css`: `navy`, `midblue`, `turquoise`, `gold`, `ink`,
  `gray-text`, `gray-meta`, `line`, `card-border`, `section`, …; the
  breakpoint `desk:` = 1100 px). `.wrap` is the page column (1600 max,
  the design's side gaps).
- Pages under `src/app/(site)/…` get the header bar; the home page is
  `src/app/(home)`.
- Data: `db` from `@/lib/supabase` (public key, cached 120 s). One file per
  area in `src/lib/data/`. Select only the columns used. Route params arrive
  percent-encoded: `slugParam()`.
- Icons: `iconsax-react` (the app's Iconsax set). Images and icons of the
  design: `public/web/…`, `public/icons/…`, `public/images/…` (copies of the
  app's `assets/`). Remote images with plain `<img loading="lazy">`.
- Paid banners: `banners('<PLACEMENT_CODE>')` and `<BannerImage>`; a slot
  with nothing booked draws nothing.
- Dates: `formatDate(iso, lang, withTime?)` — Israel time.
- Comments explain why, in plain prose, like the rest of the repo.

## Running

    npm run dev          # http://localhost:3100, data synced from the repo
    npm run typecheck
    npm run build && npm start
    python3 ../tool/check_seo_parity.py http://localhost:3100
