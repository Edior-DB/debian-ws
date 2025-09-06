#!/bin/bash
# Version Management Library for Debian-WS
# Provides functions for checking and managing system version compatibility

# Prevent multiple sourcing
if [[ "${DEBIAN_WS_VERSION_FUNCS_LOADED:-}" == "1" ]]; then
    return 0
fi
DEBIAN_WS_VERSION_FUNCS_LOADED=1

# Source required dependencies
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/logging.sh"

# ============================================================================
# VERSION DETECTION FUNCTIONS
# ============================================================================

# Get OS information from /etc/os-release
get_os_info() {
    local info_type="${1:-all}"

    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot find /etc/os-release file"
        return 1
    fi

    source /etc/os-release

    case "$info_type" in
        "id") echo "$ID" ;;
        "version_id") echo "$VERSION_ID" ;;
        "version_codename") echo "$VERSION_CODENAME" ;;
        "name") echo "$NAME" ;;
        "pretty_name") echo "$PRETTY_NAME" ;;
        "all")
            echo "ID: $ID"
            echo "VERSION_ID: $VERSION_ID"
            echo "VERSION_CODENAME: $VERSION_CODENAME"
            echo "NAME: $NAME"
            echo "PRETTY_NAME: $PRETTY_NAME"
            ;;
        *)
            log_error "Invalid info type: $info_type"
            return 1
            ;;
    esac
}

# Export version environment variables
export_version_vars() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot find /etc/os-release file"
        return 1
    fi

    source /etc/os-release

    # Export Debian-WS specific variables
    export DEBIAN_WS_OS_ID="$ID"
    export DEBIAN_WS_OS_VERSION_ID="$VERSION_ID"
    export DEBIAN_WS_OS_VERSION_CODENAME="${VERSION_CODENAME:-unknown}"
    export DEBIAN_WS_OS_NAME="$NAME"
    export DEBIAN_WS_OS_PRETTY_NAME="$PRETTY_NAME"

    # Export major and minor version numbers if available
    if [[ "$VERSION_ID" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        export DEBIAN_WS_DEBIAN_MAJOR=$(echo $VERSION_ID | cut -d. -f1)
        export DEBIAN_WS_DEBIAN_MINOR=$(echo $VERSION_ID | cut -d. -f2)
    fi

    log_debug "Version variables exported: $ID $VERSION_ID ($VERSION_CODENAME)"
}

# Check if running on Debian
is_debian() {
    local os_id=$(get_os_info "id")
    [[ "$os_id" == "debian" ]]
}

# Check if running specific Debian version
is_debian_version() {
    local required_version="$1"

    if [[ -z "$required_version" ]]; then
        log_error "Version number required"
        return 1
    fi

    if ! is_debian; then
        return 1
    fi

    local current_version=$(get_os_info "version_id")
    [[ "$current_version" == "$required_version" ]]
}

# Check if running Debian 13 (Trixie)
is_debian_trixie() {
    is_debian_version "13"
}

# ============================================================================
# VERSION VALIDATION FUNCTIONS
# ============================================================================

# Validate Debian 13 (Trixie) requirement
validate_debian_trixie() {
    local show_success="${1:-true}"

    log_info "Checking Debian version compatibility..."

    # Check if running on Debian
    if ! is_debian; then
        local os_id=$(get_os_info "id")
        local version_id=$(get_os_info "version_id")

        log_error "Debian-WS requires Debian Linux"
        log_error "You are currently running: $os_id $version_id"
        log_info "Please install Debian 13 (Trixie) to use this installer"
        return 1
    fi

    # Check if running Debian 13 (Trixie)
    if ! is_debian_trixie; then
        local version_id=$(get_os_info "version_id")
        local version_codename=$(get_os_info "version_codename")

        log_error "Debian-WS requires Debian 13 (Trixie)"
        log_error "You are currently running: Debian $version_id ($version_codename)"
        log_info "Please upgrade to Debian 13 (Trixie) to use this installer"
        echo ""
        log_info "Debian 13 (Trixie) features:"
        echo "  • Latest package versions"
        echo "  • Modern desktop environment"
        echo "  • Enhanced security features"
        echo "  • Better hardware support"
        return 1
    fi

    # Export version variables
    export_version_vars

    if [[ "$show_success" == "true" ]]; then
        local version_id=$(get_os_info "version_id")
        local version_codename=$(get_os_info "version_codename")
        log_success "Debian version check passed: Debian $version_id ($version_codename)"
    fi

    return 0
}

# Get system architecture in standardized format
get_debian_arch() {
    local arch=$(uname -m)

    case "$arch" in
        x86_64) echo "amd64" ;;
        aarch64) echo "arm64" ;;
        armv7l) echo "armhf" ;;
        i386|i686) echo "i386" ;;
        *) echo "$arch" ;;
    esac
}

# Check if architecture is supported
is_supported_arch() {
    local arch=$(get_debian_arch)

    case "$arch" in
        amd64|arm64|armhf) return 0 ;;
        *) return 1 ;;
    esac
}

# Validate system architecture
validate_system_arch() {
    local arch=$(get_debian_arch)

    if is_supported_arch; then
        log_debug "System architecture: $arch (supported)"
        return 0
    else
        log_error "Unsupported system architecture: $arch"
        log_info "Supported architectures: amd64, arm64, armhf"
        return 1
    fi
}

# ============================================================================
# PACKAGE AVAILABILITY VALIDATION
# ============================================================================

# Check if a package is available in Debian 13 repositories
is_package_available() {
    local package_name="$1"

    if [[ -z "$package_name" ]]; then
        log_error "Package name required"
        return 1
    fi

    # Check if package exists in apt cache
    if apt-cache show "$package_name" >/dev/null 2>&1; then
        log_debug "Package available: $package_name"
        return 0
    else
        log_warning "Package not available: $package_name"
        return 1
    fi
}

# Validate a list of packages for Debian 13 compatibility
validate_package_list() {
    local packages=("$@")
    local missing_packages=()
    local validated_packages=()

    log_info "Validating package availability for Debian 13..."

    for package in "${packages[@]}"; do
        if is_package_available "$package"; then
            validated_packages+=("$package")
        else
            missing_packages+=("$package")
        fi
    done

    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        log_error "The following packages are not available in Debian 13:"
        printf '  - %s\n' "${missing_packages[@]}"
        return 1
    fi

    log_success "All packages validated for Debian 13 compatibility"
    return 0
}

# Check if Flatpak runtime is compatible with Debian 13
validate_flatpak_runtime() {
    local runtime_id="${1:-org.freedesktop.Platform}"
    local runtime_version="${2:-24.08}"

    if ! command -v flatpak >/dev/null 2>&1; then
        log_debug "Flatpak not installed, skipping runtime validation"
        return 0
    fi

    log_debug "Validating Flatpak runtime: $runtime_id//$runtime_version"

    # Check if runtime is available
    if flatpak list --runtime | grep -q "$runtime_id"; then
        log_debug "Flatpak runtime validated: $runtime_id"
        return 0
    else
        log_debug "Flatpak runtime not found (will be installed): $runtime_id"
        return 0
    fi
}

# ============================================================================
# COMPREHENSIVE SYSTEM VALIDATION
# ============================================================================

# Complete system validation for Debian-WS
validate_system_requirements() {
    log_info "Validating system requirements for Debian-WS..."

    local validation_failed=0

    # Check Debian 13 (Trixie) requirement
    if ! validate_debian_trixie "false"; then
        validation_failed=1
    fi

    # Check system architecture
    if ! validate_system_arch; then
        validation_failed=1
    fi

    # Check APT package manager
    if ! command -v apt >/dev/null 2>&1; then
        log_error "APT package manager not found"
        validation_failed=1
    fi

    if [[ $validation_failed -eq 1 ]]; then
        log_error "System validation failed"
        return 1
    fi

    # Export version variables
    export_version_vars

    local version_id=$(get_os_info "version_id")
    local version_codename=$(get_os_info "version_codename")
    local arch=$(get_debian_arch)

    log_success "System validation passed"
    log_info "System: Debian $version_id ($version_codename) on $arch"

    return 0
}
