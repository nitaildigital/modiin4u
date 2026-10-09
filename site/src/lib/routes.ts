// The site's addresses are WordPress's wherever WordPress had the page
// (9 Oct): Google knows those, and two addresses for one page split what
// it knows between them. The sections the app's design added under new
// names, and categories WordPress had under another slug, are 301s to the
// WordPress address (next.config.ts); every link the site draws goes
// straight there. Sections WordPress never had (events, deals, the map,
// municipal…) keep their own addresses.

/** A section's address, as WordPress had it. */
export const ROUTES = {
  businesses: '/business/',
  restaurants: '/search-rest-modiin/',
  realestate: '/search-apartments/',
  shabbat: '/shabat-times-modiin/',
  professionals: '/professionals/',
} as const;

/** The sections' new names, and the WordPress address each answers with. */
export const SECTION_MOVES: [string, string][] = [
  ['/businesses/', ROUTES.businesses],
  ['/restaurants/', ROUTES.restaurants],
  ['/realestate/', ROUTES.realestate],
  ['/shabbat/', ROUTES.shabbat],
];

/** Business categories the panel files under an English slug that
 *  WordPress had under a Hebrew one, or as a professionals category. */
export const CATEGORY_MOVES: Record<string, string> = {
  health: '/business-cat/בריאות/',
  'sports-fitness': '/business-cat/ספורט-וכושר/',
  automotive: '/business-cat/רכב/',
  services: '/professionals/',
  'web-design': '/professionals-cat/בונה-אתרים/',
  handyman: '/professionals-cat/הנדימן/',
  electrician: '/professionals-cat/חשמלאי/',
  'fridge-technician': '/professionals-cat/טכנאי-מקררים/',
  'gel-nails': '/professionals-cat/לק-ג׳ל/',
  lawyer: '/professionals-cat/עורך-דין/',
  renovations: '/professionals-cat/שיפוצניק/',
};

/** A business category's page: WordPress's address where it had one. */
export function categoryPath(slug: string): string {
  return CATEGORY_MOVES[slug] ?? `/business-cat/${slug}/`;
}
