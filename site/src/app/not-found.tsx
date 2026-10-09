import { Header } from '@/components/chrome/Header';
import { NotFoundView } from '@/components/NotFoundView';

/** Any address the site has no page for, and any page whose row is gone
 *  without a notice of its own: the header, then the way home. */
export default function NotFound() {
  return (
    <>
      <Header />
      <main><NotFoundView /></main>
    </>
  );
}
