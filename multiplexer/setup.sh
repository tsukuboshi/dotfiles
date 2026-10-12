#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

get_multiplexer_config() {
	local multiplexer_name=$1
	case "$multiplexer_name" in
	herdr)
		echo "${HOME}/.config/herdr"
		echo "config.toml"
		;;
	*)
		echo ""
		echo ""
		;;
	esac
}

show_multiplexer_usage() {
	echo "Usage: $0 [OPTIONS]"
	echo ""
	echo "OPTIONS:"
	echo "  -m, --multiplexer MULTIPLEXER  Specify multiplexer (herdr, default: herdr)"
	echo "  (no option)                    Link herdr config (default)"
	echo ""
	echo "Examples:"
	echo "  $0                             # Link herdr config (default)"
	echo "  $0 --multiplexer herdr         # Link herdr config"
	echo "  $0 -m herdr                    # Link herdr config (short)"
}

link_multiplexer_config() {
	local multiplexer_name=$1
	local config_path=$2
	local config_filename=$3

	printf "\n\033[1;36m=== Linking config to %s ===\033[0m\n" "${multiplexer_name}"

	if [ ! -d "$config_path" ]; then
		printf "\033[1;33m⚠ Directory does not exist. Creating: %s\033[0m\n" "$config_path"
		mkdir -p "$config_path"
	fi

	ln -fsvn "${SCRIPT_DIR}/${config_filename}" "${config_path}/${config_filename}"
}

setup_multiplexer() {
	local multiplexer_name=$1
	local config_path
	local config_filename
	{
		read -r config_path
		read -r config_filename
	} < <(get_multiplexer_config "$multiplexer_name")

	if [ -z "$config_path" ]; then
		printf "\033[1;31m✗ Unknown multiplexer: %s\033[0m\n" "${multiplexer_name}"
		printf "\033[1;33mAvailable multiplexers: herdr\033[0m\n"
		return 1
	fi

	link_multiplexer_config "$multiplexer_name" "$config_path" "$config_filename"
}

MULTIPLEXER="herdr"

while [[ $# -gt 0 ]]; do
	case "$1" in
	--help | -h)
		show_multiplexer_usage
		exit 0
		;;
	--multiplexer | -m)
		if [[ -z "$2" || "$2" == -* ]]; then
			echo "Error: --multiplexer requires an argument"
			show_multiplexer_usage
			exit 1
		fi
		MULTIPLEXER="$2"
		shift 2
		;;
	*)
		echo "Unknown option: $1"
		show_multiplexer_usage
		exit 1
		;;
	esac
done

setup_multiplexer "$MULTIPLEXER"
