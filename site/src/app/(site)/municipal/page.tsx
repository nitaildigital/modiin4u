import type { Metadata } from 'next';
import Link from 'next/link';
import { ArrowLeft2, ArrowRight2, Call, Candle, Car, Clock, Danger, Flash, Global, Health, Location, Moon, ShieldSecurity, ShieldTick, TickCircle } from 'iconsax-react';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { pageMetadata, h1For, breadcrumb, href, SITE_NAME, SUFFIX } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import { municipalFormsUrl, parkingLots } from '@/lib/data/municipal';
import { comingWeekendDates, shabbatDates, shabbatName, shabbatWeek } from '@/lib/data/shabbat';
import { JsonLd } from '@/components/JsonLd';
import { ShabbatTimeRow } from '@/components/municipal/Shabbat';
import { DeskSearchBar, DeskServiceGrid, PhoneSearchBar, PhoneServiceGrid, ServiceSearchProvider, type Service } from '@/components/municipal/ServiceSearch';

const PATH = '/municipal/';

function heading(lang: Lang) {
  return tr(lang)('שירותים עירוניים במודיעין', 'Municipal Services in Modiin');
}
function intro(lang: Lang) {
  return tr(lang)(
    'חניה, זמני שבת, מחלקות העירייה ומספרי חירום – כל מה שהעיר מציעה, במקום אחד.',
    'Parking, Shabbat times, city departments and emergency numbers — everything the city offers, in one place.',
  );
}

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getLang();
  return pageMetadata({ path: PATH, title: heading(lang) + SUFFIX, description: intro(lang) });
}

/** The nine tiles, in the app's order. The Forms tile opens the
 *  municipality's own page (or the link the client set in the panel). */
function services(lang: Lang, formsUrl: string): Service[] {
  const t = tr(lang);
  return [
    { id: 'parking', label: t('חניה', 'Parking'), phoneLabel: t('חניה', 'Parking'), blurb: t('חניונים על המפה', 'Car parks on the map'), phoneIcon: '/icons/m_municipal_parking.svg', href: '/parking/', external: false },
    { id: 'shabbat', label: t('שבת וחגים', 'Shabbat & Holidays'), phoneLabel: t('שבת\nוחגים', 'Shabbat &\nHolidays'), blurb: t('הדלקת נרות וסגירות', 'Candle lighting and closures'), phoneIcon: '/icons/m_municipal_shabbat.svg', href: '/shabat-times-modiin/', external: false },
    { id: 'institutions', label: t('מוסדות ציבור', 'Public Institutions'), phoneLabel: t('מוסדות\nציבור', 'Public\nInstitutions'), blurb: t('עירייה, ספריות ומתנ״סים', 'City hall, libraries, centres'), phoneIcon: '/icons/m_municipal_institutions.svg', href: '/municipal/institutions/', external: false },
    { id: 'health', label: t('בריאות', 'Health'), phoneLabel: t('בריאות', 'Health'), blurb: t('מרפאות, בתי מרקחת ורופאי שיניים', 'Clinics, pharmacies, dentists'), phoneIcon: '/icons/m_municipal_health.svg', href: '/municipal/health/', external: false },
    { id: 'education', label: t('חינוך', 'Education'), phoneLabel: t('חינוך', 'Education'), blurb: t('בתי ספר, גנים ורישום', 'Schools, kindergartens, registration'), phoneIcon: '/icons/m_municipal_education.svg', href: '/municipal/education/', external: false },
    { id: 'transport', label: t('תחבורה', 'Transportation'), phoneLabel: t('תחבורה', 'Transportation'), blurb: t('קווי אוטובוס, רכבת ומסלולים', 'Bus lines, train and routes'), phoneIcon: '/icons/m_municipal_transport.svg', href: '/municipal/transport/', external: false },
    { id: 'emergency', label: t('חירום', 'Emergency'), phoneLabel: t('חירום', 'Emergency'), blurb: t('מוקדי חירום ומקלטים', 'Hotlines and shelters'), phoneIcon: '/icons/m_municipal_emergency.svg', href: '/municipal/emergency/', external: false },
    { id: 'parks', label: t('פארקים', 'Parks'), phoneLabel: t('פארקים', 'Parks'), blurb: t('שטחים ירוקים וגני שעשועים', 'Green spaces and playgrounds'), phoneIcon: '/icons/m_municipal_parks.svg', href: '/parks/', external: false },
    { id: 'forms', label: t('טפסים', 'Forms'), phoneLabel: t('טפסים', 'Forms'), blurb: t('בקשות ואישורים', 'Applications and permits'), phoneIcon: '/icons/m_municipal_forms.svg', href: formsUrl, external: true },
  ];
}

/** One of the three Quick Info cards: a ringed icon and the title over a
 *  rule, then what the card says. */
function QuickCard({ bg, border, accent, icon, title, href: to, children }: {
  bg: string; border: string; accent: string; icon: React.ReactNode; title: string; href?: string; children: React.ReactNode;
}) {
  const body = (
    <>
      <span className="flex items-center gap-4 border-b border-line pb-5">
        <span className="flex size-14 shrink-0 items-center justify-center rounded-full border bg-white" style={{ borderColor: accent + '4D' }}>{icon}</span>
        <span className="text-lg font-semibold leading-[1.3] text-[#1C1C1E]">{title}</span>
      </span>
      <span className="mt-5 block">{children}</span>
    </>
  );
  const cls = 'block h-full rounded-2xl border p-6';
  const style = { background: bg, borderColor: border };
  return to ? <Link href={to} className={cls} style={style}>{body}</Link> : <div className={cls} style={style}>{body}</div>;
}

/** A row of the Shabbat card: icon and label, the time at the far end. */
function InfoRow({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <span className="mb-3 flex items-center gap-2 text-sm">
      {icon}
      <span className="text-gray-text">{label}</span>
      <span dir="ltr" className="ms-auto font-semibold text-[#1C1C1E]">{value}</span>
    </span>
  );
}

/** Municipal services (web_municipal_screen.dart; municipal_screen.dart on
 *  the phone): the search, the Quick Info cards — the coming Shabbat from
 *  Hebcal, the car parks, the city hotline — the nine service tiles, the
 *  emergency numbers and City Hall. */
export default async function MunicipalPage() {
  const lang = await getLang();
  const t = tr(lang);
  const [week, lots, formsUrl] = await Promise.all([shabbatWeek(), parkingLots(), municipalFormsUrl()]);
  const list = services(lang, formsUrl);
  const name = week ? shabbatName(week, lang) : null;
  const freeCount = lots.filter((l) => l.is_free === true).length;

  const contacts: [string, string, React.ReactNode][] = [
    [t('משטרה', 'Police'), '100', <ShieldTick key="p" size={22} color="#123A72" />],
    [t('מגן דוד אדום', 'Ambulance (MDA)'), '101', <Health key="a" size={22} color="#123A72" />],
    [t('כבאות והצלה', 'Fire & Rescue'), '102', <Danger key="f" size={22} color="#123A72" />],
    [t('פיקוד העורף', 'Home Front Command'), '104', <ShieldSecurity key="h" size={22} color="#123A72" />],
    [t('מוקד עירוני', 'Municipal Hotline'), '106', <Call key="m" size={22} color="#123A72" />],
    [t('חברת החשמל', 'Electric Company'), '103', <Flash key="e" size={22} color="#123A72" />],
  ];
  const hours: [string, string][] = [
    [t('א׳, ג׳, ה׳', 'Sun, Tue, Thu'), '08:30–13:00'],
    [t('יום ב׳', 'Monday'), '08:30–13:00, 16:00–18:30'],
    [t('יום ד׳', 'Wednesday'), t('סגור לקהל', 'Closed to the public')],
    [t('יום ו׳', 'Friday'), t('סגור', 'Closed')],
  ];
  const Chevron = lang === 'he' ? ArrowLeft2 : ArrowRight2;

  return (
    <ServiceSearchProvider>
      <JsonLd data={[
        {
          '@context': 'https://schema.org', '@type': 'CollectionPage', name: heading(lang), description: intro(lang),
          url: SITE_URL + href(PATH), inLanguage: lang,
        },
        breadcrumb([[SITE_NAME, '/'], [heading(lang), PATH]]),
      ]} />

      {/* ── Desktop ── */}
      <div className="pt-[13px] desk:pt-14">
        <h1 className="text-center font-medium text-black max-desk:text-base desk:font-nunito desk:text-[44px] desk:font-semibold desk:leading-[1.23]">
          {h1For(PATH, heading(lang))}
        </h1>
        <div className="hidden desk:block">
          <p className="wrap mt-3.5 text-center text-base leading-[1.19] text-[#6D6D6D]">{intro(lang)}</p>
          <div className="mt-10 px-6"><DeskSearchBar lang={lang} /></div>
        </div>
      </div>

      <div className="hidden desk:block">
        <section className="wrap pt-16" aria-labelledby="quick">
          <h2 id="quick" className="font-nunito text-[28px] font-semibold text-midblue">{t('במבט מהיר', 'Quick Info')}</h2>
          <div className="mt-6 grid grid-cols-3 gap-6">
            {/* The coming Shabbat, from Hebcal for Modi'in. Until Hebcal
                answers, or if it cannot, the times are left out. */}
            <QuickCard bg="#FEF8EF" border="#D6820033" accent="#D68200" icon={<Candle size={26} color="#D68200" />} title={t('שבת הקרובה', 'Upcoming Shabbat')} href="/shabat-times-modiin/">
              {week && <span className="block text-sm text-gray-text">{name ? `${shabbatDates(week, lang)} · ${name}` : shabbatDates(week, lang)}</span>}
              <span className="mt-4 block">
                {week?.candles && <InfoRow icon={<Clock size={16} color="#6D6D6D" />} label={t('כניסת שבת', 'Candle lighting')} value={week.candles} />}
                {week?.havdalah && <InfoRow icon={<Moon size={16} color="#6D6D6D" />} label={t('צאת שבת', 'Havdalah')} value={week.havdalah} />}
              </span>
            </QuickCard>
            {/* Only what is behind it: no availability or paid hours, which
                nothing the client enters says. */}
            <QuickCard bg="#F0F7FD" border="#D9E8F4" accent="#123A72" icon={<Car size={26} color="#123A72" />} title={t('חניה במודיעין', 'Parking in Modiin')} href="/parking/">
              <span className="block text-sm leading-[1.4] text-gray-text">{t('כל החניונים בעיר, על המפה.', 'Every car park in the city, on the map.')}</span>
              <span className="mt-4 flex items-center gap-1 text-sm font-semibold text-midblue">{t('למפת החניה', 'Open parking map')}<Chevron size={18} color="#123A72" /></span>
            </QuickCard>
            <QuickCard bg="#EFF9F3" border="#12855A33" accent="#12855A" icon={<Call size={26} color="#12855A" />} title={t('המוקד העירוני', 'Municipal Hotline')}>
              <span className="block text-sm leading-[1.4] text-gray-text">{t('דיווח על תקלה, מפגע או פנס רחוב – 24/7.', 'Report a fault, a pothole or a street light — 24/7.')}</span>
              <a href="tel:106" dir="ltr" className="mt-4 block font-nunito text-4xl font-bold text-[#12855A] rtl:text-right">106</a>
              <span className="mt-1 block text-[13px] text-gray-text">{t('או', 'or')} <a href="tel:089726000" dir="ltr">08-9726000</a></span>
            </QuickCard>
          </div>
        </section>

        <section id="services" className="wrap scroll-mt-24 pt-20" aria-labelledby="services-h">
          <h2 id="services-h" className="font-nunito text-[28px] font-semibold text-midblue">{t('שירותי עירייה', 'Municipal Services')}</h2>
          <DeskServiceGrid services={list} lang={lang} />
        </section>

        <section className="wrap pt-20" aria-labelledby="numbers">
          <h2 id="numbers" className="font-nunito text-[28px] font-semibold text-midblue">{t('מספרי חירום ושירות', 'Emergency & Service Numbers')}</h2>
          <p className="mt-2 text-sm leading-[1.21] text-gray-text">{t('שמרו אותם בהישג יד – הם פועלים מכל טלפון בישראל.', 'Keep these close — they work from any phone in Israel.')}</p>
          <ul className="mt-8 grid grid-cols-3 gap-5">
            {contacts.map(([label, number, icon]) => (
              <li key={number}>
                <a href={`tel:${number}`} className="flex items-center gap-4 rounded-xl border border-line bg-white px-6 py-5">
                  <span className="flex size-12 shrink-0 items-center justify-center rounded-full bg-midblue/[0.06]">{icon}</span>
                  <span className="min-w-0 flex-1 truncate text-base font-medium text-[#1C1C1E]">{label}</span>
                  <span dir="ltr" className="ms-3 font-nunito text-2xl font-bold text-midblue">{number}</span>
                </a>
              </li>
            ))}
          </ul>
        </section>

        <section className="wrap pt-20" aria-labelledby="cityhall">
          <div dir="ltr" className="rounded-3xl bg-[linear-gradient(to_bottom_right,#0A1230,#123A72,#17A9D0)] px-14 py-12">
            <div dir={lang === 'he' ? 'rtl' : 'ltr'} className="flex gap-10">
              <div className="flex-[3]">
                <h2 id="cityhall" className="font-nunito text-[32px] font-semibold leading-[1.25] text-white">{t('עיריית מודיעין-מכבים-רעות', 'Modiin-Maccabim-Reut City Hall')}</h2>
                <p className="mt-4 flex items-center gap-2 text-base text-white/90"><Location size={18} color="#FFFFFFB3" />{t('רחוב דם המכבים 1, מודיעין', '1 Dam HaMaccabim St., Modiin')}</p>
                <p className="mt-2.5 flex items-center gap-2 text-base text-white/90"><Global size={18} color="#FFFFFFB3" /><a href="https://www.modiin.muni.il" target="_blank" rel="noopener">modiin.muni.il</a></p>
              </div>
              <div className="flex-[2]">
                <h3 className="text-base font-semibold text-white">{t('שעות קבלת קהל', 'Reception Hours')}</h3>
                <dl className="mt-4">
                  {hours.map(([d, h]) => (
                    <div key={d} className="mb-2.5 flex text-sm">
                      <dt className="w-[110px] shrink-0 text-white/75">{d}</dt>
                      <dd className="font-medium text-white">{h}</dd>
                    </div>
                  ))}
                </dl>
              </div>
            </div>
          </div>
        </section>
        <div className="h-[100px]" />
      </div>

      {/* ── Phone ── */}
      <div className="mx-auto max-w-[430px] px-4 pb-10 desk:hidden">
        <div className="mt-5"><PhoneSearchBar lang={lang} /></div>
        <h2 className="mt-5 text-base font-semibold text-[#1F1F1F]">{t('מידע מהיר', 'Quick Info')}</h2>
        <div className="mt-3 grid grid-cols-2 gap-3">
          <Link href="/shabat-times-modiin/" className="rounded-xl border border-[#D68200]/20 bg-[#FEF8EF] p-3">
            <span className="flex items-center gap-3 border-b border-line pb-3">
              <img src="/icons/m_municipal_shabbat_circle.svg" alt="" width={48} height={48} className="size-12 shrink-0" />
              <TwoLineTitle text={t('שבת הקרובה', 'Upcoming Shabbat')} />
            </span>
            {/* Hebcal's dates once it has answered, the coming weekend's
                until then; the times only from Hebcal. */}
            <span className="mt-3 block text-xs text-navy">{week ? shabbatDates(week, lang) : comingWeekendDates(lang)}</span>
            {week?.candles && <span className="mt-2 block"><ShabbatTimeRow icon="clock" label={t('כניסת שבת', 'Candle lighting')} time={week.candles} size={12} /></span>}
            {week?.havdalah && <span className="mt-1.5 block"><ShabbatTimeRow icon="moon" label={t('צאת שבת', 'Havdalah')} time={week.havdalah} size={12} /></span>}
          </Link>
          {/* How many car parks the city has and how many are free — never
              how full they are, which nothing measures. */}
          <Link href="/parking/" className="rounded-xl border border-[#D9E8F4] bg-[#F0F7FD] p-3">
            <span className="flex items-center gap-3 border-b border-line pb-3">
              <img src="/icons/m_municipal_parking_circle.svg" alt="" width={48} height={48} className="size-12 shrink-0" />
              <TwoLineTitle text={t('חניה במודיעין', 'Parking in Modiin')} />
              {lang === 'he' ? <ArrowLeft2 size={16} color="#0A1230" className="ms-auto shrink-0" /> : <ArrowRight2 size={16} color="#0A1230" className="ms-auto shrink-0" />}
            </span>
            {lots.length > 0 && (
              <span className="mt-3 block text-xs text-navy">
                <span className="flex items-center gap-1.5"><Car size={14} color="#17A9D0" />{lots.length === 1 ? t('חניון אחד', '1 car park') : t(`${lots.length} חניונים`, `${lots.length} car parks`)}</span>
                {freeCount > 0 && (
                  <span className="mt-1.5 flex items-center gap-1.5"><TickCircle size={14} color="#17A9D0" />{freeCount === 1 ? t('אחד מהם בחינם', '1 of them free') : t(`${freeCount} מהם בחינם`, `${freeCount} of them free`)}</span>
                )}
              </span>
            )}
          </Link>
        </div>
        <h2 className="mt-9 text-base font-semibold text-[#1F1F1F]">{t('שירותי עירייה', 'Municipal Services')}</h2>
        <p className="mt-1 text-sm text-[#6D6D6D]">{t('שירותים ומידע', 'Explore services and information')}</p>
        <PhoneServiceGrid services={list} />
      </div>
    </ServiceSearchProvider>
  );
}

/** A card's title as the frame sets it: the first word, and the rest under
 *  it in semi-bold. */
function TwoLineTitle({ text }: { text: string }) {
  const i = text.indexOf(' ');
  return (
    <span className="text-sm leading-[1.4] text-navy">
      {i < 0 ? text : text.slice(0, i)}
      {i >= 0 && <><br /><span className="font-semibold">{text.slice(i + 1)}</span></>}
    </span>
  );
}
