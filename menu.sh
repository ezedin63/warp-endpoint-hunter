#!/data/data/com.termux/files/usr/bin/bash

REPO="https://raw.githubusercontent.com/ezedin63/warp-endpoint-hunter/main"

while true; do

    clear

    echo "=============================================="
    echo "        WARP ENDPOINT HUNTER"
    echo "=============================================="
    echo
    echo "[1] WARP Endpoint Hunter"
    echo "[2] WARP Auto Config"
    echo "[0] Exit"
    echo
    printf "Select an option: "
    read -r CHOICE

    case "$CHOICE" in

        1)
            echo
            echo "[+] Starting WARP Endpoint Hunter..."
            echo
            curl -fsSL "$REPO/warp-endpoint-hunter.sh" | bash
            echo
            printf "Press Enter to return to menu..."
            read -r
            ;;

        2)
            echo
            echo "[+] Starting WARP Auto Config..."
            echo
            curl -fsSL "$REPO/warp-auto-config.sh" | bash
            echo
            printf "Press Enter to return to menu..."
            read -r
            ;;

        0)
            echo
            echo "[✓] Exit."
            exit 0
            ;;

        *)
            echo
            echo "[!] Invalid option."
            sleep 1
            ;;

    esac

done
