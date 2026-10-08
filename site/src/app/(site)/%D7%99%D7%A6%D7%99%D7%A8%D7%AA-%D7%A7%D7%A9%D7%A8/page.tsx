import type { Metadata } from 'next';
import { Call, Instagram, Sms, Whatsapp } from 'iconsax-react';
import { getLang, tr } from '@/lib/i18n';
import { pageMetadata, h1For, breadcrumb, href, organization, SITE_NAME } from '@/lib/seo';
import { CONTACT, SITE_URL } from '@/lib/config';
import { JsonLd } from '@/components/JsonLd';

const PATH = '/יצירת-קשר/';

export async function generateMetadata(): Promise<Metadata> {
  return pageMetadata({ path: PATH });
}

/** WordPress's contact page, at its address: the client's contact details as
 *  the footer has always published them (CONTACT). The app sent this
 *  address home; there is no form — a message is a call, an e-mail or a
 *  WhatsApp away. */
export default async function ContactPage() {
  const lang = await getLang();
  const t = tr(lang);
  const h1 = h1For(PATH, t('צור קשר', 'Contact Us'));
  const ways: [React.ReactNode, string, string, string][] = [
    [<Call key="p" size={24} color="#123A72" />, t('טלפון', 'Phone'), CONTACT.phone, `tel:${CONTACT.phone}`],
    [<Sms key="e" size={24} color="#123A72" />, t('אימייל', 'Email'), CONTACT.email, `mailto:${CONTACT.email}`],
    [<Whatsapp key="w" size={24} color="#123A72" />, t('וואטסאפ', 'WhatsApp'), CONTACT.phone, `https://wa.me/${CONTACT.whatsapp}`],
  ];
  const socials: [string, string][] = [['Facebook', CONTACT.facebook], ['Instagram', CONTACT.instagram], ['TikTok', CONTACT.tiktok]];

  return (
    <div className="wrap">
      <JsonLd data={[
        {
          '@context': 'https://schema.org', '@type': 'ContactPage', name: h1, url: SITE_URL + href(PATH),
          mainEntity: {
            ...organization(),
            contactPoint: { '@type': 'ContactPoint', telephone: '+972-58-4770195', email: CONTACT.email, contactType: 'customer service', areaServed: 'IL', availableLanguage: ['Hebrew', 'English'] },
            sameAs: socials.map(([, u]) => u),
          },
        },
        breadcrumb([[SITE_NAME, '/'], [h1, PATH]]),
      ]} />
      <div className="mx-auto max-w-[720px] pb-10 pt-8 desk:pb-[100px] desk:pt-14">
        <h1 className="font-nunito text-[28px] font-semibold leading-[1.2] text-[#1C1C1E] desk:text-[40px]">{h1}</h1>
        <p className="mt-3 text-base text-gray-text">{t('אנחנו כאן לכל שאלה.', 'We are here for any questions.')}</p>
        <ul className="mt-8 grid gap-4 desk:mt-10 desk:grid-cols-3">
          {ways.map(([icon, label, value, link]) => (
            <li key={label}>
              <a href={link} className="flex h-full items-center gap-4 rounded-xl border border-line p-5 hover:border-midblue desk:flex-col desk:items-start">
                <span className="flex size-12 shrink-0 items-center justify-center rounded-full bg-midblue/[0.06]">{icon}</span>
                <span className="min-w-0">
                  <span className="block text-sm font-medium text-gray-text">{label}</span>
                  <span dir="ltr" className="mt-1 block break-all text-base font-semibold text-[#1C1C1E] rtl:text-right">{value}</span>
                </span>
              </a>
            </li>
          ))}
        </ul>
        <h2 className="mt-10 text-base font-semibold text-[#1C1C1E]">{t('הרשתות שלנו', 'Our Socials')}</h2>
        <ul className="mt-4 flex flex-wrap gap-3">
          {socials.map(([name, url]) => (
            <li key={name}>
              <a href={url} target="_blank" rel="noopener" className="flex h-11 items-center gap-2 rounded-full border border-line px-5 text-sm font-medium text-midblue hover:border-midblue">
                {name === 'Instagram' && <Instagram size={18} color="#123A72" />}{name}
              </a>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
