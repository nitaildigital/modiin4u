import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { Calendar1, DiscountShape, Export, Location, MedalStar, Mobile, Shop } from 'iconsax-react';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { slugParam } from '@/lib/params';
import { pageMetadata, h1For, plain, breadcrumb, href, SITE_NAME, SUFFIX } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import { businessGallery, dealById, hasExpired, liveDeals, type Deal } from '@/lib/data/deals';
import { JsonLd } from '@/components/JsonLd';
import { Photo } from '@/components/events/Photo';
import { ShareMenu } from '@/components/events/ShareMenu';
import { LogoRing, MDealMiniCard } from '@/components/deals/DealCards';
import { PhotoGallery } from '@/components/deals/PhotoGallery';
import { businessName, dealBadge, isHebrew, neighborhood, residentsOnly, timeLeftLabel } from '@/components/deals/labels';

type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const id = slugParam((await params).id);
  const d = await dealById(id);
  if (!d) return {};
  return pageMetadata({
    path: `/deal/${id}/`,
    title: d.name + SUFFIX,
    description: plain(d.description || d.terms, 160) || null,
    image: d.image_url || d.business?.cover,
  });
}

const MONTHS_EN = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const MONTHS_HE = ['ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני', 'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר'];

/** "October 1, 2026" / "1 באוקטובר 2026", on Israel's calendar. */
function longDate(iso: string, lang: Lang): string {
  const [y, m, d] = new Date(iso).toLocaleDateString('en-CA', { timeZone: 'Asia/Jerusalem' }).split('-').map(Number);
  return lang === 'he' ? `${d} ב${MONTHS_HE[m - 1]} ${y}` : `${MONTHS_EN[m - 1]} ${d}, ${y}`;
}

/** "1 באוקטובר 2026" as the phone prints it. */
function phoneDate(iso: string, lang: Lang): string {
  const [y, m, d] = new Date(iso).toLocaleDateString('en-CA', { timeZone: 'Asia/Jerusalem' }).split('-').map(Number);
  return `${d} ${(lang === 'he' ? MONTHS_HE : MONTHS_EN)[m - 1]} ${y}`;
}

const DESK_WRAP = 'desk:mx-auto desk:max-w-[calc(1600px_+_2*clamp(16px,4.5vw,80px))] desk:px-[clamp(16px,4.5vw,80px)]';

/** One deal (web_deal_detail_screen.dart above 1100, deal_detail_screen.dart
 *  below). Claiming takes an account, and accounts belong to the app, so the
 *  page says where to claim it instead of a button the site could not honour;
 *  the code is not printed — it is what a claim hands over. A deal past its
 *  end date still opens, and says it has ended. */
export default async function DealPage({ params }: Props) {
  const id = slugParam((await params).id);
  const d = await dealById(id);
  if (!d) notFound();
  const lang = await getLang();
  const t = tr(lang);
  const path = `/deal/${id}/`;
  const url = SITE_URL + href(path);
  const b = d.business;
  const [gallery, live] = await Promise.all([b ? businessGallery(b.id) : Promise.resolve([]), liveDeals()]);
  const more = b ? live.filter((x) => x.business?.id === b.id && x.id !== d.id) : [];

  const ended = hasExpired(d);
  const badge = dealBadge(d.name);
  const biz = businessName(d, lang);
  const hood = neighborhood(d, lang);
  const place = b?.address ?? hood;
  const left = timeLeftLabel(d, lang);
  const image = d.image_url ?? b?.cover ?? null;
  const logo = b?.logo ?? b?.cover ?? null;
  const directions = place ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(b?.address ?? place)}` : null;
  const shareMessage = [d.name, biz].filter(Boolean).join(' — ');
  // The phone's restrictions: the limits the admin set, then the terms, one per line.
  const restrictions = [
    ...(residentsOnly(d) ? [t('לתושבים רשומים בלבד', 'Registered residents only')] : []),
    ...(d.max_per_user === 1 ? [t('מימוש אחד למשתמש', 'One redemption per user')] : []),
    ...(d.terms ?? '').split('\n').map((l) => l.replace(/^\s*[-•*·]\s*/, '').trim()).filter(Boolean),
  ];
  const dir = (s: string) => (isHebrew(s) ? 'rtl' : 'ltr');
  const align = lang === 'he' ? 'text-right' : 'text-left';

  return (
    <article className={`desk:pt-10 ${DESK_WRAP}`}>
      <JsonLd data={[
        {
          '@context': 'https://schema.org', '@type': 'Offer', name: d.name, url,
          ...(d.description ? { description: plain(d.description, 500) } : {}),
          ...(image ? { image } : {}),
          ...(d.start_at ? { availabilityStarts: d.start_at } : {}),
          ...(d.end_at ? { availabilityEnds: d.end_at, validThrough: d.end_at } : {}),
          availability: ended ? 'https://schema.org/Discontinued' : 'https://schema.org/InStock',
          ...(b ? {
            offeredBy: {
              '@type': 'LocalBusiness', name: b.name, url: SITE_URL + href(`/business/${b.slug}/`),
              ...(b.address ? { address: b.address } : {}), ...(b.phone ? { telephone: b.phone } : {}), ...(b.logo ? { image: b.logo } : {}),
            },
          } : {}),
        },
        breadcrumb([[SITE_NAME, '/'], ['מבצעים', '/deals/'], [d.name, path]]),
      ]} />

      <Link href="/deals/" className="hidden items-center gap-2 text-[15px] font-medium text-midblue desk:inline-flex">
        <img src="/web/deals/arrow20.svg" alt="" className="size-5 ltr:-scale-x-100" />
        {t('חזרה למבצעים', 'Back to Deals')}
      </Link>

      {/* On the phone the two columns below open into one, in the phone's
          order: their wrappers step aside (`contents`) and each part takes
          its place by `order`. */}
      <div className="flex flex-col desk:mt-6 desk:flex-row desk:items-start desk:gap-12 min-[1648px]:gap-[136px]">
        <div className="contents desk:block desk:min-w-0 desk:flex-1">
          {/* The phone's photograph, with back, share, the gallery and the logo. */}
          <div className="relative order-1 h-[310px] desk:hidden">
            <div className="relative h-[260px]">
              <Photo url={image} alt={d.name} className="size-full" icon={DiscountShape} iconSize={60} eager />
              <div className="absolute inset-0" style={{ background: 'linear-gradient(to top, rgba(0,0,0,0.4), rgba(0,0,0,0))' }} />
            </div>
            <Link href="/deals/" aria-label={t('חזרה', 'Back')} className="absolute start-3 top-[7px]">
              <img src="/icons/m_deals_back.svg" alt="" className="size-10 rtl:-scale-x-100" />
            </Link>
            <div className="absolute end-3 top-[7px]">
              <ShareMenu url={url} title={d.name} message={shareMessage} lang={lang} align="end" className="flex size-10 items-center justify-center rounded-full bg-white">
                <Export size={20} color="#3D3D3D" />
              </ShareMenu>
            </div>
            {gallery.length > 0 && (
              <div className="absolute bottom-16 end-3.5">
                <PhotoGallery photos={gallery} label={t('כל התמונות', 'Show all photos')}
                  className="flex items-center gap-2 rounded-[60px] bg-black/50 px-2 py-1.5 text-xs font-medium text-white" />
              </div>
            )}
            <span className="absolute start-4 top-[210px] size-[100px] rounded-full border-[3px] border-white bg-white">
              <Photo url={logo} alt="" className="size-full rounded-full" icon={Shop} iconSize={36} />
            </span>
          </div>

          {/* The website's photograph, with the badge or "has ended". */}
          <div className="relative hidden h-[460px] overflow-hidden rounded-xl desk:block">
            <Photo url={image} alt={d.name} className="size-full" icon={DiscountShape} iconSize={72} eager />
            {(badge || ended) && (
              <span dir={ended ? undefined : dir(badge!)}
                className={`absolute start-5 top-5 rounded-lg px-4 py-2 text-lg font-semibold leading-[1.21] ${ended ? 'bg-white text-[#CB3E3C]' : 'bg-orange text-white'}`}>
                {ended ? t('המבצע הסתיים', 'This offer has ended') : badge}
              </span>
            )}
          </div>
          {d.description && (
            <section className="mt-14 hidden desk:block">
              <h2 className="font-nunito text-2xl font-semibold text-midblue">{t('על המבצע', 'About this deal')}</h2>
              <p dir={dir(d.description)} className="mt-6 whitespace-pre-line text-start text-base leading-[1.6] text-[#3D3D3D]">{d.description}</p>
            </section>
          )}
          {d.terms && (
            <section className="mt-14 hidden desk:block">
              <h2 className="font-nunito text-2xl font-semibold text-midblue">{t('תנאים והגבלות', 'Terms & Conditions')}</h2>
              <p dir={dir(d.terms)} className="mt-6 whitespace-pre-line text-start text-base leading-[1.6] text-[#3D3D3D]">{d.terms}</p>
            </section>
          )}
        </div>

        <aside className="contents desk:block desk:w-[376px] desk:shrink-0 desk:rounded-xl desk:border desk:border-line desk:bg-white desk:p-6">
          {/* The website's business row, opening its page. */}
          {b && biz && (
            <Link href={href(`/business/${b.slug}/`)} className="hidden items-center gap-3 desk:flex">
              <LogoRing url={logo} size={56} />
              <span className="min-w-0 flex-1">
                <span dir={dir(biz)} className={`line-clamp-2 text-base font-semibold text-[#1C1C1E] ${align}`}>{biz}</span>
                {hood && <span dir={dir(hood)} className="mt-1 block truncate text-sm text-gray-text">{hood}</span>}
              </span>
            </Link>
          )}
          {/* The phone's: the business's name and address. */}
          {biz || b?.address ? (
            <div className="order-2 mx-4 border-b border-line py-5 desk:hidden">
              {biz && <p className="font-nunito text-[28px] font-semibold text-black">{biz}</p>}
              {b?.address && (
                <p className={`flex items-center gap-2 ${biz ? 'mt-2' : ''}`}>
                  <img src="/icons/m_deals_location.svg" alt="" className="size-4 shrink-0" />
                  <span className="truncate text-sm text-[#6D6D6D]">{b.address}</span>
                </p>
              )}
            </div>
          ) : <div className="order-2 h-5 desk:hidden" />}

          <h1 dir={dir(d.name)}
            className={`order-3 px-4 pt-5 text-xl font-semibold text-midblue desk:mt-5 desk:px-0 desk:pt-0 desk:text-[26px] desk:leading-[1.25] ${align}`}>
            {h1For(path, d.name)}
          </h1>

          {/* The phone's description, valid-until and restrictions. */}
          <div className="order-4 px-4 pb-5 desk:hidden">
            {d.description && <p className="mt-3 whitespace-pre-line text-sm leading-[1.4] text-[#6D6D6D]">{d.description}</p>}
          </div>
          {(d.end_at || restrictions.length > 0) && (
            <div className="order-5 flex flex-col gap-5 px-4 desk:hidden">
              {d.end_at && (
                <Fact icon="/icons/m_deals_valid_until.svg" title={t('בתוקף עד', 'Valid Until')}>
                  <p className="text-sm leading-[1.4] text-gray-text">{phoneDate(d.end_at, lang)}</p>
                </Fact>
              )}
              {restrictions.length > 0 && (
                <Fact icon="/icons/m_deals_restrictions.svg" title={t('הגבלות', 'Restrictions')}>
                  <ul className="text-sm leading-[1.4] text-gray-text">
                    {restrictions.map((r, i) => <li key={i} className="flex"><span className="w-[21px] shrink-0 text-center">•</span><span>{r}</span></li>)}
                  </ul>
                </Fact>
              )}
            </div>
          )}

          {/* The website's clock, facts, where to claim it, and the buttons. */}
          <div className="hidden desk:block">
            {(left || residentsOnly(d)) && (
              <div className="mt-5 flex items-center">
                {left && (
                  <>
                    <img src="/web/deals/card_clock.svg" alt="" className="size-5" />
                    <span className="ms-2 flex flex-col">
                      <span dir="ltr" className={`text-base font-semibold leading-[1.19] text-navy ${align}`}>{left}</span>
                      <span className="mt-0.5 text-xs leading-[1.25] text-gray-text">{t('זמן שנותר', 'Time Left')}</span>
                    </span>
                    <span className="w-11" />
                  </>
                )}
                {residentsOnly(d) && (
                  <span className="flex items-center gap-2">
                    <img src="/web/deals/card_lock.svg" alt="" className="size-5" />
                    <span className="text-xs font-semibold leading-[1.25] text-orange">{t('לתושבים בלבד', 'Residents Only')}</span>
                  </span>
                )}
              </div>
            )}
            {(d.end_at || d.points_required > 0 || place) && (
              <div className="mt-6 flex flex-col gap-5 border-t border-line pt-6">
                {d.end_at && <DeskFact icon={<Calendar1 size={20} color="#123A72" />} label={t('בתוקף עד', 'Valid Until')} value={longDate(d.end_at, lang)} align={align} />}
                {d.points_required > 0 && (
                  <DeskFact icon={<MedalStar size={20} color="#123A72" />} label={t('נקודות', 'Points')} value={t(`${d.points_required} נקודות`, `${d.points_required} points`)} align={align} />
                )}
                {place && <DeskFact icon={<Location size={20} color="#123A72" />} label={t('מיקום', 'Location')} value={place} align={align} />}
              </div>
            )}
            {!ended && (
              <div className="mt-7 flex items-start gap-3 rounded-xl bg-[#EEF3FB] p-4">
                <Mobile size={22} color="#123A72" className="shrink-0" />
                <span>
                  <span className="block text-[15px] font-semibold text-midblue">{t('מממשים באפליקציית מודיעין בשבילך', 'Claim it in the Modiin4u app')}</span>
                  <span className="mt-1 block text-sm leading-[1.4] text-[#3D3D3D]">{t('האפליקציה נותנת את הקוד להצגה בבית העסק.', 'The app gives you the code to show at the business.')}</span>
                </span>
              </div>
            )}
            <div className={ended ? 'mt-7' : ''}>
              {b && (
                <Link href={href(`/business/${b.slug}/`)} className="mt-4 flex h-11 items-center justify-center rounded-[60px] border border-midblue bg-midblue px-8 text-base font-medium leading-6 text-white">
                  {t('לעמוד העסק', 'View Business')}
                </Link>
              )}
              {directions && (
                <a href={directions} target="_blank" rel="noopener" className="mt-3 flex h-11 items-center justify-center rounded-[60px] border border-midblue bg-white px-8 text-base font-medium leading-6 text-midblue hover:bg-midblue hover:text-white">
                  {t('ניווט', 'Get Directions')}
                </a>
              )}
              <div className="mt-3">
                <ShareMenu url={url} title={d.name} message={shareMessage} lang={lang}
                  className="flex h-11 w-full items-center justify-center rounded-[60px] border border-midblue bg-white px-8 text-base font-medium leading-6 text-midblue hover:bg-midblue hover:text-white">
                  {t('שיתוף', 'Share')}
                </ShareMenu>
              </div>
            </div>
          </div>
        </aside>

        {/* The phone's "More Deals from …". */}
        {more.length > 0 && (
          <section className="order-6 pt-[50px] desk:hidden">
            <h2 className="px-4 text-base font-semibold text-[#1F1F1F]">
              {biz ? t(`מבצעים נוספים של ${biz}`, `More Deals from ${biz}`) : t('מבצעים נוספים', 'More Deals')}
            </h2>
            <div className="mt-3.5 flex gap-3 overflow-x-auto px-4 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
              {more.map((x) => <MDealMiniCard key={x.id} deal={x} lang={lang} />)}
            </div>
          </section>
        )}
        <div className="order-6 h-6 desk:hidden" />

        <PhoneBar d={d} lang={lang} ended={ended} />
      </div>
      <div className="hidden h-[120px] desk:block" />
    </article>
  );
}

/** The phone's bar at the foot of the screen: where to claim it (the app),
 *  and directions and a call where the business has an address and a phone. */
function PhoneBar({ d, lang, ended }: { d: Deal; lang: Lang; ended: boolean }) {
  const t = tr(lang);
  const address = d.business?.address;
  const phone = d.business?.phone?.trim();
  if (!address && !phone && ended) return null;
  return (
    <div className="sticky bottom-[76px] z-30 order-7 border-t border-line bg-white px-4 py-3 desk:hidden">
      {!ended && <p className="mb-3 text-center text-sm text-gray-text">{t('למימוש — באפליקציית מודיעין בשבילך', 'Claim it in the Modiin4u app')}</p>}
      {(address || phone) && (
        <div className="flex gap-[11px]">
          {address && (
            <a href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(address)}`} target="_blank" rel="noopener"
              className="flex h-11 min-w-0 flex-1 items-center justify-center gap-3 rounded-[60px] border border-midblue bg-white px-3 text-sm font-medium leading-6 text-midblue">
              <img src="/icons/m_deals_direction.svg" alt="" className="size-5" /><span className="truncate">{t('ניווט', 'Get Direction')}</span>
            </a>
          )}
          {phone && (
            <a href={`tel:${phone}`} className="flex h-11 min-w-0 flex-1 items-center justify-center gap-3 rounded-[60px] border border-midblue bg-white px-3 text-sm font-medium leading-6 text-midblue">
              <img src="/icons/m_deals_call.svg" alt="" className="size-5" /><span className="truncate">{t('התקשרו לעסק', 'Call Business')}</span>
            </a>
          )}
        </div>
      )}
    </div>
  );
}

function Fact({ icon, title, children }: { icon: string; title: string; children: React.ReactNode }) {
  return (
    <div className="flex items-start gap-3">
      <img src={icon} alt="" className="size-[38px] shrink-0" />
      <div className="min-w-0 flex-1 pt-px">
        <p className="truncate text-sm font-medium text-black">{title}</p>
        <div className="mt-0.5">{children}</div>
      </div>
    </div>
  );
}

function DeskFact({ icon, label, value, align }: { icon: React.ReactNode; label: string; value: string; align: string }) {
  return (
    <div className="flex items-start gap-3.5">
      <span className="flex size-10 shrink-0 items-center justify-center rounded-full bg-[#EEF3FB]">{icon}</span>
      <span className="min-w-0 flex-1">
        <span className="block text-sm text-[#6D6D6D]">{label}</span>
        <span dir={isHebrew(value) ? 'rtl' : 'ltr'} className={`mt-1 block text-[15px] font-medium leading-[1.4] text-black ${align}`}>{value}</span>
      </span>
    </div>
  );
}
