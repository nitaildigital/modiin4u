import { Candle, Clock, Moon } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import { dayMonth, shabbatDates, shabbatName, type HolidayDay, type ShabbatWeek } from '@/lib/data/shabbat';

// The Shabbat pieces the Municipal page and the Shabbat & Holidays page
// share (shabbat_widgets.dart), in the card's warm colours.

const tr = (lang: Lang) => (he: string, en: string) => (lang === 'he' ? he : en);

/** A clock or a moon, the label, and the time in bold — digits left to
 *  right in Hebrew too. */
export function ShabbatTimeRow({ icon, label, time, size = 14 }: { icon: 'clock' | 'moon'; label: string; time: string; size?: number }) {
  const Icon = icon === 'clock' ? Clock : Moon;
  return (
    <p className="flex items-center gap-2 leading-[1.21] text-[#6D6D6D]" style={{ fontSize: size }}>
      <Icon size={size + 2} color="#6D6D6D" className="shrink-0" />
      <span>{label}</span>
      <span dir="ltr" className="ms-1.5 font-semibold text-[#1F1F1F]">{time}</span>
    </p>
  );
}

/** The coming Shabbat, large: dates, parasha or holiday, and both times. */
export function ShabbatWeekPanel({ week, lang, large = false }: { week: ShabbatWeek; lang: Lang; large?: boolean }) {
  const t = tr(lang);
  const name = shabbatName(week, lang);
  const body = large ? 16 : 14;
  return (
    <div className={`rounded-xl border border-[#D68200]/20 bg-[#FEF8EF] ${large ? 'p-6' : 'p-4'}`}>
      <p className="flex items-center gap-2">
        <Candle size={large ? 24 : 20} color="#D68200" />
        <span className={`font-semibold text-[#1F1F1F] ${large ? 'text-xl' : 'text-base'}`}>{t('שבת הקרובה', 'Upcoming Shabbat')}</span>
      </p>
      <p className="mt-2 text-[#6D6D6D]" style={{ fontSize: body }}>{shabbatDates(week, lang)}</p>
      {name && <p className="mt-1 font-medium text-[#D68200]" style={{ fontSize: body }}>{name}</p>}
      <div className="mt-4 flex flex-col gap-2.5">
        {week.candles && <ShabbatTimeRow icon="clock" label={t('כניסת שבת', 'Candle lighting')} time={week.candles} size={body} />}
        {week.havdalah && <ShabbatTimeRow icon="moon" label={t('צאת שבת', 'Havdalah')} time={week.havdalah} size={body} />}
      </div>
    </div>
  );
}

/** The holidays of the coming months, one row a day. */
export function HolidayList({ days, lang, large = false }: { days: HolidayDay[]; lang: Lang; large?: boolean }) {
  const t = tr(lang);
  const size = large ? 16 : 14;
  if (!days.length) {
    return <p className="text-[#6D6D6D]" style={{ fontSize: size }}>{t('אין חגים בחודשים הקרובים', 'No holidays in the coming months')}</p>;
  }
  return (
    <ul>
      {days.map((d, i) => (
        <li key={d.date + i} className={`flex items-start border-line ${i < days.length - 1 ? 'border-b' : ''} ${large ? 'py-3.5' : 'py-3'}`} style={{ fontSize: size }}>
          <span className={`shrink-0 font-medium text-midblue ${large ? 'w-[110px]' : 'w-[84px]'}`}>{dayMonth(d.date, lang)}</span>
          <span className="text-[#1F1F1F]">{d.name[lang]}</span>
        </li>
      ))}
    </ul>
  );
}

/** The credit Hebcal's licence asks for, linking to it. */
export function HebcalCredit({ lang, size = 12 }: { lang: Lang; size?: number }) {
  return (
    <a href="https://www.hebcal.com" target="_blank" rel="noopener" className="text-[#6D6D6D] underline" style={{ fontSize: size }}>
      {tr(lang)('הזמנים מ-Hebcal.com, מחושבים למודיעין', "Times from Hebcal.com, calculated for Modi'in")}
    </a>
  );
}
