#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

get_agent_config() {
    local agent_name=$1
    case "$agent_name" in
        claude)
            echo "${HOME}/.claude"
            echo "${HOME}/.claude/commands"
            ;;
        *)
            echo ""
            echo ""
            ;;
    esac
}

show_agent_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -a, --agent AGENT          Specify agent (claude, default: claude)"
    echo "  -l, --link-files-only            Link configuration files only"
    echo "  (no option)                Execute all operations (default)"
    echo ""
    echo "Examples:"
    echo "  $0                         # Execute all operations for Claude (default)"
    echo "  $0 --agent claude          # Execute all operations for Claude"
    echo "  $0 -a claude               # Execute all operations for Claude (short)"
    echo "  $0 -l                      # Link Claude configuration files only"
    echo "  $0 -a claude -l            # Link Claude configuration files only"
}

link_agent_config() {
    local agent_name=$1
    local config_path=$2
    local commands_path=$3

    printf "\n\033[1;36m=== Linking config to %s ===\033[0m\n" "${agent_name}"

    if [ ! -d "$commands_path" ]; then
        printf "\033[1;33m⚠ Directory does not exist. Creating: %s\033[0m\n" "$commands_path"
        mkdir -p "$commands_path"
    fi

    ln -fsvn "${SCRIPT_DIR}/AGENTS.md" "${config_path}/CLAUDE.md"
    ln -fsvn "${SCRIPT_DIR}/settings.json" "${config_path}/settings.json"
    ln -fsvn "${SCRIPT_DIR}/mcp.json" "${config_path}/.mcp.json"
    for file in "${SCRIPT_DIR}"/commands/*; do
        if [ -f "$file" ]; then
            ln -fsvn "$file" "$commands_path"
        fi
    done
}

setup_agent() {
    local agent_name=$1
    local mode=$2
    local config_path
    local commands_path
    {
        read -r config_path
        read -r commands_path
    } < <(get_agent_config "$agent_name")

    if [ -z "$config_path" ]; then
        printf "\033[1;31m✗ Unknown agent: %s\033[0m\n" "${agent_name}"
        printf "\033[1;33mAvailable agents: claude\033[0m\n"
        return 1
    fi

    case "$mode" in
        link)
            link_agent_config "$agent_name" "$config_path" "$commands_path"
            ;;
        *)
            link_agent_config "$agent_name" "$config_path" "$commands_path"
            ;;
    esac
}

AGENT="claude"
MODE="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_agent_usage
            exit 0
            ;;
        --agent|-a)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --agent requires an argument"
                show_agent_usage
                exit 1
            fi
            AGENT="$2"
            shift 2
            ;;
        --link-files-only|-l)
            MODE="link"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_agent_usage
            exit 1
            ;;
    esac
done

setup_agent "$AGENT" "$MODE"
