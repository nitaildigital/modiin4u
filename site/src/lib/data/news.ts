import { cache } from 'react';
import { db } from '../supabase';
import type { Lang } from '../i18n';

/** How many stories one page of a news list holds. Every published article
 *  sits on one of these pages, linked plainly, so a search engine reaches
 *  all of them from /news/ (there are some 670, and 25 of them are filed
 *  under no category). */
export const PER_PAGE = 24;

/** One story as the lists draw it (web_news_screen.dart, news_screen.dart). */
export type NewsCard = {
  id: string; slug: string; title: string; excerpt: string | null;
  /** featured_image, else mobile_image, else og_image — the app's order. */
  image: string | null;
  published_at: string | null; is_featured: boolean; is_breaking: boolean;
};

/** What ordering, the hero and the sections need of every published story:
 *  its id, its date, whether the newsroom featured it and whether it has a
 *  picture. The text is read only for the stories a page shows. */
type IndexRow = { id: string; published_at: string | null; is_featured: boolean; pic: boolean };

/** Every published article, newest first — the app's order (published_at,
 *  then created_at; every imported row has the same created_at). */
export const newsIndex = cache(async (): Promise<IndexRow[]> => {
  const out: IndexRow[] = [];
  // PostgREST answers at most a thousand rows at a time.
  for (let from = 0; ; from += 1000) {
    const { data } = await db.from('articles')
      .select('id,published_at,is_featured,featured_image,mobile_image,og_image')
      .eq('status', 'published')
      .order('published_at', { ascending: false, nullsFirst: false })
      .order('created_at', { ascending: false })
      .order('id')
      .range(from, from + 999);
    const rows = (data ?? []) as { id: string; published_at: string | null; is_featured: boolean | null; featured_image: string | null; mobile_image: string | null; og_image: string | null }[];
    for (const r of rows) {
      out.push({ id: r.id, published_at: r.published_at, is_featured: !!r.is_featured, pic: !!(r.featured_image || r.mobile_image || r.og_image) });
    }
    if (rows.length < 1000) break;
  }
  return out;
});

/** The stories with these ids, in the order given. */
export async function newsCards(ids: string[]): Promise<NewsCard[]> {
  if (!ids.length) return [];
  const { data } = await db.from('articles')
    .select('id,slug,title,excerpt,featured_image,mobile_image,og_image,published_at,is_featured,is_breaking')
    .in('id', ids).eq('status', 'published');
  const byId = new Map(((data ?? []) as (Omit<NewsCard, 'image'> & { featured_image: string | null; mobile_image: string | null; og_image: string | null })[])
    .map((r) => [r.id, {
      id: r.id, slug: r.slug, title: r.title, excerpt: r.excerpt,
      image: r.featured_image || r.mobile_image || r.og_image || null,
      published_at: r.published_at, is_featured: !!r.is_featured, is_breaking: !!r.is_breaking,
    } as NewsCard]));
  return ids.map((id) => byId.get(id)).filter(Boolean) as NewsCard[];
}

/** The story in the hero slot (news_providers.dart, pickHeroArticle): a
 *  featured story with a picture, else any featured one, else the newest
 *  with a picture, else the newest. Which story is featured is the client's
 *  call in the panel. */
export function pickHero<T extends { is_featured: boolean; pic: boolean }>(rows: T[]): T | undefined {
  return rows.find((a) => a.is_featured && a.pic) ?? rows.find((a) => a.is_featured) ?? rows.find((a) => a.pic) ?? rows[0];
}

export type NewsCategory = {
  id: string; slug: string; name: string; name_en: string | null; parent_id: string | null;
  is_active: boolean; meta_title: string | null; meta_description: string | null; description: string | null;
};

/** The news categories (scope `article`), active or not, in the panel's
 *  order: the inactive ones still name the stories filed under them. */
export const newsCategories = cache(async (): Promise<NewsCategory[]> => {
  const { data } = await db.from('categories')
    .select('id,slug,name,name_en,parent_id,is_active,meta_title,meta_description,description')
    .eq('scope', 'article').order('sort_order');
  return (data ?? []) as NewsCategory[];
});

/** An active news category by its slug. */
export async function newsCategoryBySlug(slug: string): Promise<NewsCategory | undefined> {
  return (await newsCategories()).find((c) => c.slug === slug && c.is_active);
}

type Link = { entity_id: string; category_id: string; is_primary: boolean | null };

/** Which story is filed under which category: every article link, about
 *  seven hundred small rows. */
export const articleLinks = cache(async (): Promise<Link[]> => {
  const out: Link[] = [];
  for (let from = 0; ; from += 1000) {
    const { data } = await db.from('entity_categories').select('entity_id,category_id,is_primary')
      .eq('entity_type', 'article').order('entity_id').order('category_id').range(from, from + 999);
    const rows = (data ?? []) as Link[];
    out.push(...rows);
    if (rows.length < 1000) break;
  }
  return out;
});

/** The category a story's chip names, by story id: the link marked primary,
 *  else the first (articleFilingProvider). */
export async function chipCategories(ids: string[]): Promise<Map<string, NewsCategory>> {
  const [cats, links] = await Promise.all([newsCategories(), articleLinks()]);
  const byId = new Map(cats.map((c) => [c.id, c]));
  const want = new Set(ids);
  const out = new Map<string, NewsCategory>();
  for (const l of links) {
    const c = byId.get(l.category_id);
    if (!want.has(l.entity_id) || !c?.name) continue;
    if (!out.has(l.entity_id) || l.is_primary) out.set(l.entity_id, c);
  }
  return out;
}

export function newsCategoryName(c: Pick<NewsCategory, 'name' | 'name_en'>, lang: Lang): string {
  return lang === 'en' && c.name_en ? c.name_en : c.name;
}

export type FrontSection = { category: NewsCategory; ids: string[] };

/** The news front page (web_news_screen.dart, news_screen.dart): the hero,
 *  the two stories beside it, and a section per category holding its six
 *  newest stories — one per active category with something in it, in the
 *  panel's order. The desktop's sections leave out the three stories on
 *  top, the phone's only the hero (it has no side stories). The rest of the
 *  stories, newest first, follow on the pages after the front. */
export async function newsFront() {
  const [index, cats, links] = await Promise.all([newsIndex(), newsCategories(), articleLinks()]);
  const hero = pickHero(index);
  const rest = index.filter((a) => a !== hero);
  const side = rest.slice(0, 2);
  const members = new Map<string, Set<string>>();
  for (const l of links) {
    if (!members.has(l.category_id)) members.set(l.category_id, new Set());
    members.get(l.category_id)!.add(l.entity_id);
  }
  const sectionsLeaving = (skip: Set<string>): FrontSection[] => cats
    .filter((c) => c.is_active)
    .map((c) => {
      const m = members.get(c.id);
      return { category: c, ids: m ? index.filter((a) => m.has(a.id) && !skip.has(a.id)).slice(0, 6).map((a) => a.id) : [] };
    })
    .filter((s) => s.ids.length);
  const top = new Set([hero, ...side].filter(Boolean).map((a) => a!.id));
  const desk = sectionsLeaving(top);
  const phone = sectionsLeaving(new Set(hero ? [hero.id] : []));
  // Where nothing is filed, the phone shows the newest stories as one
  // section ("Latest Stories"), as the app does.
  const phoneLatest = phone.length ? [] : rest.slice(0, 6).map((a) => a.id);

  const onFront = new Set([...top, ...desk.flatMap((s) => s.ids), ...phone.flatMap((s) => s.ids), ...phoneLatest]);
  const archive = index.filter((a) => !onFront.has(a.id)).map((a) => a.id);
  return {
    hero: hero?.id, side: side.map((a) => a.id), desk, phone, phoneLatest, archive,
    pages: 1 + Math.ceil(archive.length / PER_PAGE),
  };
}

/** A category's stories (/new/<slug>/), its sub-categories' too — as
 *  tool/build_seo_pages.py lists them — the hero first (the same rule as
 *  the front page's), then the rest newest first. */
export async function categoryStories(category: NewsCategory): Promise<string[]> {
  const [index, cats, links] = await Promise.all([newsIndex(), newsCategories(), articleLinks()]);
  const ids = new Set([category.id, ...cats.filter((c) => c.parent_id === category.id && c.is_active).map((c) => c.id)]);
  const members = new Set(links.filter((l) => ids.has(l.category_id)).map((l) => l.entity_id));
  const list = index.filter((a) => members.has(a.id));
  const hero = pickHero(list);
  return hero ? [hero.id, ...list.filter((a) => a !== hero).map((a) => a.id)] : [];
}
