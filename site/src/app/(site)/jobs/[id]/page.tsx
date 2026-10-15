import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { Briefcase, Call, Clock, Location, MoneySend, Sms, Teacher, Timer1 } from 'iconsax-react';
import { getLang, tr } from '@/lib/i18n';
import { slugParam } from '@/lib/params';
import { pageMetadata, plain, breadcrumb, href, SITE_NAME, SUFFIX } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import { telNumber, waNumber } from '@/lib/contact';
import { jobById, jobBusiness, jobExperience, jobFlags, jobPlace, jobSalary, jobSchedule, jobType, type Job } from '@/lib/data/jobs';
import { storeLinks } from '@/lib/data/steps';
import { ownPhoto } from '@/lib/photos';
import { JsonLd } from '@/components/JsonLd';
import { BackLink, PhoneBar } from '@/components/municipal/BackLink';
import { AppStores } from '@/components/jobs/AppStores';

type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const id = slugParam((await params).id);
  const [lang, j] = await Promise.all([getLang(), jobById(id)]);
  if (!j) return {};
  const biz = jobBusiness(j, lang);
  return pageMetadata({
    path: `/jobs/${id}/`,
    title: (biz ? `${j.title} - ${biz}` : j.title) + SUFFIX,
    description: plain(j.description || j.responsibilities || j.requirements, 160) || undefined,
    image: j.image_url || j.images?.[0] || j.businesses?.logo_url,
  });
}

// Google's employment types, for what the form's kinds mean.
const EMPLOYMENT: Record<string, string> = { full_time: 'FULL_TIME', part_time: 'PART_TIME', temporary: 'TEMPORARY', freelance: 'CONTRACTOR', internship: 'INTERN' };
const UNIT: Record<string, string> = { hour: 'HOUR', month: 'MONTH', year: 'YEAR' };

/** The job for Google's job listings (JobPosting): only what the business
 *  entered — no pay, no closing date, where it gave none. */
function jobPosting(j: Job, url: string) {
  const text = plain([j.description, j.responsibilities, j.requirements].filter(Boolean).join('\n\n'));
  const pay = j.salary_min ?? j.salary_max;
  return {
    '@context': 'https://schema.org', '@type': 'JobPosting', title: j.title, url,
    description: text || j.title,
    datePosted: (j.published_at || j.created_at || '').slice(0, 10) || undefined,
    ...(j.expires_at ? { validThrough: j.expires_at } : {}),
    ...(j.job_type && EMPLOYMENT[j.job_type] ? { employmentType: EMPLOYMENT[j.job_type] } : {}),
    ...(j.businesses ? {
      hiringOrganization: {
        '@type': 'Organization', name: j.businesses.name,
        sameAs: SITE_URL + href(`/business/${j.businesses.slug || j.businesses.id}/`),
        ...(j.businesses.logo_url ? { logo: j.businesses.logo_url } : {}),
      },
    } : {}),
    jobLocation: {
      '@type': 'Place',
      address: {
        '@type': 'PostalAddress', addressLocality: 'Modiin', addressCountry: 'IL',
        ...((j.location || j.businesses?.address) ? { streetAddress: j.location || j.businesses?.address } : {}),
      },
    },
    ...(pay != null && j.salary_period && UNIT[j.salary_period] ? {
      baseSalary: {
        '@type': 'MonetaryAmount', currency: 'ILS',
        value: {
          '@type': 'QuantitativeValue', unitText: UNIT[j.salary_period],
          ...(j.salary_min != null && j.salary_max != null ? { minValue: j.salary_min, maxValue: j.salary_max } : { value: pay }),
        },
      },
    } : {}),
  };
}

/** /jobs/<id>/ — one job (job_detail_screen.dart). The ways to apply the
 *  business turned on: a call, WhatsApp and e-mail work from here; the form
 *  (with a CV) is the app's, where the applicant has an account. */
export default async function JobPage({ params }: Props) {
  const id = slugParam((await params).id);
  const [lang, j, stores] = await Promise.all([getLang(), jobById(id), storeLinks()]);
  if (!j) notFound();
  const t = tr(lang);
  const path = `/jobs/${id}/`;
  const biz = jobBusiness(j, lang);
  const facts: [React.ReactNode, string][] = ([
    [<Location key="l" size={18} color="#123A72" />, jobPlace(j, lang)],
    [<Briefcase key="b" size={18} color="#123A72" />, jobType(j, lang)],
    [<MoneySend key="m" size={18} color="#123A72" />, jobSalary(j, lang)],
    [<Teacher key="t" size={18} color="#123A72" />, jobExperience(j, lang)],
    [<Timer1 key="s" size={18} color="#123A72" />, jobSchedule(j, lang)],
    [<Clock key="h" size={18} color="#123A72" />, j.hours?.trim() || null],
  ] as [React.ReactNode, string | null][]).filter((f): f is [React.ReactNode, string] => !!f[1]);
  const sections: [string, string | null][] = [
    [t('על המשרה', 'About the job'), j.description],
    [t('תחומי אחריות', 'Responsibilities'), j.responsibilities],
    [t('דרישות', 'Requirements'), j.requirements],
  ];
  const phone = telNumber(j.contact_phone);
  const whatsapp = waNumber(j.contact_whatsapp || j.contact_phone);
  const email = j.contact_email?.trim();
  const direct: [React.ReactNode, string, string][] = [
    ...(j.apply_by_call && phone ? [[<Call key="c" size={18} color="currentColor" />, t('התקשרו', 'Call'), `tel:${phone}`] as [React.ReactNode, string, string]] : []),
    ...(j.apply_by_whatsapp && whatsapp ? [[<span key="w" aria-hidden>💬</span>, 'WhatsApp', `https://wa.me/${whatsapp}?text=${encodeURIComponent(t(`שלום, אני פונה לגבי המשרה ${j.title}`, `Hello, I'm writing about the job ${j.title}`))}`] as [React.ReactNode, string, string]] : []),
    ...(j.apply_by_email && email ? [[<Sms key="e" size={18} color="currentColor" />, t('אימייל', 'E-mail'), `mailto:${email}?subject=${encodeURIComponent(j.title)}`] as [React.ReactNode, string, string]] : []),
  ];
  const image = j.image_url || j.images?.[0];
  return (
    <div className="wrap pb-16 pt-2 desk:pb-[100px] desk:pt-12">
      <JsonLd data={[jobPosting(j, SITE_URL + href(path)), breadcrumb([[SITE_NAME, '/'], [t('משרות במודיעין', 'Jobs in Modiin'), '/jobs/'], [j.title, path]])]} />
      <PhoneBar back="/jobs/" lang={lang}><span className="font-rubik text-lg font-bold text-navy" aria-hidden>{t('משרה', 'Job')}</span></PhoneBar>
      <div className="mx-auto max-w-[960px]">
        <BackLink href="/jobs/" label={t('כל המשרות', 'All jobs')} lang={lang} className="hidden desk:block" />
        <div className="mt-2 flex items-start gap-4 desk:mt-6">
          <span className="flex size-16 shrink-0 items-center justify-center overflow-hidden rounded-2xl bg-[#E7ECF7]">
            {j.businesses?.logo_url ? <img src={ownPhoto(j.businesses.logo_url, 200) ?? j.businesses.logo_url} alt="" className="size-full object-cover" /> : <Briefcase size={30} color="#123A72" />}
          </span>
          <span className="min-w-0">
            <h1 dir="auto" className="font-nunito text-2xl font-semibold leading-tight text-navy desk:text-4xl">{j.title}</h1>
            {biz && j.businesses && (
              <Link href={href(`/business/${j.businesses.slug || j.businesses.id}/`)} dir="auto" className="mt-1.5 inline-block text-base font-medium text-midblue hover:underline">{biz}</Link>
            )}
          </span>
        </div>
        {facts.length > 0 && (
          <ul className="mt-6 grid gap-3 rounded-2xl border border-line p-4 desk:grid-cols-3">
            {facts.map(([icon, text], i) => <li key={i} className="flex items-center gap-2.5 text-sm text-[#3D3D3D]" dir="auto">{icon}<span>{text}</span></li>)}
          </ul>
        )}
        {jobFlags(j, lang).length > 0 && (
          <div className="mt-4 flex flex-wrap gap-2">
            {jobFlags(j, lang).map((f) => <span key={f} className="rounded-full bg-[#F1F6FD] px-3 py-1.5 text-xs font-medium text-midblue">{f}</span>)}
          </div>
        )}
        <div className="mt-8 grid gap-8 desk:grid-cols-[1fr_320px]">
          <div className="min-w-0">
            {image && <img src={ownPhoto(image, 1200) ?? image} alt={j.title} className="mb-6 w-full rounded-2xl object-cover" />}
            {sections.filter(([, body]) => body?.trim()).map(([title, body]) => (
              <section key={title} className="mb-6">
                <h2 className="font-nunito text-xl font-semibold text-navy">{title}</h2>
                <p dir="auto" className="mt-2 whitespace-pre-line text-base leading-[1.7] text-[#3D3D3D]">{plain(body)}</p>
              </section>
            ))}
          </div>
          <aside className="h-fit rounded-2xl border border-line p-5">
            <h2 className="font-nunito text-lg font-semibold text-navy">{t('הגשת מועמדות', 'Apply')}</h2>
            {j.contact_name && <p className="mt-1 text-sm text-gray-text" dir="auto">{t('איש קשר: ', 'Contact: ')}{j.contact_name}</p>}
            {direct.length > 0 && (
              <div className="mt-4 flex flex-col gap-2.5">
                {direct.map(([icon, label, link]) => (
                  <a key={label} href={link} className="flex h-11 items-center justify-center gap-2 rounded-full bg-midblue text-sm font-medium text-white hover:bg-midblue/90">{icon}{label}</a>
                ))}
              </div>
            )}
            {(j.apply_by_form || direct.length === 0) && (
              <div className={direct.length > 0 ? 'mt-5 border-t border-line pt-5' : 'mt-4'}>
                <p className="text-sm text-[#3D3D3D]">{t('הגשת מועמדות עם טופס וקורות חיים נעשית באפליקציה:', 'Applying with the form and a CV is done in the app:')}</p>
                <div className="mt-4"><AppStores ios={stores.ios} android={stores.android} /></div>
              </div>
            )}
          </aside>
        </div>
      </div>
    </div>
  );
}
