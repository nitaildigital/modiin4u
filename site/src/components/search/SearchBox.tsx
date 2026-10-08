'use client';
import { useRouter } from 'next/navigation';
import { SearchNormal1 } from 'iconsax-react';

/** Searches again from the results page. A plain GET form underneath, so it
 *  works before the script has loaded too; with it, the page changes in
 *  place. An empty bar goes nowhere. */
function useSubmit() {
  const router = useRouter();
  return (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const q = String(new FormData(e.currentTarget).get('q') ?? '').trim();
    if (q) router.push(`/search/?q=${encodeURIComponent(q)}`);
  };
}

/** The desktop bar (web_search_results_screen.dart, _buildSearchBar): 64
 *  high, the glass, the words, and Search at the end. */
export function DeskSearchBox({ q, placeholder, button }: { q: string; placeholder: string; button: string }) {
  const submit = useSubmit();
  return (
    <form action="/search/" method="get" role="search" onSubmit={submit}
      className="flex h-16 max-w-[820px] items-center rounded-[50px] border border-line bg-white shadow-[0_6px_24px_rgba(0,0,0,0.06)]">
      <SearchNormal1 size={20} color="#6D6D6D" className="ms-6 shrink-0" />
      <input key={q} name="q" type="search" defaultValue={q} placeholder={placeholder} aria-label={placeholder} autoComplete="off"
        className="mx-3 h-11 min-w-0 flex-1 rounded-full bg-section px-6 text-base text-[#1C1C1E] outline-none placeholder:text-[#6D6D6D] [&::-webkit-search-cancel-button]:hidden" />
      <button type="submit" className="me-2 h-12 shrink-0 rounded-[50px] bg-midblue px-8 text-base font-medium text-white hover:bg-midblue/90">{button}</button>
    </form>
  );
}

/** The phone's pill (search_results_screen.dart): the words searched and
 *  how many were found — typed into, to search again. */
export function PhoneSearchBox({ q, placeholder, count }: { q: string; placeholder: string; count: string }) {
  const submit = useSubmit();
  return (
    <form action="/search/" method="get" role="search" onSubmit={submit}
      className="mx-5 mb-4 mt-2 flex items-center gap-2.5 rounded-[50px] bg-surface px-4 py-2.5">
      <SearchNormal1 size={20} color="#888780" className="shrink-0" />
      <input key={q} name="q" type="search" enterKeyHint="search" defaultValue={q} placeholder={placeholder} aria-label={placeholder}
        className="min-w-0 flex-1 bg-transparent font-rubik text-[15px] text-ink outline-none placeholder:text-gray-light [&::-webkit-search-cancel-button]:hidden" />
      {count && <span className="shrink-0 font-rubik text-xs text-gray-meta">{count}</span>}
    </form>
  );
}
