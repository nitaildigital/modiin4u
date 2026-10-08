import { db } from '../supabase';
import type { Lang } from '../i18n';
import { href } from '../seo';

export type HitKind = 'business' | 'event' | 'deal' | 'listing' | 'news';

/** One row of the results, whatever it came from (SearchHit). */
export type Hit = { kind: HitKind; title: string; subtitle: string; href: string; image: string | null };

/** The words as they go into a PostgREST `or=(…)` filter: its own commas,
 *  brackets and quotes would end the filter early, so they are left out. */
function term(q: string): string {
  return q.replace(/[,()"\\*%]/g, ' ').replace(/\s+/g, ' ').trim();
}

/** Today's date in Israel, "2026-10-08". */
function israelToday(): string {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Jerusalem', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date());
}

const join = (parts: (string | null | undefined)[]) => parts.map((p) => (p ?? '').trim()).filter(Boolean).join(' · ');

/** The site's search, as the app runs it (searchResultsProvider): the
 *  database does the matching, over every row of each table — businesses
 *  and parks by name, English name or short description; events still to
 *  come by title or description; deals still running by name, business or
 *  text; listings by title or address; articles by title or slug. In
 *  that order: businesses, events, deals, listings, news. */
export async function search(query: string, lang: Lang): Promise<Hit[]> {
  const q = term(query);
  if (!q) return [];
  const like = `%${q}%`;

  const [biz, arts, evs, lists, offs] = await Promise.all([
    db.from('businesses')
      .select('id,slug,name,name_en,short_description,full_description,cover_url,og_image_url,neighborhoods!businesses_neighborhood_id_fkey(name,name_en)')
      .eq('status', 'active').or(`name.ilike.${like},name_en.ilike.${like},short_description.ilike.${like}`)
      .order('promoted_until', { ascending: false, nullsFirst: false }).order('created_at', { ascending: false }),
    db.from('articles').select('id,slug,title,subtitle,excerpt,featured_image,mobile_image,og_image')
      .eq('status', 'published').or(`title.ilike.${like},slug.ilike.${like}`)
      .order('published_at', { ascending: false, nullsFirst: false }).order('created_at', { ascending: false }),
    db.from('events').select('id,title,venue_name,start_date,start_time,end_date,is_all_day,image_url,og_image')
      .eq('status', 'published').or(`title.ilike.${like},short_description.ilike.${like}`)
      .order('start_date', { ascending: true }),
    db.from('listings').select('id,title,address,cover_url,neighborhoods(name,name_en)')
      .eq('status', 'active').or(`title.ilike.${like},address.ilike.${like}`)
      .order('is_featured', { ascending: false }).order('created_at', { ascending: false }).limit(100),
    // The live deals, matched here as the app does (activeOffersProvider).
    db.from('offers').select('id,name,description,image_url,end_at,businesses(name,name_en)')
      .eq('status', 'active')
      .order('promoted_until', { ascending: false, nullsFirst: false }).order('is_featured', { ascending: false })
      .order('end_at', { ascending: true, nullsFirst: false }).limit(60),
  ]);

  type Hood = { name: string | null; name_en: string | null } | null;
  const hood = (h: Hood) => (lang === 'en' && h?.name_en?.trim()) || h?.name || '';
  const today = israelToday();
  const needle = query.trim().toLowerCase();
  const now = Date.now();

  const businesses = ((biz.data ?? []) as unknown as { id: string; slug: string; name: string; name_en: string | null; short_description: string | null; full_description: string | null; cover_url: string | null; og_image_url: string | null; neighborhoods: Hood }[])
    .map((b): Hit => ({
      kind: 'business',
      title: (lang === 'en' && b.name_en?.trim()) || b.name,
      subtitle: join([b.short_description ?? b.full_description, hood(b.neighborhoods)]),
      href: href(`/business/${b.slug || b.id}/`),
      image: b.cover_url || b.og_image_url,
    }));

  // An event is still to come until the day it ends (or starts, when it
  // gives no end) is over, so one running today is found.
  const events = ((evs.data ?? []) as { id: string; title: string; venue_name: string | null; start_date: string | null; start_time: string | null; end_date: string | null; is_all_day: boolean | null; image_url: string | null; og_image: string | null }[])
    .filter((e) => { const last = (e.end_date ?? e.start_date)?.slice(0, 10); return !last || last >= today; })
    .map((e): Hit => {
      const m = /^(\d{1,2}):(\d{2})/.exec(e.start_time ?? '');
      return {
        kind: 'event', title: e.title,
        subtitle: join([e.venue_name, !e.is_all_day && m ? `${m[1]}:${m[2]}` : null]),
        href: href(`/event/${e.id}/`), image: e.image_url || e.og_image,
      };
    });

  const deals = ((offs.data ?? []) as unknown as { id: string; name: string; description: string | null; image_url: string | null; end_at: string | null; businesses: { name: string | null; name_en: string | null } | null }[])
    .filter((o) => (!o.end_at || Date.parse(o.end_at) > now)
      && [o.name, o.businesses?.name, o.description].some((t) => (t ?? '').toLowerCase().includes(needle)))
    .map((o): Hit => ({
      kind: 'deal', title: o.name,
      subtitle: (lang === 'en' && o.businesses?.name_en?.trim()) || o.businesses?.name || '',
      href: href(`/deal/${o.id}/`), image: o.image_url,
    }));

  const listings = ((lists.data ?? []) as unknown as { id: string; title: string; address: string | null; cover_url: string | null; neighborhoods: Hood }[])
    .map((l): Hit => ({
      kind: 'listing', title: l.title, subtitle: join([l.address, hood(l.neighborhoods)]),
      href: href(`/listing/${l.id}/`), image: l.cover_url,
    }));

  const articles = ((arts.data ?? []) as { id: string; slug: string; title: string; subtitle: string | null; excerpt: string | null; featured_image: string | null; mobile_image: string | null; og_image: string | null }[])
    .map((a): Hit => ({
      kind: 'news', title: a.title, subtitle: (a.excerpt ?? a.subtitle ?? '').trim(),
      href: href(`/news/${a.slug}/`), image: a.featured_image || a.mobile_image || a.og_image,
    }));

  return [...businesses, ...events, ...deals, ...listings, ...articles];
}
