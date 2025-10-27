#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Get agent configuration
get_agent_config() {
    local agent_name=$1
    case "$agent_name" in
        claude)
            echo "${HOME}/.claude"
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
    echo "  -a, --agent AGENT          Specify agent (claude, default: claude)"
    echo ""
    echo "Examples:"
    echo "  $0                         # Link Claude files (default)"
    echo "  $0 --agent claude          # Link Claude files"
    echo "  $0 -a claude               # Link Claude files (short)"
}

# Link agent files
link_agent_files() {
    local agent_name=$1
    local config_path
    config_path=$(get_agent_config "$agent_name")

    if [ -z "$config_path" ]; then
        printf "\033[1;31m✗ Unknown agent: %s\033[0m\n" "${agent_name}"
        printf "\033[1;33mAvailable agents: claude\033[0m\n"
        return 1
    fi

    if [ ! -d "$config_path" ]; then
        printf "\033[1;31m✗ %s settings directory not found. Please install %s CLI first\033[0m\n" "${agent_name}" "${agent_name}"
        return 1
    fi

    case "$agent_name" in
        claude)
            printf "\n\033[1;36m=== Linking setting files ===\033[0m\n"
            ln -fsvn "${SCRIPT_DIR}/AGENTS.md" "${config_path}/CLAUDE.md"
            ln -fsvn "${SCRIPT_DIR}/settings.json" "${config_path}/settings.json"
            ln -fsvn "${SCRIPT_DIR}/mcp.json" "${config_path}/.mcp.json"

            if [ -d "${SCRIPT_DIR}/commands" ]; then
            printf "\n\033[1;36m=== Linking command files ===\033[0m\n"
                for file in "${SCRIPT_DIR}"/commands/*; do
                    if [ -f "$file" ]; then
                        ln -fsvn "$file" "${config_path}/commands"
                    fi
                done
            else
                printf "\033[1;33m⚠ Commands directory not found, skipping commands\033[0m\n"
            fi

            ;;
        *)
            printf "\033[1;31m✗ Unsupported agent: %s\033[0m\n" "${agent_name}"
            return 1
            ;;
    esac
}

# Parse arguments
AGENT="claude"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --agent|-a)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --agent requires an argument"
                show_usage
                exit 1
            fi
            AGENT="$2"
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
link_agent_files "$AGENT"
