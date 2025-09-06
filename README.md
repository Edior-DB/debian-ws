# Debian-WS - Debian Workstation Setup Suite

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Debian 12+](https://img.shields.io/badge/Debian-12%2B-red.svg)](https://www.debian.org/)
[![GNOME](https://img.shields.io/badge/Desktop-GNOME-blue.svg)](https://www.gnome.org/)

*A comprehensive, security-focused Debian 12+ installation and configuration suite with function-based architecture*

[Quick Start](#quick-start) • [Features](#features) • [Documentation](#documentation) • [Contributing](#contributing)

</div>

---

## 🎯 Overview

Debian-WS transforms a fresh Debian 12 installation into a fully-configured, modern development workstation through a single command. Built on a robust function-based architecture inspired by the [archer project](https://github.com/Edior-DB/archer), this suite refactors and enhances the functionality of [debian-ok](https://github.com/Edior-DB/debian-ok) with improved modularity, security, and maintainability.

### Key Improvements from debian-ok

- **🏗️ Function-Based Architecture**: Modular, reusable functions instead of monolithic scripts
- **🔒 Enhanced Security**: Modern APT keyring management and secure download practices
- **⚡ Better Error Handling**: Comprehensive error detection and recovery mechanisms
- **🔄 Improved Idempotency**: Safe to run multiple times without side effects
- **📊 Better Logging**: Centralized logging system with multiple verbosity levels
- **🧩 Modular Design**: Clean separation of system, application, and configuration logic

## 🚀 Quick Start

### Prerequisites

- **Debian 12+** (Bookworm or later)
- **GNOME Desktop Environment** with GDM3
- **Internet connection**
- **Sudo privileges**

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Edior-DB/debian-ws/main/bin/boot.sh | bash
```

### Alternative Installation Methods

#### Git Clone (Recommended for Development)

```bash
git clone https://github.com/Edior-DB/debian-ws.git
cd debian-ws
./bin/debian-ws.sh
```

#### Direct Script Download

```bash
wget https://raw.githubusercontent.com/Edior-DB/debian-ws/main/bin/debian-ws.sh
chmod +x debian-ws.sh
./debian-ws.sh
```

## 📋 Features

### 🛡️ System & Security
- ✅ **Modern Package Management**: Secure APT keyring handling in `/etc/apt/keyrings/`
- ✅ **Security Hardening**: Firewall configuration and security tools
- ✅ **Driver Support**: Automatic hardware detection and driver installation
- ✅ **System Utilities**: Essential command-line tools and utilities

### 🖥️ Desktop Environment
- ✅ **GNOME Optimization**: Performance tweaks and extensions
- ✅ **Theme Management**: Beautiful themes with proper transparency support
- ✅ **Terminal Configuration**: Alacritty, Kitty with Chris Titus configurations
- ✅ **Application Management**: Organized installation of productivity apps

### 💻 Development Environment
- ✅ **Programming Languages**: Python, Node.js, Rust, Go, Java support
- ✅ **Development Tools**: VS Code, Git, Docker, and essential dev tools
- ✅ **Shell Enhancement**: Zsh with Oh My Zsh and productivity plugins
- ✅ **Container Support**: Docker and container development tools

### 🎵 Multimedia & Gaming
- ✅ **Media Codecs**: Complete audio/video codec support
- ✅ **Gaming Setup**: Steam, Lutris, and gaming optimizations
- ✅ **Content Creation**: OBS, media editing tools
- ✅ **Streaming Tools**: Broadcasting and streaming applications

### 📦 Package Management
- ✅ **Multiple Backends**: APT, Flatpak, Snap support
- ✅ **External Packages**: GitHub releases and vendor-specific installations
- ✅ **Conflict Resolution**: Intelligent handling of package conflicts
- ✅ **Cleanup Tools**: System maintenance and cleanup utilities

## 🏗️ Architecture

### Directory Structure

```
debian-ws/
├── bin/                          # Executable scripts
│   ├── debian-ws.sh             # Main interactive menu
│   └── boot.sh                  # Quick installation bootstrap
├── lib/                         # Shared library functions
│   ├── core/                    # Core system functions
│   │   ├── system.sh           # System detection and utilities
│   │   ├── package.sh          # Package management functions
│   │   ├── network.sh          # Network and connectivity
│   │   └── logging.sh          # Centralized logging system
│   ├── install/                 # Installation helper functions
│   │   ├── apt.sh              # APT-specific operations
│   │   ├── flatpak.sh          # Flatpak management
│   │   └── external.sh         # External package handling
│   └── config/                  # Configuration management
│       ├── gnome.sh            # GNOME-specific settings
│       ├── terminal.sh         # Terminal configurations
│       └── dotfiles.sh         # Dotfile management
├── install/                     # Installation modules
│   ├── system/                  # Core system components
│   │   ├── base.sh             # Essential packages
│   │   ├── security.sh         # Security tools
│   │   └── utilities.sh        # System utilities
│   └── apps/                    # Application installations
│       ├── development/         # Development tools
│       ├── multimedia/          # Media applications
│       └── productivity/        # Office and productivity
├── resources/                   # Static resources
│   ├── configs/                 # Configuration templates
│   ├── themes/                  # Theme files
│   └── defaults/                # Default settings
└── uninstall/                   # Cleanup and removal scripts
```

### Function-Based Design

Every operation is implemented as a reusable function with:
- **Clear documentation** and parameter specification
- **Error handling** with appropriate return codes
- **Logging integration** for debugging and user feedback
- **Idempotent behavior** for safe re-execution

Example function structure:
```bash
# Install a package if not already present
# Args: $1 - package name
# Returns: 0 on success, 1 on failure
install_package() {
    local package="$1"
    
    if check_package_installed "$package"; then
        log_info "$package is already installed"
        return 0
    fi
    
    log_info "Installing $package..."
    if ! apt install -y "$package"; then
        log_error "Failed to install $package"
        return 1
    fi
    
    log_success "$package installed successfully"
}
```

## 🎛️ Usage

### Interactive Mode (Recommended)

```bash
./bin/debian-ws.sh
```

Provides a menu-driven interface for:
- System component installation
- Application management
- Configuration updates
- Theme application
- System maintenance

### Direct Function Execution

```bash
# Install development tools
source lib/core/logging.sh
source install/apps/development/base.sh
install_development_base

# Configure GNOME settings
source lib/config/gnome.sh
configure_gnome_dark_theme
```

### Automated Installation

```bash
# Set environment variables for automation
export DEBIANWS_SKIP_PROMPTS=true
export DEBIANWS_INSTALL_PROFILE=developer

./bin/debian-ws.sh
```

## 🔧 Configuration

### Environment Variables

- `DEBIANWS_CONFIG_DIR` - Configuration directory (default: ~/.config/debian-ws)
- `DEBIANWS_LOG_LEVEL` - Logging verbosity (debug, info, warning, error)
- `DEBIANWS_SKIP_PROMPTS` - Enable automated mode (true/false)
- `DEBIANWS_INSTALL_PROFILE` - Installation profile (minimal, developer, multimedia)

### Custom Configurations

Create custom configuration files in `~/.config/debian-ws/`:
- `user-preferences.conf` - Personal settings
- `package-overrides.conf` - Custom package lists
- `theme-settings.conf` - Theme preferences

## 🔒 Security

Debian-WS follows modern security practices:

- **GPG Key Management**: Uses `/etc/apt/keyrings/` for secure key storage
- **Download Verification**: All external downloads are verified with checksums
- **Minimal Privileges**: Requests elevated privileges only when necessary
- **Input Validation**: All user inputs are sanitized and validated
- **Secure Defaults**: Applies security-focused default configurations

See [SECURITY.md](.github/SECURITY.md) for detailed security information.

## 📚 Documentation

- [**Architecture Guide**](.github/prompts/ARCHITECTURE_PROMPT.md) - Project structure and design principles
- [**Development Instructions**](.github/prompts/DEVELOPMENT_INSTRUCTIONS.md) - Detailed development guidelines
- [**Refactoring Guide**](.github/prompts/REFACTORING_GUIDE.md) - Migration from debian-ok patterns
- [**Contributing Guidelines**](.github/CONTRIBUTING.md) - How to contribute to the project
- [**Security Policy**](.github/SECURITY.md) - Security practices and vulnerability reporting

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](.github/CONTRIBUTING.md) for details.

### Quick Contribution Guide

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow our function-based architecture and coding standards
4. Test thoroughly on Debian 12+
5. Submit a pull request

### Development Setup

```bash
git clone https://github.com/YOUR_USERNAME/debian-ws.git
cd debian-ws
# Make your changes
# Test on clean Debian 12 installation
```

## 🙏 Acknowledgments

- **[debian-ok](https://github.com/Edior-DB/debian-ok)** - Original project foundation
- **[archer](https://github.com/Edior-DB/archer)** - Function-based architecture inspiration  
- **[Chris Titus Tech](https://github.com/ChrisTitusTech)** - Terminal configurations and themes
- **[Debian Project](https://www.debian.org/)** - The amazing operating system
- **GNOME Project** - Desktop environment

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 📖 **Documentation**: Check the docs in `.github/prompts/`
- 🐛 **Bug Reports**: [Create an issue](https://github.com/Edior-DB/debian-ws/issues/new?template=bug_report.md)
- 💡 **Feature Requests**: [Suggest a feature](https://github.com/Edior-DB/debian-ws/issues/new?template=feature_request.md)
- ❓ **Questions**: [Ask a question](https://github.com/Edior-DB/debian-ws/issues/new?template=question.md)

---

<div align="center">

**Debian-WS** - *Making Debian development workstations beautiful and functional*

</div>
