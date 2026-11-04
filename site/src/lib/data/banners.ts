import { cache } from 'react';
import { db } from '../supabase';

/** [mobile_image_url] is a phone-shaped creative, when there is one (00086);
 *  only the article page's banners use it so far. */
export type Banner = { id: string; image_url: string; destination_url: string | null; name: string; mobile_image_url?: string | null };

/** The paid banners running now in one slot (`ad_placements.code`), through
 *  `active_banners()` (00028): the creative and the link, nothing else. A slot
 *  with nothing booked — or a failed call — draws nothing. */
export async function banners(code: string): Promise<Banner[]> {
  try {
    const { data } = await db.rpc('active_banners', { p_code: code });
    return ((data ?? []) as Banner[]).filter((b) => b.image_url);
  } catch {
    return [];
  }
}

export type ArticleBannerSlot = 'top' | 'middle' | 'end';

/** The article page's default banners — `article_banners` in app_settings,
 *  set from the panel's Articles screen (00087) — for any slot an article
 *  leaves empty. None when unset or unreadable. */
export const articleBannerDefaults = cache(async (): Promise<unknown> => {
  const { data } = await db.from('app_settings').select('value').eq('key', 'article_banners').maybeSingle()
    .then((r) => r, () => ({ data: null }));
  return data?.value ?? null;
});

const web = (v: unknown) => (typeof v === 'string' && /^https?:\/\//i.test(v.trim()) ? v.trim() : null);

/** One slot's banner: the article's own ([own], its `banners`), or else the
 *  default. Each is `{ top|middle|end: { image, mobile?, link? } }`; only a
 *  web address counts, for the picture as for the link, so nothing else
 *  saved there can turn into a link on the page. [label] names it for a
 *  screen reader. */
export function articleBanner(own: unknown, defaults: unknown, slot: ArticleBannerSlot, label: string): Banner | null {
  for (const source of [own, defaults]) {
    const b = (source as Record<string, Record<string, unknown> | undefined> | null)?.[slot];
    const image = web(b?.image);
    if (image) return { id: slot, name: label, image_url: image, mobile_image_url: web(b?.mobile), destination_url: web(b?.link) };
  }
  return null;
}
