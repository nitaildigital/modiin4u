import Link from 'next/link';
import { Book, Brush2, Car, Coffee, Health, Music, Reserve, Setting2, Shop, ShoppingBag, Weight } from 'iconsax-react';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { breadcrumb, h1For, href, SITE_NAME } from '@/lib/seo';
import { categoryPath } from '@/lib/routes';
import { SITE_URL, CONTACT } from '@/lib/config';
import {
  activeBusinesses, bizDescription, bizName, bizPhoto, businessCategories, catName, categoriesByBusiness,
  categoryCounts, primaryCategories, sizedPhoto, type BizCategory, type BizRow,
} from '@/lib/data/businesses';
import { JsonLd } from '@/components/JsonLd';
import { toCard, searchText } from './card-data';
import { CategoryTiles, type Tile } from './CategoryTiles';
import { DesktopSearch, DirectorySearchProvider, PhoneSearch } from './DirectorySearch';
import { DirectoryResults } from './DirectoryResults';
import { ContactButton } from './ContactButton';
import { Photo } from './Photo';

/** A "professional" is no record of its own — there is no such table — but a
 *  business filed under one of these (web_businesses_screen _serviceSlugs). */
const SERVICE_SLUGS = new Set(['services', 'health', 'beauty', 'automotive', 'education']);

/** The business directory (WordPress's /business/, and the old addresses that stand
 *  for it): web_businesses_screen.dart at desktop width — the title and
 *  search, the busiest categories, every business in a grid, the service
 *  providers and the "add your business" band — and businesses_screen.dart on
 *  a phone: the title, search, the main categories two a row and the list.
 *  [path] is the address being served, for its H1 and breadcrumb. */
export async function DirectoryPage({ path }: { path: string }) {
  const lang = await getLang();
  const t = tr(lang);
  const [rows, cats, counts, primary, byBusiness] = await Promise.all([
    activeBusinesses(), businessCategories(), categoryCounts(), primaryCategories(), categoriesByBusiness(),
  ]);
  const count = (c: BizCategory) => counts.get(c.id) ?? 0;
  const tile = (c: BizCategory): Tile => ({ id: c.id, slug: c.slug, href: href(categoryPath(c.slug)), name: catName(c, lang), count: count(c) });
  const byCount = (a: BizCategory, b: BizCategory) => count(b) - count(a);
  const inMenus = cats.filter((c) => c.in_menus !== false);
  // The main ones above the fold; sub-categories such as "מסעדות כשרות"
  // would push them off the first row, so they wait for "All categories".
  const mainTiles = inMenus.filter((c) => !c.parent_id).sort(byCount).map(tile);
  const allTiles = [...inMenus].sort(byCount).map(tile);
  // The phone's grid: the main categories in the panel's order.
  const phoneCats = inMenus.filter((c) => !c.parent_id);

  const items = rows.map((b) => ({ card: toCard(b, lang, primary.get(b.id)), search: searchText(b, lang, byBusiness.get(b.id)) }));
  const serviceIds = new Set(cats.filter((c) => SERVICE_SLUGS.has(c.slug)).map((c) => c.id));
  const professionals = rows.filter((b) => (byBusiness.get(b.id) ?? []).some((c) => serviceIds.has(c.id))).slice(0, 6);

  const title = h1For(path, t('עסקים ובעלי מקצוע במודיעין', 'Businesses & Professionals in Modiin'));
  return (
    <div className="wrap pb-10 max-desk:mx-auto max-desk:max-w-[430px] max-desk:px-4 desk:pb-0">
      <JsonLd data={[
        breadcrumb([[SITE_NAME, '/'], [title, path]]),
        {
          '@context': 'https://schema.org', '@type': 'ItemList', name: title,
          itemListElement: rows.map((b, i) => ({ '@type': 'ListItem', position: i + 1, url: SITE_URL + href(`/business/${b.slug}/`), name: b.name })),
        },
      ]} />
      <DirectorySearchProvider
        businesses={items.map(({ card, search }) => ({ name: card.name, href: card.href, line: card.kind, search }))}
        categories={allTiles.filter((c) => c.count > 0).map((c) => ({ name: c.name, href: c.href, line: t(`${c.count} עסקים`, `${c.count} businesses`), search: c.name.toLowerCase() }))}>
        <header className="pt-3.5 text-center desk:pt-14">
          <h1 className="text-base font-semibold text-black desk:font-nunito desk:text-[44px] desk:leading-[1.23]">{title}</h1>
          <p className="mt-3.5 hidden text-base text-[#6D6D6D] desk:block">
            {t('מצאו עסקים מקומיים, נותני שירות ובעלי מקצוע מומלצים – הכל במקום אחד.', 'Find trusted local businesses, service providers and professionals — all in one place.')}
          </p>
          <div className="mx-auto mt-10 hidden max-w-[820px] px-6 desk:block">
            <DesktopSearch placeholder={t('חפשו עסקים, שירותים או בעלי מקצוע במודיעין...', 'Search businesses, services or professionals in Modiin...')} button={t('חיפוש', 'Search')} lang={lang} />
          </div>
          <div className="mt-4 desk:hidden">
            <PhoneSearch placeholder={t('חיפוש עסקים במודיעין', 'Search businesses in Modiin')} lang={lang} />
          </div>
        </header>

        {mainTiles.length > 0 && (
          <div className="hidden desk:block"><CategoryTiles main={mainTiles} all={allTiles} lang={lang} /></div>
        )}
        {phoneCats.length > 0 && (
          <ul className="mt-5 grid grid-cols-2 gap-[13px] desk:hidden">
            {phoneCats.map((c) => <li key={c.id}><PhoneCategory c={c} count={count(c)} lang={lang} /></li>)}
          </ul>
        )}

        <DirectoryResults items={items} lang={lang} />
      </DirectorySearchProvider>

      {professionals.length > 0 && (
        <section className="mt-20 hidden desk:block">
          <h2 className="font-nunito text-[28px] font-semibold leading-[34px] text-midblue">{t('בעלי מקצוע ושירותים', 'Professionals & Services')}</h2>
          <p className="mt-2.5 text-sm text-gray-text">{t('נותני שירות הרשומים במדריך מודיעין', 'Service providers listed in the Modiin directory')}</p>
          <ul className="mt-8 grid grid-cols-6 gap-5">
            {professionals.map((b, i) => <li key={b.id}><ProfessionalCard b={b} cats={byBusiness.get(b.id) ?? []} index={i} lang={lang} /></li>)}
          </ul>
        </section>
      )}

      <section className="my-[100px] hidden items-center gap-10 rounded-3xl bg-gradient-to-br from-navy via-midblue to-turquoise px-14 py-12 desk:flex">
        <div className="flex-1">
          <h2 className="font-nunito text-[32px] font-semibold leading-[1.25] text-white">{t('יש לכם עסק במודיעין?', 'Own a business in Modiin?')}</h2>
          <p className="mt-3 text-base leading-[1.4] text-white/90">{t('כתבו לנו ונוסיף אותו למדריך מודיעין4u.', 'Write to us and we will add it to the Modiin4u directory.')}</p>
        </div>
        {/* No self-service listing form: the office mailbox the footer uses. */}
        <a href={`mailto:${CONTACT.email}?subject=${encodeURIComponent(t('הוספת העסק שלי למודיעין4u', 'Adding my business to Modiin4u'))}`}
          className="rounded-full bg-white px-10 py-[18px] text-base font-semibold text-midblue hover:bg-white/90">
          {t('הוסיפו את העסק שלכם', 'Add Your Business')}
        </a>
      </section>
    </div>
  );
}

/** The phone's category colours, by the category's place in the panel. */
const PHONE_COLORS = ['#17A9D0', '#2ECC71', '#8B5CF6', '#E74C3C', '#FF9800', '#123A72', '#00BCD4', '#795548', '#607D8B', '#9C27B0'];

function PhoneIcon({ slug }: { slug: string }) {
  const p = { size: 26, color: 'currentColor', variant: 'Bold' as const };
  switch (slug) {
    case 'restaurants': return <Reserve {...p} />;
    case 'cafe-bakery': return <Coffee {...p} />;
    case 'health': return <Health {...p} />;
    case 'sports-fitness': return <Weight {...p} />;
    case 'education': return <Book {...p} />;
    case 'services': return <Setting2 {...p} />;
    case 'shopping': return <ShoppingBag {...p} />;
    case 'automotive': return <Car {...p} />;
    case 'beauty': return <Brush2 {...p} />;
    case 'entertainment': return <Music {...p} />;
    default: return <Shop {...p} />;
  }
}

/** darken(): a colour mixed with black, as Color.lerp(c, black, t). */
function darken(hex: string, t: number): string {
  const n = parseInt(hex.slice(1), 16);
  const ch = (s: number) => Math.round(((n >> s) & 255) * (1 - t)).toString(16).padStart(2, '0');
  return `#${ch(16)}${ch(8)}${ch(0)}`;
}

/** A phone category card (businesses_screen _CategoryCard): the category's
 *  photograph under a gradient to black at the foot, or a coloured tile and
 *  its icon where it has none; the name and the count in white. */
function PhoneCategory({ c, count, lang }: { c: BizCategory; count: number; lang: Lang }) {
  const color = PHONE_COLORS[Math.abs(c.sort_order ?? 0) % PHONE_COLORS.length];
  const image = sizedPhoto(c.image_url, 400);
  return (
    <Link href={href(categoryPath(c.slug))} className="relative flex aspect-[174/170] flex-col overflow-hidden rounded-xl p-4 text-white"
      style={image ? undefined : { backgroundImage: `linear-gradient(to bottom right, ${color}, ${darken(color, 0.55)})` }}>
      {image && (
        <>
          <img src={image} alt="" loading="lazy" className="absolute inset-0 size-full object-cover" />
          <span className="absolute inset-0 bg-[linear-gradient(to_bottom,transparent_52%,#000)]" />
        </>
      )}
      {!image && <span className="self-end text-white/35"><PhoneIcon slug={c.slug} /></span>}
      <span className="relative mt-auto line-clamp-2 text-lg font-semibold leading-tight">{catName(c, lang)}</span>
      {count > 0 && <span className="relative mt-1 text-xs">{lang === 'he' ? `${count} עסקים` : `${count} businesses`}</span>}
    </Link>
  );
}

const LOGO_BG = ['#4A2D6E', '#6E2D54', '#283593', '#6D4C41', '#37474F', '#2E7D32', '#2E5A47', '#5D4037'];

/** A service provider (_ProfessionalCard): the logo in a circle, the name,
 *  the category, its own line where a star rating used to invent a score,
 *  and Contact where there is a number. */
function ProfessionalCard({ b, cats, index, lang }: { b: BizRow; cats: BizCategory[]; index: number; lang: Lang }) {
  const t = tr(lang);
  const cat = cats.length ? (cats.find((c) => c.parent_id) ?? cats[0]) : null;
  const base = LOGO_BG[index % LOGO_BG.length];
  const phone = (b.phone ?? '').trim();
  return (
    <article className="group relative flex h-full flex-col items-center rounded-xl border border-line bg-white px-4 py-6 text-center hover:border-midblue">
      <Photo src={sizedPhoto(b.logo_url || bizPhoto(b), 200)} alt={bizName(b, lang)} icon={24} glyph="image" iconClass="text-white/35"
        style={{ backgroundImage: `linear-gradient(to bottom right, ${base}, ${darken(base, 0.22)})` }} className="size-[88px] shrink-0 rounded-full" />
      <h3 className="mt-4 w-full truncate text-base font-semibold text-[#1C1C1E]">
        <Link href={href(`/business/${b.slug}/`)} className="after:absolute after:inset-0">{bizName(b, lang)}</Link>
      </h3>
      <p className="mt-1 w-full truncate text-[13px] text-gray-text">{cat ? catName(cat, lang) : t('עסק', 'Business')}</p>
      <p className="mt-2.5 line-clamp-2 h-8 text-xs leading-[1.35] text-gray-text">{bizDescription(b)}</p>
      {phone && (
        <div className="mt-4 w-full [&>div]:w-full">
          <ContactButton phone={phone} whatsapp={b.whatsapp} email={b.email} lang={lang}
            className="h-10 w-full rounded-full border border-midblue text-sm font-medium text-midblue group-hover:bg-midblue group-hover:text-white">
            {t('צרו קשר', 'Contact')}
          </ContactButton>
        </div>
      )}
    </article>
  );
}

