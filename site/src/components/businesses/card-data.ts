import { href } from '@/lib/seo';
import type { Lang } from '@/lib/i18n';
import {
  bizDescription, bizName, bizNeighborhood, bizPhoto, catName, kosherLabel, sizedPhoto,
  type BizCategory, type BizRow, type PrimaryCategory,
} from '@/lib/data/businesses';
import type { BizCard } from './BusinessCard';

/** A business row as the cards draw it, in the reader's language. [primary]
 *  is the row's most specific category (primaryCategories()). */
export function toCard(b: BizRow, lang: Lang, primary: PrimaryCategory | undefined): BizCard {
  const description = bizDescription(b);
  const category = primary ? catName(primary.category, lang) : '';
  const neighborhood = bizNeighborhood(b, lang);
  return {
    id: b.id,
    href: href(`/business/${b.slug}/`),
    name: bizName(b, lang),
    subtitle: description || category,
    kind: category || description,
    address: (b.address ?? '').trim() || neighborhood,
    neighborhood,
    // The card is about 380 wide; a sharp screen wants twice that.
    photo: sizedPhoto(bizPhoto(b) || b.logo_url, 800),
    rating: Number(b.rating ?? 0),
    reviews: b.review_count ?? 0,
    kosher: kosherLabel(b.kosher_level),
    delivery: !!b.has_delivery,
    phone: (b.phone ?? '').trim() || null,
    whatsapp: b.whatsapp,
    email: b.email,
    category: category || null,
    badge: primary?.rootSlug === 'cafe-bakery' ? 'cafe' : primary?.rootSlug === 'restaurants' ? 'restaurant' : null,
  };
}

/** What the directory's search reads (web_businesses_screen): the name — in
 *  both languages —, the category the grid filters on and the area. */
export function searchText(b: BizRow, lang: Lang, cats: BizCategory[] | undefined): string {
  // A pizzeria is filed under both "restaurants" and "pizza"; the child is
  // the truer word for it.
  const cat = cats?.length ? (cats.find((c) => c.parent_id) ?? cats[0]) : null;
  return [b.name, b.name_en, cat ? catName(cat, lang) : '', bizNeighborhood(b, lang) || b.address]
    .filter(Boolean).join(' ').toLowerCase();
}
