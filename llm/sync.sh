#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Get LLM configuration
get_llm_config() {
    echo "${HOME}/.claude"
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -m, --link-markdown-only   Link CLAUDE.md only"
    echo "  -s, --link-settings-only   Link settings.json only"
    echo "  -c, --link-commands-only   Link commands only"
    echo "  (no option)                Execute all (default)"
    echo ""
    echo "Examples:"
    echo "  $0                         # Execute all links"
    echo "  $0 --link-markdown-only    # Link CLAUDE.md only"
    echo "  $0 --link-settings-only    # Link settings.json only"
    echo "  $0 --link-commands-only    # Link commands only"
    echo "  $0 -m                      # Link CLAUDE.md only (short)"
    echo "  $0 -s                      # Link settings.json only (short)"
    echo "  $0 -c                      # Link commands only (short)"
}

# Link CLAUDE.md
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

# Link settings.json
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

# Link commands
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

# Parse arguments
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

# Execute setup
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
