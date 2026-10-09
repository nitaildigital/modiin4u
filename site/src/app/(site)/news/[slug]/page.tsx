import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { Calendar } from 'iconsax-react';
import { getLang, tr } from '@/lib/i18n';
import { slugParam, formatDate } from '@/lib/params';
import { pageMetadata, h1For, plain, organization, breadcrumb, href, SITE_NAME, SUFFIX } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import { articleBySlug, articleComments, categoriesOf, categoryName, relatedArticles } from '@/lib/data/articles';
import { banners } from '@/lib/data/banners';
import { JsonLd } from '@/components/JsonLd';
import { BannerImage } from '@/components/ui/Banner';
import { ShareBar } from '@/components/ui/ShareBar';
import { ArticleView } from '@/components/news/ArticleView';

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
          ...(a.published_at ? { datePublished: a.published_at } : {}),
          ...(a.updated_at ? { dateModified: a.updated_at } : {}),
          ...(image ? { image: [image] } : {}),
        },
        breadcrumb([[SITE_NAME, '/'], ['חדשות', '/news/'], [a.title, path]]),
      ]} />

      {/* The picture and the headline card. */}
      <div className="grid overflow-hidden rounded-2xl desk:grid-cols-2 desk:items-center">
        {image && <img src={image} alt={a.title} className="aspect-[16/10] w-full object-cover desk:aspect-auto desk:max-h-[440px]" />}
        <div className="bg-section p-5 desk:flex desk:min-h-[436px] desk:flex-col desk:justify-center desk:rounded-2xl desk:p-10">
          {cat && (
            <Link href={href(`/new/${cat.slug}/`)} className="mb-5 inline-block w-fit rounded-md bg-turquoise px-3 py-2 text-sm font-semibold text-white">
              {categoryName(cat, lang)}
            </Link>
          )}
          <h1 className="text-2xl font-medium leading-snug text-ink desk:text-[34px]">{h1For(path, a.title)}</h1>
          {a.subtitle && <p className="mt-3 text-base text-gray-text">{a.subtitle}</p>}
          {(a.published_at || a.credit?.trim()) && (
            <p className="mt-6 flex flex-wrap items-center gap-x-8 gap-y-2 text-base text-gray-meta">
              {a.published_at && (
                <span className="flex items-center gap-2">
                  <Calendar size={18} color="currentColor" />
                  <time dateTime={a.published_at}>{formatDate(a.published_at, lang, true)}</time>
                </span>
              )}
              {a.credit?.trim() && (
                <span className="flex items-center gap-2"><img src="/web/news/meta_author.svg" alt="" className="size-[18px]" />{a.credit.trim()}</span>
              )}
            </p>
          )}
        </div>
      </div>

      <div className="mt-8 grid gap-12 desk:grid-cols-[1fr_426px] desk:gap-[150px]">
        <div className="min-w-0">
          <ShareBar url={SITE_URL + href(path)} title={a.title} lang={lang} views={a.view_count ?? 0} shares={a.share_count ?? 0} />
          {/* The page's one H1 is the headline above: a heading the story's own
              text opens with an h1 is set as an h2. */}
          <div className="prose-site mt-8" dangerouslySetInnerHTML={{ __html: (a.body ?? '').replace(/<(\/?)h1(\s|>)/gi, '<$1h2$2') }} />
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
                      {r.featured_image && <img src={r.featured_image} alt="" className="h-20 w-[110px] shrink-0 rounded-md object-cover" loading="lazy" />}
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
