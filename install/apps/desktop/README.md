# Optional Desktop Applications - Flatpak First

This directory contains **optional GUI/desktop applications** that users can choose to install.

## Installation Strategy: Flatpak First

Optional desktop applications prioritize Flatpak for better security and user experience:

1. **🥇 Flatpak (Flathub)** - Primary choice
   - Sandboxed security model
   - Automatic updates independent of system
   - Consistent versions across distributions
   - No dependency conflicts with system packages

2. **🥈 APT packages** - Fallback
   - When application not available on Flathub
   - For applications requiring deep system integration

3. **🥉 External .deb files** - Last resort
   - Vendor-specific applications
   - When neither Flatpak nor APT available

## Categories

### Development Tools (`development.sh`)
- **VS Code** - `com.visualstudio.code` (Flatpak) / `code` (APT)
- **IntelliJ IDEA** - `com.jetbrains.IntelliJ-IDEA-Community` (Flatpak)
- **GitKraken** - `com.axosoft.GitKraken` (Flatpak)
- **Postman** - `com.getpostman.Postman` (Flatpak)
- **DBeaver** - `io.dbeaver.DBeaverCommunity` (Flatpak)

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
