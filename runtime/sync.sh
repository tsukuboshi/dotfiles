#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

get_runtime_config() {
    echo "${HOME}/.config/mise/config.toml"
}

show_runtime_usage() {
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

link_runtime_config() {
    local runtime_config_path
    runtime_config_path=$(get_runtime_config)
    local runtime_config_dir
    runtime_config_dir=$(dirname "$runtime_config_path")

    printf "\n\033[1;36m=== Linking config to mise ===\033[0m\n"

    if [ ! -d "$runtime_config_dir" ]; then
        printf "\033[1;33m⚠ Directory does not exist. Creating: %s\033[0m\n" "$runtime_config_dir"
        mkdir -p "$runtime_config_dir"
    fi

    ln -fsvn "${SCRIPT_DIR}/config.toml" "$runtime_config_path"
}

install_runtime_plugins() {
    printf "\n\033[1;36m=== Installing plugins to mise ===\033[0m\n"
    if command -v mise &> /dev/null; then
        mise install
    else
        printf "\033[1;31m✗ mise command not found. Skipping plugins installation\033[0m\n"
    fi
}

MODE="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_runtime_usage
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
            show_runtime_usage
            exit 1
            ;;
    esac
done

case "$MODE" in
    link)
        link_runtime_config
        ;;
    install)
        install_runtime_plugins
        ;;
    *)
        link_runtime_config
        install_runtime_plugins
        ;;
esac
