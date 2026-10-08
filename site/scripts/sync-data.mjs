// Copies what the site reads from the rest of the repo into src/data/
// before every dev and build run:
//   - tool/seo/wp_pages.json  what Google reads on the WordPress site
//                             (tool/snapshot_wp_seo.py): titles,
//                             descriptions, H1s, the header menu, redirects
//   - tool/seo/site.json      the site's names for search engines
//   - the Supabase address and public key, from the app's own config
//     (lib/core/supabase/supabase_config.dart) — the same public key the
//     app ships, so the site and the app can never point at different data.
import { copyFileSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
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
console.log('site data synced');
