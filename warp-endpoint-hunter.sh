#!/data/data/com.termux/files/usr/bin/bash

# ============================================================
# WARP ENDPOINT HUNTER
# Termux Edition v1.0.0
#
# AUTO DEPENDENCY INSTALL
# AUTO WARPSCOUT UPDATE
# LATEST GITHUB RELEASE
# ARM64 / AARCH64 SUPPORT
#
# 1 = Endpoint Scanner ONLY
# 2 = WG Config Generator
# ============================================================

set -u

APP="$HOME/warp-endpoint-hunter"
ACCOUNT="$APP/warpscout-account.json"
LATEST="$APP/latest-scan.txt"
TMP="$APP/.scan.tmp"
CONF_TMP="$APP/.best-awg.conf"
INSTALL_DIR="$PREFIX/bin"

WARPSCOUT_REPO="vernette/warpscout"

mkdir -p "$APP"

# ============================================================
# COLORS
# ============================================================

RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'

RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BLUE=$'\033[34m'
MAGENTA=$'\033[35m'
CYAN=$'\033[36m'
WHITE=$'\033[37m'
GRAY=$'\033[90m'

# ============================================================
# TERMINAL
# ============================================================

clear_screen() {
    clear
    printf '\033[3J\033[H'
}

hide_cursor() {
    printf '\033[?25l'
}

show_cursor() {
    printf '\033[?25h'
}

cleanup_exit() {
    show_cursor
    rm -f "$TMP" "$CONF_TMP" "$TMP.report" \
        "$APP/.warpscout_download" \
        "$APP/.warpscout_archive" 2>/dev/null
}

trap cleanup_exit EXIT
trap 'show_cursor; exit 130' INT TERM

pause_screen() {
    echo
    printf "  ${DIM}Press Enter to return to menu...${RESET}"
    read -r
}

line() {
    printf "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
}

small_line() {
    printf "${GRAY}──────────────────────────────────────────────────────${RESET}\n"
}

# ============================================================
# BANNER
# ============================================================

header() {

    clear_screen

    printf "${CYAN}"

    cat <<'BANNER'
╔══════════════════════════════════════════════════════════╗
║  ██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗      ║
║  ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗     ║
║  ███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝     ║
║  ██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗     ║
║  ██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║     ║
║  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝     ║
╚══════════════════════════════════════════════════════════╝
BANNER

    printf "${RESET}\n"

    printf "  ${BOLD}${WHITE}W A R P   E N D P O I N T   H U N T E R${RESET}\n"
    printf "  ${DIM}Advanced WARP / AmneziaWG Scanner${RESET}\n"

    printf "\n"

    printf "${CYAN}┌──────────────────────────────────────────────────────────┐${RESET}\n"
    printf "${CYAN}│${RESET}   ${CYAN}◈${RESET}  VERSION    : ${WHITE}v1.0.0${RESET}\n"
    printf "${CYAN}│${RESET}   ${GREEN}▣${RESET}  PLATFORM   : ${WHITE}Termux / Android${RESET}\n"
    printf "${CYAN}│${RESET}   ${CYAN}>_${RESET} ARCH       : ${WHITE}ARM64 / AARCH64${RESET}\n"
    printf "${CYAN}└──────────────────────────────────────────────────────────┘${RESET}\n"

    line
}

# ============================================================
# ARCHITECTURE
# ============================================================

detect_arch() {

    local arch
    arch="$(uname -m 2>/dev/null || true)"

    case "$arch" in
        aarch64|arm64)
            WARPSCOUT_ARCH="arm64"
            ;;
        armv7l|armv7|arm)
            WARPSCOUT_ARCH="arm"
            ;;
        x86_64|amd64)
            WARPSCOUT_ARCH="amd64"
            ;;
        i686|i386)
            WARPSCOUT_ARCH="386"
            ;;
        *)
            WARPSCOUT_ARCH=""
            ;;
    esac
}

# ============================================================
# DEPENDENCIES
# ============================================================

need_pkg() {

    command -v "$1" >/dev/null 2>&1
}

install_dependencies() {

    header

    printf "  ${BOLD}${WHITE}SYSTEM PREPARATION${RESET}\n"
    small_line

    detect_arch

    printf "  ${CYAN}◇${RESET} Architecture : ${GREEN}%s${RESET}\n" \
        "$(uname -m 2>/dev/null || echo unknown)"

    if [ -z "${WARPSCOUT_ARCH:-}" ]; then
        printf "  ${RED}✗ Unsupported architecture.${RESET}\n"
        printf "  ${DIM}Supported: ARM64, ARM, AMD64, x86${RESET}\n"
        return 1
    fi

    printf "  ${GREEN}✓${RESET} Target        : ${WARPSCOUT_ARCH}\n"

    echo
    printf "  ${BOLD}Checking Termux packages...${RESET}\n"
    small_line

    local packages=(
        curl
        wget
        git
        jq
        tar
        gzip
        coreutils
        openssl
        netcat-openbsd
    )

    local missing=()
    local p

    for p in "${packages[@]}"; do

        if need_pkg "$p"; then
            printf "  ${GREEN}✓${RESET} %-18s installed\n" "$p"
        else
            printf "  ${YELLOW}!${RESET} %-18s missing\n" "$p"
            missing+=("$p")
        fi

    done

    if [ "${#missing[@]}" -gt 0 ]; then

        echo
        printf "  ${CYAN}◇ Installing missing packages...${RESET}\n"

        if ! command -v pkg >/dev/null 2>&1; then
            printf "  ${RED}✗ Termux package manager not found.${RESET}\n"
            printf "  ${DIM}This script must be executed inside Termux.${RESET}\n"
            return 1
        fi

        pkg update -y >/dev/null 2>&1 || true

        if ! pkg install -y "${missing[@]}"; then
            echo
            printf "  ${RED}✗ Dependency installation failed.${RESET}\n"
            return 1
        fi

        echo
        printf "  ${GREEN}✓ Dependencies installed successfully.${RESET}\n"

    else

        echo
        printf "  ${GREEN}✓ All required Termux packages are ready.${RESET}\n"

    fi

    echo
    return 0
}

# ============================================================
# INTERNET
# ============================================================

check_internet() {

    printf "  ${CYAN}◇${RESET} Checking internet connectivity...\n"

    if curl -fsSL \
        --connect-timeout 5 \
        --max-time 10 \
        https://api.github.com >/dev/null 2>&1; then

        printf "  ${GREEN}✓${RESET} Internet : reachable\n"
        return 0

    fi

    printf "  ${RED}✗${RESET} Internet : unavailable\n"
    return 1
}

# ============================================================
# WARPSCOUT LATEST RELEASE
# ============================================================

get_latest_release() {

    local api
    api="https://api.github.com/repos/${WARPSCOUT_REPO}/releases/latest"

    LATEST_JSON="$APP/.warpscout-latest.json"

    if ! curl -fsSL \
        --connect-timeout 8 \
        --max-time 20 \
        -H "Accept: application/vnd.github+json" \
        "$api" \
        -o "$LATEST_JSON"; then

        return 1
    fi

    LATEST_VERSION="$(
        jq -r '.tag_name // empty' "$LATEST_JSON" 2>/dev/null
    )"

    [ -n "$LATEST_VERSION" ] || return 1

    return 0
}

# ============================================================
# FIND RELEASE ASSET
# ============================================================

find_warpscout_asset() {

    local assets
    local name
    local url

    assets="$(
        jq -r '.assets[]? | [.name,.browser_download_url] | @tsv' \
        "$LATEST_JSON" 2>/dev/null
    )"

    [ -n "$assets" ] || return 1

    # Prefer Android + architecture
    while IFS=$'\t' read -r name url; do

        [ -n "$name" ] || continue

        local lname
        lname="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"

        case "$WARPSCOUT_ARCH" in

            arm64)

                if [[ "$lname" == *android* ]] &&
                   [[ "$lname" == *arm64* || "$lname" == *aarch64* ]]; then

                    WARPSCOUT_ASSET_NAME="$name"
                    WARPSCOUT_ASSET_URL="$url"
                    return 0
                fi

                ;;

            amd64)

                if [[ "$lname" == *android* ]] &&
                   [[ "$lname" == *amd64* || "$lname" == *x86_64* ]]; then

                    WARPSCOUT_ASSET_NAME="$name"
                    WARPSCOUT_ASSET_URL="$url"
                    return 0
                fi

                ;;

            arm)

                if [[ "$lname" == *android* ]] &&
                   [[ "$lname" == *arm* ]] &&
                   [[ "$lname" != *arm64* ]]; then

                    WARPSCOUT_ASSET_NAME="$name"
                    WARPSCOUT_ASSET_URL="$url"
                    return 0
                fi

                ;;

            386)

                if [[ "$lname" == *android* ]] &&
                   [[ "$lname" == *386* || "$lname" == *i386* ]]; then

                    WARPSCOUT_ASSET_NAME="$name"
                    WARPSCOUT_ASSET_URL="$url"
                    return 0
                fi

                ;;
        esac

    done <<< "$assets"

    # Fallback: architecture-only asset
    while IFS=$'\t' read -r name url; do

        [ -n "$name" ] || continue

        local lname
        lname="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"

        case "$WARPSCOUT_ARCH" in
            arm64)
                [[ "$lname" == *arm64* || "$lname" == *aarch64* ]] || continue
                ;;
            amd64)
                [[ "$lname" == *amd64* || "$lname" == *x86_64* ]] || continue
                ;;
            arm)
                [[ "$lname" == *arm* ]] || continue
                [[ "$lname" != *arm64* ]] || continue
                ;;
            386)
                [[ "$lname" == *386* || "$lname" == *i386* ]] || continue
                ;;
        esac

        WARPSCOUT_ASSET_NAME="$name"
        WARPSCOUT_ASSET_URL="$url"
        return 0

    done <<< "$assets"

    return 1
}

# ============================================================
# WARPSCOUT VERSION CHECK
# ============================================================

version_is_same() {

    local installed="$1"
    local latest="$2"

    installed="${installed#v}"
    latest="${latest#v}"

    [ "$installed" = "$latest" ]
}

get_installed_version() {

    if ! command -v warpscout >/dev/null 2>&1; then
        echo ""
        return
    fi

    warpscout version 2>/dev/null |
        head -n 1 |
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# ============================================================
# INSTALL / UPDATE WARPSCOUT
# ============================================================

ensure_warpscout() {

    header

    printf "  ${BOLD}${WHITE}WARPSCOUT MANAGER${RESET}\n"
    small_line

    detect_arch

    if [ -z "${WARPSCOUT_ARCH:-}" ]; then
        printf "  ${RED}✗ Unsupported CPU architecture.${RESET}\n"
        return 1
    fi

    printf "  ${CYAN}◇${RESET} Architecture : ${GREEN}%s${RESET}\n" "$WARPSCOUT_ARCH"

    local installed
    installed="$(get_installed_version)"

    if [ -n "$installed" ]; then
        printf "  ${GREEN}✓${RESET} Installed     : ${WHITE}%s${RESET}\n" "$installed"
    else
        printf "  ${YELLOW}!${RESET} Warpscout     : not installed\n"
    fi

    printf "  ${CYAN}◇${RESET} Checking latest GitHub release...\n"

    if ! get_latest_release; then

        printf "  ${RED}✗ Could not retrieve latest Warpscout release.${RESET}\n"

        if [ -n "$installed" ]; then
            printf "  ${YELLOW}! Continuing with installed version.${RESET}\n"
            return 0
        fi

        return 1
    fi

    printf "  ${GREEN}✓${RESET} Latest release : ${WHITE}%s${RESET}\n" \
        "$LATEST_VERSION"

    if [ -n "$installed" ] &&
       version_is_same "$installed" "$LATEST_VERSION"; then

        printf "  ${GREEN}✓${RESET} Warpscout is already up to date.\n"

        rm -f "$LATEST_JSON"
        return 0
    fi

    echo
    printf "  ${CYAN}◇${RESET} Finding compatible ${WARPSCOUT_ARCH} asset...\n"

    if ! find_warpscout_asset; then

        printf "  ${RED}✗ No compatible Warpscout asset found.${RESET}\n"
        printf "  ${DIM}Release: %s${RESET}\n" "$LATEST_VERSION"
        rm -f "$LATEST_JSON"
        return 1
    fi

    printf "  ${GREEN}✓${RESET} Asset: ${WHITE}%s${RESET}\n" \
        "$WARPSCOUT_ASSET_NAME"

    local archive="$APP/.warpscout_archive"

    rm -f "$archive"

    echo
    printf "  ${CYAN}◇${RESET} Downloading latest Warpscout...\n"

    if ! curl -fL \
        --connect-timeout 10 \
        --max-time 180 \
        --retry 3 \
        --retry-delay 2 \
        "$WARPSCOUT_ASSET_URL" \
        -o "$archive"; then

        printf "  ${RED}✗ Download failed.${RESET}\n"
        rm -f "$archive" "$LATEST_JSON"
        return 1
    fi

    printf "  ${GREEN}✓${RESET} Download completed.\n"

    local extract="$APP/.warpscout-extract"

    rm -rf "$extract"
    mkdir -p "$extract"

    echo
    printf "  ${CYAN}◇${RESET} Extracting package...\n"

    if ! tar -xzf "$archive" -C "$extract" 2>/dev/null; then

        printf "  ${RED}✗ Failed to extract Warpscout archive.${RESET}\n"
        rm -rf "$extract"
        rm -f "$archive" "$LATEST_JSON"
        return 1
    fi

    local binary=""

    binary="$(
        find "$extract" -type f -name warpscout -perm -u+x 2>/dev/null |
        head -n 1
    )"

    if [ -z "$binary" ]; then

        binary="$(
            find "$extract" -type f -name warpscout 2>/dev/null |
            head -n 1
        )"
    fi

    if [ -z "$binary" ]; then

        printf "  ${RED}✗ Warpscout binary not found in package.${RESET}\n"
        rm -rf "$extract"
        rm -f "$archive" "$LATEST_JSON"
        return 1
    fi

    chmod +x "$binary"

    echo
    printf "  ${CYAN}◇${RESET} Installing Warpscout...\n"

    if ! cp "$binary" "$INSTALL_DIR/warpscout"; then

        printf "  ${RED}✗ Cannot install to %s${RESET}\n" "$INSTALL_DIR"
        rm -rf "$extract"
        rm -f "$archive" "$LATEST_JSON"
        return 1
    fi

    chmod +x "$INSTALL_DIR/warpscout"

    rm -rf "$extract"
    rm -f "$archive" "$LATEST_JSON"

    hash -r 2>/dev/null || true

    echo

    if command -v warpscout >/dev/null 2>&1; then

        printf "  ${GREEN}✓ Warpscout installed successfully.${RESET}\n"
        printf "  ${GREEN}✓ Version:${RESET} %s\n" \
            "$(get_installed_version)"

        return 0
    fi

    printf "  ${RED}✗ Warpscout installation could not be verified.${RESET}\n"
    return 1
}

# ============================================================
# COMPLETE FIRST-RUN SETUP
# ============================================================

prepare_environment() {

    header

    printf "  ${BOLD}${WHITE}INITIAL SETUP${RESET}\n"
    line
    echo

    if ! install_dependencies; then
        echo
        printf "  ${RED}Setup failed.${RESET}\n"
        pause_screen
        return 1
    fi

    echo

    if ! check_internet; then
        echo
        printf "  ${RED}Internet connection is required for Warpscout setup.${RESET}\n"
        pause_screen
        return 1
    fi

    echo

    if ! ensure_warpscout; then
        echo
        printf "  ${RED}Warpscout setup failed.${RESET}\n"
        pause_screen
        return 1
    fi

    echo
    line
    printf "  ${GREEN}✓ Environment is ready.${RESET}\n"
    line
    sleep 1

    return 0
}

# ============================================================
# ENVIRONMENT CHECK
# ============================================================

check_warpscout() {
    command -v warpscout >/dev/null 2>&1
}

check_environment() {

    printf "  ${BOLD}${WHITE}ENVIRONMENT CHECK${RESET}\n"
    small_line

    if check_warpscout; then

        printf "  ${GREEN}✓${RESET} WARPSCOUT : ${WHITE}%s${RESET}\n" \
            "$(command -v warpscout)"

        printf "  ${GREEN}✓${RESET} Version   : ${WHITE}%s${RESET}\n" \
            "$(get_installed_version)"

    else

        printf "  ${RED}✗${RESET} WARPSCOUT was not found.\n"
        return 1
    fi

    if command -v curl >/dev/null 2>&1; then
        printf "  ${GREEN}✓${RESET} curl      : available\n"
    else
        printf "  ${YELLOW}!${RESET} curl      : unavailable\n"
    fi

    printf "  ${DIM}◇ Checking internet connectivity...${RESET}\n"

    if curl -fsS \
        --connect-timeout 5 \
        --max-time 8 \
        https://api.github.com >/dev/null 2>&1; then

        printf "  ${GREEN}✓${RESET} Internet   : reachable\n"

    else

        printf "  ${YELLOW}!${RESET} Internet   : check failed\n"

    fi

    echo
    return 0
}

# ============================================================
# ACCOUNT
# ============================================================

check_account() {

    printf "  ${BOLD}${WHITE}WARP ACCOUNT${RESET}\n"
    small_line

    if [ -s "$ACCOUNT" ]; then

        printf "  ${GREEN}✓${RESET} Existing WARP account found.\n"
        return 0
    fi

    printf "  ${YELLOW}!${RESET} WARP account not found.\n"
    printf "  ${CYAN}◇${RESET} Registering a WARP account...\n\n"

    if warpscout register -a "$ACCOUNT"; then

        printf "\n  ${GREEN}✓ WARP account registered successfully.${RESET}\n"
        return 0

    fi

    printf "\n  ${RED}✗ WARP account registration failed.${RESET}\n"
    return 1
}

# ============================================================
# STORAGE
# ============================================================

prepare_storage() {

    WG_DIR="$HOME/storage/shared/WG-Tunnel"

    if [ -d "$HOME/storage/shared" ]; then
        mkdir -p "$WG_DIR" 2>/dev/null || true
    fi

    if [ ! -d "$WG_DIR" ]; then
        WG_DIR="$APP/WG-Tunnel"
        mkdir -p "$WG_DIR"
    fi
}

# ============================================================
# LIVE SCAN
# ============================================================

live_scan() {

    local MODE="$1"

    header

    if [ "$MODE" = "ENDPOINT" ]; then

        printf "  ${BOLD}${WHITE}STEP 03/03   WARP ENDPOINT SCANNER${RESET}\n"

    else

        printf "  ${BOLD}${WHITE}STEP 03/03   WARP WG CONFIG GENERATOR${RESET}\n"

    fi

    small_line
    echo

    printf "  ${BOLD}SCAN PROFILE${RESET}\n"

    printf "  Protocol          : ${GREEN}AmneziaWG${RESET}\n"
    printf "  Tunnel ping       : ${GREEN}Enabled${RESET}\n"
    printf "  Durability burst  : ${GREEN}10 packets${RESET}\n"
    printf "  Ranking           : ${GREEN}Lowest endpoint ping${RESET}\n"

    if [ "$MODE" = "CONFIG" ]; then
        printf "  Configuration     : ${GREEN}Native AWG${RESET}\n"
    else
        printf "  Configuration     : ${DIM}Disabled (scanner only)${RESET}\n"
    fi

    echo
    line
    echo

    printf "  ${CYAN}◇ Starting WARPSCOUT...${RESET}\n"
    printf "  ${DIM}◇ Live scan output is shown below.${RESET}\n"
    printf "  ${DIM}◇ Please keep Termux open.${RESET}\n"
    echo

    rm -f "$TMP" "$CONF_TMP" "$TMP.report"

    if [ "$MODE" = "CONFIG" ]; then

        CMD=(
            warpscout scan
            -proto awg
            -P
            -tun-ping-count 10
            -best-by ping
            -a "$ACCOUNT"
            -o "$TMP.report"
            -conf "$CONF_TMP"
            -conf-type native
            -mtu 1280
        )

    else

        CMD=(
            warpscout scan
            -proto awg
            -P
            -tun-ping-count 10
            -best-by ping
            -a "$ACCOUNT"
            -o "$TMP.report"
            -mtu 1280
        )

    fi

    set +e

    "${CMD[@]}" 2>&1 | tee "$TMP"

    SCAN_STATUS=${PIPESTATUS[0]}

    set -u

    echo
    line

    if [ "$SCAN_STATUS" -eq 0 ]; then

        printf "  ${GREEN}◆ Scan completed successfully.${RESET}\n"

    else

        printf "  ${YELLOW}◆ WARPSCOUT returned status %s.${RESET}\n" \
            "$SCAN_STATUS"

        printf "  ${DIM}The output above is preserved for analysis.${RESET}\n"
    fi

    echo

    if [ -s "$TMP" ]; then
        cp "$TMP" "$LATEST"
    fi

    display_top10 "$TMP"
    display_best "$TMP"

    if [ "$MODE" = "CONFIG" ]; then

        generate_config

    else

        printf "\n"
        line
        printf "  ${BOLD}${BLUE}ENDPOINT SCANNER MODE${RESET}\n"
        small_line

        printf "  ${GREEN}✓${RESET} No configuration was generated.\n"
        printf "  ${DIM}This mode is for finding and comparing endpoints only.${RESET}\n"
    fi

    rm -f "$TMP" "$TMP.report"

    echo
    line

    if [ "$MODE" = "CONFIG" ]; then
        printf "  ${GREEN}WG Config Generator finished.${RESET}"
    else
        printf "  ${GREEN}Endpoint Scanner finished.${RESET}"
    fi

    echo

    pause_screen
}

# ============================================================
# TOP 10
# ============================================================

display_top10() {

    local file="$1"

    printf "\n"
    line
    printf "  ${BOLD}${WHITE}TOP 10 WARP ENDPOINTS${RESET}\n"
    line

    printf "  ${BOLD}RANK  ENDPOINT                    EP PING     TUN PING    LOSS${RESET}\n"
    small_line

    if [ ! -s "$file" ]; then

        printf "  ${YELLOW}No scan output available.${RESET}\n"
        line
        return
    fi

    awk '
    BEGIN { count=0 }

    /│/ && $0 ~ /:[0-9]+/ && $0 ~ /ms/ && $0 ~ /%/ {

        n=split($0,a,"│")

        if(n >= 6) {

            endpoint=a[3]
            ep=a[4]
            tun=a[5]
            loss=a[6]

            gsub(/^[ \t]+|[ \t]+$/, "", endpoint)
            gsub(/^[ \t]+|[ \t]+$/, "", ep)
            gsub(/^[ \t]+|[ \t]+$/, "", tun)
            gsub(/^[ \t]+|[ \t]+$/, "", loss)

            if(endpoint ~ /^[0-9A-Fa-f:.]+:[0-9]+$/ &&
               ep ~ /^[0-9]+ms$/ &&
               tun ~ /^[0-9]+ms$/ &&
               loss ~ /^[0-9]+%$/) {

                gsub(/ms/, "", ep)
                print ep "|" endpoint "|" tun "|" loss
            }
        }
    }
    ' "$file" |
    sort -t'|' -k1,1n |
    head -10 |
    awk -F'|' '

    {
        rank++
        ep=$1
        endpoint=$2
        tun=$3
        loss=$4

        if(rank == 1) {

            printf "  \033[32m%-5s\033[0m \033[1m\033[32m%-27s\033[0m \033[32m%-11s %-11s %-6s ★ BEST\033[0m\n",
                   rank, endpoint, ep "ms", tun, loss

        } else {

            printf "  \033[36m%-5s\033[0m %-27s \033[37m%-11s %-11s %-6s\033[0m\n",
                   rank, endpoint, ep "ms", tun, loss
        }
    }
    '

    line
}

# ============================================================
# BEST ENDPOINT
# ============================================================

extract_best_endpoint() {

    local file="$1"

    [ -s "$file" ] || return 0

    awk '
    BEGIN {
        best=""
        ping=999999
    }

    /│/ && $0 ~ /:[0-9]+/ && $0 ~ /ms/ && $0 ~ /%/ {

        n=split($0,a,"│")

        if(n >= 6) {

            endpoint=a[3]
            ep=a[4]

            gsub(/^[ \t]+|[ \t]+$/, "", endpoint)
            gsub(/^[ \t]+|[ \t]+$/, "", ep)

            if(endpoint ~ /^[0-9A-Fa-f:.]+:[0-9]+$/ &&
               ep ~ /^[0-9]+ms$/) {

                gsub(/ms/, "", ep)

                if((ep+0) < ping) {

                    ping=ep+0
                    best=endpoint
                }
            }
        }
    }

    END {
        if(best != "")
            print best
    }
    ' "$file"
}

display_best() {

    local file="$1"
    local best

    best="$(extract_best_endpoint "$file")"

    printf "\n"
    line
    printf "  ${BOLD}${WHITE}BEST ENDPOINT${RESET}\n"
    line

    if [ -z "$best" ]; then

        printf "  ${YELLOW}No valid endpoint could be determined.${RESET}\n"
        line
        return
    fi

    local info

    info="$(
        awk -v wanted="$best" '
        /│/ && $0 ~ /:[0-9]+/ && $0 ~ /ms/ && $0 ~ /%/ {

            n=split($0,a,"│")

            if(n >= 6) {

                endpoint=a[3]
                ep=a[4]
                tun=a[5]
                loss=a[6]

                gsub(/^[ \t]+|[ \t]+$/, "", endpoint)
                gsub(/^[ \t]+|[ \t]+$/, "", ep)
                gsub(/^[ \t]+|[ \t]+$/, "", tun)
                gsub(/^[ \t]+|[ \t]+$/, "", loss)

                if(endpoint == wanted) {

                    print ep "|" tun "|" loss
                    exit
                }
            }
        }
        ' "$file"
    )"

    local EP TUN LOSS

    IFS='|' read -r EP TUN LOSS <<< "$info"

    printf "  ${GREEN}★${RESET} Endpoint : ${BOLD}${GREEN}%s${RESET}\n" "$best"
    printf "  ${CYAN}◇${RESET} EP ping  : ${WHITE}%s${RESET}\n" "${EP:-unknown}"
    printf "  ${CYAN}◇${RESET} Tunnel   : ${WHITE}%s${RESET}\n" "${TUN:-unknown}"
    printf "  ${CYAN}◇${RESET} Loss     : ${WHITE}%s${RESET}\n" "${LOSS:-unknown}"

    line
}

# ============================================================
# GENERATE CONFIG
# ============================================================

generate_config() {

    printf "\n"
    line
    printf "  ${BOLD}${WHITE}WG CONFIGURATION${RESET}\n"
    line

    if [ ! -s "$CONF_TMP" ]; then

        printf "  ${YELLOW}! WARPSCOUT did not create a native AWG configuration.${RESET}\n"
        printf "  ${DIM}The endpoint scan was successful, but no config file was returned.${RESET}\n"

        line
        return
    fi

    prepare_storage

    local conf_file
    conf_file="$WG_DIR/eze63.conf"

    {
        echo "# Name = eze63"
        cat "$CONF_TMP"
    } > "$conf_file"

    if [ -s "$conf_file" ]; then

        printf "  ${GREEN}✓ Native AWG configuration created.${RESET}\n"
        printf "\n"
        printf "  ${CYAN}File:${RESET}\n"
        printf "  ${WHITE}%s${RESET}\n" "$conf_file"

        echo
        small_line
        printf "  ${BOLD}${WHITE}CONFIGURATION${RESET}\n"
        small_line

        cat "$conf_file"

        echo
        small_line

        printf "  ${GREEN}✓ Ready for import into WG Tunnel / AmneziaWG.${RESET}\n"

    else

        printf "  ${RED}✗ Failed to save configuration.${RESET}\n"
    fi

    line
}

# ============================================================
# SHOW LATEST
# ============================================================

show_latest() {

    header

    printf "  ${BOLD}${WHITE}LATEST SCAN RESULT${RESET}\n"
    line

    if [ ! -s "$LATEST" ]; then

        printf "  ${YELLOW}! No scan result has been saved yet.${RESET}\n"

        pause_screen
        return
    fi

    printf "  ${GREEN}File:${RESET} %s\n\n" "$LATEST"

    cat "$LATEST"

    echo
    line

    pause_screen
}

# ============================================================
# CONFIG LIST
# ============================================================

show_configs() {

    header

    printf "  ${BOLD}${WHITE}WG TUNNEL CONFIGURATIONS${RESET}\n"
    line

    prepare_storage

    local found=0
    local f

    for f in "$WG_DIR"/*.conf; do

        [ -e "$f" ] || continue

        found=1

        printf "  ${GREEN}◆${RESET} %s\n" "$f"
    done

    if [ "$found" -eq 0 ]; then

        printf "  ${YELLOW}! No WG Tunnel configurations found.${RESET}\n"
    fi

    pause_screen
}

# ============================================================
# VERSION
# ============================================================

show_version() {

    header

    printf "  ${BOLD}${WHITE}VERSION INFORMATION${RESET}\n"
    line

    printf "  Hunter    : ${GREEN}v1.0.0${RESET}\n"

    if command -v warpscout >/dev/null 2>&1; then

        printf "  WARPSCOUT : ${GREEN}installed${RESET}\n"

        warpscout version 2>&1

    else

        printf "  WARPSCOUT : ${RED}not found${RESET}\n"
    fi

    pause_screen
}

# ============================================================
# MENU
# ============================================================

main_menu() {

    while true; do

        header

        printf "\n"
        printf "${CYAN}┌── ${BOLD}${WHITE}MAIN CONTROL PANEL${RESET}${CYAN} ──────────────────────────────────┐${RESET}\n"
        printf "${CYAN}│${RESET}\n"

        printf "${CYAN}│${RESET}  ${GREEN}[1]${RESET} ${BOLD}WARP Endpoint Scanner${RESET} ${DIM}..............${RESET} ${GREEN}⌖${RESET}\n"
        printf "${CYAN}│${RESET}  ${MAGENTA}[2]${RESET} ${BOLD}WARP WG Config Generator${RESET} ${DIM}...........${RESET} ${MAGENTA}🔧${RESET}\n"
        printf "${CYAN}│${RESET}  ${CYAN}[3]${RESET} Show Latest Scan Result ${DIM}...................${RESET} ${CYAN}🔍${RESET}\n"
        printf "${CYAN}│${RESET}  ${YELLOW}[4]${RESET} Show Saved WG Tunnel Configs ${DIM}..............${RESET} ${YELLOW}📁${RESET}\n"
        printf "${CYAN}│${RESET}  ${BLUE}[5]${RESET} WARPSCOUT Version ${DIM}.........................${RESET} ${BLUE}ℹ${RESET}\n"
        printf "${CYAN}│${RESET}  ${RED}[0]${RESET} Exit ${DIM}.......................................${RESET} ${RED}⏻${RESET}\n"

        printf "${CYAN}│${RESET}\n"
        printf "${CYAN}└──────────────────────────────────────────────────────────┘${RESET}\n"

        printf "\n"
        printf "  ${CYAN}>_${RESET} ${DIM}Select an option to continue...${RESET}\n"

        line

        printf "\n  ${GREEN}➜${RESET}  ${BOLD}Select:${RESET} "

        read -r choice

        case "$choice" in

            1)

                if check_environment && check_account; then
                    live_scan "ENDPOINT"
                else
                    pause_screen
                fi

                ;;

            2)

                if check_environment && check_account; then
                    live_scan "CONFIG"
                else
                    pause_screen
                fi

                ;;

            3)

                show_latest
                ;;

            4)

                show_configs
                ;;

            5)

                show_version
                ;;

            0)

                clear_screen

                printf "\n"
                printf "  ${GREEN}WARP Endpoint Hunter stopped.${RESET}\n\n"

                exit 0
                ;;

            *)

                printf "\n"
                printf "  ${RED}Invalid option.${RESET}\n"
                sleep 1
                ;;

        esac

    done
}

# ============================================================
# START
# ============================================================

show_cursor

# ------------------------------------------------------------
# Automatic preparation before menu
# ------------------------------------------------------------

if ! prepare_environment; then
    exit 1
fi

main_menu

