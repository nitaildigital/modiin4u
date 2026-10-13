import { cache } from 'react';
import { db } from '@/lib/supabase';
import type { Lang } from '@/lib/i18n';

/** A job opening as the site shows it (jobs, 00052 / 00069): the open ones
 *  only — status active and not past expires_at, which is also all the
 *  database lets a visitor read. */
export type Job = {
  id: string; title: string; description: string | null; responsibilities: string | null; requirements: string | null;
  job_type: string | null; experience: string | null; schedule: string | null; location: string | null;
  salary_min: number | null; salary_max: number | null; salary_period: string | null; hours: string | null;
  image_url: string | null; images: string[] | null;
  for_youth: boolean | null; for_students: boolean | null; no_experience: boolean | null; shift_work: boolean | null;
  contact_name: string | null; contact_phone: string | null; contact_whatsapp: string | null; contact_email: string | null;
  apply_by_call: boolean | null; apply_by_whatsapp: boolean | null; apply_by_email: boolean | null; apply_by_form: boolean | null;
  published_at: string | null; expires_at: string | null; created_at: string | null; updated_at: string | null;
  businesses: { id: string; slug: string | null; name: string; name_en: string | null; logo_url: string | null; address: string | null } | null;
  categories: { name: string | null; name_en: string | null } | null;
  neighborhoods: { name: string | null; name_en: string | null } | null;
};

const COLS = 'id,title,description,responsibilities,requirements,job_type,experience,schedule,location,salary_min,salary_max,salary_period,hours,'
  + 'image_url,images,for_youth,for_students,no_experience,shift_work,contact_name,contact_phone,contact_whatsapp,contact_email,'
  + 'apply_by_call,apply_by_whatsapp,apply_by_email,apply_by_form,published_at,expires_at,created_at,updated_at,'
  + 'businesses(id,slug,name,name_en,logo_url,address),categories(name,name_en),neighborhoods(name,name_en)';

const open = () => `expires_at.is.null,expires_at.gt.${new Date().toISOString()}`;

/** The open jobs, newest first (jobs_screen.dart). */
export const openJobs = cache(async (): Promise<Job[]> => {
  const { data } = await db.from('jobs').select(COLS).eq('status', 'active').or(open())
    .order('published_at', { ascending: false, nullsFirst: false }).limit(200);
  return (data ?? []) as unknown as Job[];
});

/** One open job, or null when it is closed, expired or not there. */
export const jobById = cache(async (id: string): Promise<Job | null> => {
  if (!/^[0-9a-f-]{36}$/i.test(id)) return null;
  const { data } = await db.from('jobs').select(COLS).eq('id', id).eq('status', 'active').or(open()).maybeSingle();
  return (data as unknown as Job) ?? null;
});

// The labels of the app's Post a Job form (lib/features/jobs/models/job.dart).
const TYPES: Record<string, [string, string]> = {
  full_time: ['משרה מלאה', 'Full-time'], part_time: ['משרה חלקית', 'Part-time'], shifts: ['משמרות', 'Shifts'],
  temporary: ['זמנית', 'Temporary'], freelance: ['פרילנס', 'Freelance'], internship: ['התמחות', 'Internship'],
};
const EXPERIENCE: Record<string, [string, string]> = {
  none: ['ללא ניסיון', 'No experience'], junior: ['שנת ניסיון ומעלה', '1+ year experience'],
  mid: ['3 שנות ניסיון ומעלה', '3+ years experience'], senior: ['5 שנות ניסיון ומעלה', '5+ years experience'],
};
const SCHEDULES: Record<string, [string, string]> = {
  fixed: ['שעות קבועות', 'Fixed hours'], shifts: ['עבודה במשמרות', 'Shift work'], flexible: ['שעות גמישות', 'Flexible hours'],
};
const PERIODS: Record<string, [string, string]> = { hour: ['לשעה', '/hour'], month: ['לחודש', '/month'], year: ['לשנה', '/year'], project: ['לפרויקט', '/project'] };

const pick = (m: Record<string, [string, string]>, v: string | null, lang: Lang) => (v && m[v] ? m[v][lang === 'he' ? 0 : 1] : null);
export const jobType = (j: Job, lang: Lang) => pick(TYPES, j.job_type, lang);
export const jobExperience = (j: Job, lang: Lang) => pick(EXPERIENCE, j.experience, lang);
export const jobSchedule = (j: Job, lang: Lang) => pick(SCHEDULES, j.schedule, lang);

const shekels = (n: number) => '₪' + Math.round(n).toLocaleString('en-US');
/** "₪38–45 לשעה", "₪9,000 לחודש"; null when no pay was entered. */
export function jobSalary(j: Job, lang: Lang): string | null {
  const lo = j.salary_min, hi = j.salary_max;
  if (lo == null && hi == null) return null;
  const amount = lo != null && hi != null && hi !== lo ? `${shekels(lo)}–${shekels(hi).slice(1)}` : shekels((lo ?? hi)!);
  const per = pick(PERIODS, j.salary_period, lang);
  // The amount kept left to right (an isolate), or Hebrew text reverses it:
  // "45–₪38 לשעה" instead of "₪38–45 לשעה".
  const ltr = `\u2066${amount}\u2069`;
  return per ? (lang === 'he' ? `${ltr} ${per}` : `${ltr}${per}`) : ltr;
}

export const jobBusiness = (j: Job, lang: Lang) =>
  j.businesses ? (lang === 'en' && j.businesses.name_en?.trim()) || j.businesses.name : null;

export function jobPlace(j: Job, lang: Lang): string | null {
  const n = j.neighborhoods ? (lang === 'en' && j.neighborhoods.name_en) || j.neighborhoods.name : null;
  return [j.location?.trim(), n].filter(Boolean).join(', ') || j.businesses?.address || null;
}

/** The marks the app shows on a card: for youth, students, no experience, shifts. */
export function jobFlags(j: Job, lang: Lang): string[] {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  return [
    j.for_youth && t('מתאים לנוער', 'Youth jobs'),
    j.for_students && t('מתאים לסטודנטים', 'Students'),
    j.no_experience && t('ללא ניסיון', 'No experience'),
    j.shift_work && t('עבודה במשמרות', 'Shift work'),
  ].filter((x): x is string => !!x);
}
