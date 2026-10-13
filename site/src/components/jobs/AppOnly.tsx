import { Mobile } from 'iconsax-react';
import { tr, type Lang } from '@/lib/i18n';
import { storeLinks } from '@/lib/data/steps';
import { AppStores } from './AppStores';

/** Where a notification about something kept in the app leads, opened in a
 *  browser (my apartments, a business's events, deals or applicants): what
 *  it is, that it is in the app — accounts are the app's — and the stores. */
export async function AppOnly({ lang, title, body }: { lang: Lang; title: [string, string]; body: [string, string] }) {
  const t = tr(lang);
  const stores = await storeLinks();
  return (
    <div className="wrap pb-20 pt-10 desk:pt-16">
      <div className="mx-auto flex max-w-[520px] flex-col items-center rounded-[20px] border border-line px-6 py-10 text-center">
        <span className="flex size-16 items-center justify-center rounded-full bg-midblue/[0.08]"><Mobile size={30} color="#123A72" /></span>
        <h1 className="mt-5 font-nunito text-2xl font-semibold text-navy">{t(...title)}</h1>
        <p className="mt-2 text-sm leading-[1.6] text-gray-text">{t(...body)}</p>
        <p className="mt-1 text-sm leading-[1.6] text-gray-text">{t('פתחו את אפליקציית מודיעין בשבילך כדי לראות אותו.', 'Open the Modiin4U app to see it.')}</p>
        <div className="mt-6"><AppStores ios={stores.ios} android={stores.android} /></div>
      </div>
    </div>
  );
}
