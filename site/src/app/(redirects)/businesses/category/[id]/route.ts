import { moved, slugOf } from '@/lib/old-address';
import { categoryPath } from '@/lib/routes';

/** The Flutter site's /businesses/category/<id or slug> → the category's
 *  page (`services` was the professionals' link there). */
export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const slug = await slugOf('categories', (await params).id, 'business');
  return moved(req, slug ? categoryPath(slug) : '/business/');
}
