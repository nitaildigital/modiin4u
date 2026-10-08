import { tr, type Lang } from '@/lib/i18n';
import type { NavItem } from './NavLinks';

/** The header's links, from the logo outwards (web_chrome.dart,
 *  webNavItems), and the addresses each underlines itself on — the old
 *  WordPress addresses included. Shared by the bar and the phone menus. */
export function navItems(lang: Lang): NavItem[] {
  const t = tr(lang);
  return [
    { id: 'businesses', label: t('עסקים', 'Businesses'), href: '/businesses/', menu: 'businesses', match: ['/businesses', '/business/', '/business-cat', '/maar'] },
    { id: 'restaurants', label: t('מסעדות', 'Restaurants'), href: '/restaurants/', match: ['/restaurants', '/search-rest-modiin'] },
    { id: 'realestate', label: t('נדל״ן', 'Real Estate'), href: '/realestate/', match: ['/realestate', '/listing', '/neighborhood', '/apartments', '/real-estate-agents', '/real-astate-agents', '/my-avenue', '/search-apartments'] },
    { id: 'deals', label: t('מבצעים', 'Deals'), href: '/deals/', match: ['/deals', '/deal/'] },
    { id: 'events', label: t('אירועים', 'Events'), href: '/events/', match: ['/events', '/event/'] },
    { id: 'news', label: t('חדשות מודיעין', 'Modiin News'), href: '/news/', menu: 'news', match: ['/news', '/new/', '/modiin-news'] },
    { id: 'professionals', label: t('בעלי מקצוע', 'Professionals'), href: '/professionals/', menu: 'professionals', match: ['/professionals'] },
  ];
}
