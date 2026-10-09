'use client';
import { ShareMenu } from '@/components/events/ShareMenu';

/** The bar under an article's picture (web_article_screen.dart, _buildStatsBar):
 *  the views and the Share menu (with Copy link) on one side, the four share
 *  links on the other. A count is shown only when the row has one — never
 *  "0" — as the current site does. */
export function ShareBar({ url, title, lang, views = 0, shares = 0 }: {
  url: string; title: string; lang: 'he' | 'en'; views?: number; shares?: number;
}) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const u = encodeURIComponent(url);
  const ti = encodeURIComponent(title);
  const links: [string, string, string][] = [
    ['Facebook', `https://www.facebook.com/sharer/sharer.php?u=${u}`, '/web/news/share_facebook.svg'],
    ['WhatsApp', `https://wa.me/?text=${ti}%20${u}`, '/web/news/share_whatsapp.svg'],
    ['X', `https://twitter.com/intent/tweet?url=${u}&text=${ti}`, '/web/news/share_x.svg'],
    ['Email', `mailto:?subject=${ti}&body=${u}`, '/web/news/share_mail.svg'],
  ];
  return (
    <div className="flex flex-wrap items-center justify-between gap-4 rounded-xl border border-card-border px-6 py-4">
      <span className="flex items-center gap-6">
        {views > 0 && (
          <span className="flex items-center gap-2 text-sm text-ink">
            <img src="/web/news/stat_views.svg" alt="" className="size-6" />
            <span className="font-semibold">{String(views).replace(/\B(?=(\d{3})+(?!\d))/g, ',')}</span>
            <span className="text-gray-meta">{t('צפיות', 'Views')}</span>
          </span>
        )}
        <ShareMenu url={url} title={title} lang={lang} className="flex items-center gap-2 text-sm text-ink hover:text-midblue">
          <img src="/web/news/stat_share.svg" alt="" className="size-6" />
          {shares > 0 && <span className="font-semibold">{shares}</span>}
          <span className="font-medium">{t('שיתוף', 'Share')}</span>
        </ShareMenu>
      </span>
      <span className="flex items-center gap-5 border-s border-line ps-6">
        {links.map(([name, href, icon]) => (
          <a key={name} href={href} target={href.startsWith('mailto:') ? '_self' : '_blank'} rel="noopener" aria-label={name}>
            <img src={icon} alt="" width={28} height={28} className="size-7 object-contain" />
          </a>
        ))}
      </span>
    </div>
  );
}
