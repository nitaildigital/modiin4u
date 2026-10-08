'use client';
import { useState } from 'react';
import { Call, Routing2, SearchNormal1 } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import { MUNICIPAL_CATEGORIES, placeName, type MunicipalPlace } from '@/lib/data/municipal-shared';

const tel = (phone: string) => `tel:${phone.replace(/[^\d+*#]/g, '')}`;

/** Waze to the place's point, or to its address when it has no point. */
function navigate(p: MunicipalPlace): string | null {
  if (p.latitude != null && p.longitude != null) return `https://waze.com/ul?ll=${p.latitude},${p.longitude}&navigate=yes`;
  if (p.address) return `https://waze.com/ul?q=${encodeURIComponent(`${p.address}, מודיעין`)}&navigate=yes`;
  return null;
}

function Round({ href, label, filled = false, color = '#17A9D0', children }: { href: string; label: string; filled?: boolean; color?: string; children: React.ReactNode }) {
  return (
    <a href={href} title={label} aria-label={label} target={href.startsWith('http') ? '_blank' : undefined} rel="noopener"
      className="flex size-10 shrink-0 items-center justify-center rounded-full border"
      style={{ background: filled ? color : '#fff', borderColor: filled ? color : '#E7E7E7' }}>
      {children}
    </a>
  );
}

/** The places of one Municipal tile (municipal_places_screen.dart), under
 *  their category headings, with a search once the list is long. The whole
 *  list is in the page; the search only hides rows. */
export function PlacesList({ places, lang }: { places: MunicipalPlace[]; lang: Lang }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [q, setQ] = useState('');
  const needle = q.trim().toLowerCase();
  const shown = needle
    ? places.filter((p) => p.name.toLowerCase().includes(needle) || (p.name_en ?? '').toLowerCase().includes(needle) || (p.address ?? '').toLowerCase().includes(needle))
    : places;
  const multiple = new Set(shown.map((p) => p.category)).size > 1;

  if (!places.length) {
    return <p className="py-10 text-center text-sm text-[#6D6D6D] desk:text-base">{t('עדיין לא נוספו רשומות.', 'Nothing is listed here yet.')}</p>;
  }
  return (
    <div>
      {places.length > 8 && (
        <label className="mb-3 flex h-11 items-center gap-2 rounded-full border border-line px-4 desk:h-12">
          <SearchNormal1 size={18} color="#6D6D6D" />
          <input type="search" value={q} onChange={(e) => setQ(e.target.value)} placeholder={t('חיפוש לפי שם או כתובת', 'Search by name or address')}
            className="min-w-0 flex-1 bg-transparent text-sm outline-none placeholder:text-[#6D6D6D]" />
        </label>
      )}
      {shown.length === 0 && <p className="py-10 text-center text-sm text-[#6D6D6D] desk:text-base">{t('אין תוצאות לחיפוש.', 'Nothing matches your search.')}</p>}
      {MUNICIPAL_CATEGORIES.map(([category, names], gi) => {
        const inIt = shown.filter((p) => p.category === category);
        if (!inIt.length) return null;
        return (
          <section key={category}>
            {multiple && (
              <h2 className={`mb-1 text-base font-semibold text-midblue desk:text-xl ${gi > 0 ? 'mt-6' : ''}`}>{`${names[lang]} (${inIt.length})`}</h2>
            )}
            <ul>
              {inIt.map((p) => {
                const nav = navigate(p);
                if (category === 'emergency') {
                  return (
                    <li key={p.id} className="mb-3 flex items-center gap-3 rounded-xl border border-[#F5C2C2] bg-[#FFF5F5] p-4">
                      <span className="flex-1">
                        <span className="block text-[15px] font-semibold text-[#1F1F1F]">{placeName(p, lang)}</span>
                        {p.notes && <span className="block text-xs text-[#6D6D6D]">{p.notes}</span>}
                      </span>
                      {p.phone && (
                        <>
                          <span dir="ltr" className="text-[26px] font-bold text-[#C62828]">{p.phone}</span>
                          <Round href={tel(p.phone)} label={t('התקשרות', 'Call')} filled color="#C62828"><Call size={18} color="#fff" variant="Bold" /></Round>
                        </>
                      )}
                    </li>
                  );
                }
                return (
                  <li key={p.id} className="flex items-start gap-3 border-b border-line py-3.5 desk:py-4">
                    <span className="min-w-0 flex-1">
                      <span className="block text-[15px] font-semibold text-[#1F1F1F] desk:text-[17px]">{placeName(p, lang)}</span>
                      {p.address && <span className="mt-1 block text-[13px] text-[#6D6D6D] desk:text-[15px]">{p.address}</span>}
                      {p.notes && <span className="mt-1 block text-[13px] leading-[1.35] text-[#6D6D6D] desk:text-[15px]">{p.notes}</span>}
                      {p.phone && <span dir="ltr" className="mt-1 block text-[13px] text-[#6D6D6D] rtl:text-right desk:text-[15px]">{p.phone}</span>}
                    </span>
                    {p.phone && <Round href={tel(p.phone)} label={t('התקשרות', 'Call')}><Call size={18} color="#17A9D0" /></Round>}
                    {nav && <Round href={nav} label={t('ניווט', 'Get Directions')}><Routing2 size={18} color="#17A9D0" /></Round>}
                  </li>
                );
              })}
            </ul>
          </section>
        );
      })}
      {/* OpenStreetMap's licence (ODbL) asks for this where its data shows. */}
      {places.some((p) => p.source === 'osm') && (
        <p className="mt-5 text-xs text-[#6D6D6D]">{t('נתוני מפה © תורמי OpenStreetMap', 'Map data © OpenStreetMap contributors')}</p>
      )}
    </div>
  );
}
