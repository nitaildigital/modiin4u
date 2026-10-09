# Launch runbook — moving www.modiin4u.co.il from WordPress to the new site

The steps in order, each with its command or where it is done. LAUNCH_TEST.md
is what to check once it is live; PLAN.md says why each step exists. Tick
each line as it is done.

## A. A week before

- [ ] **DNS at uPress:** lower the TTL of `www`, the bare domain and `app` to
      300 s, so the switch takes minutes. Leave the MX, SPF and DKIM records
      as they are — mail stays where it is.
- [ ] **Decide the panel's address** (its own subdomain, e.g. `panel.`) and
      ask the client for its DNS record with the others.
- [ ] **Supabase → Authentication → URL configuration:** Site URL
      `https://www.modiin4u.co.il`; redirect allow-list: `https://www.modiin4u.co.il/**`,
      `https://modiin4u.co.il/**`, `https://app.modiin4u.co.il/**`, the panel's
      address. Keep the sslip.io entry until the move is done.
- [ ] **Google Cloud → the web keys** (Maps tiles, Places web): add
      `www.modiin4u.co.il/*`, `modiin4u.co.il/*` and the panel's address to
      the allowed referrers. The app keys are restricted to the apps already.

## B. Freeze WordPress (the day before)

- [ ] Ask the client to stop publishing on WordPress from now on (the panel
      takes over).
- [ ] `python3 tool/snapshot_wp_seo.py` — what Google reads on every page,
      again, after the last WordPress edit.
- [ ] Import what was published since the last import:
      `python3 tool/import_new_wordpress.py` (it keeps a registry, `--undo`).
- [ ] `python3 tool/copy_wp_uploads.py` — the old images onto the server, again
      (12 failed last time, plus anything uploaded since).
- [ ] Export WordPress's redirect rules from its admin (Redirection / Yoast),
      and add any the site does not already answer to `site/next.config.ts`.
- [ ] `python3 tool/check_seo_parity.py http://localhost:3100` on a production
      build — every WordPress page at its address, with its title, description,
      H1 and menu. Businesses the client closed answer "not listed" (404):
      his decision whether they keep a page.

## C. Remove what is not real

- [ ] `python3 tool/seed_sample_content.py --undo --dry-run`, read it, then
      `python3 tool/seed_sample_content.py --undo` — the demo events, deals,
      listings, reviews, banners. It restores a field only where it still holds
      the value the script set, so the client's later edits stand.
- [ ] `python3 tool/remove_seed_remote.py`, read it, then `--apply` — the 19
      placeholder businesses, 10 articles and 10 events from `seed_remote.sql`
      (invented phone numbers and view counts).
- [ ] `python3 tool/tmp_admin.py --list`, then `--purge` — leftover test admins.
- [ ] Test rows and test accounts made during testing: none should be left
      (each test deletes its own; LAUNCH_TEST.md).

## D. The switch

- [ ] Build and deploy the Next.js site for Linux (the image library is per
      platform): `tool/deploy_site.sh --live` — `--live` turns on the
      business statistics and article views; `SEO_LIVE=1` in
      `/etc/modiin4u-site.env` opens indexing and the analytics.
- [ ] nginx: `deploy/next/cache.conf` into `/etc/nginx/conf.d/`, the www and
      bare-domain server blocks with `include proxy.conf`, then `nginx -t` and
      reload. Never `certbot --nginx` (deploy/README.md).
- [ ] DNS: `www` and the bare domain → 45.93.94.49; certificates with
      `tool/enable_domain.sh`.
- [ ] Check at once: `curl -sI https://www.modiin4u.co.il/` (200),
      `curl -s https://www.modiin4u.co.il/robots.txt` (no `Disallow: /`),
      `/sitemap.xml`, one `/_next/image/` photo, one old address
      (`/news/<slug>/`), the bell's Turn on.

## E. Links that still point at the test server

- [ ] **Notifications:** the `push-dispatch` function's `SITE_URL` →
      `https://www.modiin4u.co.il` (`tool/setup_push.py` sets it — check its
      default is no longer sslip.io before re-running it).
- [ ] **Invitations:** the `site_url` setting (step-group links) → www.
- [ ] **App sign-up links:** `AUTH_REDIRECT_URL` for app builds →
      `https://www.modiin4u.co.il/auth/callback` (in the allow-list above).
- [ ] **App links:** add www to `ios/Runner/Runner.entitlements` and
      `android/app/src/main/AndroidManifest.xml`; `apple-app-site-association`
      and `assetlinks.json` (with Play's signing certificate) served from www.
- [ ] **The panel** on its own https address; the bare IP no longer serves it.

## F. After

- [ ] Google Search Console: the new sitemap; watch Coverage for a week.
- [ ] The Flutter website on sslip.io and the bare IP: retired; its
      certificate, nginx block and app-link entries removed.
- [ ] Supabase: billing alerts on; the spend cap back on after the 22 Oct
      reset, once no build in use asks Supabase to resize photos.
- [ ] An uptime check on www, `/_next/image/`, the panel, and certificate
      expiry.
