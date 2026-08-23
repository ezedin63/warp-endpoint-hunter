#!/data/data/com.termux/files/usr/bin/bash
# WARP Auto Config Generator - با نام پیش‌فرض eze63

set -u

APP="$HOME/warp-endpoint-hunter"
mkdir -p "$APP"
cd "$APP" || exit 1

echo "══════════════════════════════════════════════════"
echo "     WARP AUTO CONFIG GENERATOR (TERMUX)"
echo "══════════════════════════════════════════════════"
echo
echo "📋 This script will automatically:"
echo "   1. Prepare the environment"
echo "   2. Register with WARP"
echo "   3. Find the best endpoint"
echo "   4. Generate the final config"
echo
echo "══════════════════════════════════════════════════"
echo

echo "🔍 Step 1/7: Checking device architecture..."
ARCH="$(uname -m)"

if [ "$ARCH" != "aarch64" ]; then
    echo "❌ Error: This script is designed only for ARM64."
    echo "   Current architecture: $ARCH"
    exit 1
fi

echo "✅ Architecture: $ARCH (supported)"
echo

echo "🌐 Step 2/7: Checking internet connection..."

if curl -4 -fsS --connect-timeout 5 \
    https://raw.githubusercontent.com >/dev/null 2>&1; then
    echo "✅ GitHub is reachable."
else
    echo "❌ Error: Cannot reach GitHub."
    echo "   Please check your internet connection or DNS settings."
    exit 1
fi

echo

echo "📦 Step 3/7: Checking and installing dependencies..."

need_install=0

for CMD in curl tar unzip; do
    if ! command -v "$CMD" >/dev/null 2>&1; then
        need_install=1
        break
    fi
done

if [ "$need_install" -eq 1 ]; then
    echo "   ⏳ Installing required tools..."

    if ! pkg install -y curl tar unzip >/dev/null 2>&1; then
        echo "❌ Error: Failed to install required tools."
        echo "   Please run: termux-change-repo"
        exit 1
    fi

    echo "✅ Required tools installed."
else
    echo "✅ All dependencies are already installed."
fi

echo

echo "🔧 Step 4/7: Installing and setting up WARPSCOUT..."

if command -v warpscout >/dev/null 2>&1; then

    WARP="$(command -v warpscout)"
    echo "✅ WARPSCOUT is already installed: $WARP"

else

    echo "   ⏳ Downloading and installing WARPSCOUT..."

    INSTALLER="$APP/warpscout-install.sh"

    if ! curl -4 -fsSL \
        --connect-timeout 10 \
        --max-time 60 \
        https://raw.githubusercontent.com/vernette/warpscout/master/install.sh \
        -o "$INSTALLER"; then

        echo "❌ Error: Failed to download the installer."
        exit 1
    fi

    chmod +x "$INSTALLER"

    if ! sh "$INSTALLER"; then
        echo "❌ Error: WARPSCOUT installation failed."
        exit 1
    fi

    if command -v warpscout >/dev/null 2>&1; then
        WARP="$(command -v warpscout)"
    elif [ -x "$HOME/bin/warpscout" ]; then
        WARP="$HOME/bin/warpscout"
    elif [ -x "$APP/warpscout" ]; then
        WARP="$APP/warpscout"
    else
        echo "❌ Error: WARPSCOUT not found after installation."
        exit 1
    fi

    echo "✅ WARPSCOUT successfully installed: $WARP"
fi

echo

echo "🔑 Step 5/7: Registering with WARP..."

if ! "$WARP" register; then
    echo "❌ Error: WARP registration failed."
    exit 1
fi

echo "✅ Registration successful."
echo

echo "📂 Step 6/7: Locating account information..."

ACC_FILE=""

for f in \
    "$APP/warpscout-account.json" \
    "$HOME/warpscout-account.json" \
    "$APP/warpscout-account.json" \
    "$HOME/.config/warpscout/warpscout-account.json"
do
    if [ -f "$f" ]; then
        ACC_FILE="$f"
        break
    fi
done

if [ -z "$ACC_FILE" ]; then
    echo "   ⏳ Searching for account file..."
    ACC_FILE="$(find "$HOME" \
        -name "warpscout-account.json" \
        2>/dev/null | head -n 1)"
fi

if [ -z "$ACC_FILE" ] || [ ! -f "$ACC_FILE" ]; then
    echo "❌ Error: Account file not found."
    echo "   Please run: warpscout register"
    exit 1
fi

echo "✅ Account file found: $ACC_FILE"
echo

echo "   ⏳ Extracting PrivateKey and IPs..."

PRIVKEY="$(grep -o '"private_key": *"[^"]*' \
    "$ACC_FILE" 2>/dev/null | cut -d'"' -f4)"

IPV4="$(grep -o '"v4": *"[^"]*' \
    "$ACC_FILE" 2>/dev/null | cut -d'"' -f4 | sed 's/\/32//')"

IPV6="$(grep -o '"v6": *"[^"]*' \
    "$ACC_FILE" 2>/dev/null | cut -d'"' -f4 | sed 's/\/128//')"

if [ -z "$IPV4" ]; then
    IPV4="172.16.0.2"
fi

if [ -z "$IPV6" ]; then
    IPV6="2606:4700:110:8a4d:5ed7:91f5:4e3b:eb2d"
fi

if [ -z "$PRIVKEY" ]; then
    echo "❌ Error: Failed to extract PrivateKey."
    exit 1
fi

echo "✅ PrivateKey and IPs extracted successfully."
echo

echo "🔍 Step 7/7: Scanning for the best endpoint..."
echo "   ⏳ Please wait..."

SCAN_OUTPUT="$APP/scan_result.tmp"

if ! "$WARP" scan \
    -p awg \
    -P \
    -tun-ping-count 10 \
    -jt 8 \
    -best > "$SCAN_OUTPUT" 2>&1; then

    echo "❌ WARP scan failed."
    echo
    cat "$SCAN_OUTPUT"
    rm -f "$SCAN_OUTPUT"
    exit 1
fi

BEST_ENDPOINT="$(grep -Eo \
    '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' \
    "$SCAN_OUTPUT" | head -n 1)"

if [ -z "$BEST_ENDPOINT" ]; then
    echo "❌ Could not find a working endpoint."
    echo
    cat "$SCAN_OUTPUT"
    rm -f "$SCAN_OUTPUT"
    exit 1
fi

echo "✅ Best endpoint found: $BEST_ENDPOINT"

rm -f "$SCAN_OUTPUT"

echo

echo "📝 Enter config file name [default: eze63]:"
read -r CONF_NAME

if [ -z "$CONF_NAME" ]; then
    CONF_NAME="eze63"
fi

if [[ ! "$CONF_NAME" =~ \.conf$ ]]; then
    CONF_NAME="${CONF_NAME}.conf"
fi

CONF_PATH="$HOME/$CONF_NAME"

echo "✅ Config will be saved as: $CONF_PATH"
echo

echo "📝 Generating configuration..."

cat > "$CONF_PATH" <<CONFIG
# Name = $(basename "$CONF_NAME" .conf)

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

echo "✅ Configuration generated successfully."
echo

echo "══════════════════════════════════════════════════"
echo "          YOUR FINAL CONFIGURATION"
echo "══════════════════════════════════════════════════"
echo

cat "$CONF_PATH"

echo

echo "══════════════════════════════════════════════════"
echo "✅ Script completed successfully!"
echo "📁 Config file saved to:"
echo "   $CONF_PATH"
echo "🌐 Best endpoint used: $BEST_ENDPOINT"
echo "══════════════════════════════════════════════════"

