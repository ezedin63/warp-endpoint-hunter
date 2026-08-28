#!/data/data/com.termux/files/usr/bin/bash

set -u

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
APP="$HOME/warp-endpoint-hunter"
mkdir -p "$APP"
cd "$APP" || exit 1

COMMON_DIR="$SCRIPT_DIR"

if [ ! -f "$COMMON_DIR/warp-common.inc" ]; then
    echo "[!] Common module not found."
    exit 1
fi

. "$COMMON_DIR/warp-common.inc"

echo "=============================================="
echo "       WARP ENDPOINT HUNTER"
echo "=============================================="
echo

ARCH="$(uname -m)"

if [ "$ARCH" != "aarch64" ]; then
    echo "[!] This Public Release supports Android ARM64."
    echo "[!] Current architecture: $ARCH"
    exit 1
fi

echo "[✓] Architecture: $ARCH"

echo
echo "[+] Checking direct internet connection..."

if check_github_api; then
    echo "[✓] GitHub API is reachable."
else
    echo "[!] GitHub API is not reachable."
    echo "[!] A VPN is not required, but direct GitHub API access is."
    exit 1
fi

echo
echo "[+] Checking dependencies..."

if ! check_common_dependencies; then
    exit 1
fi

echo "[✓] Dependencies are ready."

echo
echo "[+] Checking WARPSCOUT..."

WARP="$(get_warpscout)"

if [ -z "$WARP" ] || [ ! -x "$WARP" ]; then
    echo "[!] WARPSCOUT could not be installed or located."
    exit 1
fi

echo "[✓] WARPSCOUT:"
echo "$WARP"

echo
echo "[✓] WARPSCOUT version:"
"$WARP" version || true

echo
echo "=============================================="
echo "             WARP REGISTER"
echo "=============================================="
echo

if ! "$WARP" register; then
    echo "[!] WARP registration failed."
    exit 1
fi

echo
echo "=============================================="
echo "       SCANNING AMNEZIAWG ENDPOINTS"
echo "=============================================="
echo

REPORT="$APP/public-hunter-scan.txt"

if ! "$WARP" scan \
    -p awg \
    -P \
    -tun-ping-count 10 \
    -jt 8 >"$REPORT" 2>&1; then

    echo "[!] AWG scan failed."
    cat "$REPORT"
    rm -f "$REPORT"
    exit 1
fi

cat "$REPORT"

echo
echo "=============================================="
echo "              SCAN COMPLETE"
echo "=============================================="
echo

echo "[✓] Scan completed."
echo "[✓] Report: $REPORT"
