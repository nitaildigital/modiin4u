'use client';
import { useState } from 'react';
import { ProfessionalCard, type BizCardData } from './Cards';

export type Pro = { card: BizCardData; trade: string; tradeIds: string[] };

/** The professionals row's heading, trade pills and cards
 *  (_buildProfessionalsFrame). The pills filter the row; "All" is everybody.
 *  The server sends the first six of everybody and of each trade, so each
 *  choice shows what the app would. */
export function ProfessionalsRow({ heading, trades, people, allLabel, lang }: {
  heading: React.ReactNode; trades: { id: string; name: string }[]; people: Pro[]; allLabel: string; lang: 'he' | 'en';
}) {
  const [chosen, setChosen] = useState<string | null>(null);
  const shown = (chosen ? people.filter((p) => p.tradeIds.includes(chosen)) : people).slice(0, 6);
  const pill = (on: boolean) =>
    `flex h-9 items-center gap-1.5 rounded-[60px] border px-4 text-sm leading-6 ${on ? 'border-midblue bg-midblue font-medium text-white' : 'border-gray-text text-gray-text hover:bg-black/[.03]'}`;
  return (
    <>
      <div className="flex items-center gap-6">
        <div className="min-w-0 flex-1">{heading}</div>
        {trades.length > 0 && (
          <div className="flex flex-1 flex-wrap justify-end gap-2" role="group">
            <button type="button" onClick={() => setChosen(null)} aria-pressed={chosen === null} className={pill(chosen === null)}>
              <span aria-hidden className="size-4 bg-current" style={{ mask: 'url(/web/home/pro_all.svg) center / contain no-repeat', WebkitMask: 'url(/web/home/pro_all.svg) center / contain no-repeat' }} />
              {allLabel}
            </button>
            {trades.map((t) => (
              <button key={t.id} type="button" onClick={() => setChosen(t.id)} aria-pressed={chosen === t.id} className={pill(chosen === t.id)}>{t.name}</button>
            ))}
          </div>
        )}
      </div>
      <div className="mt-[33px] grid grid-cols-3 gap-4 min-[1320px]:grid-cols-6">
        {shown.map((p) => <ProfessionalCard key={p.card.id} b={p.card} trade={p.trade} lang={lang} />)}
      </div>
    </>
  );
}
