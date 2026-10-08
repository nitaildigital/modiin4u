import Script from 'next/script';
import { ANALYTICS, SEO_LIVE } from '@/lib/config';

/** The old site's analytics — Google Analytics, Clarity and Hotjar — on the
 *  live site only, so the copies on other addresses never count as visits. */
export function Analytics() {
  if (!SEO_LIVE) return null;
  return (
    <>
      <Script src={`https://www.googletagmanager.com/gtag/js?id=${ANALYTICS.ga4}`} strategy="afterInteractive" />
      <Script id="ga4" strategy="afterInteractive">{`
        window.dataLayer = window.dataLayer || []; function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date()); gtag('config', '${ANALYTICS.ga4}');
      `}</Script>
      <Script id="clarity" strategy="afterInteractive">{`
        (function(c,l,a,r,i,t,y){c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
        t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
        y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);})(window,document,"clarity","script","${ANALYTICS.clarity}");
      `}</Script>
      <Script id="hotjar" strategy="afterInteractive">{`
        (function(h,o,t,j,a,r){h.hj=h.hj||function(){(h.hj.q=h.hj.q||[]).push(arguments)};
        h._hjSettings={hjid:${ANALYTICS.hotjar},hjsv:6};a=o.getElementsByTagName('head')[0];
        r=o.createElement('script');r.async=1;r.src=t+h._hjSettings.hjid+j+h._hjSettings.hjsv;a.appendChild(r);
        })(window,document,'https://static.hotjar.com/c/hotjar-','.js?sv=');
      `}</Script>
    </>
  );
}
