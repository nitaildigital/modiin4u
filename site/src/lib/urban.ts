'use client';
import { sessionDb } from './session';

/** The Urban Profile on the website (the app's urban_profile.dart; 00077):
 *  the signed-in resident's own, read and saved with their session — the same
 *  rows and the same limits as the app, so a profile started in one is
 *  finished in the other. */

// The app's list, as 00077 stores the keys.
export const INTERESTS: [key: string, emoji: string, he: string, en: string][] = [
  ['cafes', '☕', 'בתי קפה', 'Cafés'], ['brunch', '🥐', 'ארוחות בוקר ובראנץ׳', 'Breakfast & Brunch'],
  ['nightlife', '🍷', 'ברים וחיי לילה', 'Bars & Nightlife'], ['restaurants', '🍽️', 'מסעדות', 'Restaurants'],
  ['asian', '🍣', 'אוכל אסייתי', 'Asian Food'], ['nature', '🌳', 'פארקים וטבע', 'Parks & Nature'],
  ['running', '🏃', 'ריצה', 'Running'], ['cycling', '🚴', 'רכיבה על אופניים', 'Cycling'],
  ['fitness', '🏋️', 'כושר וספורט', 'Fitness & Sports'], ['family', '👨‍👩‍👧', 'משפחה וילדים', 'Family & Kids'],
  ['culture', '🎭', 'תרבות', 'Culture'], ['music', '🎵', 'מוזיקה', 'Music'], ['pets', '🐶', 'חיות מחמד', 'Pets'],
  ['shopping', '🛍️', 'קניות', 'Shopping'], ['events', '🎉', 'אירועים', 'Events'], ['local_business', '💼', 'עסקים מקומיים', 'Local Businesses'],
];
export const MIN_INTERESTS = 3;
export const MAX_INTERESTS = 8;
export const MAX_PLACES = 5;
export const BIO_MAX = 160;
/** Accounts made from this day get the steps at their first sign-in. */
export const LAUNCH = Date.UTC(2026, 9, 9);

export type Place = { id: string; name: string; name_en: string | null; image: string | null; kind: string; top_pick: string | null };
export type Mine = {
  id: string; isBusiness: boolean; name: string; email: string; username: string | null; avatar_url: string | null;
  bio: string | null; interests: string[]; places: Place[]; visibility: string;
  created_at: string | null; seen_at: string | null; completed_at: string | null;
};

const PLACE_COLS = 'id,name,name_en,cover_url,logo_url,kind';
const placeOf = (b: Record<string, unknown>, pick: string | null = null): Place => ({
  id: b.id as string, name: (b.name as string) ?? '', name_en: (b.name_en as string) ?? null,
  image: ((b.cover_url as string) || (b.logo_url as string) || '').trim() || null, kind: (b.kind as string) ?? 'business', top_pick: pick,
});

/** The signed-in resident's profile, or null when nobody is signed in. */
export async function mine(): Promise<Mine | null> {
  const db = sessionDb();
  const { data: { session } } = await db.auth.getSession();
  const uid = session?.user.id;
  if (!uid) return null;
  // A business account is one that owns a business, as the app decides
  // (auth_provider.dart): it has no Urban Profile.
  const [{ data: p, error }, { data: rows }, { data: owned }] = await Promise.all([
    db.from('profiles').select('full_name,avatar_url,bio,interests,profile_visibility,username,created_at,urban_profile_seen_at,urban_profile_completed_at').eq('id', uid).maybeSingle(),
    db.from('profile_places').select(`position,top_pick,businesses(${PLACE_COLS},status)`).eq('profile_id', uid).order('position'),
    db.from('businesses').select('id').eq('owner_id', uid).limit(1),
  ]);
  if (error || !p) throw error ?? new Error('no profile');
  type Row = { top_pick: string | null; businesses: (Record<string, unknown> & { status?: string }) | null };
  const places = ((rows ?? []) as unknown as Row[]).filter((r) => r.businesses?.status === 'active').map((r) => placeOf(r.businesses!, r.top_pick));
  return {
    id: uid, isBusiness: (owned ?? []).length > 0, name: p.full_name ?? '', email: session.user.email ?? '', username: p.username, avatar_url: p.avatar_url,
    bio: p.bio, interests: p.interests ?? [], places, visibility: p.profile_visibility ?? 'private',
    created_at: p.created_at, seen_at: p.urban_profile_seen_at, completed_at: p.urban_profile_completed_at,
  };
}

/** The first step still missing something (1 photo and bio, 2 interests,
 *  3 places), or null when all three are done. */
export function firstIncomplete(m: Mine): 1 | 2 | 3 | null {
  if (!m.avatar_url?.trim() || !m.bio?.trim()) return 1;
  if (m.interests.length < MIN_INTERESTS) return 2;
  if (m.places.length === 0) return 3;
  return null;
}

/** Whether signing in should open the steps, as the app's gate decides: a
 *  resident's account made from the launch on, that has never seen them. */
export function opensSteps(m: Mine): boolean {
  if (m.isBusiness || m.seen_at) return false;
  const made = m.created_at ? Date.parse(m.created_at) : NaN;
  return Number.isFinite(made) && made >= LAUNCH;
}

async function update(patch: Record<string, unknown>) {
  const db = sessionDb();
  const { data: { session } } = await db.auth.getSession();
  if (!session) throw new Error('not signed in');
  const { error } = await db.from('profiles').update(patch).eq('id', session.user.id);
  if (error) throw error;
}

export const markSeen = () => update({ urban_profile_seen_at: new Date().toISOString() });
export const markCompleted = () => update({ urban_profile_completed_at: new Date().toISOString() });
export const saveBio = (bio: string) => update({ bio: bio.trim() || null });
export const saveAvatar = (url: string) => update({ avatar_url: url });
export const saveInterests = (keys: string[]) => update({ interests: keys });
export const setVisible = (on: boolean) => update({ profile_visibility: on ? 'residents' : 'private' });
export const setUsername = (name: string) => update({ username: name.trim().toLowerCase() });

/** A new photo to `avatars/<id>/`, as the app's Edit Profile does; its address. */
export async function uploadPhoto(file: File): Promise<string> {
  const db = sessionDb();
  const { data: { session } } = await db.auth.getSession();
  if (!session) throw new Error('not signed in');
  const ext = (file.name.match(/\.[a-z0-9]+$/i)?.[0] ?? '.jpg').toLowerCase();
  const path = `avatars/${session.user.id}/${Date.now()}${ext}`;
  const { error } = await db.storage.from('media').upload(path, file, { contentType: file.type || 'image/jpeg' });
  if (error) throw error;
  return db.storage.from('media').getPublicUrl(path).data.publicUrl;
}

/** Replaces the favourite places with these, in this order, keeping each one's top pick. */
export async function savePlaces(places: Place[]) {
  const db = sessionDb();
  const { data: { session } } = await db.auth.getSession();
  if (!session) throw new Error('not signed in');
  const uid = session.user.id;
  const del = await db.from('profile_places').delete().eq('profile_id', uid);
  if (del.error) throw del.error;
  if (!places.length) return;
  const { error } = await db.from('profile_places').insert(places.slice(0, MAX_PLACES).map((p, i) => ({ profile_id: uid, business_id: p.id, position: i + 1, top_pick: p.top_pick })));
  if (error) throw error;
}

/** Places matching the words by Hebrew or English name; with none, the
 *  suggestions — recommended and featured places and parks, best reviewed first. */
export async function searchPlaces(query: string): Promise<Place[]> {
  const q = query.trim().replace(/[,()%*]/g, ' ');
  let req = sessionDb().from('businesses').select(PLACE_COLS).eq('status', 'active');
  req = q ? req.or(`name.ilike.%${q}%,name_en.ilike.%${q}%`) : req.or('is_recommended.eq.true,is_featured.eq.true,kind.eq.park');
  const { data } = await (q ? req.order('review_count', { ascending: false }) : req.order('is_recommended', { ascending: false }).order('review_count', { ascending: false })).limit(20);
  return (data ?? []).map((b) => placeOf(b as Record<string, unknown>));
}

export async function usernameAvailable(name: string): Promise<boolean> {
  const { data } = await sessionDb().rpc('username_available', { p_username: name });
  return data === true;
}

export async function suggestUsernames(base: string): Promise<string[]> {
  const { data } = await sessionDb().rpc('suggest_usernames', { p_base: base });
  return (data as string[] | null) ?? [];
}

/** A first username from the name (Latin letters) or the e-mail. */
export function usernameSeed(name: string, email: string): string {
  const latin = name.toLowerCase().replace(/[^a-z0-9]+/g, '.').replace(/^\.+|\.+$/g, '');
  if (latin.length >= 3) return latin;
  const local = email.split('@')[0].toLowerCase().replace(/[^a-z0-9_.]/g, '');
  return local.length >= 3 ? local : 'resident';
}
