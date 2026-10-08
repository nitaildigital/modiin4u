import { getLang, tr } from '@/lib/i18n';
import { h1For, breadcrumb, href, SITE_NAME } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import { shabbatWeek, upcomingHolidays } from '@/lib/data/shabbat';
import { JsonLd } from '@/components/JsonLd';
import { BackLink, PhoneBar } from './BackLink';
import { HebcalCredit, HolidayList, ShabbatWeekPanel } from './Shabbat';

/** Shabbat & Holidays (web_shabbat_screen.dart; shabbat_screen.dart on the
 *  phone): the coming Shabbat with its parasha or holiday and both times,
 *  then the holidays of the next three months — all from Hebcal for
 *  Modi'in, never a time of our own. [path] is the address it is read at:
 *  /shabbat/, or WordPress's /shabat-times-modiin/ with its own H1. */
export async function ShabbatPage({ path }: { path: string }) {
  const lang = await getLang();
  const t = tr(lang);
  const [week, holidays] = await Promise.all([shabbatWeek(), upcomingHolidays()]);
  const name = t('שבת וחגים', 'Shabbat & Holidays');
  const failed = (
    <div className="py-6">
      <p className="text-sm text-[#6D6D6D] desk:text-base">{t('לא ניתן היה לטעון את זמני השבת.', 'The Shabbat times could not be loaded.')}</p>
      <a href={href(path)} className="mt-4 inline-block rounded-full border border-line px-5 py-2 text-sm text-midblue">{t('נסו שוב', 'Try again')}</a>
    </div>
  );

  return (
    <div className="wrap">
      <JsonLd data={[
        { '@context': 'https://schema.org', '@type': 'WebPage', name: h1For(path, name), url: SITE_URL + href(path), inLanguage: lang },
        breadcrumb([[SITE_NAME, '/'], [t('שירותים עירוניים במודיעין', 'Municipal Services in Modiin'), '/municipal/'], [h1For(path, name), path]]),
      ]} />
      <div className="mx-auto max-w-[430px] pb-6 pt-2.5 desk:max-w-[720px] desk:pb-[100px] desk:pt-14">
        <PhoneBar back="/municipal/" lang={lang}><span className="text-sm font-semibold text-[#1F1F1F]" aria-hidden>{name}</span></PhoneBar>
        <BackLink href="/municipal/" label={t('חזרה', 'Back')} lang={lang} className="hidden desk:block" />
        {/* Where WordPress's heading differs from the bar's title, the phone
            shows it too; otherwise the bar says it. */}
        <h1 className={`font-nunito font-semibold text-[#1C1C1E] desk:mt-6 desk:px-0 desk:text-[40px] desk:leading-[1.2] ${h1For(path, name) === name ? 'max-desk:sr-only' : 'mt-2 text-xl leading-snug'}`}>{h1For(path, name)}</h1>
        <div className="mt-5 desk:mt-8">
          <div className="desk:hidden">{week ? <ShabbatWeekPanel week={week} lang={lang} /> : failed}</div>
          <div className="hidden desk:block">{week ? <ShabbatWeekPanel week={week} lang={lang} large /> : failed}</div>
          <h2 className="mt-7 text-base font-semibold text-[#1F1F1F] desk:mt-10 desk:text-[22px]">{t('חגים ומועדים קרובים', 'Upcoming holidays')}</h2>
          <div className="mt-2 desk:mt-3">
            {holidays == null ? failed : (
              <>
                <div className="desk:hidden"><HolidayList days={holidays} lang={lang} /></div>
                <div className="hidden desk:block"><HolidayList days={holidays} lang={lang} large /></div>
              </>
            )}
          </div>
          <div className="mt-6 desk:mt-8">
            <span className="desk:hidden"><HebcalCredit lang={lang} /></span>
            <span className="hidden desk:inline"><HebcalCredit lang={lang} size={14} /></span>
          </div>
        </div>
      </div>
    </div>
  );
}
