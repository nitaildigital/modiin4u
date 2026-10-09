import { moved, slugOf } from '@/lib/old-address';

/** The Flutter site's /article/<id> → the story at its own address. */
export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const slug = await slugOf('articles', (await params).id);
  return moved(req, slug ? `/news/${slug}/` : '/news/');
}
