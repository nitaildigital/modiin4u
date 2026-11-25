import type { Metadata, Viewport } from 'next';
import { Inter, Nunito, Rubik } from 'next/font/google';
import Script from 'next/script';
import { Suspense } from 'react';
import { prefetchDNS } from 'react-dom';
import './globals.css';
import { getLang } from '@/lib/i18n';
import { SEO_LIVE, SITE_URL } from '@/lib/config';
import { SITE_NAME } from '@/lib/seo';
import { Footer } from '@/components/chrome/Footer';
import { MobileTabBar } from '@/components/chrome/MobileTabBar';
import { NavProgress } from '@/components/chrome/NavProgress';
import { Analytics } from '@/components/chrome/Analytics';
import { CookieConsent } from '@/components/chrome/CookieConsent';
import { PushBoot } from '@/components/push/PushBoot';
import { PushBanner } from '@/components/push/PushBanner';
import { ChatPreload } from '@/components/home/AskButton';

const inter = Inter({ subsets: ['latin'], variable: '--font-inter', display: 'swap' });
const rubik = Rubik({ subsets: ['latin', 'hebrew'], variable: '--font-rubik', display: 'swap' });
const nunito = Nunito({ subsets: ['latin'], variable: '--font-nunito', display: 'swap' });

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: SITE_NAME,
  // The app's icon (13 Oct): the tab, and a phone's home screen.
  icons: { icon: [{ url: '/favicon.png', sizes: '96x96', type: 'image/png' }], apple: [{ url: '/icons/apple-touch-icon.png', sizes: '180x180' }] },
  // The news feed for pages without their own metadata; pageMetadata names
  // it on the rest.
  alternates: { types: { 'application/rss+xml': [{ url: '/feed/', title: SITE_NAME }] } },
};

export const viewport: Viewport = { width: 'device-width', initialScale: 1 };

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const lang = await getLang();
  // The chat's address looked up in advance: a question to the visitor's own
  // DNS, nothing sent to PersonaAI (AskButton.tsx).
  prefetchDNS('https://personaai.me');
  return (
    <html lang={lang} dir={lang === 'he' ? 'rtl' : 'ltr'} className={`${inter.variable} ${rubik.variable} ${nunito.variable}`}>
      <body className="min-h-screen font-sans antialiased">
        {children}
        <Footer lang={lang} />
        <MobileTabBar lang={lang} />
        {/* It reads the query string, which needs a boundary of its own. */}
        <Suspense fallback={null}><NavProgress /></Suspense>
        <Analytics live={SEO_LIVE} />
        <CookieConsent lang={lang} />
        <PushBoot lang={lang} />
        <PushBanner lang={lang} />
        {/* The client's PersonaAI chat; the "Ask" buttons open it. Its script
            keeps visit details in the browser, so it waits for the visitor:
            loaded once the page has settled for those who accepted marketing
            cookies (ChatPreload), otherwise by the first "Ask" (the cookie
            notice, 23 Oct; AskButton.tsx). */}
        <Script id="personaai-config" strategy="afterInteractive">{`
          window.PersonaAI = { businessId: "25ea67c7-94cd-4771-8f71-1d530bc7b2a1", position: "bottom-right",
            primaryColor: "#5B21E6", showWelcomeBubble: false,
            offsetBottom: window.innerWidth < 1100 ? 92 : 20, offsetSide: 20 };
        `}</Script>
        <ChatPreload />
      </body>
    </html>
  );
}
