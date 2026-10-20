#!/usr/bin/env bash
# install.sh — Installer for the "nothing" SDDM theme
# Usage: sudo ./install.sh

set -euo pipefail

THEME_NAME="nothing"
THEME_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/${THEME_NAME}"
SDDM_THEMES_DIR="/usr/share/sddm/themes"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_CONF_FILE="${SDDM_CONF_DIR}/theme.conf"

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }

# ── Pre-flight checks ─────────────────────────────────────────────────────────
if [[ "${EUID}" -ne 0 ]]; then
    error "This script must be run as root (try: sudo ./install.sh)"
    exit 1
fi

if [[ ! -d "${THEME_SRC}" ]]; then
    error "Theme source directory not found: ${THEME_SRC}"
    exit 1
fi

if ! command -v sddm &>/dev/null; then
    warn "sddm binary not found in PATH. Make sure SDDM is installed before continuing."
fi

# ── Install theme ─────────────────────────────────────────────────────────────
info "Installing '${THEME_NAME}' theme to ${SDDM_THEMES_DIR}/ ..."

DEST="${SDDM_THEMES_DIR}/${THEME_NAME}"
if [[ -d "${DEST}" ]]; then
    warn "Existing theme found at ${DEST} — overwriting."
    rm -rf "${DEST}"
fi

cp -r "${THEME_SRC}" "${DEST}"
success "Theme files copied to ${DEST}"

# ── Set permissions ───────────────────────────────────────────────────────────
chmod -R 755 "${DEST}"
success "Permissions set."

# ── Apply SDDM configuration ──────────────────────────────────────────────────
info "Configuring SDDM to use '${THEME_NAME}' ..."

mkdir -p "${SDDM_CONF_DIR}"

cat > "${SDDM_CONF_FILE}" <<EOF
[Theme]
Current=${THEME_NAME}
EOF

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
