// owner-invite — the panel makes a business owner of someone by e-mail
// (O4). The service key that invites a new account cannot be in the panel,
// so the panel calls this with the admin's own session:
//
//   POST { business_id, email, full_name? }   Authorization: Bearer <admin's JWT>
//
// 1. The caller must be on the team with the right to edit businesses —
//    asked of the database as the caller (is_admin, admin_may).
// 2. A new address is invited: Supabase sends the invitation e-mail (the
//    Hebrew template, supabase/email_templates/invite.html), whose link
//    opens the website's page to choose a password. An address that already
//    has an account is not e-mailed; it is simply made the owner.
// 3. The owner is set by admin_assign_business_owner as the caller, so the
//    audit log names the admin and the database checks the right again. A
//    business that has another owner is refused unless `replace` is sent.
//
// Answers { ok, invited, profile_id } or { error } with a 4xx/5xx status.

import { createClient } from 'npm:@supabase/supabase-js@2';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const answer = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...CORS, 'Content-Type': 'application/json' } });

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return answer({ error: 'method' }, 405);

  const auth = req.headers.get('Authorization') ?? '';
  let body: { business_id?: string; email?: string; full_name?: string; replace?: boolean };
  try { body = await req.json(); } catch { return answer({ error: 'bad-json' }, 400); }
  const email = (body.email ?? '').trim().toLowerCase();
  const business = (body.business_id ?? '').trim();
  if (!EMAIL.test(email) || !UUID.test(business)) return answer({ error: 'bad-input' }, 400);

  const url = Deno.env.get('SUPABASE_URL')!;
  const asCaller = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const service = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // 1. Only the team, with the right to edit businesses — before anything is sent.
  const [{ data: admin }, { data: may }] = await Promise.all([
    asCaller.rpc('is_admin'),
    asCaller.rpc('admin_may', { p_module: 'businesses', p_action: 'edit' }),
  ]);
  if (admin !== true || may !== true) return answer({ error: 'not-allowed' }, 403);

  const { data: biz } = await service.from('businesses').select('id, name, owner_id').eq('id', business).maybeSingle();
  if (!biz) return answer({ error: 'no-business' }, 404);

  // 2. The account: an existing one by its profile's address, else an invitation.
  let profileId: string | null = null;
  let invited = false;
  const { data: existing } = await service.from('profiles').select('id').ilike('email', email).limit(1).maybeSingle();
  if (existing) {
    profileId = existing.id;
  } else {
    const site = Deno.env.get('SITE_URL') ?? 'https://www.modiin4u.co.il';
    const { data, error } = await service.auth.admin.inviteUserByEmail(email, {
      redirectTo: `${site}/auth/callback`,
      data: { full_name: (body.full_name ?? '').trim() || null, account_type: 'business' },
    });
    if (error || !data?.user) return answer({ error: 'invite-failed', detail: error?.message }, 502);
    profileId = data.user.id;
    invited = true;
  }

  if (biz.owner_id && biz.owner_id !== profileId && !body.replace) {
    return answer({ error: 'business-has-owner', invited, profile_id: profileId }, 409);
  }

  // 3. As the admin: the database checks the right again and logs who did it.
  const { error: assignError } = await asCaller.rpc('admin_assign_business_owner', {
    p_business: business, p_profile: profileId, p_replace: body.replace === true,
  });
  if (assignError) return answer({ error: 'assign-failed', detail: assignError.message, invited, profile_id: profileId }, 500);

  return answer({ ok: true, invited, profile_id: profileId });
});
