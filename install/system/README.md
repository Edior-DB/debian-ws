# System Required Applications

This directory contains **all required applications** for the Debian-WS installation, both terminal and desktop applications.

## Key Principle: APT Packages Only

**All required applications must be installed from official Debian repositories using APT**, even desktop applications. This ensures:
- Better system integration
- Proper dependency management
- Stable, tested versions
- Consistent package management

## Applications Included

### Terminal Required (`terminal-required.sh`)
- **git** - Version control system
- **curl** - HTTP client and download tool
- **wget** - File retrieval utility
- **fastfetch** - System information display
- **tree** - Directory tree display
- **unzip** - Archive extraction

### Desktop Required (`desktop-required.sh`)
- **firefox-esr** - Web browser (Debian ESR version)
- **gnome-tweaks** - GNOME customization tool
- **gnome-software** - Software center
- **file-roller** - Archive manager

### System Base (`base.sh`)
- Essential system packages
- Build tools and compilers
- Network utilities

### Security (`security.sh`)
- Firewall tools
- Security utilities
- System hardening tools

## Installation Pattern

Required applications use a simple APT-only pattern:

```bash
#!/bin/bash
source "$(dirname "$0")/../lib/core/logging.sh"
source "$(dirname "$0")/../lib/install/apt.sh"

install_required_terminal_apps() {
    local required_apps=(
        "git"
        "curl"
        "wget"
        "fastfetch"
        "tree"
        "unzip"
    )

    log_info "Installing required terminal applications..."

    for app in "${required_apps[@]}"; do
        if ! install_required_application "$app" "$app"; then
            log_error "Failed to install required app: $app"
            return 1
        fi
    done

    log_success "All required terminal applications installed"
}

install_required_application() {
    local app_name="$1"
    local package_name="$2"

    if check_package_installed "$package_name"; then
        log_info "$app_name already installed"
        return 0
    fi

    log_info "Installing required $app_name..."

    if ! install_package "$package_name"; then
        log_error "Failed to install required $app_name"
        return 1
    fi

    log_success "$app_name installed successfully"
    return 0
}
```

## Why APT Only for Required Apps?

1. **System Stability**: Debian repository packages are thoroughly tested
2. **Dependency Management**: APT handles dependencies automatically
3. **Security Updates**: Security patches delivered through apt update
4. **Integration**: Better integration with system services and configurations
5. **Predictability**: Consistent behavior across Debian installations
