#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

get_editor_config() {
    local editor_name=$1
    case "$editor_name" in
        vscode)
            echo "code"
            echo "${HOME}/Library/Application Support/Code/User"
            ;;
        cursor)
            echo "cursor"
            echo "${HOME}/Library/Application Support/Cursor/User"
            ;;
        *)
            echo ""
            echo ""
            ;;
    esac
}

show_editor_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -e, --editor EDITOR                Specify editor (vscode|cursor, default: vscode)"
    echo "  -l, --link-settings-only           Link setting files only"
    echo "  -i, --install-extensions-only      Install extensions only"
    echo "  (no option)                        Execute both (default)"
    echo ""
    echo "Examples:"
    echo "  $0                                  # Setup VSCode settings and extensions"
    echo "  $0 --editor cursor                  # Setup Cursor settings and extensions"
    echo "  $0 -e vscode --link-settings-only   # Link VSCode setting files only"
    echo "  $0 -e cursor --install-extensions-only # Install Cursor extensions only"
    echo "  $0 -l                               # Link VSCode setting files only (short)"
    echo "  $0 -e cursor -i                     # Install Cursor extensions only (short)"
}

link_editor_config() {
    local editor_name=$1
    local settings_path=$2

    printf "\n\033[1;36m=== Linking config to %s ===\033[0m\n" "${editor_name}"
    ln -fsvn "${SCRIPT_DIR}/settings.json" "${settings_path}/settings.json"
}

install_editor_extensions() {
    local editor_name=$1
    local command_name=$2

    printf "\n\033[1;36m=== Installing extensions to %s ===\033[0m\n" "${editor_name}"
    if command -v "$command_name" &> /dev/null; then
        while read -r line; do
            [ -z "$line" ] && continue
            "$command_name" --install-extension "$line"
        done < "${SCRIPT_DIR}/extensions"
    else
        printf "\033[1;31m✗ %s command not found. Skipping extensions\033[0m\n" "${command_name}"
    fi
}

setup_editor() {
    local editor_name=$1
    local mode=$2
    local command_name
    local settings_path
    {
        read -r command_name
        read -r settings_path
    } < <(get_editor_config "$editor_name")

    if [ -z "$settings_path" ]; then
        printf "\033[1;31m✗ Unknown editor: %s\033[0m\n" "${editor_name}"
        printf "\033[1;33mAvailable editors: vscode cursor\033[0m\n"
        return 1
    fi

    case "$mode" in
        link)
            link_editor_config "$editor_name" "$settings_path"
            ;;
        install)
            install_editor_extensions "$editor_name" "$command_name"
            ;;
        *)
            link_editor_config "$editor_name" "$settings_path"
            install_editor_extensions "$editor_name" "$command_name"
            ;;
    esac
}

EDITOR="vscode"
MODE="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_editor_usage
            exit 0
            ;;
        --editor|-e)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --editor requires an argument (vscode|cursor)"
                show_editor_usage
                exit 1
            fi
            EDITOR="$2"
            shift 2
            ;;
        --link-settings-only|-l)
            MODE="link"
            shift
            ;;
        --install-extensions-only|-i)
            MODE="install"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_editor_usage
            exit 1
            ;;
    esac
done

setup_editor "$EDITOR" "$MODE"
