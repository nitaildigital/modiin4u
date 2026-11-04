import { db } from '../supabase';

/** [mobile_image_url] is the campaign's phone-shaped creative, when it has
 *  one (00086); only the article page's slots use it so far. */
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
