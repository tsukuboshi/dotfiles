#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

get_agent_config() {
	local agent_name=$1
	case "$agent_name" in
	claude)
		echo "claude"
		echo "${HOME}/.claude"
		echo "CLAUDE.md"
		echo "settings.json"
		echo "skills"
		echo "rules"
		;;
	codex)
		echo "codex"
		echo "${HOME}/.codex"
		echo "AGENTS.md"
		echo "config.toml"
		echo "skills"
		echo "rules"
		;;
	*)
		echo ""
		echo ""
		echo ""
		echo ""
		echo ""
		echo ""
		;;
	esac
}

show_agent_usage() {
	echo "Usage: $0 [OPTIONS]"
	echo ""
	echo "OPTIONS:"
	echo "  -a, --agent AGENT          Specify agent (claude, codex, default: claude)"
	echo "  -l, --link-files-only      Link configuration files only (no apm install)"
	echo "  -i, --install-apm-only     Install apm-managed skills only (no link)"
	echo "  (no option)                Execute all operations (default)"
	echo ""
	echo "Examples:"
	echo "  $0                         # Execute all operations for Claude (default)"
	echo "  $0 --agent claude          # Execute all operations for Claude"
	echo "  $0 -a codex                # Execute all operations for Codex"
	echo "  $0 -l                      # Link Claude configuration files only"
	echo "  $0 -a codex -l             # Link Codex configuration files only"
	echo "  $0 -i                      # Install apm-managed skills only"
	echo "  $0 -a codex -i             # Install apm-managed skills only (codex header)"
}

link_agent_config() {
	local agent_name=$1
	local command_name=$2
	local config_path=$3
	local agents_filename=$4
	local main_settings_filename=$5
	local skills_path="${config_path}/$6"
	local rules_path="${config_path}/$7"
	local dir_path dir file

	printf "\n\033[1;36m=== Linking config to %s ===\033[0m\n" "${agent_name}"

	for dir_path in "$skills_path" "$rules_path"; do
		if [ ! -d "$dir_path" ]; then
			printf "\033[1;33m⚠ Directory does not exist. Creating: %s\033[0m\n" "$dir_path"
			mkdir -p "$dir_path"
		fi
	done

	ln -fsvn "${SCRIPT_DIR}/AGENTS.md" "${config_path}/${agents_filename}"
	if [ "${agent_name}" = "codex" ]; then
		# Detach a pre-existing symlink so cp does not follow it back into the source tree.
		[ -L "${config_path}/${main_settings_filename}" ] && unlink "${config_path}/${main_settings_filename}"
		cp -fv "${SCRIPT_DIR}/${main_settings_filename}" "${config_path}/${main_settings_filename}"
	else
		ln -fsvn "${SCRIPT_DIR}/${main_settings_filename}" "${config_path}/${main_settings_filename}"
	fi
	for dir in "${SCRIPT_DIR}"/skills/*/; do
		if [ -d "$dir" ]; then
			ln -fsvn "$dir" "$skills_path"
		fi
	done
	for file in "${SCRIPT_DIR}"/rules/*; do
		if [ -f "$file" ]; then
			ln -fsvn "$file" "$rules_path"
		fi
	done
}

install_agent_apm() {
	local agent_name=$1

	printf "\n\033[1;36m=== Installing apm-managed skills (global) for %s ===\033[0m\n" "${agent_name}"
	if ! command -v apm >/dev/null 2>&1; then
		printf "\033[1;33m⚠ apm not installed — skipping external skills. Install via: brew bundle --global\033[0m\n"
		return
	fi
	if [ -e "${HOME}/.apm" ] && [ ! -L "${HOME}/.apm" ]; then
		printf "\033[1;33m⚠ %s exists as a non-symlink. Move it aside to enable dotfiles management.\033[0m\n" "${HOME}/.apm"
	else
		ln -fsvn "${SCRIPT_DIR}/apm" "${HOME}/.apm"
	fi
	(cd "${HOME}/.apm" && apm install -g)
}

setup_agent() {
	local agent_name=$1
	local mode=$2
	local command_name
	local config_path
	local agents_filename
	local main_settings_filename
	local skills_path
	local rules_path
	{
		read -r command_name
		read -r config_path
		read -r agents_filename
		read -r main_settings_filename
		read -r skills_path
		read -r rules_path
	} < <(get_agent_config "$agent_name")

	if [ -z "$config_path" ]; then
		printf "\033[1;31m✗ Unknown agent: %s\033[0m\n" "${agent_name}"
		printf "\033[1;33mAvailable agents: claude, codex\033[0m\n"
		return 1
	fi

	case "$mode" in
	link)
		link_agent_config "$agent_name" "$command_name" "$config_path" "$agents_filename" "$main_settings_filename" "$skills_path" "$rules_path"
		;;
	install)
		install_agent_apm "$agent_name"
		;;
	*)
		link_agent_config "$agent_name" "$command_name" "$config_path" "$agents_filename" "$main_settings_filename" "$skills_path" "$rules_path"
		install_agent_apm "$agent_name"
		;;
	esac
}

AGENT="claude"
MODE="all"

while [[ $# -gt 0 ]]; do
	case "$1" in
	--help | -h)
		show_agent_usage
		exit 0
		;;
	--agent | -a)
		if [[ -z "$2" || "$2" == -* ]]; then
			echo "Error: --agent requires an argument"
			show_agent_usage
			exit 1
		fi
		AGENT="$2"
		shift 2
		;;
	--link-files-only | -l)
		MODE="link"
		shift
		;;
	--install-apm-only | -i)
		MODE="install"
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
