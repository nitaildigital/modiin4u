import Link from 'next/link';
import { Briefcase, Location, MoneySend } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import { href } from '@/lib/seo';
import { ownPhoto } from '@/lib/photos';
import { jobBusiness, jobFlags, jobPlace, jobSalary, jobType, type Job } from '@/lib/data/jobs';

/** A job in the list (the app's job card): the business's logo, the title,
 *  the business, where, the kind of job and the pay, and its marks. */
export function JobCard({ job, lang }: { job: Job; lang: Lang }) {
  const logo = job.businesses?.logo_url;
  const place = jobPlace(job, lang);
  const type = jobType(job, lang);
  const pay = jobSalary(job, lang);
  return (
    <Link href={href(`/jobs/${job.id}/`)} className="flex gap-4 rounded-2xl border border-line bg-white p-4 transition-shadow hover:shadow-[0_4px_16px_rgba(0,0,0,0.06)]">
      <span className="flex size-14 shrink-0 items-center justify-center overflow-hidden rounded-xl bg-[#E7ECF7]">
        {logo ? <img src={ownPhoto(logo, 200) ?? logo} alt="" loading="lazy" className="size-full object-cover" /> : <Briefcase size={26} color="#123A72" />}
      </span>
      <span className="min-w-0 flex-1">
        <span dir="auto" className="block truncate font-nunito text-lg font-semibold text-navy">{job.title}</span>
        {jobBusiness(job, lang) && <span dir="auto" className="mt-0.5 block truncate text-sm text-[#4F4F4F]">{jobBusiness(job, lang)}</span>}
        <span className="mt-2 flex flex-wrap items-center gap-x-4 gap-y-1 text-[13px] text-[#6D6D6D]">
          {place && <span className="flex min-w-0 items-center gap-1"><Location size={14} color="#6D6D6D" className="shrink-0" /><span className="truncate">{place}</span></span>}
          {type && <span className="flex items-center gap-1"><Briefcase size={14} color="#6D6D6D" />{type}</span>}
          {pay && <span className="flex items-center gap-1" dir="auto"><MoneySend size={14} color="#6D6D6D" />{pay}</span>}
        </span>
        {jobFlags(job, lang).length > 0 && (
          <span className="mt-2.5 flex flex-wrap gap-1.5">
            {jobFlags(job, lang).map((f) => <span key={f} className="rounded-full bg-[#F1F6FD] px-2.5 py-1 text-[11px] font-medium text-midblue">{f}</span>)}
          </span>
        )}
      </span>
    </Link>
  );
}
