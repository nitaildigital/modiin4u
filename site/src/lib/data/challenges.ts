import { db } from '../supabase';

/** The competition running now (activeChallengeProvider): switched on in
 *  the panel, started, not yet over — the newest if several. */
export type Challenge = {
  id: string; name: string | null; description: string | null; goal: number | null;
  prize: string | null; prize_en: string | null; start_at: string; end_at: string;
};

export async function activeChallenge(): Promise<Challenge | null> {
  // To the minute, so the cached read is reused for a minute rather than
  // made afresh for every view (the exact time made every key new).
  const now = new Date(Math.floor(Date.now() / 60_000) * 60_000).toISOString();
  const { data } = await db.from('challenges').select('id,name,description,goal,prize,prize_en,start_at,end_at')
    .eq('is_active', true).lte('start_at', now).gte('end_at', now).order('start_at', { ascending: false }).limit(1);
  return ((data ?? [])[0] as Challenge | undefined) ?? null;
}
