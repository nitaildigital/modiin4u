#!/usr/bin/env python3
"""Deploys the push sender and gives it its secrets.

    python3 tool/setup_push.py --service-account firebase-service-account.json
    python3 tool/setup_push.py --service-account … --site-url https://app.modiin4u.co.il

Three things, each safe to repeat:

1. A fresh random `push_dispatch_secret` in the database's vault — the header
   pg_cron sends when it calls the function (migration 00045).
2. The function's environment: the same secret, the Firebase service
   account's JSON key (FCM_SERVICE_ACCOUNT), and SITE_URL, where a browser
   notification opens.
3. supabase/functions/push-dispatch, deployed with JWT checking off.

Everything goes through Supabase's management API with the
SUPABASE_ACCESS_TOKEN in .env.local, so no Supabase CLI is needed. Nothing
secret is printed. The service-account file is gitignored; keep it outside
the repository or under that name.
"""

import argparse
import json
import secrets
import sys
import urllib.error
import urllib.request
import uuid

from run_migrations import env

FUNCTION = "push-dispatch"


def api(values, method, path, body=None, content_type="application/json"):
    ref = values["SUPABASE_URL"].split("//", 1)[1].split(".", 1)[0]
    data = body if isinstance(body, bytes) or body is None else json.dumps(body).encode()
    request = urllib.request.Request(
        f"https://api.supabase.com/v1/projects/{ref}{path}",
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {values['SUPABASE_ACCESS_TOKEN']}",
            "Content-Type": content_type,
            # Cloudflare turns away urllib's own user agent.
            "User-Agent": "modiin4u-setup-push",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            raw = response.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        sys.exit(f"{method} {path}: {e.code} {e.read().decode(errors='replace')[:500]}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--service-account", required=True,
                        help="Firebase service-account JSON key file")
    parser.add_argument("--site-url", default="https://45-93-94-49.sslip.io",
                        help="the website's https address, no trailing slash")
    args = parser.parse_args()

    values = env()
    with open(args.service_account, encoding="utf-8") as f:
        account = f.read()
    parsed = json.loads(account)
    for key in ("project_id", "client_email", "private_key"):
        if key not in parsed:
            sys.exit(f"{args.service_account} is not a service-account key: no {key}")

    # A hex token needs no quoting inside the SQL below.
    secret = secrets.token_hex(32)

    print("1. vault: push_dispatch_secret")
    api(values, "POST", "/database/query", {"query": f"""
        do $$
        declare
          existing uuid;
        begin
          select id into existing from vault.secrets where name = 'push_dispatch_secret';
          if existing is null then
            perform vault.create_secret('{secret}', 'push_dispatch_secret',
              'Header pg_cron sends to the push-dispatch function');
          else
            perform vault.update_secret(existing, '{secret}');
          end if;
        end $$;
    """})

    print("2. function environment: PUSH_DISPATCH_SECRET, FCM_SERVICE_ACCOUNT, SITE_URL")
    api(values, "POST", "/secrets", [
        {"name": "PUSH_DISPATCH_SECRET", "value": secret},
        {"name": "FCM_SERVICE_ACCOUNT", "value": account},
        {"name": "SITE_URL", "value": args.site_url.rstrip("/")},
    ])

    print(f"3. deploy {FUNCTION}")
    with open(f"supabase/functions/{FUNCTION}/index.ts", "rb") as f:
        source = f.read()
    metadata = {"name": FUNCTION, "entrypoint_path": "index.ts", "verify_jwt": False}
    boundary = uuid.uuid4().hex
    body = (
        f"--{boundary}\r\n"
        'Content-Disposition: form-data; name="metadata"\r\n'
        "Content-Type: application/json\r\n\r\n"
        f"{json.dumps(metadata)}\r\n"
        f"--{boundary}\r\n"
        'Content-Disposition: form-data; name="file"; filename="index.ts"\r\n'
        "Content-Type: application/typescript\r\n\r\n"
    ).encode() + source + f"\r\n--{boundary}--\r\n".encode()
    result = api(values, "POST", f"/functions/deploy?slug={FUNCTION}", body,
                 content_type=f"multipart/form-data; boundary={boundary}")
    print(f"   deployed, version {result.get('version') if result else '?'}")
    print(f"\nFirebase project: {parsed['project_id']}. Due campaigns go out within a minute.")


if __name__ == "__main__":
    main()
