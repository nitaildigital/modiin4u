import Script from 'next/script';
import { SEO_LIVE } from '@/lib/config';

/** A tap on a store badge, for the Meta Pixel the whole site loads from
 *  launch (chrome/Analytics.tsx) — so on the live site only, like the rest
 *  of the statistics. The ads point here: a page view says someone came, this
 *  says they went on to a store. */
export function LandingPixel() {
  if (!SEO_LIVE) return null;
  return (
    <Script id="landing-store-click" strategy="afterInteractive">{`
      document.addEventListener('click', function (e) {
        var a = e.target && e.target.closest && e.target.closest('a[data-store]');
        if (a && window.fbq) window.fbq('trackCustom', 'StoreClick', { store: a.getAttribute('data-store') });
      });
    `}</Script>
  );
}
