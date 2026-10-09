"""A temporary super_admin, for testing the management panel.

  python3 tool/tmp_admin.py --create   # a new admin with a random password
  python3 tool/tmp_admin.py --delete   # removes it again, and says what is left
  python3 tool/tmp_admin.py --list     # every temporary admin still there
  python3 tool/tmp_admin.py --purge    # removes them all (before launch)

Testing the panel needs someone who can sign in to it, and borrowing a real
administrator's account means acting as them. This makes a throwaway one: an
address at .test, a random password, the super_admin role. The e-mail and
password are written to a file in the system's temporary folder (mode 600),
never printed, so a test script can read them without them appearing in a
terminal or a log. Delete the admin when the test is done — the script checks
that nothing of it remains.

--delete knows only the admin in this machine's file; an admin made on
another machine, or whose file was lost, stayed (two super_admins on 5 Oct).
--list finds every account at a tmp-admin-…@modiin4u.test address, and
--purge removes them all — only those: no other account matches.

Reads SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY from .env.local.
"""
import json
import os
import secrets
import sys
import tempfile
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CREDS = os.path.join(tempfile.gettempdir(), 'modiin4u_tmp_admin.json')

env = {}
for line in open(os.path.join(ROOT, '.env.local'), encoding='utf-8'):
    line = line.rstrip('\n')
    if line.strip() and not line.lstrip().startswith('#'):
        k, _, v = line.partition('=')
        env[k] = v
URL = env['SUPABASE_URL'].rstrip('/')
KEY = env['SUPABASE_SERVICE_ROLE_KEY']


def http(method, path, body=None, extra=None):
    headers = {'apikey': KEY, 'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'}
    if extra:
        headers.update(extra)
    req = urllib.request.Request(URL + path, method=method, headers=headers,
                                 data=None if body is None else json.dumps(body).encode())
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        raise SystemExit(f'{method} {path.split("?")[0]} -> {e.code}: {e.read().decode()[:200]}')


if '--create' in sys.argv:
    if os.path.exists(CREDS):
        raise SystemExit(f'{CREDS} exists — delete the previous admin first (--delete)')
    email = f'tmp-admin-{secrets.token_hex(4)}@modiin4u.test'
    password = secrets.token_urlsafe(24)
    user = http('POST', '/auth/v1/admin/users', {'email': email, 'password': password, 'email_confirm': True})
    uid = user['id']
    role = http('GET', '/rest/v1/admin_roles?select=id&name=eq.super_admin')[0]['id']
    http('POST', '/rest/v1/admin_users', {'profile_id': uid, 'role_id': role, 'is_active': True},
         {'Prefer': 'return=minimal'})
    with open(CREDS, 'w') as f:
        json.dump({'email': email, 'password': password, 'id': uid}, f)
    os.chmod(CREDS, 0o600)
    print('created', email, '— credentials in', CREDS)
elif '--delete' in sys.argv:
    c = json.load(open(CREDS))
    http('DELETE', f"/rest/v1/admin_users?profile_id=eq.{c['id']}")
    http('DELETE', f"/auth/v1/admin/users/{c['id']}")
    left_admin = http('GET', f"/rest/v1/admin_users?select=id&profile_id=eq.{c['id']}")
    left_profile = http('GET', f"/rest/v1/profiles?select=id&id=eq.{c['id']}")
    os.remove(CREDS)
    print('deleted', c['email'], '| admin_users left:', len(left_admin), '| profiles left:', len(left_profile))
elif '--list' in sys.argv or '--purge' in sys.argv:
    import re
    found, page = [], 1
    while True:
        batch = (http('GET', f'/auth/v1/admin/users?page={page}&per_page=200') or {}).get('users', [])
        found += [u for u in batch if re.fullmatch(r'tmp-admin-[0-9a-f]+@modiin4u\.test', u.get('email') or '')]
        if len(batch) < 200:
            break
        page += 1
    for u in found:
        print(u['email'], '| created', (u.get('created_at') or '')[:10], '| last sign-in', (u.get('last_sign_in_at') or 'never')[:10])
    print(len(found), 'temporary admin account(s)')
    if '--purge' in sys.argv:
        for u in found:
            http('DELETE', f"/rest/v1/admin_users?profile_id=eq.{u['id']}")
            http('DELETE', f"/auth/v1/admin/users/{u['id']}")
            left = http('GET', f"/rest/v1/admin_users?select=id&profile_id=eq.{u['id']}")
            print('deleted', u['email'], '| admin_users left:', len(left))
        if os.path.exists(CREDS):
            os.remove(CREDS)
else:
    print(__doc__)
