#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# LLMの設定を取得する関数
get_llm_config() {
    echo "${HOME}/.claude"
}

# 使用方法の表示
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -m, --link-markdown-only   CLAUDE.mdのリンクのみ実行"
    echo "  -s, --link-settings-only   settings.jsonのリンクのみ実行"
    echo "  -c, --link-commands-only   commandsのリンクのみ実行"
    echo "  (no option)                全て実行 (default)"
    echo ""
    echo "Examples:"
    echo "  $0                         # 全てのリンクを実行"
    echo "  $0 --link-markdown-only    # CLAUDE.mdのみリンク"
    echo "  $0 --link-settings-only    # settings.jsonのみリンク"
    echo "  $0 --link-commands-only    # commandsのみリンク"
    echo "  $0 -m                      # CLAUDE.mdのみリンク(短縮)"
    echo "  $0 -s                      # settings.jsonのみリンク(短縮)"
    echo "  $0 -c                      # commandsのみリンク(短縮)"
}

# CLAUDE.mdのリンク
link_markdown() {
    local claude_setting_path
    claude_setting_path=$(get_llm_config)

    if [ ! -d "$claude_setting_path" ]; then
        echo "Claude settings directory not found. Please install claude CLI first."
        return 1
    fi

    echo "Linking CLAUDE.md to claude..."
    ln -fsvn "${SCRIPT_DIR}/CLAUDE.md" "${claude_setting_path}/CLAUDE.md"
    echo "CLAUDE.md linked successfully."
}

# settings.jsonのリンク
link_settings() {
    local claude_setting_path
    claude_setting_path=$(get_llm_config)

    if [ ! -d "$claude_setting_path" ]; then
        echo "Claude settings directory not found. Please install claude CLI first."
        return 1
    fi

    echo "Linking settings.json to claude..."
    ln -fsvn "${SCRIPT_DIR}/settings.json" "${claude_setting_path}/settings.json"
    echo "settings.json linked successfully."
}

# commandsのリンク
link_commands() {
    local claude_setting_path
    claude_setting_path=$(get_llm_config)

    if [ ! -d "$claude_setting_path" ]; then
        echo "Claude settings directory not found. Please install claude CLI first."
        return 1
    fi

    if [ ! -d "${SCRIPT_DIR}/commands" ]; then
        echo "Commands directory not found in ${SCRIPT_DIR}"
        return 1
    fi

    echo "Linking commands to claude..."
    for file in "${SCRIPT_DIR}"/commands/*; do
        if [ -f "$file" ]; then
            ln -fsvn "$file" "${claude_setting_path}/commands"
        fi
    done
    echo "Commands linked successfully."
}

# 引数の解析
MODE="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --link-markdown-only|-m)
            MODE="markdown"
            shift
            ;;
        --link-settings-only|-s)
            MODE="settings"
            shift
            ;;
        --link-commands-only|-c)
            MODE="commands"
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
if command -v claude &> /dev/null; then
    echo "Setting up claude CLI..."

    case "$MODE" in
        markdown)
            link_markdown
            ;;
        settings)
            link_settings
            ;;
        commands)
            link_commands
            ;;
        *)
            link_markdown
            link_settings
            link_commands
            ;;
    esac
else
    echo "claude command not found. Please install claude CLI first."
    exit 1
fi
