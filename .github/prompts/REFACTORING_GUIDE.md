# Debian-WS Refactoring Guide

## Overview

This guide provides specific instructions for refactoring the existing debian-ok codebase into the new function-based architecture of debian-ws, following the patterns established in the archer project.

## Refactoring Strategy

### Phase 1: Core Library Creation

1. **Extract System Functions**
   - Move OS detection logic to `lib/core/system.sh`
   - Create reusable functions for common operations
   - Standardize environment variable usage

2. **Create Package Management Layer**
   - Abstract APT operations in `lib/install/apt.sh`
   - Implement Flatpak management in `lib/install/flatpak.sh`
   - Create external package handlers in `lib/install/external.sh`

3. **Implement Logging System**
   - Create centralized logging in `lib/core/logging.sh`
   - Replace all echo statements with log functions
   - Add debug and error handling capabilities

### Phase 2: Installation Module Refactoring

#### From debian-ok to debian-ws Structure Mapping

**Old Structure** → **New Structure**

```
debian-ok/install/          → debian-ws/install/
├── terminal/               → ├── system/
│   ├── required/          → │   ├── base.sh
│   │   ├── git.sh         → │   ├── terminal-required.sh (git, curl, etc.)
│   │   ├── curl.sh        → │   ├── desktop-required.sh (firefox-esr, etc.)
│   │   └── fastfetch.sh   → │   ├── security.sh
│   └── optional/          → │   └── utilities.sh
│       ├── neovim.sh      → └── apps/
│       └── ...            →     ├── terminal/
├── desktop/               →     │   ├── development.sh (neovim, etc.)
│   ├── required/          →     │   └── productivity.sh
│   │   ├── firefox.sh     →     └── desktop/
│   │   └── ...            →         ├── development.sh (VS Code via Flatpak)
│   └── optional/          →         ├── multimedia.sh (VLC, GIMP via Flatpak)
│       ├── vscode.sh      →         └── productivity.sh (LibreOffice via Flatpak)
│       ├── gimp.sh        →
│       └── ...            →
```

#### Specific Refactoring Tasks

**1. Required Applications → System Directory (APT Only)**

Original required files go to `install/system/`:
- `install/terminal/required/git.sh` → Function in `install/system/terminal-required.sh`
- `install/terminal/required/curl.sh` → Function in `install/system/terminal-required.sh`
- `install/desktop/required/firefox.sh` → Function in `install/system/desktop-required.sh`

**2. Optional Terminal Applications → Apps/Terminal (APT/External)**

Original optional terminal files go to `install/apps/terminal/`:
- `install/terminal/optional/neovim.sh` → Function in `install/apps/terminal/development.sh`
- `install/terminal/optional/tmux.sh` → Function in `install/apps/terminal/development.sh`

**3. Optional Desktop Applications → Apps/Desktop (Flatpak First)**

Original optional desktop files go to `install/apps/desktop/`:
- `install/desktop/optional/vscode.sh` → Function in `install/apps/desktop/development.sh` (Flatpak first)
- `install/desktop/optional/gimp.sh` → Function in `install/apps/desktop/multimedia.sh` (Flatpak first)
- `install/desktop/optional/vlc.sh` → Function in `install/apps/desktop/multimedia.sh` (Flatpak first)

**3. Configuration Files Refactoring**

Original files in various locations:
- GNOME settings → `lib/config/gnome.sh`
- Terminal configs → `lib/config/terminal.sh`
- Theme files → `resources/themes/`

### Phase 3: Function Extraction Patterns

#### Pattern 1: Required Application Installation (APT Only)

**Before (debian-ok style):**
```bash
# install/terminal/required/git.sh
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    sudo apt update
    sudo apt install -y git
fi
```

**After (debian-ws style):**
```bash
# install/system/terminal-required.sh
install_git() {
    install_required_application "Git" "git"
}

# lib/install/apt.sh
install_required_application() {
    local app_name="$1"
    local package="$2"

    if check_package_installed "$package"; then
        log_info "$app_name is already installed"
        return 0
    fi

    log_info "Installing required $app_name..."
    update_package_cache

    if ! apt install -y "$package"; then
        log_error "Failed to install required $app_name"
        return 1
    fi

    log_success "$app_name installed successfully"
    return 0
}
```

#### Pattern 2: Required Desktop Application (APT Only)

**Before (debian-ok style):**
```bash
# install/desktop/required/firefox.sh
if ! command -v firefox &> /dev/null; then
    echo "Installing Firefox..."
    sudo apt update
    sudo apt install -y firefox-esr
fi
```

**After (debian-ws style):**
```bash
# install/system/desktop-required.sh
install_firefox() {
    install_required_application "Firefox" "firefox-esr"

    # Configure Firefox for system integration
    configure_firefox_system_integration
}

configure_firefox_system_integration() {
    # Set Firefox as default browser
    if command -v update-alternatives &> /dev/null; then
        update-alternatives --set x-www-browser /usr/bin/firefox-esr
    fi
}
```#### Pattern 2: Complex Configuration

**Before:**
```bash
# Inline GNOME configuration
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.wm.preferences theme "Adwaita-dark"
```

**After:**
```bash
# lib/config/gnome.sh
configure_gnome_dark_theme() {
    log_info "Configuring GNOME dark theme..."

    local settings=(
        "org.gnome.desktop.interface color-scheme prefer-dark"
        "org.gnome.desktop.wm.preferences theme Adwaita-dark"
    )

    for setting in "${settings[@]}"; do
        if ! gsettings set $setting; then
            log_warning "Failed to set: $setting"
        fi
    done

    log_success "GNOME dark theme configured"
}
```

#### Pattern 3: Desktop Application Installation (Flatpak First)

**Before (debian-ok style):**
```bash
# install/desktop/optional/firefox.sh
if ! command -v firefox &> /dev/null; then
    echo "Installing Firefox..."
    sudo apt update
    sudo apt install -y firefox-esr
fi
```

**After (debian-ws style):**
```bash
# install/desktop/required/browser.sh
install_firefox() {
    local app_name="Firefox"
    local flatpak_id="org.mozilla.firefox"
    local apt_package="firefox-esr"

    log_info "Installing $app_name browser..."

    # Flatpak first (preferred for desktop apps)
    if check_flatpak_available "$flatpak_id"; then
        if install_flatpak_app "$flatpak_id"; then
            log_success "$app_name installed via Flatpak"
            setup_firefox_flatpak_integration
            return 0
        fi
    fi

    # Fallback to APT
    log_info "Flatpak unavailable, using APT package: $apt_package"
    if install_package "$apt_package"; then
        log_success "$app_name installed via APT"
        return 0
    fi

    log_error "Failed to install $app_name"
    return 1
}

# Setup Flatpak integration for better system integration
setup_firefox_flatpak_integration() {
    # Allow filesystem access for downloads
    flatpak override --user --filesystem=xdg-download "$flatpak_id"
    # Allow theme access
    flatpak override --user --filesystem=xdg-config/gtk-3.0 "$flatpak_id"
}
```

#### Pattern 4: Multi-Application Desktop Module

**Before (multiple separate files):**
```bash
# install/desktop/optional/gimp.sh
# install/desktop/optional/vlc.sh
# install/desktop/optional/audacity.sh
```

**After (consolidated multimedia.sh):**
```bash
# install/desktop/optional/multimedia.sh
install_multimedia_apps() {
    local -A multimedia_apps=(
        ["GIMP"]="org.gimp.GIMP:gimp:"
        ["VLC"]="org.videolan.VLC:vlc:"
        ["Audacity"]="org.audacityteam.Audacity:audacity:"
        ["OBS Studio"]="com.obsproject.Studio:obs-studio:"
    )

    for app_name in "${!multimedia_apps[@]}"; do
        IFS=':' read -r flatpak_id apt_package deb_url <<< "${multimedia_apps[$app_name]}"

        log_info "Installing $app_name..."
        if install_desktop_application "$app_name" "$flatpak_id" "$apt_package" "$deb_url"; then
            configure_multimedia_app "$app_name"
        fi
    done
}

configure_multimedia_app() {
    local app_name="$1"
    case "$app_name" in
        "GIMP")
            # GIMP-specific Flatpak permissions
            flatpak override --user --filesystem=host org.gimp.GIMP
            ;;
        "OBS Studio")
            # OBS needs camera and microphone access
            flatpak override --user --device=all com.obsproject.Studio
            ;;
    esac
}
```

**Before:**
```bash
# Inline download and install
wget -O /tmp/code.deb https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64
sudo dpkg -i /tmp/code.deb
sudo apt-get install -f
```

**After:**
```bash
# lib/install/external.sh
install_from_url() {
    local name="$1"
    local url="$2"
    local temp_file="/tmp/${name}.deb"

    log_info "Downloading $name..."
    if ! download_file "$url" "$temp_file"; then
        log_error "Failed to download $name"
        return 1
    fi

    log_info "Installing $name..."
    if ! install_from_deb "$temp_file"; then
        log_error "Failed to install $name"
        return 1
    fi

    rm -f "$temp_file"
    log_success "$name installed successfully"
}

# install/apps/development/vscode.sh
install_vscode() {
    local url="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
    install_from_url "vscode" "$url"
}
```

### Phase 4: Configuration Management

#### Centralized Configuration

Create configuration management system:

```bash
# lib/config/manager.sh
apply_configuration() {
    local config_name="$1"
    local config_file="$DEBIANWS_CONFIG_DIR/$config_name.conf"

    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi

    log_info "Applying configuration: $config_name"
    source "$config_file"
}
```

#### Theme and Visual Configuration

```bash
# lib/config/themes.sh
apply_theme() {
    local theme_name="$1"
    local theme_dir="$DEBIANWS_ROOT/resources/themes/$theme_name"

    if [[ ! -d "$theme_dir" ]]; then
        log_error "Theme not found: $theme_name"
        return 1
    fi

    # Apply theme files
    copy_theme_files "$theme_dir"
    configure_gnome_theme "$theme_name"
    configure_terminal_theme "$theme_name"
}
```

### Phase 5: Main Script Refactoring

#### New Main Entry Point

```bash
# bin/debian-ws.sh
#!/bin/bash
set -euo pipefail

# Initialize environment
source "$(dirname "$0")/../lib/core/system.sh"
source "$(dirname "$0")/../lib/core/logging.sh"

main() {
    # Check prerequisites
    check_debian_version || exit 1
    check_gnome_session || exit 1

    # Show interactive menu
    show_main_menu
}

show_main_menu() {
    local choice
    while true; do
        echo "=== Debian-WS System Manager ==="
        echo "1. Install System Essentials"
        echo "2. Install Development Tools"
        echo "3. Install Multimedia Apps"
        echo "4. Configure Desktop"
        echo "5. Apply Themes"
        echo "6. Exit"

        read -p "Choose an option: " choice

        case $choice in
            1) install_system_essentials ;;
            2) install_development_tools ;;
            3) install_multimedia_apps ;;
            4) configure_desktop ;;
            5) apply_themes ;;
            6) break ;;
            *) log_warning "Invalid choice" ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### Phase 6: Testing and Validation

#### Function Testing Framework

```bash
# test/test_framework.sh
run_test() {
    local test_name="$1"
    local test_function="$2"

    echo "Running test: $test_name"

    if $test_function; then
        echo "✓ PASS: $test_name"
        return 0
    else
        echo "✗ FAIL: $test_name"
        return 1
    fi
}

# Example test
test_package_installation() {
    local test_package="curl"

    # Test installation
    install_package "$test_package"

    # Verify installation
    command -v "$test_package" &> /dev/null
}
```

## Migration Checklist

- [ ] Create core library structure (`lib/core/`)
- [ ] Implement logging system
- [ ] Create package management functions
- [ ] Refactor installation scripts to use functions
- [ ] Move configuration logic to `lib/config/`
- [ ] Update main entry points
- [ ] Create comprehensive error handling
- [ ] Implement testing framework
- [ ] Update documentation
- [ ] Test on clean Debian 12 installation

## Best Practices for Refactoring

1. **Maintain Backward Compatibility**: Ensure existing configurations work
2. **Incremental Changes**: Refactor in small, testable chunks
3. **Function Isolation**: Each function should have a single responsibility
4. **Error Propagation**: Properly handle and propagate errors
5. **Documentation**: Update documentation as you refactor
6. **Testing**: Test each refactored component individually

## Common Pitfalls to Avoid

- Don't create overly complex function hierarchies
- Avoid tight coupling between modules
- Don't ignore error conditions
- Avoid hardcoded paths and values
- Don't skip validation of function parameters
- Avoid functions that are too large or do too much
