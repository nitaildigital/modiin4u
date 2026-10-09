'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Location, Lock1 } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import { sessionDb, useSession } from '@/lib/session';
import { Avatar } from './parts';

type Place = { id: string; slug: string | null; name: string; name_en: string | null; image: string | null; kind: string; top_pick: string | null };
type Profile = {
  username: string; name: string; avatar_url: string | null; neighborhood: string | null; neighborhood_en: string | null;
  bio: string | null; interests: string[]; places: Place[];
};

// The app's list (urban_profile.dart): the keys 00077 stores, as the card
// writes them.
const INTERESTS: Record<string, [string, string, string]> = {
  cafes: ['☕', 'בתי קפה', 'Cafés'], brunch: ['🥐', 'ארוחות בוקר ובראנץ׳', 'Breakfast & Brunch'],
  nightlife: ['🍷', 'ברים וחיי לילה', 'Bars & Nightlife'], restaurants: ['🍽️', 'מסעדות', 'Restaurants'],
  asian: ['🍣', 'אוכל אסייתי', 'Asian Food'], nature: ['🌳', 'פארקים וטבע', 'Parks & Nature'],
  running: ['🏃', 'ריצה', 'Running'], cycling: ['🚴', 'רכיבה על אופניים', 'Cycling'],
  fitness: ['🏋️', 'כושר וספורט', 'Fitness & Sports'], family: ['👨‍👩‍👧', 'משפחה וילדים', 'Family & Kids'],
  culture: ['🎭', 'תרבות', 'Culture'], music: ['🎵', 'מוזיקה', 'Music'], pets: ['🐶', 'חיות מחמד', 'Pets'],
  shopping: ['🛍️', 'קניות', 'Shopping'], events: ['🎉', 'אירועים', 'Events'], local_business: ['💼', 'עסקים מקומיים', 'Local Businesses'],
};
// seo.ts's href, here: importing it would bring the WordPress snapshot into
// the browser's bundle.
const href = (path: string) => path.split('/').map((s) => (s ? encodeURIComponent(s) : s)).join('/');

const PICKS: Record<string, [string, string]> = {
  coffee: ['בית הקפה שלי', 'My Coffee Spot'], restaurant: ['המסעדה שלי', 'My Restaurant'], city: ['המקום שלי בעיר', 'My Place in the City'],
};

/** A resident's Urban Profile on the website: read-only, the same card as the
 *  app's, each place linking to its page. */
export function UrbanProfileView({ lang, username, stores }: {
  lang: Lang; username: string; stores: { android: string | null; ios: string | null };
}) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const { session, ready } = useSession();
  const [profile, setProfile] = useState<Profile | null | undefined>(undefined);

  useEffect(() => {
    if (!ready) return;
    if (!session) { setProfile(null); return; }
    sessionDb().rpc('urban_profile', { p_username: username }).then(({ data }) => setProfile((data as Profile | null) ?? null));
  }, [ready, session, username]);

  const local = (he: string, en: string | null) => (lang === 'en' && en?.trim() ? en : he);
  const placeHref = (p: Place) => href(`/business/${p.slug || p.id}/`);

  return (
    <div className="wrap">
      <div className="mx-auto max-w-[560px] py-8 desk:py-12">
        {profile === undefined ? (
          <div className="flex justify-center py-16"><span className="size-9 animate-spin rounded-full border-[3px] border-midblue border-t-transparent" aria-hidden /></div>
        ) : profile === null ? (
          <div className="flex flex-col items-center py-12 text-center">
            <span className="flex size-[72px] items-center justify-center rounded-full bg-midblue/[0.08]"><Lock1 size={32} color="#123A72" /></span>
            <h1 className="mt-5 text-xl font-semibold text-ink">
              {session ? t('הפרופיל הזה פרטי', 'This profile is private') : t('פרופיל עירוני במודיעין בשבילך', 'An Urban Profile on Modiin4U')}
            </h1>
            <p className="mt-2 max-w-sm text-sm text-[#6D6D6D]">
              {session
                ? t('בעליו לא שיתפו אותו עם תושבים אחרים.', 'Its owner has not shared it with other residents.')
                : t('פרופילים של תושבים נפתחים לתושבים מחוברים. התחברו, או פתחו באפליקציה.', "Residents' profiles open for signed-in residents. Sign in, or open it in the app.")}
            </p>
            {!session && (
              <Link href={`/signin/?next=${encodeURIComponent(`/u/${username}/`)}`} className="mt-6 flex h-12 items-center rounded-full bg-midblue px-10 font-medium text-white">
                {t('התחברות', 'Sign in')}
              </Link>
            )}
            <div className="mt-6 flex flex-wrap justify-center gap-3">
              {stores.ios && <a href={stores.ios} target="_blank" rel="noopener" className="flex h-11 items-center gap-2 rounded-full border border-line px-4 text-sm font-medium text-ink"><img src="/images/apple_logo.svg" alt="" className="size-5" />App Store</a>}
              {stores.android && <a href={stores.android} target="_blank" rel="noopener" className="flex h-11 items-center gap-2 rounded-full border border-line px-4 text-sm font-medium text-ink"><img src="/images/google_play.svg" alt="" className="size-5" />Google Play</a>}
            </div>
          </div>
        ) : (
          <article className="overflow-hidden rounded-[22px] border border-[#E9EDF3] bg-white shadow-[0_8px_24px_rgba(0,0,0,0.08)]">
            <div className="relative h-[132px]">
              <div className="h-[84px] bg-gradient-to-br from-midblue to-navy" />
              <div className="absolute start-5 top-9 rounded-full border-4 border-white">
                <Avatar url={profile.avatar_url} name={profile.name} size={84} />
              </div>
            </div>
            <div className="px-5 pb-6 pt-2">
              <h1 className="text-[22px] font-bold text-black">{profile.name}</h1>
              {profile.neighborhood && (
                <p className="mt-1 flex items-center gap-1 text-sm text-[#6D6D6D]"><Location size={15} color="#6D6D6D" />{local(profile.neighborhood, profile.neighborhood_en)}</p>
              )}
              {profile.bio?.trim() && <p className="mt-4 text-[15px] italic leading-[1.45] text-ink">“{profile.bio.trim()}”</p>}
              {profile.interests.length > 0 && (
                <div className="mt-4 flex flex-wrap gap-2">
                  {profile.interests.filter((k) => INTERESTS[k]).map((k) => (
                    <span key={k} className="rounded-2xl bg-[#EEF3FA] px-2.5 py-1.5 text-[12.5px] font-medium text-midblue">
                      {INTERESTS[k][0]} {lang === 'he' ? INTERESTS[k][1] : INTERESTS[k][2]}
                    </span>
                  ))}
                </div>
              )}
              {profile.places.length > 0 && (
                <>
                  <h2 className="mt-6 text-sm font-bold text-ink">{t('המקומות שלי', 'My Places')}</h2>
                  <ul className="mt-3 grid grid-cols-3 gap-3">
                    {profile.places.map((p) => (
                      <li key={p.id}>
                        <Link href={placeHref(p)} className="block">
                          {p.image
                            ? <img src={p.image} alt="" loading="lazy" className="aspect-[4/3] w-full rounded-xl bg-surface object-cover" />
                            : <span className="block aspect-[4/3] w-full rounded-xl bg-[#EEF2F7]" />}
                          <span className="mt-1.5 line-clamp-2 text-xs font-medium text-ink">{local(p.name, p.name_en)}</span>
                        </Link>
                      </li>
                    ))}
                  </ul>
                </>
              )}
              {profile.places.length >= 3 && profile.places.some((p) => p.top_pick) && (
                <>
                  <h2 className="mt-6 text-sm font-bold text-ink">{t('הבחירות שלי במודיעין', 'My Top Picks in Modiin')}</h2>
                  <ul className="mt-3 flex flex-col gap-2">
                    {(['coffee', 'restaurant', 'city'] as const).map((pick) => {
                      const p = profile.places.find((x) => x.top_pick === pick);
                      if (!p) return null;
                      return (
                        <li key={pick}>
                          <Link href={placeHref(p)} className="flex items-center gap-3 rounded-xl border border-line p-2">
                            {p.image ? <img src={p.image} alt="" className="size-12 rounded-lg object-cover" /> : <span className="size-12 rounded-lg bg-[#EEF2F7]" />}
                            <span>
                              <span className="block text-xs font-medium text-midblue">{lang === 'he' ? PICKS[pick][0] : PICKS[pick][1]}</span>
                              <span className="block text-[15px] font-semibold text-ink">{local(p.name, p.name_en)}</span>
                            </span>
                          </Link>
                        </li>
                      );
                    })}
                  </ul>
                </>
              )}
            </div>
          </article>
        )}
      </div>
    </div>
  );
}
