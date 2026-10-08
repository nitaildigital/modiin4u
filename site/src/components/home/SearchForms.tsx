'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { CloseCircle, SearchNormal1 } from 'iconsax-react';
import { AskButton, AskArea } from './AskButton';

/** Goes to the results for what was typed; nothing typed, nowhere. A plain
 *  GET form underneath, so it searches before the script has loaded too. */
function useSubmit() {
  const router = useRouter();
  return (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const q = String(new FormData(e.currentTarget).get('q') ?? '').trim();
    if (q) router.push(`/search/?q=${encodeURIComponent(q)}`);
  };
}

/** The hero's bar (web_home_screen.dart, _buildSearchBar): 751 × 70, the
 *  glass, the words, and Ask at the end. Enter searches; Ask opens the chat. */
export function HeroSearch({ placeholder, ask }: { placeholder: string; ask: string }) {
  const submit = useSubmit();
  return (
    <form action="/search/" method="get" role="search" onSubmit={submit}
      className="mx-auto flex h-[70px] w-[751px] max-w-[calc(100%-48px)] items-center gap-4 rounded-[50px] bg-white ps-6 pe-3">
      <img src="/web/home/search.svg" alt="" width={24} height={24} className="size-6 shrink-0" />
      <input name="q" type="search" placeholder={placeholder} aria-label={placeholder} autoComplete="off"
        className="min-w-0 flex-1 bg-transparent text-base leading-[1.21] text-[#1F1F1F] outline-none placeholder:text-[#4F4F4F] [&::-webkit-search-cancel-button]:hidden" />
      <AskButton label={ask}
        className="flex h-[46px] shrink-0 items-center gap-2 rounded-[60px] bg-[linear-gradient(155.6deg,#010928_11%,#00C4DC_95%)] px-10 text-base font-semibold leading-6 text-white" />
    </form>
  );
}

/** The phone's bar (home_screen.dart, _buildHeader): the bar asks the chat
 *  (the client's choice); the magnifier at its start is the keyword search,
 *  typed into a sheet from the bottom. */
export function PhoneSearch({ placeholder, ask, searchLabel, closeLabel }: { placeholder: string; ask: string; searchLabel: string; closeLabel: string }) {
  const [open, setOpen] = useState(false);
  const submit = useSubmit();
  return (
    <>
      <div className="mx-4 flex h-12 items-center rounded-[50px] bg-white ps-1">
        <button type="button" onClick={() => setOpen(true)} aria-label={searchLabel} className="flex h-12 w-10 shrink-0 items-center justify-center text-[#6D6D6D]">
          <SearchNormal1 size={18} color="currentColor" />
        </button>
        <AskArea label={ask} className="flex h-12 min-w-0 flex-1 items-center text-start">
          <span className="truncate text-sm text-[#6D6D6D]">{placeholder}</span>
        </AskArea>
        <AskButton label={ask}
          className="m-[5px] flex shrink-0 items-center gap-2 rounded-[60px] bg-[linear-gradient(135deg,#010928_20%,#00C4DC_90%)] px-4 py-[7px] text-base font-semibold leading-[1.21] text-white" />
      </div>
      {open && (
        <div className="fixed inset-0 z-50 flex flex-col justify-end desk:hidden" role="dialog" aria-modal aria-label={searchLabel}>
          <button type="button" className="flex-1 bg-black/40" aria-label={closeLabel} onClick={() => setOpen(false)} />
          <form action="/search/" method="get" role="search" onSubmit={submit}
            className="flex items-center gap-2 rounded-t-[20px] bg-white p-4 pb-[calc(16px+env(safe-area-inset-bottom))]">
            <label className="flex h-12 flex-1 items-center gap-2 rounded-xl border border-line px-3 text-[#6D6D6D]">
              <SearchNormal1 size={18} color="currentColor" />
              <input name="q" type="search" autoFocus enterKeyHint="search" placeholder={searchLabel} aria-label={searchLabel}
                className="min-w-0 flex-1 bg-transparent text-sm text-[#1F1F1F] outline-none placeholder:text-[#6D6D6D]" />
            </label>
            <button type="button" onClick={() => setOpen(false)} aria-label={closeLabel} className="p-1 text-midblue">
              <CloseCircle size={26} color="currentColor" />
            </button>
          </form>
        </div>
      )}
    </>
  );
}
