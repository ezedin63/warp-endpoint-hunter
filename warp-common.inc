# WARPscout common functions

WARP_VERSION="v0.14.0"
WARP_API="https://api.github.com/repos/vernette/warpscout/releases/tags/${WARP_VERSION}"
WARP_ARCHIVE_NAME="warpscout_0.14.0_android_arm64.tar.gz"

find_warpscout() {
    if command -v warpscout >/dev/null 2>&1; then
        command -v warpscout
        return 0
    fi

    if [ -x "$HOME/bin/warpscout" ]; then
        echo "$HOME/bin/warpscout"
        return 0
    fi

    if [ -x "$HOME/warp-endpoint-hunter/warpscout" ]; then
        echo "$HOME/warp-endpoint-hunter/warpscout"
        return 0
    fi

    return 1
}

install_warpscout() {
    local APP="${1:-$HOME/warp-endpoint-hunter}"
    local ARCHIVE="$APP/$WARP_ARCHIVE_NAME"
    local URL

    echo
    echo "[+] WARPSCOUT is not installed."
    echo "[+] Installing official Android ARM64 release: $WARP_VERSION"
    echo

    URL="$(curl -4 -fsSL \
        --connect-timeout 10 \
        --max-time 30 \
        -H "Accept: application/vnd.github+json" \
        -H "User-Agent: warp-endpoint-hunter" \
        "$WARP_API" 2>/dev/null \
        | grep -Eo 'https://github\.com/vernette/warpscout/releases/download/[^"]+/warpscout_0\.14\.0_android_arm64\.tar\.gz' \
        | head -n 1)"

    if [ -z "$URL" ]; then
        echo "[!] Could not obtain the Android ARM64 release URL."
        return 1
    fi

    echo "[+] Downloading official release..."

    if ! curl -4 -fL \
        --connect-timeout 15 \
        --max-time 180 \
        "$URL" \
        -o "$ARCHIVE"; then
        echo "[!] WARPSCOUT download failed."
        rm -f "$ARCHIVE"
        return 1
    fi

    mkdir -p "$APP"

    if ! tar -xzf "$ARCHIVE" -C "$APP"; then
        echo "[!] Failed to extract WARPSCOUT."
        rm -f "$ARCHIVE"
        return 1
    fi

    rm -f "$ARCHIVE"

    if [ ! -f "$APP/warpscout" ]; then
        echo "[!] warpscout binary was not found after extraction."
        return 1
    fi

    chmod +x "$APP/warpscout"

    echo "[✓] WARPSCOUT installed:"
    echo "$APP/warpscout"

    return 0
}

get_warpscout() {
    local APP="${1:-$HOME/warp-endpoint-hunter}"
    local WARP

    if WARP="$(find_warpscout 2>/dev/null)"; then
        echo "$WARP"
        return 0
    fi

    if ! install_warpscout "$APP"; then
        return 1
    fi

    if WARP="$(find_warpscout 2>/dev/null)"; then
        echo "$WARP"
        return 0
    fi

    return 1
}

check_common_dependencies() {
    local missing=0

    for CMD in curl tar grep awk sed head; do
        if ! command -v "$CMD" >/dev/null 2>&1; then
            echo "[!] Missing command: $CMD"
            missing=1
        fi
    done

    if [ "$missing" -ne 0 ]; then
        echo
        echo "[+] Installing required Termux packages..."

        if ! pkg install -y curl tar grep gawk sed >/dev/null 2>&1; then
            echo "[!] Failed to install dependencies."
            return 1
        fi
    fi

    return 0
}

check_github_api() {
    curl -4 -fsS \
        --connect-timeout 8 \
        --max-time 15 \
        -H "User-Agent: warp-endpoint-hunter" \
        https://api.github.com >/dev/null 2>&1
}

scan_best_endpoint() {
    local WARP="$1"
    local OUT="$2"
    local ENDPOINT=""

    rm -f "$OUT"

    if ! "$WARP" scan \
        -p awg \
        -P \
        -tun-ping-count 10 \
        -jt 8 \
        -best >"$OUT" 2>&1; then
        return 1
    fi

    # WARPSCOUT may print the best verified endpoint either:
    #   1) as a standalone IP:PORT line
    #   2) at the beginning of a result/table line.
    #
    # Extract only IPv4:PORT candidates and ignore unrelated text.
    ENDPOINT="$(
        grep -Eo \
        '(^|[[:space:]])[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+([[:space:]]|$)' \
        "$OUT" 2>/dev/null \
        | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' \
        | head -n 1
    )"

    if [ -z "$ENDPOINT" ]; then
        return 1
    fi

    printf '%s\n' "$ENDPOINT"
    return 0
}
