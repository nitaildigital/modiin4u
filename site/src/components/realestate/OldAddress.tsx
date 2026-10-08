import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { h1For, pageMetadata, wpPage } from '@/lib/seo';
import { slugParam } from '@/lib/params';
import { RealEstateView } from './RealEstateView';
import type { SearchParams } from './search';

// The old WordPress real estate addresses — the apartments archive and its
// four apartments, the agents and their categories, the My Avenue project,
// the apartment search. Each stays a page of its own at its address, with
// WordPress's title, description and H1, and the real estate section
// beneath that heading: nothing about it changes for Google.

/** The address of an old page under [base], or null when WordPress had no
 *  page there (or sent it elsewhere). */
export function oldPath(base: string, slug?: string): string | null {
  const path = slug == null ? base : `${base}${slugParam(slug)}/`;
  const wp = wpPage(path);
  return wp && !wp.redirect_to ? path : null;
}

export function oldMetadata(path: string | null): Metadata {
  return path ? pageMetadata({ path }) : {};
}

export async function OldAddressPage({ path, searchParams }: { path: string | null; searchParams: Promise<SearchParams> }) {
  if (!path) notFound();
  return <RealEstateView path={path} h1={h1For(path, 'נדל״ן')} sp={await searchParams} oldAddress />;
}
