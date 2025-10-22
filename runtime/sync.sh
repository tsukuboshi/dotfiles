#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Get runtime configuration
get_runtime_config() {
    echo "${HOME}/.config/mise/config.toml"
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -l, --link-config-only     Link config.toml only"
    echo "  -i, --install-plugins-only Install mise plugins only"
    echo "  (no option)                Execute both (default)"
    echo ""
    echo "Examples:"
    echo "  $0                         # Setup config and plugins"
    echo "  $0 --link-config-only      # Link config.toml only"
    echo "  $0 --install-plugins-only  # Install mise plugins only"
    echo "  $0 -l                      # Link config.toml only (short)"
    echo "  $0 -i                      # Install mise plugins only (short)"
}

# Link config.toml
link_config() {
    local runtime_config_path
    runtime_config_path=$(get_runtime_config)

    printf "\033[1;36m=== Linking config.toml to mise ===\033[0m\n"
    ln -fsvn "${SCRIPT_DIR}/config.toml" "$runtime_config_path"
    printf "\033[1;32m✓ config.toml linked successfully\033[0m\n"
}

# Install mise plugins
install_plugins() {
    if command -v mise &> /dev/null; then
        printf "\033[1;36m=== Installing mise plugins ===\033[0m\n"
        mise install
        printf "\033[1;32m✓ mise plugins installed successfully\033[0m\n"
    else
        printf "\033[1;31m✗ mise command not found. Skipping plugins installation\033[0m\n"
    fi
}

# Parse arguments
MODE="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --link-config-only|-l)
            MODE="link"
            shift
            ;;
        --install-plugins-only|-i)
            MODE="install"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Execute setup
printf "\n\033[1;34m========================================\033[0m\n"
printf "\033[1;34m  Setting up mise runtime\033[0m\n"
printf "\033[1;34m========================================\033[0m\n\n"

case "$MODE" in
    link)
        link_config
        ;;
    install)
        install_plugins
        ;;
    *)
        link_config
        install_plugins
        ;;
esac
