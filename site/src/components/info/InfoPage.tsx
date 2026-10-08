import type { Metadata } from 'next';
import { Clock, DocumentText, Trash } from 'iconsax-react';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { pageMetadata, h1For, breadcrumb, href, plain, SITE_NAME, SUFFIX } from '@/lib/seo';
import { CONTACT, SITE_URL } from '@/lib/config';
import { contentLang, fallbackTitle, pageTitle, sitePage, sitePageDate } from '@/lib/data/site-pages';
import { JsonLd } from '@/components/JsonLd';
import { BackLink, PhoneBar } from '@/components/municipal/BackLink';
import { SitePageBody } from './SitePageBody';

/** The metadata of an information page: its title and the start of its
 *  text, in the language it is read in. */
export async function infoMetadata(slug: string): Promise<Metadata> {
  const lang = await getLang();
  const page = await sitePage(slug);
  const content = contentLang(page, lang);
  const title = content && page ? pageTitle(page, content) : fallbackTitle(slug, lang);
  const body = content && page ? (content === 'he' ? page.body_he : page.body_en) : '';
  return pageMetadata({ path: `/${slug}/`, title: title + SUFFIX, description: body ? plain(body.replace(/^#+ /gm, ''), 160) : undefined });
}

/** The one way on /delete-account to ask for an account to be deleted: an
 *  e-mail to the office with the subject the page's text tells people to
 *  use, and lines to fill in — the website has no signed-in account to
 *  name (SiteDeletionRequestButton). Shown whether or not the text is
 *  published: the request has to work before the words around it are
 *  final. */
function DeletionRequest({ lang, size }: { lang: Lang; size: number }) {
  const t = tr(lang);
  const body = [
    t('אבקש למחוק את החשבון שלי במודיעין בשבילך.', 'Please delete my Modiin4u account.'),
    '',
    `${t('שם', 'Name')}: `,
    `${t('האימייל שאיתו נרשמתי', 'E-mail I signed up with')}: `,
    `${t('טלפון', 'Phone')}: `,
    '',
    t('(נא לשלוח מכתובת האימייל שאיתה נרשמתם.)', '(Please send this from the e-mail address you signed up with.)'),
  ].join('\r\n');
  const mail = `mailto:${CONTACT.email}?subject=${encodeURIComponent(t('מחיקת חשבון', 'Delete my account'))}&body=${encodeURIComponent(body)}`;
  return (
    <div>
      <a href={mail} className="inline-flex items-center gap-2 rounded-full bg-midblue font-semibold text-white"
        style={{ height: size * 3.125, paddingInline: size * 1.75, fontSize: size }}>
        <Trash size={size * 1.25} color="#fff" />{t('בקשה למחיקת חשבון', 'Request account deletion')}
      </a>
      {/* The address under the button, for someone whose browser has no
          mail app to open. */}
      <p className="mt-2.5 select-text text-[#6D6D6D]" style={{ fontSize: size * 0.875 }}>{t(`או כתבו אל ${CONTACT.email}`, `Or write to ${CONTACT.email}`)}</p>
    </div>
  );
}

/** An information page the client writes in the panel (עמודי מידע)
 *  — web_site_page_screen.dart and site_page_screen.dart. Until he publishes
 *  it, it says the content will be published soon and shows nothing in its
 *  place. Written in one language only, it is shown in that one. */
export async function InfoPage({ slug }: { slug: string }) {
  const lang = await getLang();
  const t = tr(lang);
  const path = `/${slug}/`;
  const page = await sitePage(slug);
  const content = contentLang(page, lang);
  const title = content && page ? pageTitle(page, content) : fallbackTitle(slug, lang);
  const body = content && page ? (content === 'he' ? page.body_he : page.body_en) : '';
  const updated = content && page?.updated_at ? sitePageDate(page.updated_at) : null;
  const tc = tr(content ?? lang);
  const h1 = h1For(path, title);

  return (
    <div className="wrap">
      <JsonLd data={[
        {
          '@context': 'https://schema.org', '@type': 'WebPage', name: h1, url: SITE_URL + href(path), inLanguage: content ?? lang,
          ...(page?.updated_at && content ? { dateModified: page.updated_at } : {}),
        },
        breadcrumb([[SITE_NAME, '/'], [h1, path]]),
      ]} />
      <div className="mx-auto max-w-[430px] pb-6 pt-2.5 desk:max-w-[720px] desk:pb-[100px] desk:pt-14">
        <PhoneBar back="/" lang={lang}><span className="line-clamp-1 text-sm font-semibold text-[#1F1F1F]" aria-hidden>{title}</span></PhoneBar>
        <BackLink href="/" label={t('חזרה', 'Back')} lang={lang} className="hidden desk:block" />
        <div dir={content ? (content === 'he' ? 'rtl' : 'ltr') : undefined} className="mt-5 desk:mt-6">
          <h1 className="font-nunito font-semibold leading-[1.2] text-[#1C1C1E] max-desk:sr-only desk:text-[40px]">{h1}</h1>
          {content ? (
            <>
              {updated && (
                <p className="flex items-center gap-2 text-xs text-[#6D6D6D] desk:mt-3 desk:text-sm">
                  <Clock size={16} color="#6D6D6D" className="hidden desk:block" />
                  {tc(`עודכן לאחרונה: ${updated}`, `Last updated: ${updated}`)}
                </p>
              )}
              <div className="mt-4 text-sm leading-[1.6] desk:mt-10 desk:text-base desk:leading-[1.75]">
                <SitePageBody text={body} />
              </div>
            </>
          ) : (
            <div className="mt-0 flex flex-col items-center rounded-xl border border-line bg-[#F5F7FB] px-[21px] py-[35px] text-center desk:mt-10 desk:px-6 desk:py-10">
              <DocumentText size={32} color="#6D6D6D" />
              <p className="mt-3 text-sm leading-[1.5] text-[#3D3D3D] desk:text-base">{t('תוכן העמוד יפורסם בקרוב', 'The content of this page will be published soon')}</p>
            </div>
          )}
          {slug === 'delete-account' && (
            <div className="mt-7 desk:mt-10">
              <div className="desk:hidden"><DeletionRequest lang={content ?? lang} size={14} /></div>
              <div className="hidden desk:block"><DeletionRequest lang={content ?? lang} size={16} /></div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
