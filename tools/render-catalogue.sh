#!/bin/bash
# render-catalogue.sh - rebuild the measurement rig and re-measure the whole
# catalogue in one command.
#
#   tools/render-catalogue.sh [--out FILE.md] [--rig DIR]
#
# Builds a local lazysite site (every layout installed, every theme's assets
# mirrored as a pack carries them, the design-kit specimen and the form in
# steps pinned per layout and theme), serves it with the engine's standalone
# dev server on 127.0.0.1:8097, drives headless Chromium on 127.0.0.1:9333 at
# 390 and 1280 in light and dark, runs `lzs-design-kit.sh check` on each theme
# folder, and writes the report. Stops the server and the browser at the end.
#
# Environment:
#   RIG_PORT  port for the dev server (default 8097)
#   RIG_CDP   port for Chromium's remote debugging (default 9333)
# Each port must be free when the script starts; if either already answers,
# the script stops with an error rather than measure whoever is listening.
# Use other values to run beside another rig, for example
#   RIG_PORT=8297 RIG_CDP=9633 bash tools/render-catalogue.sh
#
# Defaults: --rig tmp/rig (gitignored), --out tmp/rig/report.md. The committed
# baseline is written with
#   tools/render-catalogue.sh --out docs/measurements/2026-11-04-catalogue-baseline.md
# so an after measurement is the same command with another --out.
#
# Reads, never edits: /srv/projects/lazysite (engine), /srv/projects/lazysite-sites/bin
# (design kit), /srv/projects/odoo/oom/lazysite-oom-dev/bin/cdp_tab.py.
# Loopback only; no other network access.
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
ENGINE=/srv/projects/lazysite
RIG="$REPO/tmp/rig"
OUT=""
while [ $# -gt 0 ]; do
    case "$1" in
        --out) OUT="$2"; shift 2 ;;
        --rig) RIG="$2"; shift 2 ;;
        *) echo "usage: $0 [--out FILE.md] [--rig DIR]" >&2; exit 2 ;;
    esac
done
[ -n "$OUT" ] || OUT="$RIG/report.md"
case "$OUT" in /*) ;; *) OUT="$REPO/$OUT" ;; esac
case "$RIG" in /*) ;; *) RIG="$REPO/$RIG" ;; esac

PORT="${RIG_PORT:-8097}"
CDP="${RIG_CDP:-9333}"
PROF="$REPO/tmp/chrome-prof"
mkdir -p "$RIG" "$REPO/tmp"

stop_all() {
    pkill -f "lazysite-server.pl --docroot $RIG/docroot" 2>/dev/null
    pkill -f "user-data-dir=$REPO/tmp/chrome-pro[f]" 2>/dev/null
    return 0
}
trap stop_all EXIT
stop_all
sleep 1

# Fail loudly if either port is taken; never measure whoever answers.
python3 -I - "$PORT" "$CDP" <<'PY'
import socket, sys
busy = []
for p in map(int, sys.argv[1:]):
    s = socket.socket()
    s.settimeout(1)
    if s.connect_ex(('127.0.0.1', p)) == 0:
        busy.append(p)
    s.close()
if busy:
    sys.exit('port(s) already in use: %s; set RIG_PORT and RIG_CDP to free ports' % ', '.join(map(str, busy)))
PY
[ $? -eq 0 ] || exit 1

set -e
bash "$REPO/tools/rig-build.sh" "$RIG"

ENGINE_VERSION="$(cat "$ENGINE/VERSION")"
ENGINE_TAG="$(git -C "$ENGINE" describe --tags 2>/dev/null || echo untagged)"

set +e
perl "$ENGINE/tools/lazysite-server.pl" --docroot "$RIG/docroot" --port "$PORT" --no-seed > "$RIG/server.log" 2>&1 &
chromium --headless=new --remote-debugging-port="$CDP" --user-data-dir="$PROF" about:blank > "$REPO/tmp/chrome.log" 2>&1 &

# Wait for both listeners (loopback only).
python3 -I - "$PORT" "$CDP" <<'PY'
import socket, sys, time
for p in map(int, sys.argv[1:]):
    for _ in range(60):
        try:
            socket.create_connection(('127.0.0.1', p), timeout=1).close(); break
        except OSError:
            time.sleep(0.5)
    else:
        sys.exit('nothing listening on %d' % p)
PY
[ $? -eq 0 ] || { echo "server or browser did not start" >&2; exit 1; }

set -e
python3 "$REPO/tools/rig-measure.py" "$RIG" --base "http://127.0.0.1:$PORT" --port "$CDP"
python3 "$REPO/tools/rig-states.py" "$RIG"
bash "$REPO/tools/rig-sheet.sh" "$RIG"

ROUTE="the engine's standalone dev server rendering the real processor, with every layout pinned per page by front matter (SM120) and the asset mirror pre-filled under lazysite-assets/. The dev server rendered every pinned layout and its mirror; the Template Toolkit fallback was not needed."
CMD="tools/render-catalogue.sh --out ${OUT#$REPO/}"
python3 "$REPO/tools/rig-report.py" "$RIG" "$OUT" "$ENGINE_VERSION ($ENGINE_TAG)" "$ROUTE" "$(date +%F)" "$CMD"
echo "contact sheets: $RIG/sheet-*.png"
