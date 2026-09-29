"""A temporary super_admin, for testing the management panel.

  python3 tool/tmp_admin.py --create   # a new admin with a random password
  python3 tool/tmp_admin.py --delete   # removes it again, and says what is left

Testing the panel needs someone who can sign in to it, and borrowing a real
administrator's account means acting as them. This makes a throwaway one: an
address at .test, a random password, the super_admin role. The e-mail and
password are written to a file in the system's temporary folder (mode 600),
never printed, so a test script can read them without them appearing in a
terminal or a log. Delete the admin when the test is done — the script checks
that nothing of it remains.

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
else:
    print(__doc__)
