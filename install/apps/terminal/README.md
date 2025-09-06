# Optional Terminal Applications

This directory contains **optional CLI/terminal applications** that users can choose to install.

## Installation Strategy

Optional terminal applications follow this priority:
1. **APT packages** - For tools available in Debian repositories
2. **External downloads** - For specialized tools not in Debian repos
3. **Manual compilation** - For cutting-edge development tools
4. **AppImages** - For portable applications

## Categories

### Development Tools (`development.sh`)
- **neovim** - Modern Vim-based editor
- **tmux** - Terminal multiplexer
- **zsh** - Advanced shell
- **oh-my-zsh** - Zsh framework
- **fzf** - Fuzzy finder
- **ripgrep** - Fast grep alternative
- **fd** - Fast find alternative
- **bat** - Cat with syntax highlighting
- **exa/eza** - Modern ls replacement

### Network Utilities (`network.sh`)
- **nmap** - Network scanning
- **netcat** - Network swiss army knife
- **tcpdump** - Network packet analyzer
- **wireshark-cli** - Command-line Wireshark
- **dig** - DNS lookup tools
- **traceroute** - Network path tracing

### Productivity Tools (`productivity.sh`)
- **htop** - Process viewer
- **btop** - Modern system monitor
- **ncdu** - Disk usage analyzer
- **ranger** - File manager
- **mc** - Midnight Commander
- **jq** - JSON processor
- **yq** - YAML processor

## Installation Pattern

Optional terminal applications use flexible installation methods:

```bash
#!/bin/bash
source "$(dirname "$0")/../../lib/core/logging.sh"
source "$(dirname "$0")/../../lib/install/apt.sh"
source "$(dirname "$0")/../../lib/install/external.sh"

install_development_tools() {
    log_info "Installing optional development tools..."

    # APT packages first
    local apt_tools=(
        "neovim"
        "tmux"
        "zsh"
        "fzf"
        "ripgrep"
    )

    for tool in "${apt_tools[@]}"; do
        install_optional_terminal_app "$tool" "$tool"
    done

    # External tools
    install_eza_from_github
    install_bat_from_apt_or_external
}

install_optional_terminal_app() {
    local app_name="$1"
    local package_name="$2"

    log_info "Installing optional $app_name..."

    if check_package_installed "$package_name"; then
        log_info "$app_name already installed"
        return 0
    fi

    if install_package "$package_name"; then
        log_success "$app_name installed via APT"
        return 0
    else
        log_warning "$app_name not available via APT"
        return 1
    fi
}

install_eza_from_github() {
    local app_name="eza"

    if command -v eza &> /dev/null; then
        log_info "$app_name already installed"
        return 0
    fi

    log_info "Installing $app_name from GitHub..."

    if download_and_install_github_binary "eza-community/eza" "eza" "x86_64-unknown-linux-gnu"; then
        log_success "$app_name installed from GitHub"
    else
        log_warning "Failed to install $app_name from GitHub"
    fi
}
```

## Benefits of Optional vs Required Split

- **Flexibility**: Users choose what they need
- **Faster Installation**: Core system installs quickly
- **Customization**: Different workflows need different tools
- **Maintenance**: Easier to maintain optional components separately
