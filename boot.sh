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
if ! command -v sudo >/dev/null 2>&1; then
    echo "$(tput setaf 1)Error: 'sudo' command not found. Please install sudo and ensure it is in your PATH."
    echo "Installation stopped."
    exit 1
fi

if ! grep -q "^ID=.*debian" /etc/os-release; then
    echo "$(tput setaf 1)Error: This installer is designed for Debian-based systems only."
    echo "Installation stopped."
    exit 1
fi

# Display banner
cat << "EOF"
Debian-WS Installer
===================
EOF

echo "Debian-WS is for Debian 13 (Trixie) installations only!"
echo "Press Enter to begin installation, or abort with Ctrl+C."
read -r

# Install required tools
if ! command -v git >/dev/null 2>&1; then
    echo "Installing git..."
    sudo apt-get update && sudo apt-get install -y git
fi

# Clone the repository
rm -rf "$DEBIAN_WS_PATH"
echo "Cloning Debian-WS repository..."
git clone https://github.com/Edior-DB/debian-ws.git "$DEBIAN_WS_PATH"

# Source the cloned scripts
source "$DEBIAN_WS_PATH/lib/core/common.sh"
source "$DEBIAN_WS_PATH/lib/core/logging.sh"

log_success "Debian-WS repository cloned successfully."
log_info "Running the main installation script..."

# Run the main installation script
cd "$DEBIAN_WS_PATH"
bash install.sh
