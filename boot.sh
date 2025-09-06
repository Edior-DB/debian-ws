#!/bin/bash
set -euo pipefail

# Set and export DEBIAN_WS_PATH for consistency
export DEBIAN_WS_PATH="$HOME/.local/share/debian-ws"

# Prevent running as root
if [[ $EUID -eq 0 ]]; then
    echo "$(tput setaf 1)Error: Do not run this installer as root. Please run as a regular user with sudo privileges."
    echo "Installation stopped."
    exit 1
fi

# Early checks for required commands and OS
source "$(dirname "$0")/lib/core/common.sh"
source "$(dirname "$0")/lib/core/logging.sh"

if ! check_sudo_privileges; then
    log_error "Sudo privileges are required to run this installer."
    exit 1
fi

if ! check_debian_system; then
    log_error "This installer is designed for Debian-based systems only."
    exit 1
fi

show_banner "Debian-WS Installer"
log_info "Debian-WS is for fresh Debian 12+ (Bookworm or newer) installations only!"
wait_for_input "Press Enter to begin installation, or abort with Ctrl+C."

log_info "Installing required tools..."
install_with_retries git

log_info "Cloning Debian-WS repository..."
rm -rf "$DEBIAN_WS_PATH"
git clone https://github.com/Edior-DB/debian-ws.git "$DEBIAN_WS_PATH"

log_success "Debian-WS repository cloned successfully."
log_info "You can now run the main installation script: $DEBIAN_WS_PATH/install.sh"
