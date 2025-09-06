# Debian-WS Contributing Guidelines

## Welcome Contributors!

Thank you for your interest in contributing to Debian-WS! This project aims to provide a comprehensive, function-based Debian 12+ installation and configuration suite.

## Project Philosophy

- **Function-First Architecture**: All functionality is organized into reusable functions
- **Security-Focused**: Modern security practices and secure defaults
- **Idempotent Operations**: Scripts can be run multiple times safely
- **Comprehensive Testing**: All changes must be tested thoroughly
- **Clear Documentation**: Every function and feature must be documented

## How to Contribute

### 1. Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a new branch for your feature/fix
4. Make your changes following our guidelines
5. Test your changes thoroughly
6. Submit a pull request

### 2. Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/debian-ws.git
cd debian-ws

# Create a feature branch
git checkout -b feature/your-feature-name

# Set up development environment
# Ensure you're on Debian 12+ with GNOME
```

### 3. Code Standards

#### Function Structure
All new functions must follow this template:

```bash
# Brief description of what the function does
# Args:
#   $1 - Parameter description
#   $2 - Optional parameter description (optional)
# Returns: 0 on success, 1 on error
# Globals: List any global variables used
function_name() {
    local param1="$1"
    local param2="${2:-default_value}"

    # Validate parameters
    if [[ -z "$param1" ]]; then
        log_error "Parameter required: param1"
        return 1
    fi

    # Function implementation
    log_info "Starting function_name..."

    # Error handling
    if ! some_command; then
        log_error "Failed to execute some_command"
        return 1
    fi

    log_success "Function completed successfully"
    return 0
}
```

#### Logging Requirements
- Use the centralized logging system
- Always log the start and completion of operations
- Log errors with context
- Use appropriate log levels

```bash
log_debug "Debug information"
log_info "General information"
log_warning "Warning message"
log_error "Error message"
log_success "Success message"
```

#### Error Handling
- Every function must handle errors gracefully
- Return appropriate exit codes (0 = success, 1 = error)
- Log errors with sufficient context
- Implement recovery mechanisms where possible

### 4. File Organization

Place your code in the appropriate directory:

- **Core functions**: `lib/core/`
- **Installation functions**: `lib/install/`
- **Configuration functions**: `lib/config/`
- **Required applications**: `install/system/` (APT only, both terminal and desktop)
- **Optional terminal applications**: `install/apps/terminal/` (APT/external preferred)
- **Optional desktop applications**: `install/apps/desktop/` (Flatpak first, APT fallback)
- **Resources**: `resources/`

#### Application Installation Guidelines

**Required Applications** (`install/system/`):
- **APT packages only** for all required apps (both terminal and desktop)
- Better system integration and dependency management
- Examples: `firefox-esr`, `git`, `curl`, `gnome-tweaks`

**Optional Terminal Applications** (`install/apps/terminal/`):
- Use APT packages for system tools and widely available CLI apps
- External downloads for specialized tools not in Debian repos
- Manual installation for cutting-edge development tools

**Optional Desktop Applications** (`install/apps/desktop/`):
- **Primary method**: Flatpak from Flathub (sandboxed, auto-updates)
- **Secondary method**: APT packages (when Flatpak unavailable)
- **Fallback method**: External .deb files (vendor-specific apps)

Example required app installation:
```bash
install_required_firefox() {
    install_required_application "Firefox" "firefox-esr"
}
```

Example optional desktop app installation:
```bash
install_optional_vscode() {
    install_optional_desktop_application "VS Code" \
        "com.visualstudio.code" \     # Flatpak ID
        "code" \                      # APT package
        "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
}
```

### 5. Testing Requirements

Before submitting your PR:

1. **Test on Clean System**: Test on a fresh Debian 12 installation
2. **Test Idempotency**: Run your scripts multiple times
3. **Test Error Conditions**: Verify error handling works
4. **Test Different Scenarios**: Various system configurations
5. **Performance Testing**: Ensure efficient execution

### 6. Documentation Requirements

- Update relevant documentation files
- Include function documentation headers
- Update README.md if adding new features
- Add examples in comments where helpful

### 7. Security Guidelines

- Validate all user inputs
- Use secure download methods (HTTPS + verification)
- Implement proper privilege checking
- Follow principle of least privilege
- Sanitize environment variables

### 8. Pull Request Process

1. **Clear Description**: Explain what your PR does and why
2. **Link Issues**: Reference any related issues
3. **Testing Evidence**: Describe how you tested your changes
4. **Breaking Changes**: Highlight any breaking changes
5. **Screenshots**: Include screenshots for UI changes

#### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested on clean Debian 12 installation
- [ ] Tested idempotency
- [ ] Tested error conditions
- [ ] No breaking changes to existing functionality

## Checklist
- [ ] Code follows project standards
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Testing completed
```

### 9. Code Review Process

All PRs will be reviewed for:
- Code quality and standards compliance
- Security considerations
- Testing adequacy
- Documentation completeness
- Compatibility with existing functionality

### 10. Common Contribution Areas

We welcome contributions in these areas:
- New application installations
- System configuration improvements
- Performance optimizations
- Bug fixes
- Documentation improvements
- Testing infrastructure
- Security enhancements

### 11. Getting Help

- **Documentation**: Check existing documentation first
- **Issues**: Search existing issues for similar problems
- **Discussions**: Use GitHub Discussions for questions
- **Code Examples**: Look at existing functions for patterns

### 12. Commit Guidelines

- Use clear, descriptive commit messages
- Reference issues when applicable
- Keep commits focused and atomic
- Follow conventional commit format when possible

```bash
feat: add support for additional terminal emulators
fix: resolve GNOME extension installation issue
docs: update installation instructions
refactor: improve error handling in package management
```

### 13. License

By contributing to Debian-WS, you agree that your contributions will be licensed under the MIT License.

### 14. Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes for significant contributions
- Project documentation

## Thank You!

Your contributions help make Debian-WS better for everyone. We appreciate your time and effort in improving this project!
