# Debian-WS Architecture Prompt

## Project Overview

Debian-WS is a comprehensive Debian 12+ installation and configuration suite, refactored from debian-ok with a modular, function-based architecture inspired by the archer project structure.

## Core Principles

1. **Function-Based Architecture**: All code is organized into reusable functions
2. **Modular Design**: Components are separated by functionality and purpose
3. **Security First**: Modern package management with proper keyring handling
4. **Idempotent Operations**: All scripts can be run multiple times safely
5. **Error Handling**: Comprehensive error detection and recovery
6. **Environment Detection**: Smart detection of OS, desktop environment, and hardware

## Directory Structure

```
debian-ws/
├── bin/                          # Executable scripts and main entry points
│   ├── debian-ws.sh             # Main system management menu
│   └── boot.sh                  # Quick installation bootstrap
├── lib/                         # Shared library functions
│   ├── core/                    # Core system functions
│   │   ├── system.sh           # System detection and utilities
│   │   ├── package.sh          # Package management functions
│   │   ├── network.sh          # Network and connectivity functions
│   │   └── logging.sh          # Logging and output functions
│   ├── install/                 # Installation helper functions
│   │   ├── apt.sh              # APT-specific functions
│   │   ├── flatpak.sh          # Flatpak management functions
│   │   ├── snap.sh             # Snap package functions
│   │   └── external.sh         # External package downloads
│   └── config/                  # Configuration management functions
│       ├── gnome.sh            # GNOME-specific configurations
│       ├── terminal.sh         # Terminal configurations
│       └── dotfiles.sh         # Dotfile management
├── install/                     # Installation modules
│   ├── system/                  # Required system and application packages
│   │   ├── base.sh             # Essential system packages
│   │   ├── security.sh         # Security tools and configurations
│   │   ├── drivers.sh          # Hardware drivers
│   │   ├── utilities.sh        # System utilities
│   │   ├── terminal-required.sh# Required terminal applications
│   │   └── desktop-required.sh # Required desktop applications (from Debian repos)
│   └── apps/                    # Optional applications
│       ├── terminal/            # Optional CLI/terminal applications
│       │   ├── development.sh   # Dev tools (neovim, tmux, etc.)
│       │   ├── network.sh       # Network utilities
│       │   └── productivity.sh  # CLI productivity tools
│       └── desktop/             # Optional GUI applications (prefer Flatpak)
│           ├── development.sh   # IDE/editors (VS Code, etc.)
│           ├── multimedia.sh    # Media apps (VLC, GIMP, etc.)
│           ├── productivity.sh  # Office apps (LibreOffice, etc.)
│           └── communication.sh # Chat/email clients
├── resources/                   # Static resources and configurations
│   ├── configs/                 # Configuration files
│   ├── themes/                  # Theme and styling files
│   └── defaults/                # Default settings and templates
├── uninstall/                   # Uninstallation and cleanup scripts
└── .github/                     # GitHub-specific files
    ├── prompts/                 # AI prompts and instructions
    └── workflows/               # CI/CD workflows (future)
```

## Function Organization Guidelines

### Core Functions (`lib/core/`)
- System detection and environment checking
- Package management abstractions
- Network connectivity and DNS handling
- Logging and user feedback
- Error handling and recovery

### Installation Functions (`lib/install/`)
- Package manager specific operations
- External software installation
- Dependency resolution
- Installation verification
- Flatpak management and preference handling

### Configuration Functions (`lib/config/`)
- Desktop environment setup
- Application configuration
- User preference management
- System setting modifications

## Application Installation Strategy

### Required Applications (`install/system/`)
All required applications (both terminal and desktop) are installed from Debian repositories:
1. **APT packages only** - Use official Debian package repositories
2. **System integration** - Better integration with system package management
3. **Stability** - Tested and stable versions from Debian
4. **Dependencies** - Proper dependency resolution through APT

Examples:
- `firefox-esr` (required desktop browser)
- `git` (required version control)
- `curl` (required HTTP client)
- `gnome-tweaks` (required desktop customization)

### Optional Terminal Applications (`install/apps/terminal/`)
Optional CLI/terminal applications follow this priority:
1. **APT packages** for system tools and widely available packages
2. **External downloads** for tools not in Debian repositories
3. **Manual installation** for specialized tools
4. **Snap packages** as fallback for some development tools

### Optional Desktop Applications (`install/apps/desktop/`) - Flatpak First
Optional GUI applications follow this priority order:
1. **Flatpak (Flathub)** - Primary choice for optional desktop applications
   - Sandboxed security model
   - Automatic updates
   - Consistent user experience
   - Avoid dependency conflicts with system packages
2. **APT packages** - For applications not available as Flatpak
3. **External .deb files** - For vendor-specific applications
4. **Snap packages** - Last resort for GUI applications

### Installation Implementation Patterns

#### Required Applications Pattern (System)
```bash
# Example: Install required application from Debian repos
install_required_app() {
    local app_name="$1"
    local package_name="$2"

    log_info "Installing required $app_name..."

    if ! install_package "$package_name"; then
        log_error "Failed to install required $app_name"
        return 1
    fi

    log_success "$app_name installed successfully"
    return 0
}
```

#### Optional Desktop Applications Pattern (Flatpak First)
```bash
# Example: Install optional desktop application with Flatpak preference
install_optional_desktop_app() {
    local app_name="$1"
    local flatpak_id="$2"
    local apt_package="$3"

    # Try Flatpak first for optional desktop apps
    if install_flatpak_app "$flatpak_id"; then
        log_success "$app_name installed via Flatpak"
        return 0
    fi

    # Fallback to APT if available
    if [[ -n "$apt_package" ]]; then
        log_info "Flatpak unavailable, trying APT package: $apt_package"
        install_package "$apt_package"
    else
        log_warning "$app_name not available via Flatpak or APT"
        return 1
    fi
}
```## Coding Standards

1. **Function Naming**: Use descriptive, verb-noun combinations
   - `install_package()`, `check_system()`, `configure_gnome()`

2. **Error Handling**: Every function should handle errors gracefully
   ```bash
   install_package() {
       local package="$1"
       if ! command -v "$package" &> /dev/null; then
           log_info "Installing $package..."
           apt install -y "$package" || {
               log_error "Failed to install $package"
               return 1
           }
       fi
   }
   ```

3. **Documentation**: All functions must have header comments
   ```bash
   # Install a package if not already present
   # Args: $1 - package name
   # Returns: 0 on success, 1 on failure
   install_package() {
       # function body
   }
   ```

4. **Modularity**: Each function should do one thing well
5. **Testing**: Functions should be testable in isolation

## Security Considerations

- Use `/etc/apt/keyrings/` for GPG keys
- Validate all downloads with checksums
- Implement proper sudo/root privilege checking
- Sanitize all user inputs
- Use secure defaults for all configurations

## Integration Points

- Compatible with existing debian-ok configurations
- Maintains backward compatibility where possible
- Integrates with systemd services
- Supports both interactive and automated installations
