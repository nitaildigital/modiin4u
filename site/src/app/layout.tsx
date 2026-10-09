import type { Metadata, Viewport } from 'next';
import { Inter, Nunito, Rubik } from 'next/font/google';
import Script from 'next/script';
import './globals.css';
import { getLang } from '@/lib/i18n';
import { SITE_URL } from '@/lib/config';
import { SITE_NAME } from '@/lib/seo';
import { Footer } from '@/components/chrome/Footer';
import { MobileTabBar } from '@/components/chrome/MobileTabBar';
import { Analytics } from '@/components/chrome/Analytics';
import { PushBoot } from '@/components/push/PushBoot';

const inter = Inter({ subsets: ['latin'], variable: '--font-inter', display: 'swap' });
const rubik = Rubik({ subsets: ['latin', 'hebrew'], variable: '--font-rubik', display: 'swap' });
const nunito = Nunito({ subsets: ['latin'], variable: '--font-nunito', display: 'swap' });

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: SITE_NAME,
  icons: { icon: '/favicon.png', apple: '/icons/Icon-192.png' },
};

export const viewport: Viewport = { width: 'device-width', initialScale: 1 };

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const lang = await getLang();
  return (
    <html lang={lang} dir={lang === 'he' ? 'rtl' : 'ltr'} className={`${inter.variable} ${rubik.variable} ${nunito.variable}`}>
      <body className="min-h-screen font-sans antialiased">
        {children}
        <Footer lang={lang} />
        <MobileTabBar lang={lang} />
        <Analytics />
        <PushBoot lang={lang} />
        {/* The client's PersonaAI chat; the "Ask" buttons open it. */}
        <Script id="personaai-config" strategy="afterInteractive">{`
          window.PersonaAI = { businessId: "25ea67c7-94cd-4771-8f71-1d530bc7b2a1", position: "bottom-right",
            primaryColor: "#5B21E6", showWelcomeBubble: false,
            offsetBottom: window.innerWidth < 1100 ? 92 : 20, offsetSide: 20 };
        `}</Script>
        <Script src="https://personaai.me/widget.js" strategy="lazyOnload" />
      </body>
    </html>
  );
}
