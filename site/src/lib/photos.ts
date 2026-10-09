/** The widths a photo is asked for, so one copy serves many boxes; they are
 *  the image optimiser's allowed sizes in next.config.ts. */
export const PHOTO_WIDTHS = [200, 400, 600, 800, 1200, 1600, 2000, 2500];

/** A photo from our Supabase storage at about the size it is drawn, made
 *  by this site's own image optimiser (/_next/image), which keeps each copy
 *  on disk. Supabase's resizing (/render/image) was used before: every
 *  photo it resizes counts against the plan's 100 a month, and on 9 Oct
 *  the project was restricted at 862. Now Supabase serves each original
 *  once, as an ordinary download. Anything not a stored JPEG, PNG or WebP —
 *  a logo in SVG, a picture on another site — is left as it is. */
export function ownPhoto(url: string | null | undefined, px: number): string | null {
  if (!url) return null;
  const stored = '/storage/v1/object/public/';
  if (!url.includes('.supabase.co' + stored)) return url;
  const path = url.split('?')[0].toLowerCase();
  if (!/\.(jpe?g|png|webp)$/.test(path)) return url;
  const w = PHOTO_WIDTHS.find((s) => s >= px) ?? PHOTO_WIDTHS[PHOTO_WIDTHS.length - 1];
  // With a slash, as the site's addresses end (trailingSlash): without
  // it every photo would first be a redirect.
  return `/_next/image/?url=${encodeURIComponent(url)}&w=${w}&q=75`;
}
