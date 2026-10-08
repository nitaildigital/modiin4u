import { cache } from 'react';
import { db } from '../supabase';

// What the Community page links to, as the client sets it in the panel
// (Remote Config): his Facebook group, his "share with us" form and the news
// category the page lists (community_providers.dart). An empty or missing
// link hides its card rather than pointing somewhere made up.

export type CommunitySettings = { facebookUrl: string | null; shareUrl: string | null; newsCategorySlug: string | null };

export const communitySettings = cache(async (): Promise<CommunitySettings> => {
  const { data } = await db.from('remote_config').select('key,value')
    .in('key', ['community_facebook_url', 'community_share_url', 'community_news_category']);
  const values = Object.fromEntries((data ?? []).map((r) => [r.key as string, String(r.value ?? '').trim()]));
  const value = (k: string) => values[k] || null;
  return {
    facebookUrl: value('community_facebook_url'),
    shareUrl: value('community_share_url'),
    newsCategorySlug: value('community_news_category'),
  };
});

export type CommunityArticle = { id: string; slug: string; title: string; featured_image: string | null; published_at: string | null };

/** The chosen news category — its slug, for "See all" — and its eight newest
 *  published stories. Null when no category is set or the slug matches
 *  none. */
export const communityNews = cache(async (): Promise<{ slug: string; articles: CommunityArticle[] } | null> => {
  const slug = (await communitySettings()).newsCategorySlug;
  if (!slug) return null;
  const { data: cats } = await db.from('categories').select('id,slug').eq('slug', slug).eq('scope', 'article').limit(1);
  const cat = cats?.[0];
  if (!cat) return null;
  const { data: links } = await db.from('entity_categories').select('entity_id')
    .eq('entity_type', 'article').eq('category_id', cat.id).limit(2000);
  const ids = [...new Set((links ?? []).map((l) => l.entity_id as string))];
  if (!ids.length) return { slug: cat.slug as string, articles: [] };
  const { data } = await db.from('articles').select('id,slug,title,featured_image,published_at')
    .eq('status', 'published').in('id', ids.slice(0, 300))
    .order('published_at', { ascending: false, nullsFirst: false })
    .order('created_at', { ascending: false }).limit(8);
  return { slug: cat.slug as string, articles: (data ?? []) as CommunityArticle[] };
});
