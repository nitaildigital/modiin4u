import Link from 'next/link';
import { getLang, tr } from '@/lib/i18n';

/** What a reader sees where a page has nothing to show (PageNotFound in
 *  slug_routes.dart, and the "not listed" notices of the business, deal and
 *  event pages): a line saying so, why, and the way back — in the reader's
 *  language, not Next's English "404". Next answers these with status 404
 *  and noindex on its own. */
export async function NotFoundView({ title, body, back }: {
  title?: [string, string]; body?: [string, string]; back?: [string, string, string];
}) {
  const t = tr(await getLang());
  const [label, to] = back ? [t(back[0], back[1]), back[2]] : [t('לדף הבית', 'Home'), '/'];
  return (
    <div className="wrap flex flex-col items-center py-24 text-center desk:py-36">
      <p className="font-nunito text-[22px] font-semibold text-navy desk:text-[28px]">
        {title ? t(...title) : t('הדף לא נמצא', 'Page not found')}
      </p>
      {body && <p className="mt-3 max-w-[460px] text-sm leading-[1.5] text-gray-text desk:text-base">{t(...body)}</p>}
      <Link href={to} className="mt-7 flex h-12 items-center rounded-full bg-midblue px-7 text-base font-medium text-white hover:bg-midblue/90">
        {label}
      </Link>
    </div>
  );
}
