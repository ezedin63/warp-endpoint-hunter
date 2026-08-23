#!/data/data/com.termux/files/usr/bin/bash

set -u

APP="$HOME/warp-endpoint-hunter"
mkdir -p "$APP"
cd "$APP" || exit 1

echo "=============================================="
echo "       WARP ENDPOINT HUNTER"
echo "=============================================="
echo

ARCH="$(uname -m)"

if [ "$ARCH" != "aarch64" ]; then
    echo "[!] This version is designed for ARM64."
    echo "[!] Device architecture: $ARCH"
    exit 1
fi

echo "[✓] Architecture: $ARCH"

# ------------------------------------------------
# Check Internet WITHOUT VPN
# ------------------------------------------------

echo
echo "[+] Checking direct internet connection..."

if curl -4 -fsS --connect-timeout 5 https://raw.githubusercontent.com >/dev/null 2>&1; then
    echo "[✓] GitHub is reachable."
else
    echo "[!] GitHub is not reachable."
    echo "[!] Please check your internet connection or DNS settings."
    exit 1
fi

# ------------------------------------------------
# Check required commands
# ------------------------------------------------

need_install=0

for CMD in curl tar unzip; do
    if ! command -v "$CMD" >/dev/null 2>&1; then
        need_install=1
    fi
done

# ------------------------------------------------
# Install packages ONLY if missing
# ------------------------------------------------

if [ "$need_install" -eq 1 ]; then

    echo
    echo "[+] Some required tools are missing."
    echo "[+] Attempting to install them..."

    if ! pkg install -y curl tar unzip; then
        echo
        echo "[!] Failed to install required tools."
        echo
        echo "If you see an error related to packages-cf.termux.dev:"
        echo
        echo "Run: termux-change-repo"
        echo
        echo "Then select a different Main repository mirror."
        exit 1
    fi

else
    echo "[✓] Required tools are already installed."
fi

# ------------------------------------------------
# Locate / Install WARPSCOUT
# ------------------------------------------------

if command -v warpscout >/dev/null 2>&1; then

    WARP="$(command -v warpscout)"
    echo
    echo "[✓] WARPSCOUT is already installed:"
    echo "$WARP"

else

    echo
    echo "[+] Installing WARPSCOUT..."

    INSTALLER="$APP/warpscout-install.sh"

    if ! curl -4 -fsSL \
        --connect-timeout 10 \
        --max-time 60 \
        https://raw.githubusercontent.com/vernette/warpscout/master/install.sh \
        -o "$INSTALLER"; then

        echo "[-] Failed to download the installer."
        exit 1
    fi

    chmod +x "$INSTALLER"

    if ! sh "$INSTALLER"; then
        echo "[-] WARPSCOUT installation failed."
        exit 1
    fi

    if command -v warpscout >/dev/null 2>&1; then
        WARP="$(command -v warpscout)"
    elif [ -x "$HOME/bin/warpscout" ]; then
        WARP="$HOME/bin/warpscout"
    elif [ -x "$APP/warpscout" ]; then
        WARP="$APP/warpscout"
    else
        echo "[-] WARPSCOUT was not found after installation."
        exit 1
    fi

fi

echo
echo "[✓] Scanner:"
echo "$WARP"

# ------------------------------------------------
# Register
# ------------------------------------------------

echo
echo "=============================================="
echo "             WARP REGISTER"
echo "=============================================="
echo

if ! "$WARP" register; then
    echo
    echo "[-] WARP registration failed."
    exit 1
fi

# ------------------------------------------------
# Scan
# ------------------------------------------------

echo
echo "=============================================="
echo "       SCANNING AMNEZIAWG ENDPOINTS"
echo "=============================================="
echo

"$WARP" scan \
    -p awg \
    -P \
    -tun-ping-count 10 \
    -jt 8

# ------------------------------------------------
# Best endpoints
# ------------------------------------------------

echo
echo "=============================================="
echo "             TOP ENDPOINTS"
echo "=============================================="
echo

"$WARP" scan \
    -p awg \
    -P \
    -tun-ping-count 10 \
    -jt 8 \
    -best

echo
echo "=============================================="
echo "              SCAN COMPLETE"
echo "=============================================="
echo
echo "[✓] Scan completed."
echo
