#!/data/data/com.termux/files/usr/bin/bash

set -u

APP="$HOME/warp-endpoint-hunter"
mkdir -p "$APP"
cd "$APP" || exit 1

COMMON_DIR="$HOME/warp-endpoint-hunter-public-test"

if [ ! -f "$COMMON_DIR/warp-common.inc" ]; then
    echo "[!] Common module not found."
    exit 1
fi

. "$COMMON_DIR/warp-common.inc"

echo "══════════════════════════════════════════════════"
echo "     WARP AUTO CONFIG GENERATOR (PUBLIC)"
echo "══════════════════════════════════════════════════"
echo
echo "This script will:"
echo "  1. Check Android ARM64"
echo "  2. Check GitHub API"
echo "  3. Prepare dependencies"
echo "  4. Prepare WARPSCOUT"
echo "  5. Register a WARP account"
echo "  6. Find a working AWG endpoint"
echo "  7. Generate a configuration"
echo
echo "══════════════════════════════════════════════════"
echo

echo "[1/7] Checking architecture..."

ARCH="$(uname -m)"

if [ "$ARCH" != "aarch64" ]; then
    echo "[!] Android ARM64 is required."
    echo "[!] Current architecture: $ARCH"
    exit 1
fi

echo "[✓] Architecture: $ARCH"

echo
echo "[2/7] Checking GitHub API..."

if ! check_github_api; then
    echo "[!] GitHub API is unreachable."
    exit 1
fi

echo "[✓] GitHub API reachable."

echo
echo "[3/7] Checking dependencies..."

if ! check_common_dependencies; then
    exit 1
fi

echo "[✓] Dependencies ready."

echo
echo "[4/7] Preparing WARPSCOUT..."

WARP="$(get_warpscout)"

if [ -z "$WARP" ] || [ ! -x "$WARP" ]; then
    echo "[!] WARPSCOUT is unavailable."
    exit 1
fi

echo "[✓] WARPSCOUT: $WARP"
echo "[✓] Version: $("$WARP" version 2>/dev/null || echo unknown)"

echo
echo "[5/7] Registering WARP..."

if ! "$WARP" register; then
    echo "[!] WARP registration failed."
    exit 1
fi

echo "[✓] Registration successful."

echo
echo "[6/7] Finding the best working endpoint..."
echo "      Please wait..."

SCAN_OUTPUT="$APP/public-auto-scan.txt"

BEST_ENDPOINT="$(scan_best_endpoint "$WARP" "$SCAN_OUTPUT" || true)"

if [ -z "$BEST_ENDPOINT" ]; then
    echo
    echo "[!] No verified endpoint was found."
    echo
    echo "Last scan output:"
    cat "$SCAN_OUTPUT" 2>/dev/null || true
    rm -f "$SCAN_OUTPUT"
    exit 1
fi

echo
echo "[✓] Verified endpoint:"
echo "    $BEST_ENDPOINT"

rm -f "$SCAN_OUTPUT"

echo
echo "[7/7] Locating WARP account..."

ACC_FILE=""

for f in \
    "$APP/warpscout-account.json" \
    "$HOME/warpscout-account.json" \
    "$HOME/.config/warpscout/warpscout-account.json"
do
    if [ -f "$f" ]; then
        ACC_FILE="$f"
        break
    fi
done

if [ -z "$ACC_FILE" ]; then
    ACC_FILE="$(find "$HOME" \
        -name "warpscout-account.json" \
        -type f \
        2>/dev/null | head -n 1)"
fi

if [ -z "$ACC_FILE" ] || [ ! -f "$ACC_FILE" ]; then
    echo "[!] WARP account file was not found."
    exit 1
fi

echo "[✓] Account file found."

PRIVKEY="$(
    grep -o '"private_key"[[:space:]]*:[[:space:]]*"[^"]*' \
    "$ACC_FILE" 2>/dev/null \
    | head -n 1 \
    | cut -d'"' -f4
)"

IPV4="$(
    grep -o '"v4"[[:space:]]*:[[:space:]]*"[^"]*' \
    "$ACC_FILE" 2>/dev/null \
    | head -n 1 \
    | cut -d'"' -f4 \
    | sed 's#/32##'
)"

IPV6="$(
    grep -o '"v6"[[:space:]]*:[[:space:]]*"[^"]*' \
    "$ACC_FILE" 2>/dev/null \
    | head -n 1 \
    | cut -d'"' -f4 \
    | sed 's#/128##'
)"

if [ -z "$PRIVKEY" ]; then
    echo "[!] Could not extract WARP PrivateKey."
    exit 1
fi

if [ -z "$IPV4" ]; then
    IPV4="172.16.0.2"
fi

if [ -z "$IPV6" ]; then
    IPV6="2606:4700:110:8a4d:5ed7:91f5:4e3b:eb2d"
fi

echo
printf "Config file name [default: eze63]: "
read -r CONF_NAME

if [ -z "$CONF_NAME" ]; then
    CONF_NAME="eze63"
fi

CONF_NAME="${CONF_NAME%.conf}.conf"

# Basic filename safety.
case "$CONF_NAME" in
    ""|*"/"*|*".."*)
        echo "[!] Invalid config filename."
        exit 1
        ;;
esac

CONF_PATH="$HOME/$CONF_NAME"

cat > "$CONF_PATH" <<CONFIG
# Name = ${CONF_NAME%.conf}

[Interface]
PrivateKey = $PRIVKEY
Address = $IPV4, $IPV6
DNS = 1.1.1.1, 2606:4700:4700::1111, 1.0.0.1, 2606:4700:4700::1001
Jc = 120
Jmin = 23
Jmax = 911
S1 = 0
S2 = 0
H1 = 1
H2 = 2
H3 = 3
H4 = 4

[Peer]
PublicKey = bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
Endpoint = $BEST_ENDPOINT
AllowedIPs = 0.0.0.0/1, 128.0.0.0/1, ::/1, 8000::/1
CONFIG

chmod 600 "$CONF_PATH"

echo
echo "══════════════════════════════════════════════════"
echo "          CONFIGURATION GENERATED"
echo "══════════════════════════════════════════════════"
echo
echo "File:"
echo "$CONF_PATH"
echo
echo "Endpoint:"
echo "$BEST_ENDPOINT"
echo
echo "PrivateKey is intentionally not printed."
echo
echo "══════════════════════════════════════════════════"
