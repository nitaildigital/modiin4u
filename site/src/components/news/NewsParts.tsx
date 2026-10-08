import Link from 'next/link';
import { Danger, DocumentText, Image as ImageIcon, Note } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import { tr } from '@/lib/i18n';
import { href, plain } from '@/lib/seo';
import type { NewsCard, NewsCategory } from '@/lib/data/news';
import { newsCategoryName } from '@/lib/data/news';

// The pieces of the news lists: the desktop's hero and cards
// (web_news_screen.dart) and the phone's (news_screen.dart,
// m_article_parts.dart).

const HE_MONTHS = ['ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני', 'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר'];
const EN_MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

/** "25 בספטמבר 2026 | 16:17" or "September 25, 2026 | 4:17 p.m.", as the
 *  design writes a story's date — in Israel's time. */
export function newsDate(iso: string | null | undefined, lang: Lang): string {
  if (!iso) return '';
  const p = Object.fromEntries(new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Asia/Jerusalem', year: 'numeric', month: 'numeric', day: 'numeric', hour: 'numeric', minute: '2-digit', hourCycle: 'h23',
  }).formatToParts(new Date(iso)).map((x) => [x.type, x.value]));
  const day = +p.day, month = +p.month - 1, hour = +p.hour % 24, mm = p.minute;
  if (lang === 'he') return `${day} ב${HE_MONTHS[month]} ${p.year} | ${String(hour).padStart(2, '0')}:${mm}`;
  const h = hour % 12 === 0 ? 12 : hour % 12;
  return `${EN_MONTHS[month]} ${day}, ${p.year} | ${h}:${mm} ${hour < 12 ? 'a.m.' : 'p.m.'}`;
}

export function storyHref(c: Pick<NewsCard, 'slug'>): string {
  return href(`/news/${c.slug}/`);
}

/** The calendar-clock icon and the date. */
export function DateLine({ card, lang, white = false, icon = 16, className = '' }: { card: NewsCard; lang: Lang; white?: boolean; icon?: number; className?: string }) {
  if (!card.published_at) return null;
  return (
    <span className={`flex items-center gap-[9px] text-sm leading-[17px] ${white ? 'text-white' : 'text-gray-text'} ${className}`}>
      <img src={white ? '/web/news/date_white.svg' : '/web/home/date.svg'} alt="" width={icon} height={icon} className="shrink-0" style={{ width: icon, height: icon }} />
      <time dateTime={card.published_at} className="truncate">{newsDate(card.published_at, lang)}</time>
    </span>
  );
}

/** Behind a story with no picture: a dark gradient picked by its id, so the
 *  same story always looks the same (web_news_screen.dart). */
const GRADIENTS = [
  ['#2E5C8A', '#0C1A33'], ['#7A3B4A', '#1E0A10'], ['#3F6B4F', '#0E1C14'],
  ['#6B5A3B', '#1C160C'], ['#4A3B7A', '#120E22'], ['#2F6B6B', '#0B1C1C'],
];

export function Photo({ card, className = '', glyph = 40, eager = false }: { card: NewsCard; className?: string; glyph?: number | null; eager?: boolean }) {
  if (card.image) {
    return <img src={card.image} alt={card.title} className={`object-cover ${className}`} loading={eager ? 'eager' : 'lazy'} />;
  }
  let h = 0;
  for (const ch of card.id) h = (h * 31 + ch.charCodeAt(0)) >>> 0;
  const [a, b] = GRADIENTS[h % GRADIENTS.length];
  return (
    <span className={`flex items-center justify-center ${className}`} style={{ background: `linear-gradient(to bottom, ${a}, ${b})` }} role="img" aria-label={card.title}>
      {glyph ? <ImageIcon size={glyph} color="rgba(255,255,255,0.55)" /> : null}
    </span>
  );
}

function Badge({ children, className }: { children: React.ReactNode; className: string }) {
  return <span className={`flex h-9 items-center gap-1.5 rounded-lg px-3 text-sm font-medium leading-6 ${className}`}>{children}</span>;
}

/** "Breaking", "Now in Modiin" on the lead when the newsroom featured it,
 *  and the category the story is filed under. */
function Badges({ card, chip, lang, lead }: { card: NewsCard; chip?: NewsCategory; lang: Lang; lead: boolean }) {
  const t = tr(lang);
  return (
    <span className="absolute start-4 top-4 flex gap-3">
      {card.is_breaking && <Badge className="bg-error text-white"><Danger size={20} color="#fff" />{t('מבזק', 'Breaking')}</Badge>}
      {lead && card.is_featured && (
        <Badge className="bg-[#C9F31D] text-navy"><img src="/web/news/now_in_modiin.svg" alt="" width={20} height={20} />{t('עכשיו במודיעין', 'Now in Modiin')}</Badge>
      )}
      {chip && <Badge className="bg-turquoise text-white">{newsCategoryName(chip, lang)}</Badge>}
    </span>
  );
}

/** The desktop's top: the lead story across 1014 and two stories stacked
 *  in 576 beside it, 552 tall, the headlines over a dark fade. */
export function DeskHero({ lead, side, chips, lang }: { lead: NewsCard; side: NewsCard[]; chips: Map<string, NewsCategory>; lang: Lang }) {
  return (
    <div className={`grid h-[552px] gap-[10px] ${side.length ? 'grid-cols-[1014fr_576fr]' : ''}`}>
      <Link href={storyHref(lead)} className="group relative block overflow-hidden rounded-xl">
        <Photo card={lead} glyph={null} eager className="absolute inset-0 size-full transition-transform duration-150 group-hover:scale-[1.008]" />
        <span className="absolute inset-x-0 bottom-0 top-[39px]" style={{ background: 'linear-gradient(to bottom, transparent 55.43%, #000 100%)' }} />
        <Badges card={lead} chip={chips.get(lead.id)} lang={lang} lead />
        <span className="absolute start-7 end-[34px] bottom-7 flex flex-col gap-3">
          <span dir="auto" className="line-clamp-2 font-nunito text-[28px] font-semibold leading-[34px] text-white">{lead.title}</span>
          <DateLine card={lead} lang={lang} white />
        </span>
      </Link>
      {side.length > 0 && (
        <div className="grid min-h-0 gap-[10px]" style={{ gridTemplateRows: `repeat(${side.length}, minmax(0, 1fr))` }}>
          {side.map((s, i) => (
            <Link key={s.id} href={storyHref(s)} className="group relative block overflow-hidden rounded-xl">
              <Photo card={s} glyph={48} className="absolute inset-0 size-full transition-transform duration-150 group-hover:scale-[1.008]" />
              <span className="absolute inset-x-0 bottom-0" style={{ top: i === 0 ? 0 : 27, background: 'linear-gradient(to bottom, transparent 31.37%, #000 100%)' }} />
              <Badges card={s} chip={chips.get(s.id)} lang={lang} lead={false} />
              <span className="absolute start-[18px] end-[23px] bottom-[18px] flex flex-col gap-5">
                <span dir="auto" className="line-clamp-2 font-nunito text-2xl font-semibold leading-[30px] text-white">{s.title}</span>
                <DateLine card={s} lang={lang} white />
              </span>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}

/** A story card of the desktop's grid: the picture 270 tall, two lines of
 *  headline, a line of the excerpt and the date. */
export function DeskCard({ card, lang }: { card: NewsCard; lang: Lang }) {
  const excerpt = plain(card.excerpt);
  return (
    <Link href={storyHref(card)} className="group block">
      <span className="block h-[270px] overflow-hidden rounded-xl">
        <Photo card={card} className="size-full transition-transform duration-150 group-hover:scale-[1.015]" />
      </span>
      <span dir="auto" className="mt-4 line-clamp-2 h-[50px] font-nunito text-xl font-semibold leading-[25px] text-black group-hover:text-midblue">{card.title}</span>
      {excerpt && <span dir="auto" className="mt-3 block truncate text-sm leading-[21px] text-gray-text">{excerpt}</span>}
      <DateLine card={card} lang={lang} className="mt-[14px]" />
    </Link>
  );
}

/** Three cards across wherever they can be about 340 wide, then two, then
 *  one (web_news_screen.dart, _gridColumns). */
export function DeskGrid({ cards, lang }: { cards: NewsCard[]; lang: Lang }) {
  return (
    <div className="grid gap-x-8 gap-y-10" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(max(340px, calc((100% - 64px) / 3)), 1fr))' }}>
      {cards.map((c) => <DeskCard key={c.id} card={c} lang={lang} />)}
    </div>
  );
}

/** A grid's heading: Nunito 28 in the mid blue, linking to the category
 *  where there is one. */
export function DeskHeading({ title, link }: { title: string; link?: string }) {
  const h = <h2 className="font-nunito text-[28px] font-semibold leading-[34px] text-midblue">{title}</h2>;
  return <div className="mb-6">{link ? <Link href={link} className="inline-block hover:underline">{h}</Link> : h}</div>;
}

/** The phone's hero (news_screen.dart, _FeaturedArticle): the picture 200
 *  tall, the headline, the date and a rule under them. */
export function PhoneFeatured({ card, lang }: { card: NewsCard; lang: Lang }) {
  const t = tr(lang);
  return (
    <Link href={storyHref(card)} className="mx-4 block border-b border-line pb-5">
      <span className="relative block h-[200px] overflow-hidden rounded-xl">
        <Photo card={card} eager className="size-full" />
        {card.is_featured && (
          <span className="absolute start-2 top-2 flex items-center gap-1 rounded-lg bg-[#C9F31D] px-2 py-1.5 text-xs font-medium leading-[15px] text-navy">
            <img src="/web/news/now_in_modiin.svg" alt="" width={16} height={16} />{t('עכשיו במודיעין', 'Now in Modiin')}
          </span>
        )}
      </span>
      <span dir="auto" className="mt-[14px] line-clamp-2 font-nunito text-xl font-semibold leading-[1.2] text-black">{card.title}</span>
      <PhoneDate card={card} lang={lang} className="mt-2.5" />
    </Link>
  );
}

function PhoneDate({ card, lang, className = '' }: { card: NewsCard; lang: Lang; className?: string }) {
  if (!card.published_at) return null;
  return (
    <span className={`flex items-center gap-2 text-sm leading-[1.2] text-[#6D6D6D] ${className}`}>
      <img src="/web/news/meta_date.svg" alt="" width={16} height={16} className="size-4 shrink-0" />
      <time dateTime={card.published_at} className="truncate">{newsDate(card.published_at, lang)}</time>
    </span>
  );
}

/** The phone's story card (m_article_parts.dart, MNewsCard): 250 wide with a
 *  150 picture in the sideways rows, the full width and 200 in a list. */
export function PhoneCard({ card, lang, wide = false }: { card: NewsCard; lang: Lang; wide?: boolean }) {
  return (
    <Link href={storyHref(card)} className={`block ${wide ? 'w-full' : 'w-[250px] shrink-0 snap-start'}`}>
      <span className={`block overflow-hidden rounded-xl ${wide ? 'h-[200px]' : 'h-[150px]'}`}>
        <Photo card={card} className="size-full" />
      </span>
      <span dir="auto" className="mt-3 line-clamp-2 text-base font-medium leading-[1.2] text-black">{card.title}</span>
      <PhoneDate card={card} lang={lang} className="mt-3" />
    </Link>
  );
}

/** A category's row on the phone: its name, "See All", and its stories
 *  sideways. */
export function PhoneSection({ title, link, cards, lang }: { title: string; link?: string; cards: NewsCard[]; lang: Lang }) {
  const t = tr(lang);
  return (
    <section>
      <div className="flex items-center gap-3 px-4">
        <h2 className="min-w-0 flex-1 truncate text-base font-semibold leading-[19px] text-[#1F1F1F]">{title}</h2>
        {link && <Link href={link} className="text-xs font-medium leading-[15px] text-midblue">{t('הצג הכל', 'See All')}</Link>}
      </div>
      <div className="mt-3 flex snap-x gap-5 overflow-x-auto px-4 [scrollbar-width:none]">
        {cards.map((c) => <PhoneCard key={c.id} card={c} lang={lang} />)}
      </div>
    </section>
  );
}

/** The phone's list of a category's stories, a full-width card each. */
export function PhoneList({ cards, lang }: { cards: NewsCard[]; lang: Lang }) {
  return (
    <div className="flex flex-col gap-6 px-4 pt-2">
      {cards.map((c) => <PhoneCard key={c.id} card={c} lang={lang} wide />)}
    </div>
  );
}

/** The page's one heading: the phone's title bar (Inter Medium 16, centred,
 *  48 tall); the desktop draws no title over the news, so there it is read
 *  but not seen. */
export function PageTitle({ children }: { children: React.ReactNode }) {
  return (
    <h1 className="flex h-12 items-center justify-center px-4 text-center text-base font-medium text-black desk:sr-only">{children}</h1>
  );
}

/** Nothing to show (web_news_screen.dart, _buildNotice; the phone's
 *  EmptyState). */
export function EmptyNews({ lang, category }: { lang: Lang; category: boolean }) {
  const t = tr(lang);
  return (
    <>
      <div className="hidden flex-col items-center rounded-xl border border-line px-6 py-24 text-center desk:flex">
        <Note size={44} color="rgba(95,94,90,0.5)" />
        <p className="mt-4 font-nunito text-xl font-semibold text-navy">
          {category ? t('אין עדיין כתבות בקטגוריה הזו', 'Nothing in this category yet') : t('עדיין לא פורסמו כתבות', 'No articles published yet')}
        </p>
        <p className="mt-2 text-sm text-gray-text">{t('כתבות יופיעו כאן עם פרסומן.', 'Stories will appear here as the newsroom publishes them.')}</p>
      </div>
      <div className="flex flex-col items-center px-6 py-24 text-center desk:hidden">
        <DocumentText size={48} color="#888780" />
        <p className="mt-4 text-base font-semibold text-ink">{t('אין כתבות להצגה', 'No stories yet')}</p>
        <p className="mt-1 text-sm text-gray-text">{t('כתבות חדשות יופיעו כאן', 'New stories will appear here')}</p>
      </div>
    </>
  );
}

/** The pages of a list, as plain links a search engine follows: the first,
 *  the last, two either side of this one, and "Next" in the app's
 *  outlined pill. */
export function Pager({ base, page, pages, lang }: { base: string; page: number; pages: number; lang: Lang }) {
  if (pages < 2) return null;
  const t = tr(lang);
  const url = (n: number) => (n === 1 ? href(base) : `${href(base)}?page=${n}`);
  const shown: (number | null)[] = [];
  for (let n = 1; n <= pages; n++) {
    if (n === 1 || n === pages || Math.abs(n - page) <= 2) shown.push(n);
    else if (shown[shown.length - 1] !== null) shown.push(null);
  }
  return (
    <nav className="mt-12 flex flex-wrap items-center justify-center gap-2 px-4">
      {shown.map((n, i) => n === null
        ? <span key={`gap${i}`} className="px-1 text-gray-meta">…</span>
        : n === page
          ? <span key={n} aria-current="page" className="flex size-11 items-center justify-center rounded-full bg-midblue text-base font-medium text-white">{n}</span>
          : <Link key={n} href={url(n)} rel={n === page - 1 ? 'prev' : n === page + 1 ? 'next' : undefined}
              className="flex size-11 items-center justify-center rounded-full border border-line text-base font-medium text-ink hover:border-midblue hover:text-midblue">{n}</Link>)}
      {page < pages && (
        <Link href={url(page + 1)} rel="next" className="ms-2 flex h-12 items-center rounded-full border border-midblue px-10 text-base font-medium text-midblue hover:bg-midblue hover:text-white">
          {t('הבא', 'Next')}
        </Link>
      )}
    </nav>
  );
}
