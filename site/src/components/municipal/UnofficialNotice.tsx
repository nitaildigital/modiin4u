import { InfoCircle } from 'iconsax-react';
// Only the type from i18n: it reads cookies (next/headers), and the places
// list that shows this runs in the browser.
import type { Lang } from '@/lib/i18n';

/** The municipality's own website, the source the notice links to. */
export const MUNICIPALITY_URL = 'https://www.modiin.muni.il/';

/** That Modiin4u is not the municipality's, and where its information comes
 *  from — the app's UnofficialNotice (unofficial_notice.dart), word for word.
 *  Google Play turned the app down on 19 Oct under its Misleading Claims
 *  policy for want of both; the site's municipal pages say the same. */
export function UnofficialNotice({ lang, className = '' }: { lang: Lang; className?: string }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  return (
    <aside className={`flex items-start gap-3 rounded-xl border border-[#D8E2EF] bg-[#F2F6FB] p-4 ${className}`}>
      <InfoCircle size={20} color="#123A72" className="mt-0.5 shrink-0" />
      <div className="text-start">
        <p className="text-sm font-semibold text-[#1F1F1F]">
          {t('אפליקציה פרטית, לא אפליקציה עירונית רשמית', 'A private app, not an official municipal app')}
        </p>
        <p className="mt-1 text-[13px] leading-[1.5] text-[#4B4B4B]">
          {t(
            'מודיעין בשבילך היא אפליקציה פרטית ועצמאית. היא אינה אפליקציה רשמית של עיריית מודיעין-מכבים-רעות ואינה מייצגת אותה או כל גוף ממשלתי. המידע העירוני כאן מבוסס על מקורות ציבוריים – אתר העירייה, OpenStreetMap ו־Hebcal (זמני שבת). למידע רשמי ומחייב יש לפנות לעירייה.',
            "Modiin4u is an independent, private app. It is not an official app of the Modiin-Maccabim-Re'ut Municipality and does not represent it or any government body. The municipal information here comes from public sources – the municipality's website, OpenStreetMap and Hebcal (Shabbat times). For official, binding information, contact the municipality.",
          )}
        </p>
        <a href={MUNICIPALITY_URL} target="_blank" rel="noopener" className="mt-2 inline-block text-[13px] font-semibold text-midblue underline">
          {t('לאתר הרשמי של העירייה: www.modiin.muni.il', "The municipality's official website: www.modiin.muni.il")}
        </a>
      </div>
    </aside>
  );
}
