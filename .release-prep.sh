#!/bin/bash
# lazysite-layouts v0.3.0 release prep (LL-SM001..006).
#
# Run AFTER Stuart rsyncs CC's working tree onto the canonical repo.
# Idempotent per CLAUDE.md rules.
#
# What needs commit-side handling:
#
#   1. The directory reshape dropped top-level dark/ default/ manager/
#      and created layouts/default/ with nested themes/. After rsync
#      --delete, the old dirs are gone from the working tree but git
#      still has them indexed. git add -A picks up both the deletions
#      and the additions; git auto-detects renames at diff/log display.
#
#   2. releases/ restructured: the old flat zips at
#      releases/{dark,default,manager}.zip are gone. New layout-nested
#      zips live at releases/default/{default,dark}.zip (mirrors source
#      structure so future layouts don't collide). manager.zip has no
#      successor - the manager theme was dropped per LL-SM005.
#
#   3. docs/creating-views.md deleted; docs/creating-themes.md and
#      docs/creating-layouts.md added. Content differs substantially
#      from the old doc, so rename detection may or may not fire at
#      git display time - either way the indexed history on the
#      branch is preserved.

set -e

cd "$(dirname "$0")"

# --- stage everything ---
# Covers: layouts/ (new tree), docs/ (new + deleted), releases/ (rebuilt),
# tools/package-themes.sh (rewritten), README.md (rewritten), and the
# deletion of the old top-level dark/ default/ manager/ directories.
git add -A

# --- sanity check: the three old theme dirs must NOT be staged ---
# If any lingering files remain, they were put back by something
# unexpected; bail before committing garbage.
for stale in dark default manager; do
    if git -C . ls-files "$stale/" 2>/dev/null | grep -q .; then
        echo "ERROR: $stale/ files still tracked after reshape" >&2
        echo "       Run 'git ls-files $stale/' to inspect" >&2
        exit 1
    fi
done

# --- confirm the new tree is staged correctly ---
for required in \
    layouts/default/layout.tt \
    layouts/default/layout.json \
    layouts/default/themes/default/theme.json \
    layouts/default/themes/default/assets/main.css \
    layouts/default/themes/dark/theme.json \
    layouts/default/themes/dark/assets/main.css \
    docs/creating-themes.md \
    docs/creating-layouts.md \
    tools/package-themes.sh \
    releases/default/default.zip \
    releases/default/dark.zip \
    README.md
do
    if ! git ls-files --error-unmatch "$required" >/dev/null 2>&1; then
        echo "ERROR: required file not tracked: $required" >&2
        exit 1
    fi
done

echo "release-prep: working tree staged for v0.3.0 commit"
