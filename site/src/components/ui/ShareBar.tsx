'use client';
import { Share } from 'iconsax-react';

/** Share the page: Facebook, WhatsApp, X, e-mail (web_article_screen). */
export function ShareBar({ url, title, label }: { url: string; title: string; label: string }) {
  const u = encodeURIComponent(url);
  const t = encodeURIComponent(title);
  const links: [string, string, string][] = [
    ['Facebook', `https://www.facebook.com/sharer/sharer.php?u=${u}`, '/web/news/share_facebook.svg'],
    ['WhatsApp', `https://wa.me/?text=${t}%20${u}`, '/web/news/share_whatsapp.svg'],
    ['X', `https://twitter.com/intent/tweet?url=${u}&text=${t}`, '/web/news/share_x.svg'],
    ['Email', `mailto:?subject=${t}&body=${u}`, '/web/news/share_mail.svg'],
  ];
  return (
    <div className="flex items-center justify-between rounded-xl border border-card-border px-6 py-5">
      <span className="flex items-center gap-3 text-xs font-medium uppercase text-ink"><Share size={24} color="currentColor" />{label}</span>
      <span className="flex items-center gap-5 border-s border-line ps-6">
        {links.map(([name, href, icon]) => (
          <a key={name} href={href} target="_blank" rel="noopener" aria-label={name}>
            <img src={icon} alt="" width={28} height={28} className="size-7 object-contain" onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }} />
          </a>
        ))}
      </span>
    </div>
  );
}
