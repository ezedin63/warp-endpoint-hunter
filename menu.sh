#!/data/data/com.termux/files/usr/bin/bash

set -u

REPO="https://api.github.com/repos/ezedin63/warp-endpoint-hunter/contents"
TMPDIR="$PREFIX/tmp/warp-endpoint-hunter"

mkdir -p "$TMPDIR"

clear

echo "=============================================="
echo "       WARP ENDPOINT HUNTER"
echo "=============================================="
echo
echo "[1] WARP Endpoint Hunter"
echo "[2] WARP Auto Config"
echo "[0] Exit"
echo

printf "Select an option: "
read -r OPTION </dev/tty

download_file() {
    local FILE="$1"
    local OUT="$TMPDIR/$FILE"

    echo
    echo "[+] Downloading $FILE..."

    if ! curl -4 -fsSL \
        --connect-timeout 10 \
        --max-time 120 \
        -H "Accept: application/vnd.github.raw+json" \
        -H "User-Agent: warp-endpoint-hunter" \
        "$REPO/$FILE" \
        -o "$OUT"; then

        echo "[!] Failed to download $FILE"
        return 1
    fi

    if [ ! -s "$OUT" ]; then
        echo "[!] Downloaded file is empty."
        return 1
    fi

    chmod +x "$OUT"
    return 0
}

run_script() {
    local FILE="$1"

    rm -f "$TMPDIR/$FILE" "$TMPDIR/warp-common.inc"

    if ! download_file "$FILE"; then
        return 1
    fi

    if ! download_file "warp-common.inc"; then
        return 1
    fi

    echo
    echo "[✓] Required files downloaded."
    echo

    bash "$TMPDIR/$FILE"
}

case "$OPTION" in
    1)
        run_script "warp-endpoint-hunter.sh"
        ;;
    2)
        run_script "warp-auto-config.sh"
        ;;
    0)
        echo
        echo "[+] Exit."
        exit 0
        ;;
    *)
        echo
        echo "[!] Invalid option."
        exit 1
        ;;
esac
