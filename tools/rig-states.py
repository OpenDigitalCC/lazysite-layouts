#!/usr/bin/env python3
"""rig-states.py - run lzs-design-kit.sh check on every theme folder of the rig.

  rig-states.py <rig-dir>

Runs offline: the check is given the theme folder only (no <site>), so the
comparison against a site's kit tokens is skipped; every other check runs. The
folder is the pack as built (theme.json + assets with fonts and favicon
injected). Writes <rig-dir>/states.json.
"""
import json, os, re, subprocess, sys

rig = sys.argv[1]
KIT = '/srv/projects/lazysite-sites/bin/lzs-design-kit.sh'
out = {}
for line in open(os.path.join(rig, 'themes.tsv')):
    if not line.strip():
        continue
    L, T = line.rstrip('\n').split('\t')
    folder = os.path.join(rig, 'check', L, T)
    r = subprocess.run(['bash', KIT, 'check', folder], capture_output=True, text=True)
    fails = [m.group(1) for l in r.stdout.splitlines() for m in [re.match(r'FAIL (.*)', l)] if m]
    warns = [m.group(1) for l in r.stdout.splitlines() for m in [re.match(r'WARN (.*)', l)] if m]
    states = [m.group(1) for f in fails for m in [re.match(r'no style for (.*) \(STATES\.md\)', f)] if m]
    other = [f for f in fails if not re.match(r'no style for .* \(STATES\.md\)', f)]
    out['%s/%s' % (L, T)] = {'rc': r.returncode, 'states': states, 'other': other, 'warns': warns}
json.dump(out, open(os.path.join(rig, 'states.json'), 'w'), indent=1)
print('states: checked %d theme folders' % len(out))
