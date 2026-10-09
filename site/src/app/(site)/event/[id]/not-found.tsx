import { NotFoundView } from '@/components/NotFoundView';

/** An event that was removed (web_event_detail_screen.dart). */
export default function EventNotFound() {
  return <NotFoundView
    title={['האירוע לא נמצא', 'This event could not be found']}
    body={['ייתכן שהאירוע הוסר, או שהכתובת שגויה.', 'It may have been removed, or the address is wrong.']}
    back={['כל האירועים', 'All events', '/events/']} />;
}
