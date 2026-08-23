#!/data/data/com.termux/files/usr/bin/bash

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
read -r OPTION

case "$OPTION" in

    1)
        echo
        echo "[+] Starting WARP Endpoint Hunter..."
        echo

        curl -fsSL \
        https://raw.githubusercontent.com/ezedin63/warp-endpoint-hunter/main/warp-endpoint-hunter.sh \
        | bash
        ;;

    2)
        echo
        echo "[+] Starting WARP Auto Config..."
        echo

        curl -fsSL \
        https://raw.githubusercontent.com/ezedin63/warp-endpoint-hunter/main/warp-auto-config.sh \
        | bash
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
