#!/usr/bin/env python3
"""Finds wording that says almost, but not quite, the same thing twice.

Checks both languages. The English half drifted in 36 places and the Hebrew
half in a further 24 — which matters more, because Hebrew is what the
residents read.

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
  - a web page opens with a heading that invites ("גלו מבצעים לפי קטגוריה")
    where the phone has a compact section header ("מבצעים לפי קטגוריה")
  - two cards that are genuinely different one letter apart: הרשאות
    (permissions) against התראות (notifications)

    python3 tool/copy_drift.py           # both languages
    python3 tool/copy_drift.py he        # Hebrew only
"""

import difflib
import glob
import json
import os
import re
import sys

CUTOFF = 0.82

# `_t('english', 'hebrew')` — one pattern per half, so either can be read.
_EN = r"_t\(\s*(['\"])((?:\\.|(?!\1).)*)\1"
_HE = _EN + r"\s*,\s*(['\"])((?:\\.|(?!\3).)*)\3"

LANGS = {
    'en': ('lib/l10n/app_en.arb', _EN, 2, r'[A-Za-z]'),
    'he': ('lib/l10n/app_he.arb', _HE, 4, r'[\u0590-\u05FF]'),
}


def arb_strings(path):
    d = json.load(open(path))
    return {k: v for k, v in d.items() if not k.startswith('@') and isinstance(v, str)}


def web_strings(path, pattern, group, script):
    """One half of every _t() call, ignoring the very short."""
    s = open(path).read()
    out = set()
    for m in re.finditer(pattern, s):
        t = m.group(group).strip()
        if len(t) >= 4 and re.search(script, t):
            out.add(t)
    return out


def twin_strings(path, arb):
    """What the phone screen says, reached through the keys it uses."""
    s = open(path).read()
    keys = set(re.findall(r'\bl\.([a-zA-Z][a-zA-Z0-9]*)', s))
    return {arb[k] for k in keys if k in arb}


def run(lang):
    arb_path, pattern, group, script = LANGS[lang]
    arb = arb_strings(arb_path)
    found = 0
    for f in sorted(glob.glob('lib/features/**/web_*.dart', recursive=True)):
        twin = os.path.join(os.path.dirname(f), os.path.basename(f)[4:])
        if not os.path.exists(twin):
            continue
        phone = twin_strings(twin, arb)
        for w in sorted(web_strings(f, pattern, group, script)):
            if w in phone:
                continue
            near = difflib.get_close_matches(w, phone, n=1, cutoff=CUTOFF)
            if near:
                found += 1
                print(f'{os.path.basename(f)}')
                print(f'    web   : {w}')
                print(f'    phone : {near[0]}')
    print(f'{found} near-matches in {lang}.\n')
    return found


def main():
    langs = sys.argv[1:] or list(LANGS)
    total = sum(run(l) for l in langs)
    print(f'{total} in all. Settle each against the Figma frame; where Figma')
    print('is silent, the web moves onto the ARB value.')


if __name__ == '__main__':
    main()
