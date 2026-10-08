'use client';
import { useState } from 'react';
import Link from 'next/link';
import { ArrowDown, ArrowUp2, Bag2, Book1, Brush, Cake, Car, Coffee, Health, Reserve, Setting2, Shop, Ticket, Weight } from 'iconsax-react';

export type Tile = { id: string; href: string; name: string; count: number; slug: string };

/** The desktop cards' colours, start and end, in turn (_categoryPalette). */
const PALETTE: [string, string][] = [
  ['#1B3A2D', '#2E5A47'], ['#3E2723', '#5D4037'], ['#2D1B4E', '#4A2D6E'], ['#4E1B3A', '#6E2D54'],
  ['#1A237E', '#283593'], ['#4E342E', '#6D4C41'], ['#263238', '#37474F'], ['#1B5E20', '#2E7D32'],
];

function Icon({ slug }: { slug: string }) {
  const p = { size: 48, color: 'currentColor', variant: 'Bold' as const };
  switch (slug) {
    case 'restaurants': case 'meat': case 'fish': case 'mediterranean': case 'asian': return <Reserve {...p} />;
    case 'pizza': return <Cake {...p} />;
    case 'cafe-bakery': return <Coffee {...p} />;
    case 'beauty': return <Brush {...p} />;
    case 'sports-fitness': return <Weight {...p} />;
    case 'automotive': return <Car {...p} />;
    case 'education': return <Book1 {...p} />;
    case 'health': return <Health {...p} />;
    case 'shopping': return <Bag2 {...p} />;
    case 'entertainment': return <Ticket {...p} />;
    case 'services': return <Setting2 {...p} />;
    default: return <Shop {...p} />;
  }
}

/** "Browse by Category" (web_businesses_screen _buildCategoriesSection): the
 *  busiest main categories as 200-high gradient cards, four a row, eight
 *  shown; "All N categories" opens every category in the menus, busiest
 *  first. Each card opens its category's page. */
export function CategoryTiles({ main, all, lang }: { main: Tile[]; all: Tile[]; lang: 'he' | 'en' }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [open, setOpen] = useState(false);
  return (
    <section className="mt-16">
      <div className="flex items-center gap-5">
        <h2 className="flex-1 font-nunito text-[28px] font-semibold leading-[34px] text-midblue">{t('עיון לפי קטגוריה', 'Browse by Category')}</h2>
        {all.length > 8 && (
          <button type="button" onClick={() => setOpen(!open)} className="flex items-center gap-1.5 text-sm font-medium text-midblue">
            {open ? <ArrowUp2 size={18} color="currentColor" /> : <ArrowDown size={18} color="currentColor" />}
            {open ? t('הצג פחות', 'Show fewer') : t(`כל ${all.length} הקטגוריות`, `All ${all.length} categories`)}
          </button>
        )}
      </div>
      {/* Both lists are in the page, so every category is a link a search
          engine can follow; the button only swaps which one shows. */}
      <Grid tiles={main.slice(0, 8)} hidden={open} lang={lang} />
      <Grid tiles={all} hidden={!open} lang={lang} />
    </section>
  );
}

function Grid({ tiles, hidden, lang }: { tiles: Tile[]; hidden: boolean; lang: 'he' | 'en' }) {
  return (
    <ul className={`mt-6 grid grid-cols-4 gap-[25px] ${hidden ? 'hidden' : ''}`}>
      {tiles.map((c, i) => {
        const [start, end] = PALETTE[i % PALETTE.length];
        return (
          <li key={c.id}>
            <Link href={c.href} style={{ backgroundImage: `linear-gradient(to bottom, ${end}, ${start})` }}
              className="relative block h-[200px] overflow-hidden rounded-xl border-[3px] border-transparent transition-shadow hover:shadow-[0_8px_18px_rgba(0,0,0,0.18)]">
              <span className="absolute inset-0 bg-[linear-gradient(to_bottom,transparent_52.35%,#000000BB)]" />
              <span className="absolute end-5 top-5 text-white/15"><Icon slug={c.slug} /></span>
              <span className="absolute inset-x-5 bottom-5">
                <span className="line-clamp-2 text-xl font-semibold leading-[1.22] text-white">{c.name}</span>
                <span className="mt-1.5 block text-[13px] text-white/90">{c.count} {lang === 'he' ? 'עסקים' : 'businesses'}</span>
              </span>
            </Link>
          </li>
        );
      })}
    </ul>
  );
}
