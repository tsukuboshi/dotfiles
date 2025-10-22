#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Get editor configuration
get_editor_config() {
    local editor_name=$1
    case "$editor_name" in
        vscode)
            echo "${HOME}/Library/Application Support/Code/User/settings.json:code"
            ;;
        cursor)
            echo "${HOME}/Library/Application Support/Cursor/User/settings.json:cursor"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -e, --editor EDITOR                Specify editor (vscode|cursor, default: vscode)"
    echo "  -l, --link-settings-only           Link settings.json only"
    echo "  -i, --install-extensions-only      Install extensions only"
    echo "  (no option)                        Execute both (default)"
    echo ""
    echo "Examples:"
    echo "  $0                                  # Setup VSCode settings and extensions"
    echo "  $0 --editor cursor                  # Setup Cursor settings and extensions"
    echo "  $0 -e vscode --link-settings-only   # Link VSCode settings.json only"
    echo "  $0 -e cursor --install-extensions-only # Install Cursor extensions only"
    echo "  $0 -l                               # Link VSCode settings.json only (short)"
    echo "  $0 -e cursor -i                     # Install Cursor extensions only (short)"
}

# Link settings.json
link_settings() {
    local editor_name=$1
    local settings_path=$2

    if [ ! -L "$settings_path" ]; then
        printf "\033[1;36m=== Linking settings.json to %s ===\033[0m\n" "${editor_name}"
        ln -fsvn "${SCRIPT_DIR}/settings.json" "$settings_path"
        printf "\033[1;32m✓ settings.json linked successfully\033[0m\n"
    else
        printf "\033[1;33m⚠ %s settings.json already linked\033[0m\n" "${editor_name}"
    fi
}

# Install extensions
install_extensions() {
    local editor_name=$1
    local command_name=$2

    if command -v "$command_name" &> /dev/null; then
        printf "\033[1;36m=== Installing extensions to %s ===\033[0m\n" "${editor_name}"
        while read -r line; do
            [ -z "$line" ] && continue
            "$command_name" --install-extension "$line"
        done < "${SCRIPT_DIR}/extensions"
        printf "\033[1;32m✓ Extensions installed successfully\033[0m\n"
    else
        printf "\033[1;31m✗ %s command not found. Skipping extensions\033[0m\n" "${command_name}"
    fi
}

# Setup editor
setup_editor() {
    local editor_name=$1
    local mode=$2
    local config
    config=$(get_editor_config "$editor_name")

    if [ -z "$config" ]; then
        printf "\033[1;31m✗ Unknown editor: %s\033[0m\n" "${editor_name}"
        printf "\033[1;33mAvailable editors: vscode cursor\033[0m\n"
        return 1
    fi

    local settings_path
    local command_name
    settings_path=$(echo "$config" | cut -d: -f1)
    command_name=$(echo "$config" | cut -d: -f2)

    printf "\n\033[1;34m========================================\033[0m\n"
    printf "\033[1;34m  Setting up %s\033[0m\n" "${editor_name}"
    printf "\033[1;34m========================================\033[0m\n\n"

    case "$mode" in
        settings)
            link_settings "$editor_name" "$settings_path"
            ;;
        extensions)
            install_extensions "$editor_name" "$command_name"
            ;;
        *)
            link_settings "$editor_name" "$settings_path"
            install_extensions "$editor_name" "$command_name"
            ;;
    esac
}

# Parse arguments
EDITOR="vscode"
MODE="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --editor|-e)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --editor requires an argument (vscode|cursor)"
                show_usage
                exit 1
            fi
            EDITOR="$2"
            shift 2
            ;;
        --link-settings-only|-l)
            MODE="settings"
            shift
            ;;
        --install-extensions-only|-i)
            MODE="extensions"
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
setup_editor "$EDITOR" "$MODE"
