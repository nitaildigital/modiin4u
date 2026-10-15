#!/usr/bin/env python3
"""Deploys one Supabase Edge Function from supabase/functions/<name>/index.ts.

    python3 tool/deploy_function.py owner-invite            # JWT checked at the gateway
    python3 tool/deploy_function.py push-dispatch --no-verify-jwt

The same Management API call tool/setup_push.py makes for push-dispatch, for
any function: a single index.ts, no Supabase CLI needed on this Mac. A
function called by a signed-in person (owner-invite: the panel's admin)
keeps the gateway's JWT check on; one called by pg_cron with no session
(push-dispatch) turns it off and checks its own secret.

Reads SUPABASE_URL and SUPABASE_ACCESS_TOKEN from .env.local.
"""

import json
import os
import sys
import urllib.error
import urllib.request
import uuid

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def env():
    values = {}
    with open(os.path.join(ROOT, '.env.local'), encoding='utf-8') as f:
        for line in f:
            line = line.rstrip('\n')
            if line.strip() and not line.lstrip().startswith('#'):
                key, _, value = line.partition('=')
                values[key] = value
    return values


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    if not args:
        sys.exit(__doc__)
    name = args[0]
    verify = '--no-verify-jwt' not in sys.argv
    path = os.path.join(ROOT, 'supabase', 'functions', name, 'index.ts')
    source = open(path, 'rb').read()
    values = env()
    ref = values['SUPABASE_URL'].split('//', 1)[1].split('.', 1)[0]
    metadata = {'name': name, 'entrypoint_path': 'index.ts', 'verify_jwt': verify}
    boundary = uuid.uuid4().hex
    body = (
        f'--{boundary}\r\n'
        'Content-Disposition: form-data; name="metadata"\r\n'
        'Content-Type: application/json\r\n\r\n'
        f'{json.dumps(metadata)}\r\n'
        f'--{boundary}\r\n'
        'Content-Disposition: form-data; name="file"; filename="index.ts"\r\n'
        'Content-Type: application/typescript\r\n\r\n'
    ).encode() + source + f'\r\n--{boundary}--\r\n'.encode()
    request = urllib.request.Request(
        f'https://api.supabase.com/v1/projects/{ref}/functions/deploy?slug={name}',
        data=body, method='POST',
        headers={
            'Authorization': f"Bearer {values['SUPABASE_ACCESS_TOKEN']}",
            'Content-Type': f'multipart/form-data; boundary={boundary}',
            # Cloudflare turns away urllib's own user agent.
            'User-Agent': 'modiin4u-deploy-function',
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=180) as response:
            result = json.loads(response.read() or b'{}')
    except urllib.error.HTTPError as e:
        sys.exit(f'deploy {name}: {e.code} {e.read().decode(errors="replace")[:500]}')
    print(f"deployed {name}, version {result.get('version')}, verify_jwt {verify}, status {result.get('status')}")


if __name__ == '__main__':
    main()
