#!/usr/bin/env python3
"""Finds wording that says almost, but not quite, the same thing twice.

Every `web_*` screen writes its copy inline through `_t(en, he)` instead of
reading the ARB files its phone twin reads. So each string exists twice, and
a string that exists twice drifts: the web sign-in said "Welcome Back" for
months while the phone and the design said "Hi, welcome back! 👋".

This does not fix that — the fix is moving the web screens onto the ARB, which
touches 1,204 calls across 42 files. It finds the drift, so it can be looked
at and settled against the Figma frames, which are the authority.

How it works: for each web screen with a phone twin, take the English half of
every `_t()`, take the ARB values behind every `l.something` the twin uses,
and report pairs that are close but not equal. Exact matches are fine — that
is the same sentence written twice, which is the disease, not a symptom.

Expect false positives, and read them rather than trusting the count:

  - the phone wraps a heading with \\n where the web does not
  - the web prefixes a unit ("km · Estimated distance")
  - one side interpolates ($wait) where the ARB uses a placeholder ({seconds})
  - a map pin is labelled in the singular ("Event") against a plural layer
    name ("Events")

    python3 tool/copy_drift.py
"""

import difflib
import glob
import json
import os
import re

ARB = 'lib/l10n/app_en.arb'
CUTOFF = 0.82


def arb_strings():
    d = json.load(open(ARB))
    return {k: v for k, v in d.items() if not k.startswith('@') and isinstance(v, str)}


def web_strings(path):
    """The English argument of every _t() call, ignoring the very short."""
    s = open(path).read()
    out = set()
    for m in re.finditer(r"_t\(\s*(['\"])((?:\\.|(?!\1).)*)\1", s):
        t = m.group(2).strip()
        if len(t) >= 4 and re.search(r'[A-Za-z]', t):
            out.add(t)
    return out


def twin_strings(path, arb):
    """What the phone screen says, reached through the keys it uses."""
    s = open(path).read()
    keys = set(re.findall(r'\bl\.([a-zA-Z][a-zA-Z0-9]*)', s))
    return {arb[k] for k in keys if k in arb}


def main():
    arb = arb_strings()
    found = 0
    for f in sorted(glob.glob('lib/features/**/web_*.dart', recursive=True)):
        twin = os.path.join(os.path.dirname(f), os.path.basename(f)[4:])
        if not os.path.exists(twin):
            continue
        phone = twin_strings(twin, arb)
        for w in sorted(web_strings(f)):
            if w in phone:
                continue
            near = difflib.get_close_matches(w, phone, n=1, cutoff=CUTOFF)
            if near:
                found += 1
                print(f'{os.path.basename(f)}')
                print(f'    web   : {w!r}')
                print(f'    phone : {near[0]!r}')
    print(f'\n{found} near-matches. Settle each against the Figma frame.')


if __name__ == '__main__':
    main()
