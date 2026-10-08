'use client';
import { createContext, useContext, useState } from 'react';
import { CloseCircle, SearchNormal1 } from 'iconsax-react';

/** The directory's search, shared by the box at the top of the page and the
 *  results further down: typing narrows the list in place, as the current
 *  site does, and Search (or Enter) brings the results into view. */
const Ctx = createContext<{ query: string; setQuery: (q: string) => void }>({ query: '', setQuery: () => {} });

export function DirectorySearchProvider({ children }: { children: React.ReactNode }) {
  const [query, setQuery] = useState('');
  return <Ctx.Provider value={{ query, setQuery }}>{children}</Ctx.Provider>;
}

export const useDirectorySearch = () => useContext(Ctx);

export const RESULTS_ID = 'results';

function toResults() {
  document.getElementById(RESULTS_ID)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

/** The desktop hero's box (web_businesses_screen _buildSearchBar): 64 high,
 *  a soft shadow, the blue Search button at its end. */
export function DesktopSearch({ placeholder, button }: { placeholder: string; button: string }) {
  const { query, setQuery } = useDirectorySearch();
  return (
    <form role="search" onSubmit={(e) => { e.preventDefault(); toResults(); }}
      className="flex h-16 items-center rounded-full border border-line bg-white shadow-[0_6px_24px_rgba(0,0,0,0.06)]">
      <SearchNormal1 size={20} color="#6D6D6D" className="ms-6 shrink-0" />
      <input type="search" value={query} onChange={(e) => setQuery(e.target.value)} placeholder={placeholder} aria-label={placeholder}
        className="mx-3 h-full min-w-0 flex-1 bg-transparent text-base text-[#1C1C1E] outline-none placeholder:text-[#6D6D6D] [&::-webkit-search-cancel-button]:hidden" />
      {query && (
        <button type="button" onClick={() => setQuery('')} className="px-2" aria-label="clear">
          <CloseCircle size={20} color="#6D6D6D" />
        </button>
      )}
      <button type="submit" className="me-2 ms-2 h-12 rounded-full bg-midblue px-8 text-base font-medium text-white hover:bg-midblue/90">{button}</button>
    </form>
  );
}

/** The phone's box (businesses_screen _SearchField): 48 high, outlined. */
export function PhoneSearch({ placeholder }: { placeholder: string }) {
  const { query, setQuery } = useDirectorySearch();
  return (
    <form role="search" onSubmit={(e) => { e.preventDefault(); (document.activeElement as HTMLElement | null)?.blur(); toResults(); }}
      className="flex h-12 items-center gap-2.5 rounded-3xl border border-line px-4">
      <SearchNormal1 size={20} color="#6D6D6D" className="shrink-0" />
      <input type="search" enterKeyHint="search" value={query} onChange={(e) => setQuery(e.target.value)} placeholder={placeholder} aria-label={placeholder}
        className="h-full min-w-0 flex-1 bg-transparent text-sm outline-none placeholder:text-[#6D6D6D] [&::-webkit-search-cancel-button]:hidden" />
    </form>
  );
}
