# Optional Desktop Applications

This directory contains installers for optional desktop applications using Flatpak-first strategy.

## Categories

### Multimedia (`multimedia.sh`)
- **VLC Media Player** - Universal media player
- **GIMP** - Advanced image editor
- **Audacity** - Audio editor and recorder
- **OBS Studio** - Live streaming and recording
- **Spotify** - Music streaming service
- **Pinta** - Simple image editor
- **Flameshot** - Screenshot tool

### Development (`development.sh`)
- **Visual Studio Code** - Microsoft's code editor
- **VSCodium** - Open source build of VS Code
- **Cursor** - AI-powered code editor
- **Zed** - High-performance code editor
- **RubyMine** - JetBrains Ruby IDE

### Productivity (`productivity.sh`)
- **LibreOffice** - Complete office suite
- **Obsidian** - Knowledge management and note-taking
- **Signal** - Secure messaging
- **1Password** - Password manager
- **Dropbox** - Cloud storage
- **Zoom** - Video conferencing

### Gaming & Entertainment (`gaming.sh`)
- **Steam** - Gaming platform
- **RetroArch** - Multi-platform emulator
- **PrismLauncher** - Minecraft launcher
- **Discord** - Voice and text chat for gaming

## Installation Strategy

All applications in this directory use **Flatpak-first strategy**:

1. **Primary**: Install from Flathub when available
2. **Fallback**: Use official repositories or manual installation
3. **Benefits**: Sandboxed applications, automatic updates, consistent experience

## Usage

### Interactive Installation
```bash
# Install all categories with guided selection
./install-desktop-apps.sh

# Install specific category
./multimedia.sh
./development.sh
./productivity.sh
./gaming.sh
```

### From Main Script
```bash
# Use the main Debian-WS installer
../../../bin/debian-ws.sh
```

### Multimedia (`multimedia.sh`)
- **VLC** - `org.videolan.VLC` (Flatpak) / `vlc` (APT)
- **GIMP** - `org.gimp.GIMP` (Flatpak) / `gimp` (APT)
- **Audacity** - `org.audacityteam.Audacity` (Flatpak) / `audacity` (APT)
- **OBS Studio** - `com.obsproject.Studio` (Flatpak) / `obs-studio` (APT)
- **Blender** - `org.blender.Blender` (Flatpak) / `blender` (APT)

### Productivity (`productivity.sh`)
- **LibreOffice** - `org.libreoffice.LibreOffice` (Flatpak) / `libreoffice` (APT)
- **Thunderbird** - `org.mozilla.Thunderbird` (Flatpak) / `thunderbird` (APT)
- **Slack** - `com.slack.Slack` (Flatpak)
- **Discord** - `com.discordapp.Discord` (Flatpak)
- **Zoom** - `us.zoom.Zoom` (Flatpak)

### Communication (`communication.sh`)
- **Signal** - `org.signal.Signal` (Flatpak)
- **Telegram** - `org.telegram.desktop` (Flatpak) / `telegram-desktop` (APT)
- **WhatsApp** - `io.github.mimbrero.WhatsAppDesktop` (Flatpak)
- **Teams** - `com.microsoft.Teams` (Flatpak)

## Installation Pattern

Optional desktop applications use the Flatpak-first pattern:

```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/core/logging.sh"
source "$(dirname "$0")/../../lib/install/flatpak.sh"
source "$(dirname "$0")/../../lib/install/apt.sh"

install_multimedia_suite() {
    log_info "Installing optional multimedia applications..."

    # Define applications with Flatpak preference
    local -A multimedia_apps=(
        ["VLC Media Player"]="org.videolan.VLC:vlc"
        ["GIMP"]="org.gimp.GIMP:gimp"
        ["Audacity"]="org.audacityteam.Audacity:audacity"
        ["OBS Studio"]="com.obsproject.Studio:obs-studio"
    )

    # Ensure Flatpak is set up
    setup_flatpak || {
        log_error "Failed to setup Flatpak"
        return 1
    }

    for app_name in "${!multimedia_apps[@]}"; do
        IFS=':' read -r flatpak_id apt_package <<< "${multimedia_apps[$app_name]}"

        if install_optional_desktop_application "$app_name" "$flatpak_id" "$apt_package"; then
            setup_app_permissions "$app_name" "$flatpak_id"
        fi
    done
}

install_optional_desktop_application() {
    local app_name="$1"
    local flatpak_id="$2"
    local apt_package="$3"

    log_info "Installing optional $app_name..."

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

setup_app_permissions() {
    local app_name="$1"
    local flatpak_id="$2"

    [[ -z "$flatpak_id" ]] && return 0

    case "$app_name" in
        "GIMP")
            # Allow file system access for image editing
            flatpak override --user --filesystem=host "$flatpak_id"
            log_info "GIMP granted file system access"
            ;;
        "OBS Studio")
            # Allow camera and microphone access
            flatpak override --user --device=all "$flatpak_id"
            log_info "OBS Studio granted camera/microphone access"
            ;;
        "VLC Media Player")
            # Allow access to media directories
            flatpak override --user --filesystem=xdg-videos "$flatpak_id"
            flatpak override --user --filesystem=xdg-music "$flatpak_id"
            log_info "VLC granted media directory access"
            ;;
    esac
}
```

## Benefits of Flatpak for Optional Desktop Apps

1. **Security**: Sandboxed execution with controlled permissions
2. **Updates**: Independent update cycle, newer versions available
3. **Isolation**: No conflicts with system libraries
4. **Consistency**: Same application behavior across Linux distributions
5. **User Control**: Easy permission management and application removal
6. **Space Efficiency**: Shared runtimes reduce disk usage
