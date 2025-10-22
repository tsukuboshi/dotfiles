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

    if [ ! -L "$runtime_config_path" ]; then
        echo "Linking config.toml to mise..."
        ln -fsvn "${SCRIPT_DIR}/config.toml" "$runtime_config_path"
    else
        echo "mise config.toml already linked."
    fi
}

# Install mise plugins
install_plugins() {
    if command -v mise &> /dev/null; then
        echo "Installing mise plugins..."
        mise install
    else
        echo "mise command not found. Skipping plugins installation."
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
echo "Setting up mise runtime..."

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
