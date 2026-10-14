import type { Metadata } from 'next';
import { pageMetadata, wpPage } from '@/lib/seo';
import { shabbatWeek } from '@/lib/data/shabbat';
import { ShabbatPage } from '@/components/municipal/ShabbatPage';

const PATH = '/shabat-times-modiin/';

/** WordPress's title and description with this week's times added, from
 *  Hebcal like the page itself. Google showed the page 57,000 times in
 *  three months (Search Console, 14 Oct) for "כניסת שבת מודיעין" and the
 *  like, and one in a thousand clicked: the snippet never said the time.
 *  The share tags keep WordPress's text, since a shared link outlives the
 *  week. Without Hebcal, WordPress's text alone. */
export async function generateMetadata(): Promise<Metadata> {
  const wp = wpPage(PATH);
  const week = await shabbatWeek();
  if (!wp?.title || !week?.candles || !week.havdalah) return pageMetadata({ path: PATH });
  const times = `כניסת שבת ${week.candles}, צאת שבת ${week.havdalah}`;
  const [first, ...rest] = wp.title.split(' | ');
  const name = week.parasha?.he ?? week.holidays[0]?.he;
  return pageMetadata({
    path: PATH,
    title: [`${first}: ${week.candles}–${week.havdalah}`, ...rest].join(' | '),
    description: `${name ? `השבת (${name}): ` : 'השבת: '}${times}. ${wp.description ?? ''}`.trim(),
    ogTitle: wp.title,
    ogDescription: wp.description,
  });
}

/** WordPress's Shabbat-times page, at its old address: the Shabbat &
 *  Holidays page with WordPress's title, description and H1. */
export default function Page() {
  return <ShabbatPage path={PATH} />;
}
