#!/bin/bash
# package-layouts.sh - Build installable LAYOUT zip packages + manifest.json.
#
# Companion to package-themes.sh. For each layouts/<L>/ it produces
# releases/layouts/<L>.zip containing ONLY the layout files:
#
#   layout.tt          (required, at zip root)
#   layout.json        (required, at zip root)
#
# It deliberately does NOT include themes/ - themes are packaged separately by
# package-themes.sh as releases/<L>/<T>.zip. After building the layout zips it
# regenerates manifest.json (via gen-manifest.pl) so the catalogue the processor
# reads always matches the zips on disk.
#
# Run after package-themes.sh (which clears + rebuilds releases/). Safe to run
# standalone too: it only writes releases/layouts/ and manifest.json.

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LAYOUTS_DIR="$REPO_ROOT/layouts"
RELEASES_DIR="$REPO_ROOT/releases"

[ -d "$LAYOUTS_DIR" ] || { echo "ERROR: $LAYOUTS_DIR missing" >&2; exit 1; }

if command -v zip >/dev/null 2>&1; then
    ZIPPER=zip
elif command -v python3 >/dev/null 2>&1; then
    ZIPPER=python3
else
    echo "ERROR: neither 'zip' nor 'python3' available" >&2
    exit 1
fi

mkdir -p "$RELEASES_DIR/layouts"

trap 'rm -rf /tmp/package-layouts-$$-* 2>/dev/null' EXIT

LAYOUTS_BUILT=0
for LAYOUT_DIR in "$LAYOUTS_DIR"/*/; do
    [ -d "$LAYOUT_DIR" ] || continue
    LAYOUT_NAME="$(basename "$LAYOUT_DIR")"

    if [ ! -f "$LAYOUT_DIR/layout.tt" ]; then
        echo "SKIP $LAYOUT_NAME: no layout.tt"
        continue
    fi

    echo "Packaging layout: $LAYOUT_NAME"
    TEMP_DIR="/tmp/package-layouts-$$-$LAYOUT_NAME"
    rm -rf "$TEMP_DIR"; mkdir -p "$TEMP_DIR"
    cp "$LAYOUT_DIR/layout.tt" "$TEMP_DIR/"
    [ -f "$LAYOUT_DIR/layout.json" ] && cp "$LAYOUT_DIR/layout.json" "$TEMP_DIR/"

    ZIP_FILE="$RELEASES_DIR/layouts/$LAYOUT_NAME.zip"
    rm -f "$ZIP_FILE"
    if [ "$ZIPPER" = "zip" ]; then
        ( cd "$TEMP_DIR" && zip -qr "$ZIP_FILE" . \
            -x "*.DS_Store" -x "__MACOSX/*" -x "*.swp" )
    else
        python3 - "$TEMP_DIR" "$ZIP_FILE" <<'PY'
import os, sys, zipfile
src, out = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(src):
        for f in files:
            if f == ".DS_Store" or f.endswith(".swp"):
                continue
            full = os.path.join(root, f)
            zf.write(full, os.path.relpath(full, src))
PY
    fi
    rm -rf "$TEMP_DIR"
    SIZE=$(stat -c '%s' "$ZIP_FILE")
    echo "  Built: releases/layouts/$LAYOUT_NAME.zip ($SIZE bytes)"
    LAYOUTS_BUILT=$((LAYOUTS_BUILT + 1))
done

echo ""
echo "Done: $LAYOUTS_BUILT layout(s) packaged"

# Regenerate the catalogue from what is now on disk.
perl "$REPO_ROOT/tools/gen-manifest.pl" "$REPO_ROOT"
echo "Output: $RELEASES_DIR/layouts + manifest.json"
