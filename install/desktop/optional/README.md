# Desktop Optional Applications

This directory contains optional desktop/GUI applications that users can choose to install.

## Categories

- **development.sh** - Development IDEs and editors (VS Code, etc.)
- **multimedia.sh** - Media applications (VLC, GIMP, Audacity, etc.)
- **productivity.sh** - Office and productivity apps (LibreOffice, etc.)
- **communication.sh** - Chat and email clients (Thunderbird, Discord, etc.)

## Installation Method - Flatpak First

All desktop applications prioritize Flatpak installation:

1. **Flatpak from Flathub** (primary choice)
   - Sandboxed security model
   - Automatic updates
   - Consistent cross-distribution experience
   - No dependency conflicts with system packages

2. **APT packages** (fallback)
   - When application is not available on Flathub
   - For applications that integrate better as system packages

3. **External .deb files** (last resort)
   - For vendor-specific applications (like proprietary software)
   - When neither Flatpak nor APT options are available

## Multi-Application Installation Pattern

For categories that install multiple related applications:

```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/core/logging.sh"
source "$(dirname "$0")/../../lib/install/flatpak.sh"

install_multimedia_suite() {
    local -A multimedia_apps=(
        ["VLC Media Player"]="org.videolan.VLC:vlc"
        ["GIMP"]="org.gimp.GIMP:gimp"
        ["Audacity"]="org.audacityteam.Audacity:audacity"
        ["OBS Studio"]="com.obsproject.Studio:obs-studio"
    )
    
    for app_name in "${!multimedia_apps[@]}"; do
        IFS=':' read -r flatpak_id apt_package <<< "${multimedia_apps[$app_name]}"
        
        if install_desktop_application "$app_name" "$flatpak_id" "$apt_package"; then
            setup_app_permissions "$app_name" "$flatpak_id"
        fi
    done
}

setup_app_permissions() {
    local app_name="$1"
    local flatpak_id="$2"
    
    case "$app_name" in
        "GIMP")
            # Allow file system access for image editing
            flatpak override --user --filesystem=host "$flatpak_id"
            ;;
        "OBS Studio")
            # Allow camera and microphone access
            flatpak override --user --device=all "$flatpak_id"
            ;;
        "VLC Media Player")
            # Allow access to media directories
            flatpak override --user --filesystem=xdg-videos "$flatpak_id"
            flatpak override --user --filesystem=xdg-music "$flatpak_id"
            ;;
    esac
}
```

## Benefits of Flatpak for Desktop Apps

- **Security**: Sandboxed applications with controlled permissions
- **Updates**: Automatic updates independent of system package manager
- **Compatibility**: Same application version across different Linux distributions
- **Isolation**: No conflicts with system libraries or other applications
- **User Control**: Easy permission management and application removal
