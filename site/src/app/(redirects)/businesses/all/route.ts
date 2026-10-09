import { moved } from '@/lib/old-address';

/** The Flutter site's full business list → the directory. */
export function GET(req: Request) {
  return moved(req, '/businesses/');
}
