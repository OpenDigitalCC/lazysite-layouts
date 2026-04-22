#!/bin/bash
# package-themes.sh - Build installable theme zip packages for lazysite.
#
# Walks layouts/LAYOUT_NAME/themes/THEME_NAME/ and produces
# releases/LAYOUT_NAME/THEME_NAME.zip with the D013 upload shape:
#
#   theme.json         (required, at zip root)
#   assets/main.css    (required, web-accessible via theme_assets)
#   assets/fonts/...   (optional, any extra assets the theme ships)
#
# Only the assets/ subtree is served from /lazysite-assets/LAYOUT/THEME/
# on the live site; theme.json lives in the web-blocked theme dir and
# is read by the manager UI + the processor on load.
#
# Releases are cleared and rebuilt from scratch each run. Layouts are
# not packaged here - distributed by other means.

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LAYOUTS_DIR="$REPO_ROOT/layouts"
RELEASES_DIR="$REPO_ROOT/releases"

if [ ! -d "$LAYOUTS_DIR" ]; then
    echo "ERROR: $LAYOUTS_DIR does not exist" >&2
    exit 1
fi

if command -v zip >/dev/null 2>&1; then
    ZIPPER=zip
elif command -v python3 >/dev/null 2>&1; then
    ZIPPER=python3
else
    echo "ERROR: neither 'zip' nor 'python3' available" >&2
    echo "Install with: apt-get install zip  (or your package manager)" >&2
    exit 1
fi

# Rebuild releases/ from scratch so stale zips don't linger.
rm -rf "$RELEASES_DIR"
mkdir -p "$RELEASES_DIR"

THEMES_BUILT=0
THEMES_FAILED=0
TOTAL_BYTES=0

# Walk layouts/LAYOUT/themes/THEME/ - two levels deep from $LAYOUTS_DIR.
for LAYOUT_DIR in "$LAYOUTS_DIR"/*/; do
    [ -d "$LAYOUT_DIR" ] || continue
    LAYOUT_NAME="$(basename "$LAYOUT_DIR")"

    THEMES_ROOT="$LAYOUT_DIR/themes"
    [ -d "$THEMES_ROOT" ] || continue

    for THEME_DIR in "$THEMES_ROOT"/*/; do
        [ -d "$THEME_DIR" ] || continue
        THEME_NAME="$(basename "$THEME_DIR")"

        echo "Packaging: $LAYOUT_NAME/$THEME_NAME"

        if [ ! -f "$THEME_DIR/theme.json" ]; then
            echo "  SKIP: missing theme.json"
            THEMES_FAILED=$((THEMES_FAILED + 1))
            continue
        fi

        if [ ! -d "$THEME_DIR/assets" ] || [ ! -f "$THEME_DIR/assets/main.css" ]; then
            echo "  WARNING: no assets/main.css - theme will have no web-served CSS"
        fi

        # releases/LAYOUT/THEME.zip - mirrors source structure so
        # two layouts each shipping a "default" theme don't collide.
        mkdir -p "$RELEASES_DIR/$LAYOUT_NAME"
        ZIP_FILE="$RELEASES_DIR/$LAYOUT_NAME/$THEME_NAME.zip"

        # Stage zip contents in a temp dir. $$ per CLAUDE.md (no mktemp).
        TEMP_DIR="/tmp/package-themes-$$-$THEME_NAME"
        rm -rf "$TEMP_DIR"
        mkdir -p "$TEMP_DIR"

        cp "$THEME_DIR/theme.json" "$TEMP_DIR/"

        if [ -d "$THEME_DIR/assets" ]; then
            mkdir -p "$TEMP_DIR/assets"
            cp -r "$THEME_DIR/assets/." "$TEMP_DIR/assets/"
        fi

        # Build the zip. Excludes .DS_Store etc. Intentionally does
        # NOT include layout.tt, layout.json, or nav.conf - those
        # don't belong in a theme package.
        if [ "$ZIPPER" = "zip" ]; then
            ( cd "$TEMP_DIR" && zip -qr "$ZIP_FILE" . \
                -x "*.DS_Store" -x "__MACOSX/*" -x "*.swp" )
        else
            python3 - "$TEMP_DIR" "$ZIP_FILE" <<'PY'
import os, sys, zipfile
src, out = sys.argv[1], sys.argv[2]
skip_names = {".DS_Store"}
skip_prefixes = ("__MACOSX/",)
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(src):
        for f in files:
            if f in skip_names or f.endswith(".swp"):
                continue
            full = os.path.join(root, f)
            arc = os.path.relpath(full, src)
            if any(arc.startswith(p) for p in skip_prefixes):
                continue
            zf.write(full, arc)
PY
        fi

        rm -rf "$TEMP_DIR"

        SIZE=$(stat -c '%s' "$ZIP_FILE")
        TOTAL_BYTES=$((TOTAL_BYTES + SIZE))
        echo "  Built: releases/$LAYOUT_NAME/$THEME_NAME.zip ($SIZE bytes)"
        THEMES_BUILT=$((THEMES_BUILT + 1))
    done
done

trap 'rm -rf /tmp/package-themes-$$-* 2>/dev/null' EXIT

echo ""
TOTAL_KB=$((TOTAL_BYTES / 1024))
echo "Done: $THEMES_BUILT theme(s) packaged at ${TOTAL_KB}K total"
if [ "$THEMES_FAILED" -gt 0 ]; then
    echo "      $THEMES_FAILED theme(s) skipped"
fi
echo "Output: $RELEASES_DIR"
find "$RELEASES_DIR" -name '*.zip' -printf '  %p\n' | sort
