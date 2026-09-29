#!/usr/bin/env python3
"""Runs the pending migrations against the project, in order.

Each file is wrapped in a transaction, so one that fails leaves nothing
half-applied and the ones before it stay. `psql` is told to stop on the first
error rather than carrying on and reporting success.

The migrations are written to be safe to run more than once — `if not
exists`, `create or replace`, `drop policy if exists` — so a re-run after a
fix does not need the earlier ones undone.

    python3 tool/run_migrations.py                  # list what would run
    python3 tool/run_migrations.py --apply
    python3 tool/run_migrations.py --apply 00015    # just one
    python3 tool/run_migrations.py --apply --api 00030   # without psql

`--api` sends each file through Supabase's management API (the
SUPABASE_ACCESS_TOKEN in .env.local) instead of `psql`, for a machine that
does not have it installed. The file is wrapped in begin/commit there too,
so a failure still leaves nothing half-applied.
"""

import glob
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request


def env():
    values = {}
    with open(".env.local", encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            # Read the file directly: the shell would treat a # inside the
            # password as the start of a comment and truncate it.
            if line.strip() and not line.lstrip().startswith("#"):
                key, _, value = line.partition("=")
                values[key] = value
    return values


def run(uri: str, path: str) -> tuple[bool, str]:
    result = subprocess.run(
        [
            "psql", uri,
            "--set", "ON_ERROR_STOP=1",
            "--single-transaction",
            "--quiet",
            "--file", path,
        ],
        capture_output=True,
        text=True,
    )
    output = (result.stdout + result.stderr).strip()
    return result.returncode == 0, output


def run_api(values: dict, path: str) -> tuple[bool, str]:
    """The same as `run`, through the management API's query endpoint."""
    # https://<ref>.supabase.co — the project ref is the first label.
    ref = values["SUPABASE_URL"].split("//", 1)[1].split(".", 1)[0]
    with open(path, encoding="utf-8") as f:
        sql = f.read()
    request = urllib.request.Request(
        f"https://api.supabase.com/v1/projects/{ref}/database/query",
        data=json.dumps({"query": f"begin;\n{sql}\ncommit;"}).encode(),
        headers={
            "Authorization": f"Bearer {values['SUPABASE_ACCESS_TOKEN']}",
            "Content-Type": "application/json",
            # The API sits behind Cloudflare, which turns away urllib's own
            # user agent.
            "User-Agent": "modiin4u-migrations",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            return True, ""
    except urllib.error.HTTPError as e:
        return False, e.read().decode(errors="replace")


def main() -> None:
    apply = "--apply" in sys.argv
    only = [a for a in sys.argv[1:] if not a.startswith("--")]

    files = sorted(glob.glob("supabase/migrations/000*.sql"))
    # 00001–00013 built the schema that is already deployed.
    pending = [f for f in files if os.path.basename(f)[:5] >= "00014"]
    if only:
        pending = [f for f in pending if any(o in f for o in only)]

    if not apply:
        print("would run, in order:")
        for f in pending:
            print("  ", os.path.basename(f))
        print("\npass --apply to run them")
        return

    values = env()
    use_api = "--api" in sys.argv
    failed = []

    for path in pending:
        name = os.path.basename(path)
        print(f"\n── {name}")
        ok, output = (
            run_api(values, path) if use_api
            else run(values["SUPABASE_DB_URL"], path)
        )
        if ok:
            print("   applied")
            if output:
                for line in output.splitlines()[:6]:
                    print(f"   {line}")
        else:
            failed.append(name)
            print("   FAILED — nothing from this file was applied")
            for line in output.splitlines()[:12]:
                print(f"   {line}")
            break  # a later migration may depend on this one

    print()
    if failed:
        print(f"stopped at {failed[0]}")
        sys.exit(1)
    print(f"all {len(pending)} applied")


if __name__ == "__main__":
    main()
