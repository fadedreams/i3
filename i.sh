#!/usr/bin/env bash
#
# install-i3.sh — bootstrap i3 (window manager) config + scripts on (almost) any Linux distro
#
# Usage (one-liner, on any fresh machine):
#   curl -fsSL https://raw.githubusercontent.com/fadedreams/i3/refs/heads/main/install-i3.sh | bash
# or:
#   wget -qO- https://raw.githubusercontent.com/fadedreams/i3/refs/heads/main/install-i3.sh | bash
#
# What it does:
#   - Installs the i3 window manager via the right package manager for your distro
#   - Downloads config -> ~/.config/i3/config
#   - Downloads scripts/auto-monitor.sh, scripts/both-monitors.sh -> ~/.config/i3/scripts/
#   - Makes scripts executable
#   - Backs up any existing i3 config dir to <dir>.bak.<timestamp>
#   - Safe to re-run (idempotent)

set -euo pipefail

RAW_BASE="https://raw.githubusercontent.com/fadedreams/i3/refs/heads/main"
DEST_DIR="${HOME}/.config/i3"
SCRIPTS=("auto-monitor.sh" "both-monitors.sh")

log()  { printf '\033[1;32m[+] %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }
err()  { printf '\033[1;31m[x] %s\033[0m\n' "$*" >&2; }

# ---- sudo helper ------------------------------------------------------
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        err "Not running as root and 'sudo' is not available. Please run as root or install sudo."
        exit 1
    fi
fi

# ---- downloader helper -------------------------------------------------
DOWNLOADER=""
pick_downloader() {
    if command -v curl >/dev/null 2>&1; then
        DOWNLOADER="curl"
    elif command -v wget >/dev/null 2>&1; then
        DOWNLOADER="wget"
    else
        warn "Neither curl nor wget found; attempting to install curl..."
        install_pkg curl
        DOWNLOADER="curl"
    fi
}

fetch() { # fetch <url> <dest>
    if [ "$DOWNLOADER" = "curl" ]; then
        curl -fsSL "$1" -o "$2"
    else
        wget -q "$1" -O "$2"
    fi
}

backup_if_exists() { # backup_if_exists <path>
    if [ -e "$1" ]; then
        local b="${1}.bak.$(date +%Y%m%d%H%M%S)"
        warn "Existing $1 found. Backing up to $b"
        mv "$1" "$b"
    fi
}

# ---- generic package install across distros ----------------------------
install_pkg() { # install_pkg <pkg-name>
    local pkg="$1"
    if command -v apt-get >/dev/null 2>&1; then
        $SUDO apt-get update -y
        $SUDO apt-get install -y "$pkg"
    elif command -v dnf >/dev/null 2>&1; then
        $SUDO dnf install -y "$pkg"
    elif command -v yum >/dev/null 2>&1; then
        $SUDO yum install -y "$pkg"
    elif command -v pacman >/dev/null 2>&1; then
        $SUDO pacman -Sy --noconfirm --needed "$pkg"
    elif command -v zypper >/dev/null 2>&1; then
        $SUDO zypper --non-interactive install "$pkg"
    elif command -v apk >/dev/null 2>&1; then
        $SUDO apk add --no-cache "$pkg"
    elif command -v xbps-install >/dev/null 2>&1; then
        $SUDO xbps-install -Sy "$pkg"
    elif command -v emerge >/dev/null 2>&1; then
        $SUDO emerge --ask=n "$pkg" || $SUDO emerge "$pkg"
    elif command -v eopkg >/dev/null 2>&1; then
        $SUDO eopkg install -y "$pkg"
    elif command -v nix-env >/dev/null 2>&1; then
        nix-env -iA "nixpkgs.${pkg}"
    else
        err "Could not detect a supported package manager for '$pkg'."
        exit 1
    fi
}

# i3's package name varies slightly by distro family
i3_pkg_name() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "i3"
    elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
        echo "i3"
    elif command -v pacman >/dev/null 2>&1; then
        echo "i3-wm"
    elif command -v zypper >/dev/null 2>&1; then
        echo "i3"
    elif command -v apk >/dev/null 2>&1; then
        echo "i3wm"
    elif command -v xbps-install >/dev/null 2>&1; then
        echo "i3"
    elif command -v emerge >/dev/null 2>&1; then
        echo "x11-wm/i3"
    elif command -v eopkg >/dev/null 2>&1; then
        echo "i3"
    elif command -v nix-env >/dev/null 2>&1; then
        echo "i3"
    else
        echo "i3"
    fi
}

ensure_i3_installed() {
    if command -v i3 >/dev/null 2>&1; then
        log "i3 already installed ($(i3 --version 2>&1 | head -n1))."
    else
        local pkg
        pkg="$(i3_pkg_name)"
        log "Installing i3 (package: $pkg)..."
        install_pkg "$pkg"
        if command -v i3 >/dev/null 2>&1; then
            log "i3 installed successfully."
        else
            err "i3 install ran, but 'i3' still isn't on PATH."
            exit 1
        fi
    fi
}

# ---- config installer -------------------------------------------------
install_i3_config() {
    mkdir -p "${DEST_DIR}/scripts"

    backup_if_exists "${DEST_DIR}/config"
    fetch "${RAW_BASE}/config" "${DEST_DIR}/config"
    log "Installed ${DEST_DIR}/config"

    for s in "${SCRIPTS[@]}"; do
        backup_if_exists "${DEST_DIR}/scripts/${s}"
        fetch "${RAW_BASE}/scripts/${s}" "${DEST_DIR}/scripts/${s}"
        chmod +x "${DEST_DIR}/scripts/${s}"
        log "Installed ${DEST_DIR}/scripts/${s}"
    done
}

main() {
    pick_downloader
    ensure_i3_installed
    install_i3_config

    log "Done."
    log "Log out and select i3 from your display manager (or run 'startx' / 'exec i3' as appropriate)."
}

main "$@"
