import { isUuid, slugParam } from '@/lib/params';
import { moved, slugOf } from '@/lib/old-address';

/** The Flutter site's /restaurant/<id> → the business page. */
export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const id = slugParam((await params).id);
  const slug = await slugOf('businesses', id);
  return moved(req, slug ? `/business/${slug}/` : isUuid(id) ? `/business/${id}/` : '/restaurants/');
}
