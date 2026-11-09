#!/usr/bin/env bash
# install.sh — Interactive installer for the SDDM themes in this repo
# Usage: ./install.sh [theme]
#   Run it as your normal user: it asks which theme to install, and only
#   uses sudo (prompting for your password) for the steps that need root.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="${ROOT_DIR}/themes"
SDDM_THEMES_DIR="/usr/share/sddm/themes"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_CONF_FILE="${SDDM_CONF_DIR}/theme.conf"

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }

# ── Preview helpers (used by the menu) ───────────────────────────────────────
theme_desc() { grep -m1 '^Description=' "${THEMES_DIR}/$1/metadata.desktop" | cut -d= -f2-; }

# show_image <file> <cols> <rows>: render with chafa or kitty's icat if present
show_image() {
    local img="$1" cols="$2" rows="$3"
    [[ -f "${img}" ]] || return 1
    if command -v chafa &>/dev/null; then
        chafa -s "${cols}x${rows}" "${img}"
    elif [[ -n "${KITTY_WINDOW_ID:-}" ]] && command -v kitten &>/dev/null; then
        kitten icat --transfer-mode=memory --stdin=no --align=left "${img}"
    else
        return 1
    fi
}

# Hidden mode: `install.sh --preview <theme>` is what fzf calls for its preview pane
if [[ "${1:-}" == "--preview" ]]; then
    t="${2:-}"
    echo -e "${BOLD}${t}${RESET}"
    echo "$(theme_desc "${t}")"
    echo
    cols="${FZF_PREVIEW_COLUMNS:-60}"
    rows=$(( ${FZF_PREVIEW_LINES:-24} - 4 ))
    show_image "${ROOT_DIR}/screenshots/${t}.png" "${cols}" "${rows}" \
        || echo "(no screenshot or image viewer — install 'chafa' for previews)"
    exit 0
fi

# ── Privilege helper: sudo only when we're not already root ──────────────────
SUDO=""
if [[ "${EUID}" -ne 0 ]]; then
    if ! command -v sudo &>/dev/null; then
        error "Root access is needed to install, but 'sudo' was not found."
        error "Run this script as root instead."
        exit 1
    fi
    SUDO="sudo"
fi

# ── Discover themes ───────────────────────────────────────────────────────────
THEMES=()
if [[ -d "${THEMES_DIR}" ]]; then
    for d in "${THEMES_DIR}"/*/; do
        [[ -f "${d}metadata.desktop" ]] && THEMES+=("$(basename "${d}")")
    done
fi

if [[ ${#THEMES[@]} -eq 0 ]]; then
    error "No themes found in ${THEMES_DIR}"
    exit 1
fi

# ── Choose theme (argument, or interactive menu) ──────────────────────────────
THEME_NAME="${1:-}"

if [[ -n "${THEME_NAME}" ]]; then
    found=0
    for t in "${THEMES[@]}"; do [[ "$t" == "${THEME_NAME}" ]] && found=1; done
    if [[ ${found} -eq 0 ]]; then
        error "Unknown theme '${THEME_NAME}'. Available: ${THEMES[*]}"
        exit 1
    fi
else
    if [[ ! -t 0 ]]; then
        error "No theme given and no terminal to ask on. Usage: ./install.sh <theme>"
        error "Available: ${THEMES[*]}"
        exit 1
    fi
    if command -v fzf &>/dev/null; then
        THEME_NAME="$(printf '%s\n' "${THEMES[@]}" | fzf \
            --prompt="Theme > " --header="Choose a theme to install (Enter to select, Esc to cancel)" \
            --layout=default --height=100% \
            --preview "\"${BASH_SOURCE[0]}\" --preview {}" \
            --preview-window="right,65%,border-left")" || { warn "Cancelled."; exit 1; }
    else
        echo -e "${BOLD}Available themes:${RESET}"
        for i in "${!THEMES[@]}"; do
            printf "\n  %d) %s — %s\n\n" "$((i + 1))" "${THEMES[$i]}" "$(theme_desc "${THEMES[$i]}")"
            show_image "${ROOT_DIR}/screenshots/${THEMES[$i]}.png" 48 12 || true
        done
        echo
        while true; do
            read -rp "Choose a theme to install [1-${#THEMES[@]}]: " choice
            if [[ "${choice}" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#THEMES[@]} )); then
                THEME_NAME="${THEMES[$((choice - 1))]}"
                break
            fi
            warn "Please enter a number between 1 and ${#THEMES[@]}."
        done
    fi
fi

THEME_SRC="${THEMES_DIR}/${THEME_NAME}"
DEST="${SDDM_THEMES_DIR}/${THEME_NAME}"

if ! command -v sddm &>/dev/null; then
    warn "sddm binary not found in PATH. Make sure SDDM is installed before continuing."
fi

# ── Stage a copy (no root needed) and tailor it ───────────────────────────────
STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT
cp -r "${THEME_SRC}" "${STAGE}/${THEME_NAME}"

# Record this machine's hostname for themes that display it (fallback if the
# greeter doesn't provide one). Only touches themes that opt in via a marker.
if grep -q "^hostName=" "${STAGE}/${THEME_NAME}/theme.conf" 2>/dev/null; then
    HOST="$(cat /etc/hostname 2>/dev/null || uname -n)"
    sed -i "s|^hostName=.*|hostName=${HOST}|" "${STAGE}/${THEME_NAME}/theme.conf"
fi

# ── Install theme (root needed from here) ─────────────────────────────────────
info "Installing '${THEME_NAME}' theme to ${SDDM_THEMES_DIR}/ (may ask for your password) ..."

${SUDO} mkdir -p "${SDDM_THEMES_DIR}"
if [[ -d "${DEST}" ]]; then
    warn "Existing theme found at ${DEST} — overwriting."
    ${SUDO} rm -rf "${DEST}"
fi

${SUDO} cp -r "${STAGE}/${THEME_NAME}" "${DEST}"
${SUDO} chmod -R 755 "${DEST}"
success "Theme installed to ${DEST}"

# ── Apply SDDM configuration ──────────────────────────────────────────────────
info "Configuring SDDM to use '${THEME_NAME}' ..."

${SUDO} mkdir -p "${SDDM_CONF_DIR}"
printf '[Theme]\nCurrent=%s\n' "${THEME_NAME}" | ${SUDO} tee "${SDDM_CONF_FILE}" >/dev/null

success "SDDM configuration written to ${SDDM_CONF_FILE}"

# ── Done ──────────────────────────────────────────────────────────────────────
echo
echo -e "${GREEN}✔ Installation complete!${RESET}"
echo -e "  Theme : ${CYAN}${THEME_NAME}${RESET}"
echo -e "  Path  : ${CYAN}${DEST}${RESET}"
echo -e "  Config: ${CYAN}${SDDM_CONF_FILE}${RESET}"
echo
echo -e "Restart SDDM to apply the theme:"
echo -e "  ${YELLOW}sudo systemctl restart sddm${RESET}"
