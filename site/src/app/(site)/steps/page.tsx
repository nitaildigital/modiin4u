import type { Metadata } from 'next';
import { Award, Calendar, Mobile } from 'iconsax-react';
import { getLang, tr } from '@/lib/i18n';
import { pageMetadata, SUFFIX } from '@/lib/seo';
import { formatDate } from '@/lib/params';
import { banners } from '@/lib/data/banners';
import { activeChallenge } from '@/lib/data/challenges';
import { storeLinks } from '@/lib/data/steps';
import { BannerImage } from '@/components/ui/Banner';

export async function generateMetadata(): Promise<Metadata> {
  // A page of the app's, for the notifications that lead here.
  return pageMetadata({ path: '/steps/', title: 'מד צעדים' + SUFFIX, noindex: true });
}

const thousands = (n: number) => String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ',');

/** /steps/ — the step counter as a browser sees it (web_steps_screen.dart):
 *  the panel's banners for the section and the competition running now,
 *  where a "new challenge" or "winner" notification leads. The counting,
 *  the groups and the leaderboards need the phone's sensor and an account,
 *  so they are the app's; the page says so, with the stores' links. */
export default async function StepsPage() {
  const lang = await getLang();
  const t = tr(lang);
  const [top, inline, challenge, stores] = await Promise.all([banners('STEPS_TOP'), banners('STEPS_INLINE'), activeChallenge(), storeLinks()]);
  const prize = challenge ? (lang === 'en' ? (challenge.prize_en?.trim() || challenge.prize?.trim()) : (challenge.prize?.trim() || challenge.prize_en?.trim())) : null;
  return (
    <div className="wrap pb-20 pt-6 desk:pt-12">
      <div className="mx-auto max-w-[960px]">
        <h1 className="font-nunito text-2xl font-semibold text-black desk:text-[40px]">{t('מד צעדים', 'Step Counter')}</h1>
        <p className="mt-2 text-sm text-gray-text desk:text-base">{t('כל צעד עושה את מודיעין טובה יותר', 'Every step makes Modiin better')}</p>

        {top.length > 0 && (
          <div className="mt-8 grid gap-4 desk:grid-cols-3">
            {top.slice(0, 3).map((b) => <div key={b.id} className="[&_img]:w-full [&_img]:rounded-xl"><BannerImage banner={b} /></div>)}
          </div>
        )}

        {challenge && (
          <section className="mt-8 rounded-2xl bg-[linear-gradient(135deg,#0058B5,#010A36)] p-6 text-white desk:p-8">
            <p className="text-xs font-semibold tracking-wide text-gold">{t('אתגר חודשי במודיעין', 'MODIIN MONTHLY CHALLENGE')}</p>
            {challenge.name && <h2 className="mt-2 font-nunito text-2xl font-semibold desk:text-3xl">{challenge.name}</h2>}
            {challenge.description && <p className="mt-3 whitespace-pre-line text-sm leading-[1.6] text-white/85 desk:text-base">{challenge.description}</p>}
            <div className="mt-5 flex flex-wrap gap-x-8 gap-y-3 text-sm">
              {challenge.goal != null && challenge.goal > 0 && (
                <span className="flex items-center gap-2"><Award size={18} color="#FAC775" />{t(`יעד: ${thousands(challenge.goal)} צעדים`, `Goal: ${thousands(challenge.goal)} steps`)}</span>
              )}
              <span className="flex items-center gap-2"><Calendar size={18} color="#FAC775" />{t(`עד ${formatDate(challenge.end_at, lang)}`, `Until ${formatDate(challenge.end_at, lang)}`)}</span>
            </div>
            {prize && <p className="mt-4 rounded-xl bg-white/10 px-4 py-3 text-sm">🏆 {t('הפרס: ', 'Prize: ')}{prize}</p>}
          </section>
        )}

        {inline[0] && <div className="mt-8 [&_img]:w-full [&_img]:rounded-xl"><BannerImage banner={inline[0]} /></div>}

        <section className="mt-8 flex flex-col items-center rounded-2xl border border-line px-6 py-10 text-center">
          <span className="flex size-16 items-center justify-center rounded-full bg-surface"><Mobile size={30} color="#123A72" /></span>
          <p className="mt-4 font-nunito text-xl font-semibold text-navy">{t('מד הצעדים נמצא באפליקציה', 'The step counter is in the app')}</p>
          <p className="mt-2 max-w-[460px] text-sm text-gray-text">
            {t('ספירת הצעדים, הקבוצות והטבלאות נמצאים באפליקציית מודיעין בשבילך.', 'Counting your steps, the groups and the leaderboards are in the Modiin4u app.')}
          </p>
          {(stores.ios || stores.android) && (
            <div className="mt-6 flex gap-3">
              {stores.ios && <a href={stores.ios} className="rounded-full bg-midblue px-6 py-3 text-sm font-medium text-white">App Store</a>}
              {stores.android && <a href={stores.android} className="rounded-full bg-midblue px-6 py-3 text-sm font-medium text-white">Google Play</a>}
            </div>
          )}
        </section>
      </div>
    </div>
  );
}
