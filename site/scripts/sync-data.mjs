// Copies what the site reads from the rest of the repo into src/data/
// before every dev and build run:
//   - tool/seo/wp_pages.json  what Google reads on the WordPress site
//                             (tool/snapshot_wp_seo.py): titles,
//                             descriptions, H1s, the header menu, redirects
//   - tool/seo/site.json      the site's names for search engines
//   - the Supabase address and public key, from the app's own config
//     (lib/core/supabase/supabase_config.dart) — the same public key the
//     app ships, so the site and the app can never point at different data.
//   - the panel's redirects, read from the database (below)
import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, '..', '..');
const out = join(here, '..', 'src', 'data');
mkdirSync(out, { recursive: true });

copyFileSync(join(repo, 'tool', 'seo', 'wp_pages.json'), join(out, 'wp_pages.json'));
copyFileSync(join(repo, 'tool', 'seo', 'site.json'), join(out, 'site.json'));

const dart = readFileSync(join(repo, 'lib', 'core', 'supabase', 'supabase_config.dart'), 'utf8').replace(/\n/g, '');
const url = dart.match(/supabaseUrl\s*=\s*'([^']+)'/)[1];
const anonKey = dart.match(/anonKey\s*=\s*'([^']+)'/)[1];
writeFileSync(join(out, 'supabase.json'), JSON.stringify({ url, anonKey }) + '\n');

// The panel's redirects as they stand at build time (src/lib/redirects.ts):
// what the site answers with after a restart until it has read the live
// list, so a slow first read cannot send a redirected address to a 404 that
// nginx then caches. A failed read keeps the copy already here, or starts
// an empty one — the build never waits on it.
const redirectsFile = join(out, 'redirects.json');
try {
  const res = await fetch(`${url}/rest/v1/redirects?select=old_path,new_path,status_code&is_active=eq.true`, {
    headers: { apikey: anonKey, Authorization: `Bearer ${anonKey}` },
    signal: AbortSignal.timeout(10000),
  });
  if (!res.ok) throw new Error(`status ${res.status}`);
  const rows = await res.json();
  writeFileSync(redirectsFile, JSON.stringify(rows) + '\n');
  console.log(`redirects: ${rows.length} from the panel`);
} catch (e) {
  if (!existsSync(redirectsFile)) writeFileSync(redirectsFile, '[]\n');
  console.warn(`redirects not read (${e.message}); the previous copy is kept`);
}
console.log('site data synced');
