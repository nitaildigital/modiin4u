import Link from 'next/link';
import { Send2 } from 'iconsax-react';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { h1For, breadcrumb, href, SITE_NAME } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import { formatDate } from '@/lib/params';
import { communityNews, communitySettings, type CommunityArticle } from '@/lib/data/community';
import { JsonLd } from '@/components/JsonLd';
import { PhoneBar } from '@/components/municipal/BackLink';

/** A card that leads off the site: the client's Facebook group, or his
 *  "share with us" form (CommunityLinkCard). */
function LinkCard({ facebook, title, body, cta, url }: { facebook: boolean; title: string; body: string; cta: string; url: string }) {
  const accent = facebook ? '#1877F2' : '#17A9D0';
  return (
    <div className="flex h-full flex-col items-start rounded-xl border border-line bg-white p-4 desk:p-6">
      <div className="flex items-center gap-3">
        <span className="flex size-10 shrink-0 items-center justify-center rounded-full desk:size-12" style={{ background: accent + '1A' }}>
          {facebook
            ? <span className="block size-[18px] desk:size-[22px]" style={{ background: accent, mask: 'url(/web/news/share_facebook.svg) center / contain no-repeat', WebkitMask: 'url(/web/news/share_facebook.svg) center / contain no-repeat' }} />
            : <Send2 size={22} color={accent} />}
        </span>
        <h2 className="text-base font-semibold text-[#1F1F1F] desk:text-lg">{title}</h2>
      </div>
      <p className="mt-3 text-sm leading-[1.45] text-[#6D6D6D] desk:text-[15px]">{body}</p>
      <a href={url} target="_blank" rel="noopener" className="mt-4 flex h-11 items-center rounded-full px-6 text-[15px] font-medium text-white"
        style={{ background: facebook ? accent : '#123A72' }}>
        {cta}
      </a>
    </div>
  );
}

function NewsCard({ a, lang }: { a: CommunityArticle; lang: Lang }) {
  return (
    <Link href={href(`/news/${a.slug}/`)} className="block w-[250px] shrink-0 desk:w-[300px]">
      {a.featured_image
        ? <img src={a.featured_image} alt="" loading="lazy" className="h-[150px] w-full rounded-xl object-cover desk:h-[180px]" />
        : <span className="block h-[150px] w-full rounded-xl bg-section desk:h-[180px]" />}
      <span dir="auto" className="mt-3 line-clamp-2 text-base font-medium leading-[1.2] text-black">{a.title}</span>
      {a.published_at && (
        <span className="mt-3 flex items-center gap-2 text-sm text-gray-meta">
          <img src="/web/news/meta_date.svg" alt="" width={16} height={16} />
          <time dateTime={a.published_at}>{formatDate(a.published_at, lang, true)}</time>
        </span>
      )}
    </Link>
  );
}

/** Community (web_community_screen.dart; community_screen.dart on the
 *  phone): the city's photograph with the page's title, the client's
 *  Facebook group and his "share with us" form, then his community news —
 *  all three set in the panel, so nothing here is invented and he can change
 *  any of it. [path] is the address it is read at: /community/, or one of
 *  WordPress's (/share-with-us/, /facebookgruop/) with their own H1. */
export async function CommunityPage({ path }: { path: string }) {
  const lang = await getLang();
  const t = tr(lang);
  const [settings, news] = await Promise.all([communitySettings(), communityNews()]);
  const name = t('קהילה', 'Community');
  const h1 = h1For(path, name);
  const intro = t('הקהילה של מודיעין במקום אחד: קבוצת הפייסבוק, הסיפורים שלכם וחדשות מהעיר.',
    "Modi'in's community in one place: our Facebook group, your stories and news from around the city.");

  const cards = [
    settings.facebookUrl && (
      <LinkCard key="fb" facebook url={settings.facebookUrl} title={t('הצטרפו לקבוצת הפייסבוק שלנו', 'Join our Facebook group')}
        body={t('שיחות עם תושבי מודיעין: שאלות, המלצות ועדכונים.', "Talk with Modi'in residents: questions, recommendations and updates.")}
        cta={t('הצטרף עכשיו', 'Join now')} />
    ),
    settings.shareUrl && (
      <LinkCard key="share" facebook={false} url={settings.shareUrl} title={t('שתפו אותנו', 'Share with us')}
        body={t('שמעתם על משהו גדול? הייתם עדים לאירוע מסעיר? יש לכם תמונות או מידע שכולם חייבים לדעת? שלחו לנו – אנחנו נחקור, נאמת ונביא את הסיפור שלכם לקדמת הבמה!',
          'Heard about something big? Witnessed a dramatic event? Have photos or information everyone should know? Send them to us – we will look into it, verify it and bring your story to the front page!')}
        cta={t('שליחת סיפור', 'Send a story')} />
    ),
  ].filter(Boolean);

  return (
    <div className="wrap">
      <JsonLd data={[
        { '@context': 'https://schema.org', '@type': 'WebPage', name: h1, description: intro, url: SITE_URL + href(path), inLanguage: lang },
        breadcrumb([[SITE_NAME, '/'], [h1, path]]),
      ]} />
      <div className="mx-auto max-w-[430px] pb-6 pt-2.5 desk:max-w-none desk:pb-[100px] desk:pt-10">
        <PhoneBar back="/" lang={lang}><span className="text-sm font-semibold text-[#1F1F1F]" aria-hidden>{name}</span></PhoneBar>

        {/* The photograph, darkened towards its foot so the words read. */}
        <div className="relative mt-4 h-[170px] overflow-hidden rounded-2xl desk:mt-0 desk:h-[300px]">
          <img src="/images/community_cover.jpg" alt="" className="absolute inset-0 size-full object-cover" />
          <div className="absolute inset-0 bg-[linear-gradient(to_bottom,rgba(0,0,0,0.05),rgba(0,0,0,0.7))]" />
          <div className="absolute inset-x-4 bottom-4">
            <h1 className="font-nunito text-[22px] font-bold text-white desk:text-[40px]">{h1}</h1>
            <p className="mt-1 text-[13px] leading-[1.3] text-white/90 desk:text-2xl">{intro}</p>
          </div>
        </div>

        {cards.length > 0 && (
          <div className={`mt-4 grid gap-3 desk:mt-8 desk:gap-6 ${cards.length > 1 ? 'desk:grid-cols-2' : ''}`}>{cards}</div>
        )}

        {news && (
          <section className="mt-7 desk:mt-12">
            <div className="flex items-center">
              <h2 className="flex-1 text-base font-semibold text-[#1F1F1F] desk:font-nunito desk:text-[32px] desk:text-midblue">{t('חדשות הקהילה', 'Community news')}</h2>
              {news.articles.length > 0 && (
                <Link href={href(`/new/${news.slug}/`)} className="text-sm text-midblue desk:text-base desk:font-medium">{t('ראה הכל', 'See all')}</Link>
              )}
            </div>
            {news.articles.length === 0 ? (
              <p className="mt-3 text-sm text-[#6D6D6D] desk:mt-6 desk:text-base">{t('אין כתבות להצגה', 'No stories yet')}</p>
            ) : (
              <div className="-mx-[clamp(16px,4.5vw,80px)] mt-3 flex gap-3 overflow-x-auto px-[clamp(16px,4.5vw,80px)] pb-2 desk:mx-0 desk:mt-6 desk:flex-wrap desk:gap-x-6 desk:gap-y-8 desk:overflow-visible desk:px-0">
                {news.articles.map((a) => <NewsCard key={a.id} a={a} lang={lang} />)}
              </div>
            )}
          </section>
        )}
      </div>
    </div>
  );
}
