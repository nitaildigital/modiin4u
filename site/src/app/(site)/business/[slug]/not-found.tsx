import { NotFoundView } from '@/components/NotFoundView';

/** A business that is gone or hidden (_BusinessNotFound in
 *  business_detail_screen.dart). */
export default function BusinessNotFound() {
  return <NotFoundView
    title={['העסק הזה לא נמצא באתר', 'This business is not listed']}
    body={['ייתכן שנסגר או עבר. במדריך העסקים יש עוד רבים כמותו.', 'It may have closed or moved. The directory has others like it.']}
    back={['חזרה לעסקים', 'Back to Businesses', '/businesses/']} />;
}
