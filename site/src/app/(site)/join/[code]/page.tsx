import type { Metadata } from 'next';
import { InfoCircle, People } from 'iconsax-react';
import { getLang, tr } from '@/lib/i18n';
import { slugParam } from '@/lib/params';
import { pageMetadata, breadcrumb, SITE_NAME, SUFFIX } from '@/lib/seo';
import { groupPreview, normalizeInviteCode, storeLinks, type GroupPreview } from '@/lib/data/steps';
import { JsonLd } from '@/components/JsonLd';
import { PhoneBar } from '@/components/municipal/BackLink';

type Props = { params: Promise<{ code: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const code = normalizeInviteCode(slugParam((await params).code));
  const lang = await getLang();
  // An invitation is a private link, not a page for search engines.
  return pageMetadata({ path: `/join/${code}/`, title: tr(lang)('הזמנה לקבוצת הליכה', 'Walking group invitation') + SUFFIX, noindex: true });
}

/** A step-group invitation, as a browser shows it (join_group_screen.dart):
 *  the group's name and size, what joining means, and the way into the app
 *  — the website has no accounts, so nobody joins from it. The store links
 *  are the panel's, shown once it has them. */
export default async function JoinPage({ params }: Props) {
  const code = normalizeInviteCode(slugParam((await params).code));
  const lang = await getLang();
  const t = tr(lang);
  let group: GroupPreview | null = null;
  let failed = false;
  try { group = await groupPreview(code); } catch { failed = true; }
  const stores = group ? await storeLinks() : { android: null, ios: null };
  const title = t('הזמנה לקבוצת הליכה', 'Walking group invitation');

  const message = (text: string, retry: boolean) => (
    <div className="flex flex-col items-center py-4 text-center">
      <InfoCircle size={32} color="#6D6D6D" />
      <p className="mt-3 text-sm text-[#3D3D3D]">{text}</p>
      {retry && <a href={`/join/${code}/`} className="mt-3 px-3 py-2 text-sm text-[#6D6D6D]">{t('נסו שוב', 'Try again')}</a>}
    </div>
  );

  return (
    <div className="wrap">
      <JsonLd data={breadcrumb([[SITE_NAME, '/'], [title, `/join/${code}/`]])} />
      <PhoneBar back="/" lang={lang}><span aria-hidden /></PhoneBar>
      <div className="mx-auto max-w-[430px] pb-8 pt-6 desk:max-w-[460px] desk:pb-[120px] desk:pt-[72px]">
        <div className="rounded-[20px] border border-line bg-white px-5 pb-5 pt-7">
          {failed ? message(t('משהו השתבש', 'Something went wrong'), true)
            : !group ? message(t('ההזמנה הזו כבר לא בתוקף. בקשו קישור חדש.', 'This invitation is no longer valid. Ask for a new link.'), false)
            : (
              <div className="flex flex-col items-center text-center">
                <span className="flex size-16 items-center justify-center rounded-[20px] bg-[#E7ECF7]"><People size={30} color="#123A72" /></span>
                <p className="mt-4 text-[13px] font-medium text-[#6D6D6D]">{title}</p>
                <h1 dir="auto" className="mt-1.5 font-nunito text-2xl font-bold text-navy">{group.name}</h1>
                <p className="mt-1 text-sm text-[#6D6D6D]">
                  {group.member_count === 1 ? t('חבר אחד', '1 member') : t(`${group.member_count} חברים`, `${group.member_count} members`)}
                </p>
                <p className="mt-5 flex items-start gap-2 rounded-xl bg-[#F1F6FD] p-3 text-start text-[13px] text-[#3D3D3D]">
                  <InfoCircle size={18} color="#123A72" className="shrink-0" />
                  {t('חברי הקבוצה רואים את מספר הצעדים היומי זה של זה. אפשר לצאת בכל עת.', "Members of the group see each other's daily steps. You can leave at any time.")}
                </p>
                {/* The app's own scheme, which both platforms route to the
                    invitation. */}
                <a href={`il.co.modiin4u://app/join/${code}`} className="mt-5 flex h-12 w-full items-center justify-center rounded-xl bg-midblue text-[15px] font-semibold text-white">
                  {t('פתיחה באפליקציה', 'Open in the App')}
                </a>
                <p className="mt-3.5 text-[13px] text-[#6D6D6D]">
                  {t(`יש לכם את אפליקציית Modiin4U? פתחו בה את ההזמנה, או הזינו את הקוד ${code} במונה הצעדים ← קבוצות ← הצטרפות עם קוד.`,
                    `Have the Modiin4U app? Open this invitation in it, or enter the code ${code} in Step Counter → Groups → Join with Code.`)}
                </p>
                {(stores.android || stores.ios) && (
                  <>
                    <p className="mt-3.5 text-[13px] text-[#3D3D3D]">{t('אין לכם את האפליקציה?', "Don't have the app?")}</p>
                    <p className="flex justify-center gap-2">
                      {stores.android && <a href={stores.android} target="_blank" rel="noopener" className="px-3 py-2 text-sm text-[#6D6D6D]">Google Play</a>}
                      {stores.ios && <a href={stores.ios} target="_blank" rel="noopener" className="px-3 py-2 text-sm text-[#6D6D6D]">App Store</a>}
                    </p>
                  </>
                )}
              </div>
            )}
          {!group && <h1 className="sr-only">{title}</h1>}
        </div>
      </div>
    </div>
  );
}
