#!/bin/bash
# check-no-cdn.sh - enforce the standing no-CDN policy over layouts/.
#
# Fails (exit 1) if any layout or theme makes a visitor's browser fetch an
# external resource: stylesheet/script/font/image/frame loads, CSS url() or
# @import with an absolute http(s) URL, preconnect/prefetch hints, or JS
# fetch()/import() of an http(s) literal. Plain hyperlinks (<a href="...">)
# are navigation, not resource loads, and are allowed - e.g. the mandatory
# "This is a Lazysite" footer credit.
#
# Allowlist: none. Fonts and every other asset must be bundled with the
# theme (see fonts/README.md) and served from the site itself.
#
# No network access. Wired into package-themes.sh / package-layouts.sh so a
# theme with a CDN reference cannot be packaged.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LAYOUTS_DIR="$REPO_ROOT/layouts"

[ -d "$LAYOUTS_DIR" ] || { echo "ERROR: $LAYOUTS_DIR missing" >&2; exit 2; }

# Each pattern describes an external *resource load*. Applied to every
# text file under layouts/ (templates, CSS, JS, JSON alike).
PATTERNS=(
    # HTML/TT: resource-bearing elements with an absolute URL in a
    # fetching attribute (href on <a> is deliberately not matched).
    '<(link|script|img|source|iframe|frame|video|audio|embed|object|track|use)[^>]*(href|src|srcset|data|xlink:href)[[:space:]]*=[[:space:]]*["'\'']?https?://'
    # CSS (or inline style): url(...) with an absolute URL.
    'url\([[:space:]]*["'\'']?https?://'
    # CSS @import with an absolute URL.
    '@import[^;{]*https?://'
    # Resource hints that pre-open external origins.
    'rel[[:space:]]*=[[:space:]]*["'\'']?(preconnect|dns-prefetch|preload|prefetch)["'\'']?[^>]*https?://'
    '<link[^>]*https?://[^>]*rel[[:space:]]*=[[:space:]]*["'\'']?(preconnect|dns-prefetch|preload|prefetch)'
    # JS fetching an external literal.
    '(fetch|import|XMLHttpRequest)[[:space:]]*\([[:space:]]*["'\'']https?://'
    # Known CDN / font-service hosts, in any context at all.
    '(fonts\.googleapis\.com|fonts\.gstatic\.com|cdn\.jsdelivr\.net|cdnjs\.cloudflare\.com|unpkg\.com|use\.typekit\.net|use\.fontawesome\.com)'
)

status=0
for pat in "${PATTERNS[@]}"; do
    # grep exits 1 on no match - that is the good case under set -e.
    if hits=$(grep -rIEn --binary-files=without-match -e "$pat" "$LAYOUTS_DIR"); then
        echo "CDN/external resource reference found (pattern: $pat):" >&2
        echo "$hits" >&2
        status=1
    fi
done

if [ "$status" -ne 0 ]; then
    echo "" >&2
    echo "no-CDN policy: bundle the asset with the theme instead" >&2
    echo "(fonts: see fonts/README.md + fonts.list)" >&2
else
    echo "check-no-cdn: OK - no external resource references under layouts/"
fi
exit "$status"
