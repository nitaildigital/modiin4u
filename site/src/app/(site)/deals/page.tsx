import type { Metadata } from 'next';
import { getLang, tr } from '@/lib/i18n';
import { pageMetadata, h1For, breadcrumb, href, SITE_NAME, SUFFIX } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import { categoriesOfBusinesses, dealCategories, liveDeals } from '@/lib/data/deals';
import { banners } from '@/lib/data/banners';
import { JsonLd } from '@/components/JsonLd';
import { DealsHome } from '@/components/deals/DealsHome';

const PATH = '/deals/';
// The page's name, as the website's heading prints it.
const NAME_HE = 'המבצעים וההטבות הטובים במודיעין';
const NAME_EN = 'Best Deals & Offers in Modiin';

export async function generateMetadata(): Promise<Metadata> {
  return pageMetadata({
    path: PATH,
    title: NAME_HE + SUFFIX,
    description: 'גלו מבצעים מקומיים, הנחות והטבות לזמן מוגבל בכל מודיעין.',
  });
}

/** The deals page (web_deals_screen.dart / deals_screen.dart): the deals
 *  running now, as the app lists them — active, not past their end date,
 *  promoted first, then featured, then the soonest to end. */
export default async function DealsPage() {
  const lang = await getLang();
  const t = tr(lang);
  const [deals, categories, top] = await Promise.all([liveDeals(), dealCategories(), banners('DEALS_TOP')]);
  const kinds = await categoriesOfBusinesses(deals.map((d) => d.business?.id).filter((id): id is string => !!id));

  return (
    <>
      <JsonLd data={[
        {
          '@context': 'https://schema.org', '@type': 'ItemList', name: NAME_HE, url: SITE_URL + href(PATH),
          itemListElement: deals.map((d, i) => ({ '@type': 'ListItem', position: i + 1, url: SITE_URL + href(`/deal/${d.id}/`), name: d.name })),
        },
        breadcrumb([[SITE_NAME, '/'], [NAME_HE, PATH]]),
      ]} />
      <DealsHome lang={lang} heading={h1For(PATH, t(NAME_HE, NAME_EN))} deals={deals} categories={categories}
        kinds={kinds} banners={top} dealHref={Object.fromEntries(deals.map((d) => [d.id, href(`/deal/${d.id}/`)]))} />
    </>
  );
}
