#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# エディタの設定を取得する関数
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

# 使用方法の表示
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -e, --editor EDITOR                エディタを指定 (vscode|cursor, default: vscode)"
    echo "  -l, --link-settings-only           settings.jsonのリンクのみ実行"
    echo "  -i, --install-extensions-only      拡張機能のインストールのみ実行"
    echo "  (no option)                        両方実行 (default)"
    echo ""
    echo "Examples:"
    echo "  $0                                  # VSCodeの設定と拡張機能を両方セットアップ"
    echo "  $0 --editor cursor                  # Cursorの設定と拡張機能を両方セットアップ"
    echo "  $0 -e vscode --link-settings-only   # VSCodeのsettings.jsonのみリンク"
    echo "  $0 -e cursor --install-extensions-only # Cursorの拡張機能のみインストール"
    echo "  $0 -l                               # VSCodeのsettings.jsonのみリンク(短縮)"
    echo "  $0 -e cursor -i                     # Cursorの拡張機能のみインストール(短縮)"
}

# settings.jsonのリンク
link_settings() {
    local editor_name=$1
    local settings_path=$2

    if [ ! -L "$settings_path" ]; then
        echo "Linking settings.json to ${editor_name}..."
        ln -fsvn "${SCRIPT_DIR}/settings.json" "$settings_path"
    else
        echo "${editor_name} settings.json already linked."
    fi
}

# 拡張機能のインストール
install_extensions() {
    local editor_name=$1
    local command_name=$2

    if command -v "$command_name" &> /dev/null; then
        echo "Installing extensions to ${editor_name}..."
        while read -r line; do
            [ -z "$line" ] && continue
            "$command_name" --install-extension "$line"
        done < "${SCRIPT_DIR}/extensions"
    else
        echo "${command_name} command not found. Skipping extensions."
    fi
}

# エディタのセットアップ
setup_editor() {
    local editor_name=$1
    local mode=$2
    local config
    config=$(get_editor_config "$editor_name")

    if [ -z "$config" ]; then
        echo "Unknown editor: ${editor_name}"
        echo "Available editors: vscode cursor"
        return 1
    fi

    local settings_path
    local command_name
    settings_path=$(echo "$config" | cut -d: -f1)
    command_name=$(echo "$config" | cut -d: -f2)

    echo "Setting up ${editor_name}..."

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

# 引数の解析
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

# セットアップ実行
setup_editor "$EDITOR" "$MODE"
