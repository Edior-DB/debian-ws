# Terminal Required Applications

This directory contains essential terminal/CLI applications that are installed by default.

## Applications Included

- **git.sh** - Version control system
- **curl.sh** - HTTP client and download tool
- **fastfetch.sh** - System information display
- **zsh.sh** - Advanced shell configuration

## Installation Method

Terminal applications in this category are installed using:
1. APT packages (primary)
2. External downloads (for tools not in Debian repos)
3. Manual compilation (for cutting-edge tools)

## Usage

Each script in this directory should follow the function-based pattern:

```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/core/logging.sh"
source "$(dirname "$0")/../../lib/install/apt.sh"

install_terminal_app() {
    local app_name="$1"
    local package_name="$2"

    log_info "Installing $app_name..."

    if install_package "$package_name"; then
        log_success "$app_name installed successfully"
        return 0
    else
        log_error "Failed to install $app_name"
        return 1
    fi
}
```
