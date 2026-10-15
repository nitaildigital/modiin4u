// WordPress's category addresses whose category the panel has since given a
// new slug. The old address stays a page of its own (SEO), listing the
// category under its new slug; the header menu, which links the old
// addresses, reads the same tables for the categories' English names.

/** /business-cat/<old>/ → the business category it lists. */
export const BUSINESS_CAT_RENAMED: Record<string, string> = {
  'בריאות': 'health',
  'ספורט-וכושר': 'sports-fitness',
  'רכב': 'automotive',
};

/** /professionals-cat/<old>/ → the business category it became. The other
 *  nine WordPress kept empty list the professionals (Services). */
export const PROFESSIONALS_MOVED: Record<string, string> = {
  'בונה-אתרים': 'web-design',
  'הנדימן': 'handyman',
  'חשמלאי': 'electrician',
  'טכנאי-מקררים': 'fridge-technician',
  'לק-ג׳ל': 'gel-nails',
  'עורך-דין': 'lawyer',
  'שיפוצניק': 'renovations',
};

/** /new/<old>/ → the news category it lists. WordPress's "עירוני"
 *  (/new/municipal/) holds the municipal stories, which are filed under
 *  `municipal-news` here; the panel's own `municipal` category is empty. */
export const NEWS_OLD_SLUGS: Record<string, string> = {
  business: 'business-news',
  culinary: 'food',
  municipal: 'municipal-news',
};
