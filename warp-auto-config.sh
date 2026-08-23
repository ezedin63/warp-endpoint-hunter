#!/data/data/com.termux/files/usr/bin/bash

set -u

APP="$HOME/warp-endpoint-hunter"
mkdir -p "$APP"
cd "$APP" || exit 1

# ------------------------------------------------
# Colors
# ------------------------------------------------

GREEN='\033[1;32m'
RESET='\033[0m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'

echo "=============================================="
echo "       WARP AUTO ENDPOINT SELECTOR"
echo "=============================================="
echo

# ------------------------------------------------
# Check architecture
# ------------------------------------------------

ARCH="$(uname -m)"

if [ "$ARCH" != "aarch64" ]; then
    echo -e "${RED}[!] ARM64 is required.${RESET}"
    echo -e "${RED}[!] Architecture: $ARCH${RESET}"
    exit 1
fi

echo -e "${GREEN}[✓] Architecture: $ARCH${RESET}"

# ------------------------------------------------
# Locate WARPSCOUT
# ------------------------------------------------

if command -v warpscout >/dev/null 2>&1; then
    WARP="$(command -v warpscout)"
elif [ -x "$HOME/bin/warpscout" ]; then
    WARP="$HOME/bin/warpscout"
elif [ -x "$APP/warpscout" ]; then
    WARP="$APP/warpscout"
else
    echo -e "${RED}[!] WARPSCOUT is not installed.${RESET}"
    exit 1
fi

echo -e "${GREEN}[✓] WARPSCOUT: $WARP${RESET}"

# ------------------------------------------------
# WARP parameters
# ------------------------------------------------

PUBKEY="bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo="

ADDRESS="172.16.0.2,2606:4700:110:8a4d:5ed7:91f5:4e3b:eb2d"

DNS="1.1.1.1,2606:4700:4700::1111,1.0.0.1,2606:4700:4700::1001"

JC="120"
JMIN="23"
JMAX="911"

S1="0"
S2="0"

H1="1"
H2="2"
H3="3"
H4="4"

ALLOWED="0.0.0.0/1,128.0.0.0/1,::/1,8000::/1"

# ------------------------------------------------
# Private Key
# ------------------------------------------------

echo
read -r -s -p "Enter WARP PrivateKey: " WGKEY
echo

if [ -z "$WGKEY" ]; then
    echo -e "${RED}[!] PrivateKey cannot be empty.${RESET}"
    exit 1
fi

# ------------------------------------------------
# Register
# ------------------------------------------------

echo
echo "=============================================="
echo "             WARP REGISTER"
echo "=============================================="
echo

if ! "$WARP" register >/dev/null 2>&1; then
    echo -e "${RED}[!] WARP registration failed.${RESET}"
    exit 1
fi

echo -e "${GREEN}[✓] WARP account ready.${RESET}"

# ------------------------------------------------
# Function: Extract results
# ------------------------------------------------

extract_results() {

    FILE="$1"

    awk '
    /│/ {

        line=$0

        if (line ~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+/) {

            gsub(/[│]/," ",line)
            gsub(/[[:space:]]+/," ",line)

            if (match(line,
                /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+/)) {

                endpoint=substr(line,RSTART,RLENGTH)

            } else {
                next
            }

            n=split(line,a," ")

            tun=""
            loss=""

            for(i=1;i<=n;i++) {

                if(a[i] ~ /^[0-9]+ms$/ && tun=="")
                    tun=a[i]

                if(a[i] ~ /^[0-9]+%$/)
                    loss=a[i]
            }

            if(tun!="" && loss!="") {

                gsub(/ms/,"",tun)
                gsub(/%/,"",loss)

                print loss "|" tun "|" endpoint
            }
        }
    }
    ' "$FILE"
}

# ------------------------------------------------
# First scan
# ------------------------------------------------

echo
echo "=============================================="
echo "             AWG SCAN #1"
echo "=============================================="
echo

SCAN1="$APP/.scan1.tmp"

"$WARP" scan \
    -p awg \
    -P \
    -tun-ping-count 15 \
    -jt 8 \
    > "$SCAN1" 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}[!] First scan failed.${RESET}"
    rm -f "$SCAN1"
    exit 1
fi

RESULT1="$APP/.results1.tmp"

extract_results "$SCAN1" > "$RESULT1"

# ------------------------------------------------
# Second scan
# ------------------------------------------------

echo
echo "=============================================="
echo "             AWG SCAN #2"
echo "=============================================="
echo

SCAN2="$APP/.scan2.tmp"

"$WARP" scan \
    -p awg \
    -P \
    -tun-ping-count 15 \
    -jt 8 \
    > "$SCAN2" 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}[!] Second scan failed.${RESET}"
    rm -f "$SCAN1" "$RESULT1" "$SCAN2"
    exit 1
fi

RESULT2="$APP/.results2.tmp"

extract_results "$SCAN2" > "$RESULT2"

# ------------------------------------------------
# Combine results
# ------------------------------------------------

COMBINED="$APP/.combined.tmp"

cat "$RESULT1" "$RESULT2" \
| sort -t'|' -k1,1n -k2,2n \
> "$COMBINED"

if [ ! -s "$COMBINED" ]; then
    echo -e "${RED}[!] No working AWG endpoints found.${RESET}"

    rm -f "$SCAN1" "$RESULT1" "$SCAN2" "$RESULT2" "$COMBINED"

    exit 1
fi

# ------------------------------------------------
# Remove duplicates
# ------------------------------------------------

FINAL="$APP/.final.tmp"

awk -F'|' '!seen[$3]++' "$COMBINED" > "$FINAL"

TOP10="$APP/.top10.tmp"

head -10 "$FINAL" > "$TOP10"

# ------------------------------------------------
# Display TOP 10 in GREEN
# ------------------------------------------------

echo
echo -e "${GREEN}==============================================${RESET}"
echo -e "${GREEN}        TOP 10 AMNEZIAWG ENDPOINTS${RESET}"
echo -e "${GREEN}==============================================${RESET}"
echo

echo -e "${GREEN}Rank  Loss     Tun-Ping   Endpoint${RESET}"
echo -e "${GREEN}----------------------------------------------${RESET}"

rank=1

while IFS='|' read -r loss ping endpoint; do

    printf "${GREEN}%-5s %-8s %-10s %s${RESET}\n" \
        "$rank" "${loss}%" "${ping}ms" "$endpoint"

    rank=$((rank+1))

done < "$TOP10"

# ------------------------------------------------
# Select best endpoint
# ------------------------------------------------

BEST="$(head -1 "$FINAL")"

FINAL_LOSS="$(echo "$BEST" | cut -d'|' -f1)"
FINAL_PING="$(echo "$BEST" | cut -d'|' -f2)"
FINAL_ENDPOINT="$(echo "$BEST" | cut -d'|' -f3)"

# ------------------------------------------------
# Display BEST endpoint in GREEN
# ------------------------------------------------

echo
echo -e "${GREEN}==============================================${RESET}"
echo -e "${GREEN}          BEST ENDPOINT SELECTED${RESET}"
echo -e "${GREEN}==============================================${RESET}"
echo

echo -e "${GREEN}Endpoint : $FINAL_ENDPOINT${RESET}"
echo -e "${GREEN}Loss     : ${FINAL_LOSS}%${RESET}"
echo -e "${GREEN}Tun-Ping : ${FINAL_PING}ms${RESET}"

# ------------------------------------------------
# Final configuration
# ------------------------------------------------

echo
echo -e "${GREEN}==============================================${RESET}"
echo -e "${GREEN}           FINAL AMNEZIAWG CONFIG${RESET}"
echo -e "${GREEN}==============================================${RESET}"
echo

echo -e "${GREEN}# Name = cloudflare-auto${RESET}"
echo
echo -e "${GREEN}[Interface]${RESET}"
echo -e "${GREEN}PrivateKey = $WGKEY${RESET}"
echo -e "${GREEN}Address = $ADDRESS${RESET}"
echo -e "${GREEN}DNS = $DNS${RESET}"
echo -e "${GREEN}Jc = $JC${RESET}"
echo -e "${GREEN}Jmin = $JMIN${RESET}"
echo -e "${GREEN}Jmax = $JMAX${RESET}"
echo -e "${GREEN}S1 = $S1${RESET}"
echo -e "${GREEN}S2 = $S2${RESET}"
echo -e "${GREEN}H1 = $H1${RESET}"
echo -e "${GREEN}H2 = $H2${RESET}"
echo -e "${GREEN}H3 = $H3${RESET}"
echo -e "${GREEN}H4 = $H4${RESET}"
echo
echo -e "${GREEN}[Peer]${RESET}"
echo -e "${GREEN}PublicKey = $PUBKEY${RESET}"
echo -e "${GREEN}Endpoint = $FINAL_ENDPOINT${RESET}"
echo -e "${GREEN}AllowedIPs = $ALLOWED${RESET}"

echo
echo -e "${GREEN}==============================================${RESET}"
echo -e "${GREEN}              SCAN COMPLETE${RESET}"
echo -e "${GREEN}==============================================${RESET}"
echo

# ------------------------------------------------
# Cleanup
# ------------------------------------------------

rm -f \
    "$SCAN1" \
    "$RESULT1" \
    "$SCAN2" \
    "$RESULT2" \
    "$COMBINED" \
    "$FINAL" \
    "$TOP10"

echo -e "${GREEN}[✓] No configuration file was saved.${RESET}"
echo
