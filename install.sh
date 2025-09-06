#!/bin/bash
set -eEuo pipefail

# Initialize for error reporting
current_command=""
last_command=""

# Improved error reporting
function debian_ws_error_trap {
  local exit_code=$?
  log_error "Installation failed! Command: $last_command, Exit code: $exit_code"
}
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'debian_ws_error_trap' ERR

# Source common functions
source "$(dirname "$0")/lib/core/common.sh"
source "$(dirname "$0")/lib/core/logging.sh"
source "$(dirname "$0")/lib/core/version.sh"

show_banner "Debian-WS Installation"

log_info "Starting Debian-WS installation..."

# Perform comprehensive system validation once
if ! validate_system_requirements; then
    log_error "System validation failed. Installation cannot continue."
    exit 1
fi

# Choose package installer (apt or nala)
if command -v nala >/dev/null 2>&1; then
  INSTALLER='nala'
else
  if confirm_action "Do you want to install nala? It works faster..."; then
    install_with_retries nala
    INSTALLER='nala'
  else
    INSTALLER='apt'
  fi
fi
export INSTALLER

log_info "Using $INSTALLER as the package manager."

# Install terminal tools
log_info "Installing terminal tools..."
bash "$(dirname "$0")/install/system/terminal-required.sh"

# Install desktop tools (if GNOME is detected)
if check_gnome_desktop; then
  log_info "Installing desktop tools..."
  bash "$(dirname "$0")/install/system/desktop-required.sh"
else
  log_warning "GNOME desktop not detected. Skipping desktop tools installation."
fi

log_success "Debian-WS installation completed successfully!"
