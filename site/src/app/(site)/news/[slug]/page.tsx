import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { ArrowLeft, Calendar, Eye } from 'iconsax-react';
import { getLang, tr } from '@/lib/i18n';
import { slugParam, formatDate, formatTime } from '@/lib/params';
import { pageMetadata, h1For, plain, organization, breadcrumb, href, SITE_NAME, SUFFIX } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import { articleBySlug, articleComments, categoriesOf, categoryName, relatedArticles } from '@/lib/data/articles';
import { banners } from '@/lib/data/banners';
import { JsonLd } from '@/components/JsonLd';
import { BannerImage } from '@/components/ui/Banner';
import { ShareBar } from '@/components/ui/ShareBar';
import { ArticleView } from '@/components/news/ArticleView';
import { ownPhoto, ownPhotoSet } from '@/lib/photos';

type Props = { params: Promise<{ slug: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const slug = slugParam((await params).slug);
  const a = await articleBySlug(slug);
  if (!a) return {};
  return pageMetadata({
    path: `/news/${slug}/`,
    title: a.seo_title || (a.title + SUFFIX),
    description: a.meta_description || plain(a.excerpt || a.body, 160),
    image: a.og_image || a.featured_image,
    type: 'article',
    noindex: !!a.noindex,
    canonical: a.canonical_url,
    publishedTime: a.published_at,
    modifiedTime: a.updated_at,
    ogTitle: a.og_title,
    ogDescription: a.og_description,
    keywords: a.meta_keywords,
  });
}

/** An article (web_article_screen.dart): the picture beside a grey card with
 *  the category, the headline and the date; under them the share bar and the
 *  story, and the related news and a banner in the side column. */
export default async function ArticlePage({ params }: Props) {
  const slug = slugParam((await params).slug);
  const a = await articleBySlug(slug);
  if (!a) notFound();
  const lang = await getLang();
  const t = tr(lang);
  const path = `/news/${slug}/`;
  const [cats, comments, side, inline] = await Promise.all([categoriesOf('article', a.id), articleComments(a.id), banners('NEWS_SIDEBAR'), banners('ARTICLE_INLINE')]);
  const related = await relatedArticles(a.id, cats.map((c) => c.id), 4);
  const cat = cats[0];
  const image = a.featured_image || a.og_image;

  return (
    <article className="wrap py-8 desk:py-15">
      <ArticleView id={a.id} />
      <JsonLd data={[
        {
          '@context': 'https://schema.org', '@type': 'NewsArticle', headline: a.title.slice(0, 110),
          mainEntityOfPage: SITE_URL + href(path), publisher: organization(),
          // Google asks an article for its author: the byline where the
          // panel has one, else the site that publishes it — no name is
          // made up.
          author: a.credit?.trim() ? { '@type': 'Person', name: a.credit.trim() } : organization(),
          ...(a.published_at ? { datePublished: a.published_at } : {}),
          ...(a.updated_at ? { dateModified: a.updated_at } : {}),
          ...(image ? { image: [image] } : {}),
        },
        breadcrumb([[SITE_NAME, '/'], ['חדשות', '/news/'], [a.title, path]]),
      ]} />

      {/* The picture and the headline card. On a phone it is drawn as the
          app's article page (article_screen.dart), as the client asked (23
          Oct): the photo across the screen with the back button on it, the
          category and the views on one line, the headline, the date and a
          rule. The desktop keeps the card. One heading serves both, so the
          page still has a single H1. */}
      <div className="grid desk:grid-cols-2 desk:items-center desk:overflow-hidden desk:rounded-2xl">
        {/* What a phone paints first, so asked for at once and at the size it
            is drawn: the original here was up to a megabyte. A phone takes
            the 800 px copy — the 1200 one, all it was offered before, took
            PageSpeed's phone 6.8 s to show (15 Oct). The share tags and the
            structured data keep the original, which Google wants large. */}
        {image && (
          <div className="relative -mx-[clamp(16px,4.5vw,80px)] -mt-8 desk:m-0">
            <img src={ownPhoto(image, 1200) ?? image} srcSet={ownPhotoSet(image, [800, 1200, 1600])}
              sizes="(min-width: 1100px) 50vw, 100vw" alt={a.title} fetchPriority="high"
              className="h-[260px] w-full object-cover desk:h-auto desk:max-h-[440px]" />
            <Link href={href('/news/')} aria-label={t('חזרה לחדשות', 'Back to news')}
              className="absolute start-4 top-4 flex size-11 items-center justify-center rounded-full bg-white text-ink shadow-[0_2px_8px_rgba(0,0,0,0.15)] desk:hidden">
              <ArrowLeft size={22} color="currentColor" className="rtl:-scale-x-100" />
            </Link>
          </div>
        )}
        <div className="pt-5 desk:flex desk:min-h-[436px] desk:flex-col desk:justify-center desk:rounded-2xl desk:bg-section desk:p-10">
          <div className="mb-5 flex items-center gap-3">
            {cat && (
              <Link href={href(`/new/${cat.slug}/`)} className="inline-block w-fit rounded-md bg-turquoise px-3 py-2 text-sm font-semibold text-white">
                {categoryName(cat, lang)}
              </Link>
            )}
            <span className="ms-auto flex items-center gap-1.5 text-base text-ink desk:hidden" aria-label={t('צפיות', 'Views')}>
              <Eye size={22} color="currentColor" />{(a.view_count ?? 0).toLocaleString()}
            </span>
          </div>
          <h1 className="text-[26px] font-bold leading-snug text-ink desk:text-[34px] desk:font-medium">{h1For(path, a.title)}</h1>
          {a.subtitle && <p className="mt-3 text-base text-gray-text">{a.subtitle}</p>}
          {(a.published_at || a.credit?.trim()) && (
            <p className="mt-5 flex flex-wrap items-center gap-x-8 gap-y-2 text-base text-gray-meta desk:mt-6">
              {a.published_at && (
                <span className="flex items-center gap-2">
                  <Calendar size={18} color="currentColor" />
                  {/* The app's "22 באוקטובר 2026 | 16:53" on a phone. */}
                  <time dateTime={a.published_at} className="desk:hidden">{formatDate(a.published_at, lang)} | {formatTime(a.published_at, lang)}</time>
                  <time dateTime={a.published_at} className="hidden desk:inline">{formatDate(a.published_at, lang, true)}</time>
                </span>
              )}
              {a.credit?.trim() && (
                <span className="flex items-center gap-2"><img src="/web/news/meta_author.svg" alt="" className="size-[18px]" />{a.credit.trim()}</span>
              )}
            </p>
          )}
          <hr className="mt-5 border-line desk:hidden" />
        </div>
      </div>

      <div className="mt-6 grid gap-12 desk:mt-8 desk:grid-cols-[1fr_426px] desk:gap-[150px]">
        <div className="min-w-0">
          <div className="hidden desk:block"><ShareBar url={SITE_URL + href(path)} title={a.title} lang={lang} views={a.view_count ?? 0} shares={a.share_count ?? 0} /></div>
          {/* The page's one H1 is the headline above: a heading the story's own
              text opens with an h1 is set as an h2. */}
          <div className="prose-site desk:mt-8" dangerouslySetInnerHTML={{ __html: storyPhotos((a.body ?? '').replace(/<(\/?)h1(\s|>)/gi, '<$1h2$2')) }} />
          {/* On a phone the share comes after the story, where the app has it. */}
          <div className="mt-8 desk:hidden"><ShareBar url={SITE_URL + href(path)} title={a.title} lang={lang} views={a.view_count ?? 0} shares={a.share_count ?? 0} /></div>
          {/* The campaign booked under the story; nothing when none is. */}
          {inline[0] && <div className="mt-14 max-w-[796px]"><BannerImage banner={inline[0]} /></div>}

          {comments.length > 0 && (
            <section className="mt-12 border-t border-line pt-8">
              <h2 className="mb-5 text-xl font-semibold text-midblue">{t('תגובות', 'Comments')} ({comments.length})</h2>
              <ul className="flex flex-col gap-5">
                {comments.filter((c) => !c.parent_id).map((c) => (
                  <li key={c.id} className="rounded-xl bg-section p-4">
                    <p className="text-sm font-semibold">{c.author_name || t('תושב/ת', 'Resident')} · <span className="font-normal text-gray-meta">{formatDate(c.created_at, lang)}</span></p>
                    <p className="mt-1 whitespace-pre-line text-[15px]">{c.body}</p>
                    {comments.filter((r) => r.parent_id === c.id).map((r) => (
                      <div key={r.id} className="ms-6 mt-3 border-s-2 border-line ps-3">
                        <p className="text-sm font-semibold">{r.author_name || t('תושב/ת', 'Resident')}</p>
                        <p className="whitespace-pre-line text-[15px]">{r.body}</p>
                      </div>
                    ))}
                  </li>
                ))}
              </ul>
              <p className="mt-4 text-sm text-gray-meta">{t('מגיבים באפליקציה של מודיעין בשבילך.', 'Comments are written in the Modiin4u app.')}</p>
            </section>
          )}
        </div>

        <aside className="flex flex-col gap-10">
          {related.length > 0 && (
            <section>
              <h2 className="mb-9 text-lg font-semibold text-ink">{t('עוד חדשות קשורות', 'More Related News')}</h2>
              <ul className="flex flex-col">
                {related.map((r) => (
                  <li key={r.id} className="border-b border-line py-5 first:pt-0">
                    <Link href={href(`/news/${r.slug}/`)} className="flex items-center gap-4">
                      {r.featured_image && <img src={ownPhoto(r.featured_image, 400) ?? r.featured_image} alt="" className="h-20 w-[110px] shrink-0 rounded-md object-cover" loading="lazy" />}
                      <span className="min-w-0">
                        <span className="line-clamp-2 text-lg leading-snug text-ink">{r.title}</span>
                        <span className="mt-1 flex items-center gap-2 text-sm text-gray-meta"><Calendar size={16} color="currentColor" />{formatDate(r.published_at, lang)}</span>
                      </span>
                    </Link>
                  </li>
                ))}
              </ul>
            </section>
          )}
          {side[0] && <BannerImage banner={side[0]} />}
        </aside>
      </div>
    </article>
  );
}

/** The pictures inside a story, as WordPress wrote them: full-size files from
 *  our storage, all fetched as the page opened — 850 KB on one article,
 *  competing with the story's own picture (PageSpeed, 15 Oct). Each now goes
 *  through the site's resizer at 800 px and loads when scrolled near; its
 *  width and height stay, so nothing shifts as it arrives. WordPress's
 *  srcset/sizes name its own copies, so they go. */
function storyPhotos(html: string): string {
  return html.replace(/<img\b([^>]*)>/gi, (tag, attrs: string) => {
    let a = attrs.replace(/\s*\/\s*$/, '').replace(/\s(?:srcset|sizes|loading|decoding)=(["'])[^"']*\1/gi, '');
    a = a.replace(/\ssrc=(["'])([^"']+)\1/i, (m, q: string, src: string) => {
      const own = ownPhoto(src.replace(/&amp;/g, '&'), 800);
      return own && own !== src ? ` src=${q}${own.replace(/&/g, '&amp;')}${q}` : m;
    });
    return `<img${a} loading="lazy" decoding="async">`;
  });
}
