import { db } from '../supabase';

/** The competition running now (activeChallengeProvider): switched on in
 *  the panel, started, not yet over — the newest if several. */
export type Challenge = {
  id: string; name: string | null; description: string | null; goal: number | null;
  prize: string | null; prize_en: string | null; start_at: string; end_at: string;
};

export async function activeChallenge(): Promise<Challenge | null> {
  const now = new Date().toISOString();
  const { data } = await db.from('challenges').select('id,name,description,goal,prize,prize_en,start_at,end_at')
    .eq('is_active', true).lte('start_at', now).gte('end_at', now).order('start_at', { ascending: false }).limit(1);
  return ((data ?? [])[0] as Challenge | undefined) ?? null;
}
