import { getLang } from '@/lib/i18n';
import { homeNotice } from '@/lib/data/home';
import { Hero } from './Hero';
import { DesktopHome } from './DesktopHome';
import { PhoneHome } from './PhoneHome';

/** The home page's content, both layouts: the hero (with the page's one
 *  H1), then the desktop sections (≥ 1100) or the phone rows. Also what an
 *  old address that showed the home page renders, with its own heading. */
export async function HomeContent({ h1, underBar = false }: { h1: string; underBar?: boolean }) {
  const lang = await getLang();
  const notice = await homeNotice(lang);
  return (
    <>
      <Hero h1={h1} lang={lang} notice={notice} underBar={underBar} />
      <DesktopHome lang={lang} />
      <PhoneHome lang={lang} />
    </>
  );
}
