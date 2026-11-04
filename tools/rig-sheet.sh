#!/bin/bash
# rig-sheet.sh - contact sheets from the screenshots rig-measure.py took.
#   rig-sheet.sh <rig-dir>
# Writes <rig-dir>/sheet-1280-light.png, sheet-1280-dark.png, sheet-390-light.png.
set -eu
RIG="$1"
cd "$RIG/shots"
for V in 1280-light 1280-dark 390-light; do
    case "$V" in 1280-*) TILE=7; GEOM=360x252+6+6 ;; *) TILE=12; GEOM=150x324+6+6 ;; esac
    FILES="$(ls ./*--"$V".png)"
    # shellcheck disable=SC2086
    montage -label '%t' -pointsize 11 -tile "${TILE}x" -geometry "$GEOM" -background '#888' -fill white $FILES "$RIG/sheet-$V.png"
    echo "sheet: $RIG/sheet-$V.png"
done
