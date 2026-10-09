import { NotFoundView } from '@/components/NotFoundView';

/** A deal that has ended or never was (web_deal_detail_screen.dart). */
export default function DealNotFound() {
  return <NotFoundView
    title={['המבצע לא נמצא', 'This offer could not be found']}
    body={['המבצע הסתיים, או שהכתובת שגויה.', 'This deal has ended, or the address is wrong.']}
    back={['חזרה למבצעים', 'Back to Deals', '/deals/']} />;
}
