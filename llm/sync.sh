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
    echo "  -l, --link FILE            Link specific file (agents|settings|commands)"
    echo "  (no option)                Link all files (default)"
    echo ""
    echo "Examples:"
    echo "  $0                         # Link all files"
    echo "  $0 --link agents           # Link CLAUDE.md only"
    echo "  $0 --link settings         # Link settings.json only"
    echo "  $0 --link commands         # Link commands only"
    echo "  $0 -l agents               # Link CLAUDE.md only (short)"
    echo "  $0 -l settings             # Link settings.json only (short)"
    echo "  $0 -l commands             # Link commands only (short)"
}

# Link specific file
link_file() {
    local file_type=$1
    local claude_setting_path
    claude_setting_path=$(get_llm_config)

    if [ ! -d "$claude_setting_path" ]; then
        printf "\033[1;31m✗ Claude settings directory not found. Please install claude CLI first\033[0m\n"
        return 1
    fi

    case "$file_type" in
        agents)
            printf "\033[1;36m=== Linking CLAUDE.md to claude ===\033[0m\n"
            ln -fsvn "${SCRIPT_DIR}/CLAUDE.md" "${claude_setting_path}/CLAUDE.md"
            printf "\033[1;32m✓ CLAUDE.md linked successfully\033[0m\n"
            ;;
        settings)
            printf "\033[1;36m=== Linking settings.json to claude ===\033[0m\n"
            ln -fsvn "${SCRIPT_DIR}/settings.json" "${claude_setting_path}/settings.json"
            printf "\033[1;32m✓ settings.json linked successfully\033[0m\n"
            ;;
        commands)
            if [ ! -d "${SCRIPT_DIR}/commands" ]; then
                printf "\033[1;31m✗ Commands directory not found in %s\033[0m\n" "${SCRIPT_DIR}"
                return 1
            fi
            printf "\033[1;36m=== Linking commands to claude ===\033[0m\n"
            for file in "${SCRIPT_DIR}"/commands/*; do
                if [ -f "$file" ]; then
                    ln -fsvn "$file" "${claude_setting_path}/commands"
                fi
            done
            printf "\033[1;32m✓ Commands linked successfully\033[0m\n"
            ;;
        *)
            printf "\033[1;31m✗ Unknown file type: %s\033[0m\n" "${file_type}"
            printf "\033[1;33mAvailable types: agents, settings, commands\033[0m\n"
            return 1
            ;;
    esac
}

# Link all files
link_all() {
    link_file "agents"
    link_file "settings"
    link_file "commands"
}

# Parse arguments
LINK_TARGET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --link|-l)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --link requires an argument (agents|settings|commands)"
                show_usage
                exit 1
            fi
            LINK_TARGET="$2"
            shift 2
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
    printf "\n\033[1;34m========================================\033[0m\n"
    printf "\033[1;34m  Setting up claude CLI\033[0m\n"
    printf "\033[1;34m========================================\033[0m\n\n"

    if [ -z "$LINK_TARGET" ]; then
        link_all
    else
        link_file "$LINK_TARGET"
    fi
else
    printf "\033[1;31m✗ claude command not found. Please install claude CLI first\033[0m\n"
    exit 1
fi
