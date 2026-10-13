import type { Metadata } from 'next';
import { Briefcase } from 'iconsax-react';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { pageMetadata, breadcrumb, SITE_NAME, SUFFIX } from '@/lib/seo';
import { openJobs } from '@/lib/data/jobs';
import { storeLinks } from '@/lib/data/steps';
import { JsonLd } from '@/components/JsonLd';
import { PhoneBar } from '@/components/municipal/BackLink';
import { JobCard } from '@/components/jobs/JobCard';
import { AppStores } from '@/components/jobs/AppStores';

const PATH = '/jobs/';
const heading = (lang: Lang) => tr(lang)('משרות במודיעין', 'Jobs in Modiin');
const intro = (lang: Lang) => tr(lang)('משרות פתוחות בעסקים בעיר. מגישים מועמדות באפליקציה, או ישירות לעסק.', 'Open jobs at the city\'s businesses. Apply in the app, or straight to the business.');

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getLang();
  return pageMetadata({ path: PATH, title: heading(lang) + SUFFIX, description: intro(lang) });
}

/** /jobs/ — the open jobs (jobs_screen.dart), each to its page. Applying with
 *  the form takes an account, which is the app's; a job's call, WhatsApp and
 *  e-mail ways to apply work from its page. Where a job shared from the app
 *  leads, and a job notification opened in a browser. */
export default async function JobsPage() {
  const lang = await getLang();
  const t = tr(lang);
  const [jobs, stores] = await Promise.all([openJobs(), storeLinks()]);
  return (
    <div className="wrap pb-16 pt-2 desk:pb-[100px] desk:pt-12">
      <JsonLd data={breadcrumb([[SITE_NAME, '/'], [heading(lang), PATH]])} />
      <PhoneBar back="/" lang={lang}><span className="font-rubik text-lg font-bold text-navy" aria-hidden>{heading(lang)}</span></PhoneBar>
      <div className="mx-auto max-w-[960px]">
        <h1 className="font-nunito font-semibold text-midblue max-desk:sr-only desk:text-4xl desk:leading-[1.2]">{heading(lang)}</h1>
        <p className="mt-2 text-sm leading-[1.5] text-gray-text desk:text-base">{intro(lang)}</p>
        {jobs.length === 0 ? (
          <div className="mt-8 flex flex-col items-center rounded-2xl border border-line bg-midblue/[0.03] px-6 py-12 text-center">
            <Briefcase size={44} color="#123A724D" />
            <p className="mt-4 text-base font-medium text-[#1C1C1E]">{t('אין כרגע משרות פתוחות', 'No open jobs right now')}</p>
            <p className="mt-2 max-w-[420px] text-sm text-gray-text">{t('עסקים מפרסמים משרות באפליקציה, ומשרות חדשות מופיעות כאן.', 'Businesses post jobs in the app, and new ones appear here.')}</p>
            <div className="mt-6"><AppStores ios={stores.ios} android={stores.android} /></div>
          </div>
        ) : (
          <ul className="mt-8 grid gap-3 desk:grid-cols-2">
            {jobs.map((j) => <li key={j.id}><JobCard job={j} lang={lang} /></li>)}
          </ul>
        )}
      </div>
    </div>
  );
}
