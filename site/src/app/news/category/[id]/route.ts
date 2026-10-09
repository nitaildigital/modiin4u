import { moved, slugOf } from '@/lib/old-address';

/** The Flutter site's news menu, /news/category/<id> → the category's own
 *  address, /new/<slug>/, as WordPress had it. */
export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const slug = await slugOf('categories', (await params).id, 'article');
  return moved(req, slug ? `/new/${slug}/` : '/news/');
}
