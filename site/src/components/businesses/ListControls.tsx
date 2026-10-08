'use client';

/** A filter pill over a listing (_FilterPill): 56 high, outlined, filled
 *  blue when on. */
export function FilterPill({ on, onClick, children }: { on: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button type="button" onClick={onClick} aria-pressed={on}
      className={`h-14 rounded-full border px-7 text-base font-medium transition-colors ${on
        ? 'border-midblue bg-midblue text-white'
        : 'border-[#D1D1D1] bg-white text-[#3D3D3D] hover:border-turquoise'}`}>
      {children}
    </button>
  );
}

/** "Show more (N left)" under a grid. */
export function ShowMore({ onClick, children }: { onClick: () => void; children: React.ReactNode }) {
  return (
    <div className="mt-8 flex justify-center">
      <button type="button" onClick={onClick}
        className="rounded-full border border-midblue px-10 py-4 text-base font-medium text-midblue hover:bg-midblue hover:text-white">
        {children}
      </button>
    </div>
  );
}

/** A chip in the phone's filter sheet. */
export function Chip({ on, onClick, children }: { on: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button type="button" onClick={onClick} aria-pressed={on}
      className={`rounded-full border px-4 py-2.5 text-sm font-medium ${on ? 'border-midblue bg-midblue text-white' : 'border-line bg-white text-[#3D3D3D]'}`}>
      {children}
    </button>
  );
}
