# Launch runbook — moving www.modiin4u.co.il from WordPress to the new site

The steps in order, each with its command or where it is done. LAUNCH_TEST.md
is what to check once it is live; PLAN.md says why each step exists. Tick
each line as it is done.

## Rollback — back to WordPress

Switched on 14 Oct 2026 at about 18:25 (IST). WordPress stays live and
untouched at uPress; to send visitors back to it, set these two A records at
uPress → Manage DNS back to their old value (TTL 5 minutes, so it takes
effect in minutes):

| Record | Before the switch (WordPress, uPress) | Since the switch (Next.js) |
|---|---|---|
| A `modiin4u.co.il` | `185.108.148.183` | `45.93.94.49` |
| A `www.modiin4u.co.il` | `185.108.148.183` | `45.93.94.49` |

Nothing else changed: `ftp`, `mail`, `pop`, `smtp` stay on `185.108.148.183`
(mail is uPress's), and the CNAMEs, MX, NS, `_dmarc` and the three TXT
records (brevo-code, google-site-verification, SPF) were left as they were —
16 records in all. To open WordPress itself after the switch, on one
computer only: `185.108.148.183  www.modiin4u.co.il modiin4u.co.il` in
/etc/hosts.

## A. A week before

- [x] **DNS at uPress:** first screenshot the whole Manage DNS list (clear
      the search box), to compare against after every change — on 13 Oct four A
      records (@, mail, ftp, pop) went missing after saves there, cause not
      established. Then lower
      the TTL of `www`, the bare domain and `app` to 300 s, so the switch takes
      minutes. Leave the MX, SPF, DKIM (`brevo1`/`brevo2._domainkey`), DMARC and
      `brevo-code` records as they are — mail stays where it is. Check the
      result over HTTPS DNS (dns.google/resolve); plain `dig` from the office
      network gave false "does not exist" answers that day.
      — done 14 Oct: screenshot kept; TTL 5 minutes (`@` and `www` showed 300 s at once on Google's DNS; the bare domain's old hour ran out ~18:32).
- [x] **Decide the panel's address** (its own subdomain, e.g. `panel.`) and
      ask the client for its DNS record with the others.
      — decided 14 Oct: `panel.modiin4u.co.il` — the client added `panel` and `app` at uPress the same evening; uPress had not yet served them at 19:20.
- [x] **Supabase → Authentication → URL configuration:** Site URL
      `https://www.modiin4u.co.il`; redirect allow-list: `https://www.modiin4u.co.il/**`,
      `https://modiin4u.co.il/**`, `https://app.modiin4u.co.il/**`, the panel's
      address. Keep the sslip.io entry until the move is done.
      — done 14 Oct: Site URL `https://www.modiin4u.co.il`; www, bare and app `/**` added to the allow-list, the sslip.io and app-scheme entries kept.
- [x] **Google Cloud → the web keys** (Maps tiles, Places web): add
      `www.modiin4u.co.il/*`, `modiin4u.co.il/*` and the panel's address to
      the allowed referrers. The app keys are restricted to the apps already.
      — done 14 Oct by Harshit; checked: a Map Tiles session opens with a www, bare or sslip.io referrer.

## B. Freeze WordPress (the day before)

- [x] Ask the client to stop publishing on WordPress from now on (the panel
      takes over).
      — done 14 Oct, ~17:00; WordPress's last edit is 9 Oct.
- [x] `python3 tool/snapshot_wp_seo.py` — what Google reads on every page,
      again, after the last WordPress edit.
      — done 14 Oct 17:33: 992 pages, identical to 13 Oct.
- [x] Import what was published since the last import:
      `python3 tool/import_new_wordpress.py` (it keeps a registry, `--undo`).
      — done 14 Oct: nothing new — `modiin-news-524` was imported earlier that day.
- [x] `python3 tool/copy_wp_uploads.py` — the old images onto the server, again
      (12 failed last time, plus anything uploaded since).
      — done 14 Oct: 22 new files, 8 still fail (listed in failed.txt on the server).
- [x] Export WordPress's redirect rules from its admin (Redirection / Yoast),
      and add any the site does not already answer to `site/next.config.ts`.
      — checked 14 Oct: no redirect plugin (no Redirection, no Yoast Premium); the one Code Snippet is a disabled "test".
- [x] `python3 tool/check_seo_parity.py http://localhost:3100` on a production
      build — every WordPress page at its address, with its title, description,
      H1 and menu. Businesses the client closed answer "not listed" (404):
      his decision whether they keep a page.
      — done 14 Oct on 45 after the deploy: 178 of 180 sampled, the two intended (Shabbat title, Mondo closed); the full 992 against the live domain ran that night.

## C. Remove what is not real

- [x] `python3 tool/seed_sample_content.py --undo --dry-run`, read it, then
      `python3 tool/seed_sample_content.py --undo` — the demo events, deals,
      listings, reviews, banners. It restores a field only where it still holds
      the value the script set, so the client's later edits stand.
      — done 14 Oct.
- [ ] `python3 tool/remove_seed_remote.py`, read it, then `--apply` — the 19 — **not run** — the client kept them (14 Oct); they are live and indexed until removed
      placeholder businesses, 10 articles and 10 events from `seed_remote.sql`
      (invented phone numbers and view counts).
- [x] `python3 tool/tmp_admin.py --list`, then `--purge` — leftover test admins.
      — done: none left.
- [x] Test rows and test accounts made during testing: none should be left
      (each test deletes its own; LAUNCH_TEST.md).
      — done 14 Oct: the App Review, block and delete-account test accounts and rows deleted (the demo account `appreview@modiin4u.co.il` stays until approval).

## D. The switch

- [x] Build and deploy the Next.js site for Linux (the image library is per
      platform): `tool/deploy_site.sh --live` — `--live` turns on the
      business statistics and article views; `SEO_LIVE=1` in
      `/etc/modiin4u-site.env` opens indexing and the analytics.
      — done 14 Oct ~18:00 (`--live`); `SEO_LIVE=1` set at 18:35, after the switch, page cache emptied.
- [x] nginx: `deploy/next/cache.conf` into `/etc/nginx/conf.d/`, the www and
      bare-domain server blocks with `include proxy.conf`, then `nginx -t` and
      reload. Never `certbot --nginx` (deploy/README.md).
      — in place since 13 Oct; `/web/` `/icons/` `/brand/` `/images/` served from disk since 14 Oct (429s fixed).
- [x] DNS: `www` and the bare domain → 45.93.94.49; certificates with
      `tool/enable_domain.sh`.
      — done 14 Oct ~18:25; www certificate at 18:30 (the first try met uPress's nameservers still on the old IP), bare at 18:32.
- [x] Check at once: `curl -sI https://www.modiin4u.co.il/` (200),
      `curl -s https://www.modiin4u.co.il/robots.txt` (no `Disallow: /`),
      `/sitemap.xml`, one `/_next/image/` photo, one old address
      (`/news/<slug>/`), the bell's Turn on.
      — done 14 Oct: 200, robots open, sitemap 1,122, old addresses, photos, GA4 and Pixel tags, http → https, bare → www.

## E. Links that still point at the test server

- [x] **Notifications:** the `push-dispatch` function's `SITE_URL` →
      `https://www.modiin4u.co.il` (`tool/setup_push.py` sets it — check its
      default is no longer sslip.io before re-running it).
      — done 14 Oct.
- [x] **Invitations:** the `site_url` setting (step-group links) → www.
      (Set to https://45-93-94-49.sslip.io on 13 Oct; it was empty, and the
      app then used app.modiin4u.co.il, which does not exist.)
      — done 14 Oct.
- [ ] **App sign-up links:** `AUTH_REDIRECT_URL` for app builds →
      `https://www.modiin4u.co.il/auth/callback` (in the allow-list above).
- [ ] **App links:** add www to `ios/Runner/Runner.entitlements` and
      `android/app/src/main/AndroidManifest.xml`; `apple-app-site-association`
      and `assetlinks.json` (with Play's signing certificate) served from www.
- [x] **The panel** on its own https address. Since 13 Oct it is
      https://panel.45-93-94-49.sslip.io (`/panel`, `/admin`, `/login` on the
      main addresses 301 there); for panel.modiin4u.co.il copy its conf and
      change the name in snippets/modiin4u-public.conf's redirects.
      — done 14 Oct 19:41: https://panel.modiin4u.co.il (certificate to 12 Jan 2027, admin only, noindex); `/panel`, `/admin`, `/login` on www and the whole sslip.io panel address 301 there; added to Supabase's redirect allow-list. The DNS record flickered between uPress's nameservers; Cloudflare's cached NXDOMAIN was cleared at one.one.one.one/purge-cache.
- [x] **App links on Android:** Play's app-signing SHA-256 into both
      `assetlinks.json` (site/public and web/); `app.modiin4u.co.il` either
      set up or dropped from AndroidManifest's intent filter in the next
      build — Android verifies all claimed hosts or none.
      — 14 Oct: Play's key (`08:CE:11:…:72:B6`) added to both files and live on www; Google's Digital Asset Links API lists all three keys. Still open: `app.modiin4u.co.il` (record added at uPress that evening, not yet served).
      — 15 Oct: `app.modiin4u.co.il` live (uPress published the record overnight); https with its own certificate (to 13 Jan 2027); both app-link files served there with all three keys and the iOS app ID. Google's Digital Asset Links API had not fetched the new host yet at first check.

## F. After

- [x] Google Search Console, **before the switch:** how the property is
      verified. It is a Domain property, `modiin4u.co.il`, verified by the
      client's TXT `google-site-verification=Pbe-6…` at uPress — it survives
      the move untouched; never remove that record when the A records
      change. We have user access (not owner) since 14 Oct; the client
      adds anyone else.
- [x] Google Search Console: the new sitemap; watch Coverage for a week.
      The old `/sitemap_index.xml` already 301s to it. Check
      `https://www.modiin4u.co.il/robots.txt` has no `Disallow: /search`
      without its slash (it would block `/search-rest-modiin/`).
      — sitemap submitted 14 Oct — Success, 1,122 discovered; watching Coverage for the week; the nine old WordPress sitemaps to remove.
- [x] Search Console → URL inspection → Request indexing for the home page,
      `/search-rest-modiin/`, `/news/` and `/business/`.
      — done 14 Oct — all four "on Google".
- [ ] PageSpeed Insights (pagespeed.web.dev) on the home page, an article
      and `/search-rest-modiin/` on the live domain: LCP under 2.5 s on
      mobile.
- [ ] The Flutter website on sslip.io and the bare IP: retired; its
      certificate, nginx block and app-link entries removed.
- [ ] Supabase: billing alerts on; the spend cap back on after the 22 Oct
      reset, once no build in use asks Supabase to resize photos.
- [ ] An uptime check on www, `/_next/image/`, the panel, and certificate
      expiry.
