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
│   └── optional/          → │   └── utilities.sh
├── desktop/               → └── apps/
│   ├── required/          →     ├── development/
│   └── optional/          →     ├── multimedia/
└── *                      →     └── productivity/
```

#### Specific Refactoring Tasks

**1. Terminal Tools Refactoring**

Original files in `install/terminal/required/`:
- `alacritty.sh` → Function in `lib/config/terminal.sh`
- `fastfetch.sh` → Function in `install/system/utilities.sh`
- `zsh.sh` → Function in `lib/config/terminal.sh`

**2. Desktop Applications Refactoring**

Original files in `install/desktop/`:
- Browser installations → `install/apps/productivity/browsers.sh`
- Development tools → `install/apps/development/`
- Media applications → `install/apps/multimedia/`

**3. Configuration Files Refactoring**

Original files in various locations:
- GNOME settings → `lib/config/gnome.sh`
- Terminal configs → `lib/config/terminal.sh`
- Theme files → `resources/themes/`

### Phase 3: Function Extraction Patterns

#### Pattern 1: Simple Package Installation

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
# lib/install/apt.sh
install_package() {
    local package="$1"

    if check_package_installed "$package"; then
        log_info "$package is already installed"
        return 0
    fi

    log_info "Installing $package..."
    update_package_cache

    if ! apt install -y "$package"; then
        log_error "Failed to install $package"
        return 1
    fi

    log_success "$package installed successfully"
    return 0
}

# install/system/base.sh
install_git() {
    install_package "git"
}
```

#### Pattern 2: Complex Configuration

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

#### Pattern 3: External Package Installation

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
