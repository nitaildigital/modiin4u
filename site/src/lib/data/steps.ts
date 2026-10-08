import { db } from '../supabase';

// A step-group invitation, as the website shows it (join_group_screen.dart):
// the group's name and size, and the store links from the panel's settings.

/** An invite code as the app reads one: upper case, letters and digits. */
export function normalizeInviteCode(raw: string): string {
  return raw.toUpperCase().replace(/[^A-Z0-9]/g, '');
}

export type GroupPreview = { id: string; name: string; member_count: number };

/** The group behind a code, or null when it matches none (mistyped,
 *  replaced, or hidden by the panel). Throws when the read fails. */
export async function groupPreview(code: string): Promise<GroupPreview | null> {
  if (!code) return null;
  const { data, error } = await db.rpc('step_group_preview', { p_code: code });
  if (error) throw error;
  const row = ((data ?? []) as GroupPreview[])[0];
  return row ? { id: row.id, name: row.name ?? '', member_count: Number(row.member_count ?? 0) } : null;
}

/** The app's store links, only where the panel has given an https address
 *  (storeUrl in app_settings_provider.dart). */
export async function storeLinks(): Promise<{ android: string | null; ios: string | null }> {
  const { data } = await db.from('app_settings').select('key,value').in('key', ['store_url_android', 'store_url_ios']);
  const pick = (k: string) => {
    const v = (data ?? []).find((r) => r.key === k)?.value;
    return typeof v === 'string' && v.trim().startsWith('https://') ? v.trim() : null;
  };
  return { android: pick('store_url_android'), ios: pick('store_url_ios') };
}
