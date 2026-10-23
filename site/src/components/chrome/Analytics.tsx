'use client';
import { useEffect } from 'react';
import Script from 'next/script';
import { ANALYTICS } from '@/lib/config';
import { useConsent } from '@/lib/consent';

/** The old site's analytics — Google Analytics, Clarity and Hotjar — and the
 *  Meta Pixel, on the live site only, so the copies on other addresses never
 *  count as visits. The pixel sends no advanced matching (form contents): the
 *  client has not decided on it. It counts page changes inside the site by
 *  itself, from the browser's history. Clarity and Hotjar, recordings rather
 *  than counts, load once the page has (lazyOnload): they were a third of
 *  the main thread's blocking time on a phone (15 Oct). GA4 and the pixel
 *  stay early, so a quick visit, and the landing page's store taps, count.
 *
 *  Google Analytics counts every visitor, whatever they choose (the client,
 *  23 Oct: the counts are needed either way), through Google's Consent Mode:
 *  with "analytics" accepted it uses its cookies as before; before a choice,
 *  or with "essential only", it stores nothing and sends cookieless pings,
 *  which Google counts and models. Clarity and Hotjar wait for "analytics",
 *  the pixel for "marketing"; Clarity is told the choice too (consentv2),
 *  as it expects for visitors from Europe. [live] is SEO_LIVE, read on the
 *  server. */
export function Analytics({ live }: { live: boolean }) {
  const consent = useConsent();
  const stats = consent?.analytics ? 'granted' : 'denied';
  const ads = consent?.marketing ? 'granted' : 'denied';

  // A choice made after the page loaded: Google is told at once.
  useEffect(() => {
    const gtag = (window as unknown as { gtag?: (...a: unknown[]) => void }).gtag;
    if (live && consent !== undefined && gtag) {
      gtag('consent', 'update', { analytics_storage: stats, ad_storage: ads, ad_user_data: ads, ad_personalization: ads });
    }
  }, [live, consent, stats, ads]);

  // Until the browser knows the choice (undefined), nothing; then Google
  // whatever it is, the rest by consent.
  if (!live || consent === undefined) return null;
  return (
    <>
      <Script src={`https://www.googletagmanager.com/gtag/js?id=${ANALYTICS.ga4}`} strategy="afterInteractive" />
      <Script id="ga4" strategy="afterInteractive">{`
        window.dataLayer = window.dataLayer || []; function gtag(){dataLayer.push(arguments);} window.gtag = gtag;
        gtag('consent', 'default', { analytics_storage: '${stats}', ad_storage: '${ads}', ad_user_data: '${ads}', ad_personalization: '${ads}' });
        gtag('js', new Date()); gtag('config', '${ANALYTICS.ga4}');
      `}</Script>
      {consent?.analytics && (
        <>
          {/* Not id="clarity": an element's id becomes a window property, and
              window.clarity was then this tag rather than Clarity's queue. */}
          <Script id="clarity-tag" strategy="lazyOnload">{`
            (function(c,l,a,r,i,t,y){c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
            t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
            y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);})(window,document,"clarity","script","${ANALYTICS.clarity}");
            window.clarity('consentv2', { ad_Storage: '${ads}', analytics_Storage: 'granted' });
          `}</Script>
          <Script id="hotjar" strategy="lazyOnload">{`
            (function(h,o,t,j,a,r){h.hj=h.hj||function(){(h.hj.q=h.hj.q||[]).push(arguments)};
            h._hjSettings={hjid:${ANALYTICS.hotjar},hjsv:6};a=o.getElementsByTagName('head')[0];
            r=o.createElement('script');r.async=1;r.src=t+h._hjSettings.hjid+j+h._hjSettings.hjsv;a.appendChild(r);
            })(window,document,'https://static.hotjar.com/c/hotjar-','.js?sv=');
          `}</Script>
        </>
      )}
      {consent?.marketing && (
        <Script id="meta-pixel" strategy="afterInteractive">{`
        !function(f,b,e,v,n,t,s){if(f.fbq)return;n=f.fbq=function(){n.callMethod?
        n.callMethod.apply(n,arguments):n.queue.push(arguments)};if(!f._fbq)f._fbq=n;
        n.push=n;n.loaded=!0;n.version='2.0';n.queue=[];t=b.createElement(e);t.async=!0;
        t.src=v;s=b.getElementsByTagName(e)[0];s.parentNode.insertBefore(t,s)}(window,
        document,'script','https://connect.facebook.net/en_US/fbevents.js');
        fbq('init', '${ANALYTICS.metaPixel}'); fbq('track', 'PageView');
      `}</Script>
      )}
    </>
  );
}
