import { cookies } from 'next/headers';

export type Lang = 'he' | 'en';

/** The site is Hebrew, as WordPress was and as search engines read it.
 *  English is a reader's choice, kept in a cookie by the header's switch. */
export async function getLang(): Promise<Lang> {
  const c = (await cookies()).get('lang')?.value;
  return c === 'en' ? 'en' : 'he';
}

/** The text in the page's language. */
export function tr(lang: Lang) {
  return (he: string, en: string) => (lang === 'he' ? he : en);
}
