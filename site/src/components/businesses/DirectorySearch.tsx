'use client';
import { createContext, useContext, useMemo, useRef, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { CloseCircle, SearchNormal1, Shop, Category } from 'iconsax-react';

/** What the directory's search suggests from: every business and category
 *  on the page, with what it is matched on, lower case. */
export type Suggestible = { name: string; href: string; line: string; search: string };

/** The directory's search (9 Oct), as WordPress's was: while typing, the
 *  categories and businesses that match drop down under the box, each a
 *  link; Search or Enter opens the site's search results (/search/?q=, as
 *  WordPress's form opened /?s=). It had narrowed the grid further down and
 *  scrolled to it, which read as "the button only scrolls". */
const Ctx = createContext<{ businesses: Suggestible[]; categories: Suggestible[] }>({ businesses: [], categories: [] });

export function DirectorySearchProvider({ businesses, categories, children }: {
  businesses: Suggestible[]; categories: Suggestible[]; children: React.ReactNode;
}) {
  return <Ctx.Provider value={{ businesses, categories }}>{children}</Ctx.Provider>;
}

const MAX_BUSINESSES = 6;
const MAX_CATEGORIES = 3;

function useSuggest(query: string) {
  const { businesses, categories } = useContext(Ctx);
  return useMemo(() => {
    const q = query.trim().toLowerCase();
    if (q.length < 2) return { cats: [], biz: [], more: 0 };
    const cats = categories.filter((c) => c.search.includes(q)).slice(0, MAX_CATEGORIES);
    const all = businesses.filter((b) => b.search.includes(q));
    return { cats, biz: all.slice(0, MAX_BUSINESSES), more: all.length };
  }, [businesses, categories, query]);
}

/** The box and its dropdown; [big] is the desktop hero's 64 px pill with the
 *  Search button (web_businesses_screen _buildSearchBar), else the phone's
 *  48 px outlined one (businesses_screen _SearchField). */
function SearchBox({ placeholder, button, lang, big }: { placeholder: string; button?: string; lang: 'he' | 'en'; big: boolean }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const router = useRouter();
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState(false);
  const box = useRef<HTMLFormElement>(null);
  const { cats, biz, more } = useSuggest(query);
  const q = query.trim();
  const results = `/search/?q=${encodeURIComponent(q)}`;
  const shown = open && q.length >= 2;

  return (
    <form ref={box} role="search" className="relative"
      onSubmit={(e) => { e.preventDefault(); if (q) { setOpen(false); router.push(results); } }}
      onBlur={(e) => { if (!box.current?.contains(e.relatedTarget as Node)) setOpen(false); }}>
      <div className={big
        ? 'flex h-16 items-center rounded-full border border-line bg-white shadow-[0_6px_24px_rgba(0,0,0,0.06)]'
        : 'flex h-12 items-center gap-2.5 rounded-3xl border border-line bg-white px-4'}>
        <SearchNormal1 size={20} color="#6D6D6D" className={big ? 'ms-6 shrink-0' : 'shrink-0'} />
        <input type="search" enterKeyHint="search" value={query} placeholder={placeholder} aria-label={placeholder}
          role="combobox" aria-expanded={shown} aria-controls="directory-suggestions" autoComplete="off"
          onChange={(e) => { setQuery(e.target.value); setOpen(true); }} onFocus={() => setOpen(true)}
          onKeyDown={(e) => { if (e.key === 'Escape') setOpen(false); }}
          className={`h-full min-w-0 flex-1 bg-transparent outline-none placeholder:text-[#6D6D6D] [&::-webkit-search-cancel-button]:hidden ${big ? 'mx-3 text-base text-[#1C1C1E]' : 'text-sm'}`} />
        {query && (
          <button type="button" onClick={() => { setQuery(''); setOpen(false); }} className="px-2" aria-label={t('ניקוי', 'Clear')}>
            <CloseCircle size={20} color="#6D6D6D" />
          </button>
        )}
        {big && button && <button type="submit" className="me-2 ms-2 h-12 rounded-full bg-midblue px-8 text-base font-medium text-white hover:bg-midblue/90">{button}</button>}
      </div>
      {shown && (
        <div id="directory-suggestions" className="absolute inset-x-0 top-full z-40 mt-2 overflow-hidden rounded-2xl border border-line bg-white py-2 text-start shadow-[0_12px_32px_rgba(0,0,0,0.12)]">
          {cats.length === 0 && biz.length === 0 ? (
            <p className="px-5 py-3 text-sm text-gray-text">{t(`לא נמצאו עסקים עבור „${q}”`, `No businesses found for “${q}”`)}</p>
          ) : (
            <ul>
              {cats.map((c) => (
                <li key={c.href}>
                  <Link href={c.href} className="flex items-center gap-3 px-5 py-2.5 hover:bg-surface">
                    <Category size={18} color="#123A72" className="shrink-0" />
                    <span className="min-w-0 flex-1 truncate text-sm font-medium text-navy">{c.name}</span>
                    <span className="shrink-0 text-xs text-gray-meta">{c.line}</span>
                  </Link>
                </li>
              ))}
              {cats.length > 0 && biz.length > 0 && <li className="my-1 border-t border-line" aria-hidden />}
              {biz.map((b) => (
                <li key={b.href}>
                  <Link href={b.href} className="flex items-center gap-3 px-5 py-2.5 hover:bg-surface">
                    <Shop size={18} color="#6D6D6D" className="shrink-0" />
                    <span dir="auto" className="min-w-0 flex-1 truncate text-sm text-[#1C1C1E]">{b.name}</span>
                    {b.line && <span className="max-w-[45%] shrink-0 truncate text-xs text-gray-meta">{b.line}</span>}
                  </Link>
                </li>
              ))}
            </ul>
          )}
          <Link href={results} className="mt-1 block border-t border-line px-5 pt-3 pb-1.5 text-sm font-medium text-midblue hover:underline">
            {more > MAX_BUSINESSES ? t(`לכל ${more} התוצאות עבור „${q}”`, `All ${more} results for “${q}”`) : t(`חיפוש „${q}” בכל האתר`, `Search the whole site for “${q}”`)}
          </Link>
        </div>
      )}
    </form>
  );
}

export function DesktopSearch({ placeholder, button, lang }: { placeholder: string; button: string; lang: 'he' | 'en' }) {
  return <SearchBox placeholder={placeholder} button={button} lang={lang} big />;
}

export function PhoneSearch({ placeholder, lang }: { placeholder: string; lang: 'he' | 'en' }) {
  return <SearchBox placeholder={placeholder} lang={lang} big={false} />;
}
