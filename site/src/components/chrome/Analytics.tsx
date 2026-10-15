import Script from 'next/script';
import { ANALYTICS, SEO_LIVE } from '@/lib/config';

/** The old site's analytics — Google Analytics, Clarity and Hotjar — and the
 *  Meta Pixel, on the live site only, so the copies on other addresses never
 *  count as visits. The pixel sends no advanced matching (form contents): the
 *  client has not decided on it. It counts page changes inside the site by
 *  itself, from the browser's history. Clarity and Hotjar, recordings rather
 *  than counts, load once the page has (lazyOnload): they were a third of
 *  the main thread's blocking time on a phone (15 Oct). GA4 and the pixel
 *  stay early, so a quick visit, and the landing page's store taps, count. */
export function Analytics() {
  if (!SEO_LIVE) return null;
  return (
    <>
      <Script src={`https://www.googletagmanager.com/gtag/js?id=${ANALYTICS.ga4}`} strategy="afterInteractive" />
      <Script id="ga4" strategy="afterInteractive">{`
        window.dataLayer = window.dataLayer || []; function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date()); gtag('config', '${ANALYTICS.ga4}');
      `}</Script>
      <Script id="clarity" strategy="lazyOnload">{`
        (function(c,l,a,r,i,t,y){c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
        t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
        y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);})(window,document,"clarity","script","${ANALYTICS.clarity}");
      `}</Script>
      <Script id="hotjar" strategy="lazyOnload">{`
        (function(h,o,t,j,a,r){h.hj=h.hj||function(){(h.hj.q=h.hj.q||[]).push(arguments)};
        h._hjSettings={hjid:${ANALYTICS.hotjar},hjsv:6};a=o.getElementsByTagName('head')[0];
        r=o.createElement('script');r.async=1;r.src=t+h._hjSettings.hjid+j+h._hjSettings.hjsv;a.appendChild(r);
        })(window,document,'https://static.hotjar.com/c/hotjar-','.js?sv=');
      `}</Script>
      <Script id="meta-pixel" strategy="afterInteractive">{`
        !function(f,b,e,v,n,t,s){if(f.fbq)return;n=f.fbq=function(){n.callMethod?
        n.callMethod.apply(n,arguments):n.queue.push(arguments)};if(!f._fbq)f._fbq=n;
        n.push=n;n.loaded=!0;n.version='2.0';n.queue=[];t=b.createElement(e);t.async=!0;
        t.src=v;s=b.getElementsByTagName(e)[0];s.parentNode.insertBefore(t,s)}(window,
        document,'script','https://connect.facebook.net/en_US/fbevents.js');
        fbq('init', '${ANALYTICS.metaPixel}'); fbq('track', 'PageView');
      `}</Script>
    </>
  );
}
