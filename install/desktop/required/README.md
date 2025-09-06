# Desktop Required Applications

This directory contains essential desktop/GUI applications that are installed by default.

## Applications Included

- **browser.sh** - Web browser (Firefox via Flatpak)
- **files.sh** - File manager enhancements

## Installation Method - Flatpak First

Desktop applications follow this priority order:
1. **Flatpak from Flathub** (primary - sandboxed, auto-updates)
2. **APT packages** (fallback when Flatpak unavailable)
3. **External .deb files** (last resort for vendor-specific apps)

## Usage Pattern

Each script should use the Flatpak-first installation pattern:

```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/core/logging.sh"
source "$(dirname "$0")/../../lib/install/flatpak.sh"
source "$(dirname "$0")/../../lib/install/apt.sh"

install_desktop_app() {
    local app_name="$1"
    local flatpak_id="$2"
    local apt_package="$3"
    
    log_info "Installing $app_name..."
    
    # Try Flatpak first
    if [[ -n "$flatpak_id" ]] && install_flatpak_app "$flatpak_id"; then
        log_success "$app_name installed via Flatpak"
        return 0
    fi
    
    # Fallback to APT
    if [[ -n "$apt_package" ]] && install_package "$apt_package"; then
        log_success "$app_name installed via APT"
        return 0
    fi
    
    log_error "Failed to install $app_name"
    return 1
}
```

## Flatpak Integration

When installing via Flatpak, consider setting up proper permissions:

```bash
setup_flatpak_permissions() {
    local flatpak_id="$1"
    
    # Example: Allow access to downloads folder
    flatpak override --user --filesystem=xdg-download "$flatpak_id"
    
    # Example: Allow theme access
    flatpak override --user --filesystem=xdg-config/gtk-3.0 "$flatpak_id"
}
```
