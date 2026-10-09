import { NotFoundView } from '@/components/NotFoundView';

/** A page under the header bar whose row is gone (a listing, an article, a
 *  car park …), inside this layout so the header is drawn once. Addresses
 *  with no page at all are the root not-found's. */
export default function SiteNotFound() {
  return <NotFoundView />;
}
