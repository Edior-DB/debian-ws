#!/bin/bash
# Common Functions Library for Debian-WS
# Shared functions to eliminate code duplication across scripts
# Source this file in other scripts: source "$(dirname "${BASH_SOURCE[0]}")/../core/common.sh"

# Prevent multiple sourcing
if [[ "${DEBIAN_WS_COMMON_FUNCS_LOADED}" == "1" ]]; then
    return 0
fi
DEBIAN_WS_COMMON_FUNCS_LOADED=1

# Source required dependencies
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/logging.sh"

# ============================================================================
# USER INTERFACE FUNCTIONS (GUM-based)
# ============================================================================

# Confirm function using gum
confirm_action() {
    local message="$1"
    local default="${2:-false}"

    if command -v gum &> /dev/null; then
        if [[ "$default" == "true" ]]; then
            gum confirm --default "$message"
        else
            gum confirm "$message"
        fi
    else
        # Fallback without gum
        log_warning "gum not available, using fallback confirmation"
        read -p "$message (y/N): " choice
        case "${choice,,}" in
            y|yes) return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# Wait function using gum
wait_for_input() {
    local message="${1:-Press Enter to continue...}"

    if command -v gum &> /dev/null; then
        gum input --placeholder "$message" --value "" > /dev/null
    else
        read -p "$message"
    fi
}

# Input function using gum
get_input() {
    local prompt="$1"
    local placeholder="${2:-}"
    local default="${3:-}"

    if command -v gum &> /dev/null; then
        local result
        if [[ -n "$default" ]]; then
            result=$(gum input --prompt "$prompt " --placeholder "$placeholder" --value "$default")
        else
            result=$(gum input --prompt "$prompt " --placeholder "$placeholder")
        fi
        echo "$result"
    else
        # Fallback without gum
        if [[ -n "$default" ]]; then
            read -p "$prompt [$default]: " input
            echo "${input:-$default}"
        else
            read -p "$prompt: " input
            echo "$input"
        fi
    fi
}

# Enhanced selection function using gum
select_option() {
    local options=("$@")

    if command -v gum &> /dev/null; then
        gum choose "${options[@]}"
    else
        # Fallback without gum
        log_warning "gum not available, using fallback selection"
        echo "Please select an option:"
        for i in "${!options[@]}"; do
            echo "$((i+1)). ${options[$i]}"
        done

        while true; do
            read -p "Enter selection (1-${#options[@]}): " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#options[@]} ]]; then
                echo "${options[$((choice-1))]}"
                return 0
            else
                echo "Invalid selection. Please try again."
            fi
        done
    fi
}

# Multi-select function using gum
multi_select() {
    local options=("$@")

    if command -v gum &> /dev/null; then
        gum choose --no-limit "${options[@]}"
    else
        # Fallback without gum
        log_warning "gum not available, using fallback multi-selection"
        echo "Select multiple options (space-separated numbers):"
        for i in "${!options[@]}"; do
            echo "$((i+1)). ${options[$i]}"
        done

        read -p "Enter selections (e.g., 1 3 5): " choices
        local selected=()
        for choice in $choices; do
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#options[@]} ]]; then
                selected+=("${options[$((choice-1))]}")
            fi
        done

        printf '%s\n' "${selected[@]}"
    fi
}

# ============================================================================
# PACKAGE INSTALLATION WITH RETRY LOGIC
# ============================================================================

# Enhanced package installation function with retry logic for APT
# Usage: install_with_retries package1 package2 ...
install_with_retries() {
    local packages=("$@")
    local filtered_packages=()

    if [[ ${#packages[@]} -eq 0 ]]; then
        log_error "No packages specified for installation"
        return 1
    fi

    # Check if packages are already installed
    for pkg in "${packages[@]}"; do
        if dpkg -l "$pkg" &>/dev/null; then
            log_success "$pkg is already installed and up-to-date"
        else
            filtered_packages+=("$pkg")
        fi
    done

    # If all packages are already installed
    if [[ ${#filtered_packages[@]} -eq 0 ]]; then
        log_success "All packages are already installed and up-to-date"
        return 0
    fi

    local retry_count=0
    local max_retries=3

    while [ $retry_count -lt $max_retries ]; do
        log_info "Installing: ${filtered_packages[*]} - Attempt $((retry_count + 1)) of $max_retries"

        if sudo apt install -y "${filtered_packages[@]}"; then
            log_success "Packages installed successfully: ${filtered_packages[*]}"
            return 0
        fi

        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            log_warning "Installation failed, retrying in 3 seconds..."
            sleep 3
            sudo apt update
        else
            log_error "Installation failed after $max_retries attempts!"
            log_error "Please check your network connection and package availability"

            if command -v gum >/dev/null 2>&1 && confirm_action "Would you like to try installing again?"; then
                retry_count=0
                log_info "Retrying installation..."
                sudo apt update
            else
                log_error "Installation cannot continue without these packages: ${filtered_packages[*]}"
                return 1
            fi
        fi
    done
}

# Download file with retry logic
download_with_retries() {
    local url="$1"
    local output_file="$2"
    local max_retries="${3:-3}"
    local retry_count=0

    if [[ -z "$url" || -z "$output_file" ]]; then
        log_error "URL and output file are required for download"
        return 1
    fi

    while [ $retry_count -lt $max_retries ]; do
        log_info "Downloading: $url - Attempt $((retry_count + 1)) of $max_retries"

        if wget -q -O "$output_file" "$url"; then
            log_success "Download completed: $output_file"
            return 0
        fi

        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            log_warning "Download failed, retrying in 3 seconds..."
            sleep 3
        else
            log_error "Download failed after $max_retries attempts: $url"
            rm -f "$output_file"
            return 1
        fi
    done
}

# ============================================================================
# SYSTEM DETECTION FUNCTIONS
# ============================================================================

# Check if running on Debian-based system
check_debian_system() {
    if ! command -v apt >/dev/null 2>&1; then
        log_error "This script requires a Debian-based system with APT package manager"
        return 1
    fi

    if [[ -f /etc/debian_version ]]; then
        local debian_version=$(cat /etc/debian_version)
        log_debug "Detected Debian-based system: version $debian_version"
        return 0
    elif [[ -f /etc/os-release ]]; then
        local os_id=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
        if [[ "$os_id" == "debian" || "$os_id" == "ubuntu" ]]; then
            log_debug "Detected Debian-based system: $os_id"
            return 0
        fi
    fi

    log_error "This script requires a Debian-based system"
    return 1
}

# Check if user has sudo privileges
check_sudo_privileges() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root. Consider running as regular user with sudo privileges"
        return 0
    fi

    # Test sudo access without password prompt
    if sudo -n true 2>/dev/null; then
        log_debug "Sudo access available (passwordless)"
        return 0
    fi

    # Test sudo access with password prompt
    log_info "Testing sudo access..."
    if sudo true; then
        log_debug "Sudo access confirmed"
        return 0
    else
        log_error "User does not have sudo privileges"
        log_info "Please ensure your user is in the sudo group:"
        log_info "  sudo usermod -aG sudo \$USER"
        log_info "Then logout and login again"
        return 1
    fi
}

# Check internet connection
check_internet() {
    log_debug "Checking internet connection..."

    local test_hosts=("8.8.8.8" "1.1.1.1" "google.com")

    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 5 "$host" &> /dev/null; then
            log_debug "Internet connection: OK (via $host)"
            return 0
        fi
    done

    log_error "No internet connection detected"
    log_info "Please ensure you have an active internet connection"
    return 1
}

# Check if GNOME desktop environment is running
check_gnome_desktop() {
    if [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]] || [[ "${DESKTOP_SESSION:-}" == *"gnome"* ]]; then
        log_debug "GNOME desktop environment detected"
        return 0
    elif [[ -n "${GNOME_DESKTOP_SESSION_ID:-}" ]]; then
        log_debug "GNOME desktop environment detected (legacy detection)"
        return 0
    else
        log_warning "GNOME desktop environment not detected"
        log_info "Current desktop: ${XDG_CURRENT_DESKTOP:-Unknown}"
        log_info "This tool is optimized for GNOME desktop environment"
        return 1
    fi
}

# ============================================================================
# BANNER AND DISPLAY FUNCTIONS
# ============================================================================

# Standard script headers
show_banner() {
    local title="$1"
    local color="${2:-$COLOR_BLUE}"

    echo -e "$color"
    echo "========================================================================="
    echo "                    $title"
    echo "========================================================================="
    echo -e "$COLOR_RESET"
}

# Show completion message
show_completion() {
    local title="$1"
    local description="$2"

    echo -e "$COLOR_GREEN"
    echo "========================================================================="
    echo "                    $title"
    echo "========================================================================="
    echo ""
    echo -e "$description"
    echo ""
    echo -e "$COLOR_RESET"
}

# Show progress indicator
show_progress() {
    local current="$1"
    local total="$2"
    local description="$3"

    local percentage=$((current * 100 / total))
    local progress_bar=""
    local bar_length=50
    local filled_length=$((percentage * bar_length / 100))

    for ((i=0; i<filled_length; i++)); do
        progress_bar+="█"
    done

    for ((i=filled_length; i<bar_length; i++)); do
        progress_bar+="░"
    done

    printf "\r${COLOR_CYAN}[%s] %d%% (%d/%d) %s${COLOR_RESET}" \
           "$progress_bar" "$percentage" "$current" "$total" "$description"

    if [[ $current -eq $total ]]; then
        echo # New line when complete
    fi
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Safe directory creation
create_directory() {
    local dir_path="$1"
    local permissions="${2:-755}"

    if [[ -z "$dir_path" ]]; then
        log_error "Directory path is required"
        return 1
    fi

    if [[ -d "$dir_path" ]]; then
        log_debug "Directory already exists: $dir_path"
        return 0
    fi

    if mkdir -p "$dir_path"; then
        chmod "$permissions" "$dir_path"
        log_debug "Created directory: $dir_path"
        return 0
    else
        log_error "Failed to create directory: $dir_path"
        return 1
    fi
}

# Safe file backup
backup_file() {
    local file_path="$1"
    local backup_suffix="${2:-.backup.$(date +%Y%m%d_%H%M%S)}"

    if [[ ! -f "$file_path" ]]; then
        log_warning "File does not exist for backup: $file_path"
        return 1
    fi

    local backup_path="${file_path}${backup_suffix}"

    if cp "$file_path" "$backup_path"; then
        log_debug "Created backup: $backup_path"
        echo "$backup_path"
        return 0
    else
        log_error "Failed to create backup of: $file_path"
        return 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get system architecture
get_system_arch() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64) echo "amd64" ;;
        aarch64) echo "arm64" ;;
        armv7l) echo "armhf" ;;
        *) echo "$arch" ;;
    esac
}

# Generate random string
generate_random_string() {
    local length="${1:-16}"
    tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length"
}

# Cleanup function to be called on script exit
cleanup_common() {
    # Clear any leftover input
    while read -r -t 0.1; do true; done 2>/dev/null || true

    # Reset terminal state
    stty sane 2>/dev/null || true
}

# Set up cleanup trap for common functions
trap cleanup_common EXIT

log_debug "Common functions library loaded"
