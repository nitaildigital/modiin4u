import { cache } from 'react';
import { db } from '../supabase';
import type { Lang } from '../i18n';

export type Article = {
  id: string; slug: string; title: string; subtitle: string | null;
  excerpt: string | null; body: string | null; featured_image: string | null; og_image: string | null;
  seo_title: string | null; meta_description: string | null; published_at: string | null;
  updated_at: string | null; noindex: boolean | null; view_count: number | null; share_count: number | null;
  /** The byline the newsroom types in the panel; empty on the imported rows. */
  credit: string | null;
  og_title: string | null; og_description: string | null; meta_keywords: string | null;
};

const FIELDS = 'id,slug,title,subtitle,excerpt,body,featured_image,og_image,seo_title,meta_description,published_at,updated_at,noindex,view_count,share_count,credit,og_title,og_description,meta_keywords';
const LIST_FIELDS = 'id,slug,title,excerpt,featured_image,published_at';

/** One published article by its slug — or by its old address's slug. */
export const articleBySlug = cache(async (slug: string): Promise<Article | null> => {
  const { data } = await db.from('articles').select(FIELDS).eq('slug', slug).eq('status', 'published').maybeSingle();
  return data as Article | null;
});

export type ArticleCard = Pick<Article, 'id' | 'slug' | 'title' | 'excerpt' | 'featured_image' | 'published_at'>;

export async function latestArticles(limit: number, excludeId?: string): Promise<ArticleCard[]> {
  let q = db.from('articles').select(LIST_FIELDS).eq('status', 'published')
    .order('published_at', { ascending: false, nullsFirst: false }).limit(limit + 1);
  if (excludeId) q = q.neq('id', excludeId);
  const { data } = await q;
  return ((data ?? []) as ArticleCard[]).slice(0, limit);
}

export type Category = { id: string; slug: string; name: string; name_en: string | null; scope: string; parent_id: string | null };

/** The categories an article or business is filed under. */
export async function categoriesOf(entityType: 'article' | 'business', id: string): Promise<Category[]> {
  const { data } = await db.from('entity_categories')
    .select('categories(id,slug,name,name_en,scope,parent_id)').eq('entity_type', entityType).eq('entity_id', id);
  return ((data ?? []) as unknown as { categories: Category | null }[]).map((r) => r.categories).filter(Boolean) as Category[];
}

export function categoryName(c: Pick<Category, 'name' | 'name_en'>, lang: Lang): string {
  return lang === 'en' && c.name_en ? c.name_en : c.name;
}

/** The newest articles in the same categories, else the newest overall. */
export async function relatedArticles(articleId: string, categoryIds: string[], limit = 4): Promise<ArticleCard[]> {
  if (categoryIds.length) {
    const { data: links } = await db.from('entity_categories').select('entity_id')
      .eq('entity_type', 'article').in('category_id', categoryIds).neq('entity_id', articleId).limit(400);
    const ids = [...new Set((links ?? []).map((l) => l.entity_id as string))];
    if (ids.length) {
      const { data } = await db.from('articles').select(LIST_FIELDS).eq('status', 'published').in('id', ids.slice(0, 300))
        .order('published_at', { ascending: false, nullsFirst: false }).limit(limit);
      if (data?.length) return data as ArticleCard[];
    }
  }
  return latestArticles(limit, articleId);
}

export type Comment = { id: string; parent_id: string | null; body: string; author_name: string | null; created_at: string };

/** The approved comments under an article — read-only on the website. */
export async function articleComments(articleId: string): Promise<Comment[]> {
  const { data } = await db.from('comments').select('id,parent_id,body,author_name,created_at')
    .eq('entity_type', 'article').eq('entity_id', articleId).eq('status', 'approved').order('created_at');
  return (data ?? []) as Comment[];
}
