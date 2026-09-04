#!/data/data/com.termux/files/usr/bin/bash

URL="https://raw.githubusercontent.com/ezedin63/warp-endpoint-hunter/main/warp-endpoint-hunter.sh"
FILE="$PREFIX/tmp/warp-endpoint-hunter.sh"

mkdir -p "$PREFIX/tmp"

if ! curl -fsSL "$URL" -o "$FILE"; then
    echo "Failed to download WARP Endpoint Hunter."
    exit 1
fi

chmod +x "$FILE"

exec bash "$FILE" </dev/tty
