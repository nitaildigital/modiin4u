'use client';
import { createContext, useContext, useState } from 'react';
import Link from 'next/link';
import { ArrowRight2, ArrowLeft2, Bank, Book1, Bus, Candle, Clock, CloseCircle, Danger, DocumentText, Health, SearchNormal1, Tree } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';

/** One of the Municipal page's nine tiles (web_municipal_screen.dart and
 *  municipal_screen.dart): its words, its icons and where it leads. */
export type Service = {
  id: string;
  label: string;
  /** The phone tile's label, broken where the app breaks it. */
  phoneLabel: string;
  blurb: string;
  /** The phone tile's drawing, from the Figma "Municipal" frame. */
  phoneIcon: string;
  href: string;
  external: boolean;
};

const DESK_ICONS: Record<string, typeof Clock> = {
  parking: Clock, shabbat: Candle, institutions: Bank, health: Health, education: Book1,
  transport: Bus, emergency: Danger, parks: Tree, forms: DocumentText,
};

const Query = createContext<{ q: string; set: (q: string) => void }>({ q: '', set: () => {} });

/** The query the search bars type into and the tiles narrow by. */
export function ServiceSearchProvider({ children }: { children: React.ReactNode }) {
  const [q, set] = useState('');
  return <Query.Provider value={{ q, set }}>{children}</Query.Provider>;
}

function scrollToServices() {
  document.getElementById('services')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

/** The desktop hero's search pill: it narrows the services as you type, and
 *  Search (or Enter) brings them into view. */
export function DeskSearchBar({ lang }: { lang: Lang }) {
  const { q, set } = useContext(Query);
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  return (
    <form role="search" onSubmit={(e) => { e.preventDefault(); scrollToServices(); }}
      className="mx-auto flex h-16 max-w-[820px] items-center rounded-full border border-line bg-white shadow-[0_6px_24px_rgba(0,0,0,0.06)]">
      <SearchNormal1 size={20} color="#6D6D6D" className="ms-6 shrink-0" />
      <input value={q} onChange={(e) => set(e.target.value)} placeholder={t('חיפוש שירותי עירייה...', 'Search municipal services...')}
        aria-label={t('חיפוש שירותי עירייה', 'Search municipal services')}
        className="mx-3 min-w-0 flex-1 bg-transparent text-base text-[#1C1C1E] outline-none placeholder:text-[#6D6D6D]" />
      {q && (
        <button type="button" onClick={() => set('')} aria-label={t('ניקוי', 'Clear')} className="px-2">
          <CloseCircle size={20} color="#6D6D6D" />
        </button>
      )}
      <button type="submit" className="me-2 ms-2 h-12 rounded-full bg-midblue px-8 text-base font-medium text-white">{t('חיפוש', 'Search')}</button>
    </form>
  );
}

/** The phone's search pill, which narrows the tiles by name. */
export function PhoneSearchBar({ lang }: { lang: Lang }) {
  const { q, set } = useContext(Query);
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  return (
    <div className="flex h-12 items-center gap-2 rounded-full border border-line bg-white px-4">
      <SearchNormal1 size={18} color="#6D6D6D" className="shrink-0" />
      <input type="search" value={q} onChange={(e) => set(e.target.value)} placeholder={t('חיפוש שירותי עירייה...', 'Search municipal services...')}
        aria-label={t('חיפוש שירותי עירייה', 'Search municipal services')}
        className="min-w-0 flex-1 bg-transparent text-sm text-black outline-none placeholder:text-[#6D6D6D]" />
    </div>
  );
}

function ServiceLink({ s, className, children }: { s: Service; className: string; children: React.ReactNode }) {
  return s.external
    ? <a href={s.href} target="_blank" rel="noopener" className={className}>{children}</a>
    : <Link href={s.href} className={className}>{children}</Link>;
}

/** The desktop's three-up grid of service cards, its line under the heading
 *  saying how many match the search, and what to do when none does. */
export function DeskServiceGrid({ services, lang }: { services: Service[]; lang: Lang }) {
  const { q, set } = useContext(Query);
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const query = q.trim();
  const needle = query.toLowerCase();
  const shown = needle ? services.filter((s) => s.label.toLowerCase().includes(needle) || s.blurb.toLowerCase().includes(needle)) : services;
  const Chevron = lang === 'he' ? ArrowLeft2 : ArrowRight2;
  return (
    <>
      <p className="mt-2 text-sm leading-[1.21] text-gray-text">
        {!query ? t('גלו שירותים ומידע', 'Explore services and information')
          : shown.length === 1 ? t(`שירות אחד תואם ל"${query}"`, `1 service matches "${query}"`)
          : t(`${shown.length} שירותים תואמים ל"${query}"`, `${shown.length} services match "${query}"`)}
      </p>
      {shown.length === 0 ? (
        <div className="mt-8 flex h-[280px] flex-col items-center justify-center rounded-xl border border-line">
          <Bank size={44} color="#5F5E5A80" />
          <p className="mt-4 text-lg font-semibold text-[#1C1C1E]">{t('לא נמצא שירות שתואם לחיפוש', 'No service matches your search')}</p>
          <p className="mt-2 text-sm text-gray-text">{t('נסו מילה אחרת, או התקשרו למוקד העירוני 106.', 'Try a different word, or call the municipal hotline on 106.')}</p>
          <button type="button" onClick={() => set('')} className="mt-5 rounded-full bg-midblue px-7 py-3 text-sm font-medium text-white">{t('נקו חיפוש', 'Clear search')}</button>
        </div>
      ) : (
        <ul className="mt-8 grid grid-cols-3 gap-5">
          {shown.map((s) => {
            const Icon = DESK_ICONS[s.id] ?? Bank;
            return (
              <li key={s.id}>
                <ServiceLink s={s} className="group flex h-32 items-start gap-4 rounded-xl border border-line bg-white p-6 transition-colors hover:border-midblue">
                  <span className="flex size-14 shrink-0 items-center justify-center rounded-[14px] bg-midblue/[0.06]">
                    <Icon size={26} color="#123A72" />
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-lg font-semibold leading-tight text-[#1C1C1E]">{s.label}</span>
                    <span className="mt-1.5 line-clamp-2 block text-sm leading-[1.35] text-gray-text">{s.blurb}</span>
                  </span>
                  <Chevron size={20} className="mt-4 shrink-0 text-[#6D6D6D] group-hover:text-midblue" color="currentColor" />
                </ServiceLink>
              </li>
            );
          })}
        </ul>
      )}
    </>
  );
}

/** The phone's 3 × 3 grid of tiles, each the frame's drawing over its name. */
export function PhoneServiceGrid({ services }: { services: Service[] }) {
  const { q } = useContext(Query);
  const needle = q.trim().toLowerCase();
  const shown = needle ? services.filter((s) => s.phoneLabel.toLowerCase().includes(needle)) : services;
  return (
    <ul className="mt-[15px] grid grid-cols-3 gap-2">
      {shown.map((s) => (
        <li key={s.id}>
          <ServiceLink s={s} className="flex h-[120px] flex-col items-center justify-center rounded-xl border border-line bg-white px-1.5 text-center">
            <img src={s.phoneIcon} alt="" width={32} height={32} className="size-8" />
            <span className="mt-[9px] whitespace-pre-line text-sm font-medium leading-[1.4] text-navy">{s.phoneLabel}</span>
          </ServiceLink>
        </li>
      ))}
    </ul>
  );
}
