#!/bin/bash
# package-themes.sh - Build installable zip packages for each theme
# Usage: bash tools/package-themes.sh

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RELEASES_DIR="$REPO_ROOT/releases"

mkdir -p "$RELEASES_DIR"

THEMES_BUILT=0
THEMES_FAILED=0

for THEME_DIR in "$REPO_ROOT"/*/; do
    THEME_NAME="$(basename "$THEME_DIR")"

    # Skip non-theme directories
    case "$THEME_NAME" in
        docs|tools|releases|.git) continue ;;
    esac

    echo "Processing: $THEME_NAME"

    # Verify required files
    MISSING=0
    for REQUIRED in view.tt theme.json; do
        if [ ! -f "$THEME_DIR/$REQUIRED" ]; then
            echo "  ERROR: missing $REQUIRED"
            MISSING=1
        fi
    done

    if [ "$MISSING" -eq 1 ]; then
        echo "  SKIP: $THEME_NAME (missing required files)"
        THEMES_FAILED=$((THEMES_FAILED + 1))
        continue
    fi

    # Read theme name from theme.json for validation
    if command -v python3 >/dev/null 2>&1; then
        JSON_NAME=$(python3 -c "
import json, sys
with open('$THEME_DIR/theme.json') as f:
    d = json.load(f)
print(d.get('name', ''))
" 2>/dev/null)
        if [ -z "$JSON_NAME" ]; then
            echo "  WARNING: theme.json missing 'name' field"
        elif [ "$JSON_NAME" != "$THEME_NAME" ]; then
            echo "  WARNING: theme.json name '$JSON_NAME' differs from directory '$THEME_NAME'"
        fi
    fi

    # Build zip from theme directory
    ZIP_FILE="$RELEASES_DIR/$THEME_NAME.zip"
    TEMP_DIR=$(mktemp -d)

    # Copy theme files to temp dir (flat structure as editor expects)
    cp "$THEME_DIR/view.tt"    "$TEMP_DIR/"
    cp "$THEME_DIR/theme.json" "$TEMP_DIR/"

    if [ -f "$THEME_DIR/nav.conf" ]; then
        cp "$THEME_DIR/nav.conf" "$TEMP_DIR/"
    fi

    if [ -d "$THEME_DIR/assets" ]; then
        mkdir -p "$TEMP_DIR/assets"
        cp -r "$THEME_DIR/assets/." "$TEMP_DIR/assets/"
    fi

    # Create zip (try zip command, fall back to python3)
    if command -v zip >/dev/null 2>&1; then
        (cd "$TEMP_DIR" && zip -r "$ZIP_FILE" . -x "*.DS_Store" -x "__MACOSX/*")
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "
import zipfile, os, sys
zf = zipfile.ZipFile('$ZIP_FILE', 'w', zipfile.ZIP_DEFLATED)
for root, dirs, files in os.walk('$TEMP_DIR'):
    for f in files:
        if f == '.DS_Store': continue
        full = os.path.join(root, f)
        arc = os.path.relpath(full, '$TEMP_DIR')
        zf.write(full, arc)
zf.close()
"
    else
        echo "  ERROR: no zip tool available (install zip or python3)"
        rm -rf "$TEMP_DIR"
        THEMES_FAILED=$((THEMES_FAILED + 1))
        continue
    fi
    rm -rf "$TEMP_DIR"

    SIZE=$(du -sh "$ZIP_FILE" | cut -f1)
    echo "  Built: releases/$THEME_NAME.zip ($SIZE)"
    THEMES_BUILT=$((THEMES_BUILT + 1))
done

echo ""
echo "Done: $THEMES_BUILT theme(s) built, $THEMES_FAILED failed"
echo "Output: $RELEASES_DIR/"
ls -lh "$RELEASES_DIR/"
