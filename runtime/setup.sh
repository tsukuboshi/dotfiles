#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

get_runtime_config() {
    local runtime_name=$1
    case "$runtime_name" in
        mise)
            echo "${HOME}/.config/mise/config.toml"
            echo "mise"
            ;;
        *)
            echo ""
            echo ""
            ;;
    esac
}

show_runtime_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -r, --runtime RUNTIME      Specify runtime (mise, default: mise)"
    echo "  -l, --link-config-only     Link config.toml only"
    echo "  -i, --install-plugins-only Install plugins only"
    echo "  (no option)                Execute both (default)"
    echo ""
    echo "Examples:"
    echo "  $0                         # Setup mise config and plugins (default)"
    echo "  $0 --runtime mise          # Setup mise config and plugins"
    echo "  $0 -r mise                 # Setup mise config and plugins (short)"
    echo "  $0 --link-config-only      # Link mise config.toml only"
    echo "  $0 -r mise -l              # Link mise config.toml only (short)"
    echo "  $0 --install-plugins-only  # Install mise plugins only"
    echo "  $0 -r mise -i              # Install mise plugins only (short)"
}

link_runtime_config() {
    local runtime_name=$1
    local config_path=$2

    printf "\n\033[1;36m=== Linking config to %s ===\033[0m\n" "${runtime_name}"

    local runtime_config_dir
    runtime_config_dir=$(dirname "$config_path")

    if [ ! -d "$runtime_config_dir" ]; then
        printf "\033[1;33m⚠ Directory does not exist. Creating: %s\033[0m\n" "$runtime_config_dir"
        mkdir -p "$runtime_config_dir"
    fi

    ln -fsvn "${SCRIPT_DIR}/config.toml" "$config_path"
}

install_runtime_plugins() {
    local runtime_name=$1
    local command_name=$2

    printf "\n\033[1;36m=== Installing plugins to %s ===\033[0m\n" "${runtime_name}"
    if command -v "$command_name" &> /dev/null; then
        "$command_name" install
    else
        printf "\033[1;31m✗ %s command not found. Skipping plugins installation\033[0m\n" "${command_name}"
    fi
}

setup_runtime() {
    local runtime_name=$1
    local mode=$2
    local config_path
    local command_name
    {
        read -r config_path
        read -r command_name
    } < <(get_runtime_config "$runtime_name")

    if [ -z "$config_path" ]; then
        printf "\033[1;31m✗ Unknown runtime: %s\033[0m\n" "${runtime_name}"
        printf "\033[1;33mAvailable runtimes: mise\033[0m\n"
        return 1
    fi

    case "$mode" in
        link)
            link_runtime_config "$runtime_name" "$config_path"
            ;;
        install)
            install_runtime_plugins "$runtime_name" "$command_name"
            ;;
        *)
            link_runtime_config "$runtime_name" "$config_path"
            install_runtime_plugins "$runtime_name" "$command_name"
            ;;
    esac
}

RUNTIME="mise"
MODE="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_runtime_usage
            exit 0
            ;;
        --runtime|-r)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --runtime requires an argument"
                show_runtime_usage
                exit 1
            fi
            RUNTIME="$2"
            shift 2
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

setup_runtime "$RUNTIME" "$MODE"
