import { Suspense } from 'react';
import Link from 'next/link';
import { ArrowLeft, ArrowLeft2, ArrowRight, ArrowRight2 } from 'iconsax-react';
import { getLang, tr } from '@/lib/i18n';
import { breadcrumb, h1For, href, SITE_NAME } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import {
  businessCategories, businessesInCategory, catName, categoriesByBusiness, primaryCategories, type BizCategory,
} from '@/lib/data/businesses';
import { JsonLd } from '@/components/JsonLd';
import { toCard } from './card-data';
import { BusinessList, type ListItem } from './BusinessList';

/** One business category (/business-cat/<slug>/, and the old addresses that
 *  stand for one): web_business_list_screen.dart at desktop width — back to
 *  the directory, the name, the count and pills, the cards four a row — and
 *  business_list_screen.dart on a phone. The category's own businesses and
 *  its sub-categories'. [path] is the address being served, for its H1 and
 *  breadcrumb; [category] null lists nothing, as a category the panel has
 *  switched off does. */
export async function CategoryPage({ path, category }: { path: string; category: BizCategory | null }) {
  const lang = await getLang();
  const t = tr(lang);
  const [rows, cats, primary, byBusiness] = await Promise.all([
    category ? businessesInCategory(category.id) : Promise.resolve([]),
    businessCategories(), primaryCategories(), categoriesByBusiness(),
  ]);
  const name = category ? catName(category, lang) : '';
  const title = h1For(path, name);
  const byId = new Map(cats.map((c) => [c.id, c]));

  const items: ListItem[] = rows.map((b) => {
    const mine = byBusiness.get(b.id) ?? [];
    // Its categories with their parents, so "pizza" also answers to its
    // cuisine's parent.
    const slugs = new Set(mine.flatMap((c) => [c.slug, ...(c.parent_id && byId.get(c.parent_id) ? [byId.get(c.parent_id)!.slug] : [])]));
    return {
      card: toCard(b, lang, primary.get(b.id)),
      search: [b.name, b.name_en, b.address].filter(Boolean).join(' ').toLowerCase(),
      cuisines: [...slugs],
    };
  });
  // The cuisine filter belongs to the restaurants list, and offers only the
  // cuisines that have a place in it.
  const cuisines = category?.slug === 'restaurants'
    ? cats.filter((c) => c.parent_id === category.id && items.some((i) => i.cuisines.includes(c.slug)))
      .map((c) => ({ slug: c.slug, name: catName(c, lang) }))
    : [];

  const back = t('כל העסקים', 'All Businesses');
  const Arrow = lang === 'he' ? ArrowRight : ArrowLeft;
  const Chevron = lang === 'he' ? ArrowRight2 : ArrowLeft2;
  return (
    <div className="wrap pb-8 max-desk:mx-auto max-desk:max-w-[430px] max-desk:px-4 desk:pb-[100px] desk:pt-12">
      <JsonLd data={[
        breadcrumb([[SITE_NAME, '/'], ['עסקים', '/businesses/'], [title, path]]),
        {
          '@context': 'https://schema.org', '@type': 'ItemList', name: title,
          itemListElement: rows.map((b, i) => ({ '@type': 'ListItem', position: i + 1, url: SITE_URL + href(`/business/${b.slug}/`), name: b.name })),
        },
      ]} />
      <Link href="/businesses/" className="hidden items-center gap-2 text-sm font-medium text-navy desk:inline-flex">
        <Arrow size={22} color="currentColor" />{back}
      </Link>
      <div className="relative flex h-12 items-center justify-center desk:mt-5 desk:block desk:h-auto">
        <Link href="/businesses/" aria-label={back} className="absolute start-1 grid size-10 place-items-center text-black desk:hidden">
          <Chevron size={24} color="currentColor" />
        </Link>
        <h1 className="truncate px-14 text-base font-semibold text-black desk:px-0 desk:font-nunito desk:text-[28px] desk:leading-[34px] desk:text-midblue">{title}</h1>
      </div>
      <Suspense>
        <BusinessList items={items} lang={lang} title={name || title} cuisines={cuisines} />
      </Suspense>
    </div>
  );
}
