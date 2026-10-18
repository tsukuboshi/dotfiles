#!/bin/zsh
# Formatting helpers for the status line, sourced by render.sh.
# fmt_reset reads $current_time from the caller so that every metric
# measures remaining time against the same instant.

# ANSI color matching pie chart stages and zsh prompt palette
# ○(0-24%):white ◔(25-49%):green ◑(50-74%):yellow ◕(75-99%):magenta ●(100%+):red
# Red/● mean "used up", so they appear only once a metric reaches 100%.
color_for_pct() {
	local pct=$1
	if [ "$pct" -lt 25 ]; then
		printf '\033[37m'
	elif [ "$pct" -lt 50 ]; then
		printf '\033[32m'
	elif [ "$pct" -lt 75 ]; then
		printf '\033[33m'
	elif [ "$pct" -lt 100 ]; then
		printf '\033[35m'
	else
		printf '\033[31m'
	fi
}

# Pie chart using circle characters: ○◔◑◕●
pie_char() {
	local pct=$1
	if [ "$pct" -lt 25 ]; then
		printf '○'
	elif [ "$pct" -lt 50 ]; then
		printf '◔'
	elif [ "$pct" -lt 75 ]; then
		printf '◑'
	elif [ "$pct" -lt 100 ]; then
		printf '◕'
	else
		printf '●'
	fi
}

# Format remaining time from reset timestamp (Unix epoch seconds or ISO 8601)
fmt_reset() {
	local reset_at="$1"
	[ -z "$reset_at" ] && return 1
	local reset_ts
	if [[ "$reset_at" =~ ^[0-9]+$ ]]; then
		# Unix epoch seconds (current official schema)
		reset_ts="$reset_at"
	else
		# ISO 8601 fallback: strip fractional seconds and trailing Z for macOS date
		local clean="${reset_at%%.*}"
		clean="${clean%Z}"
		reset_ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$clean" +%s 2>/dev/null) ||
			reset_ts=$(date -d "$reset_at" +%s 2>/dev/null) ||
			return 1
	fi
	local diff=$((reset_ts - current_time))
	[ "$diff" -le 0 ] && {
		printf 'now'
		return 0
	}
	if [ "$diff" -ge 86400 ]; then
		local d=$((diff / 86400)) h=$(((diff % 86400) / 3600))
		printf '%dd%dh' "$d" "$h"
	elif [ "$diff" -ge 3600 ]; then
		local h=$((diff / 3600)) m=$(((diff % 3600) / 60))
		printf '%dh%dm' "$h" "$m"
	else
		printf '%dm' "$((diff / 60))"
	fi
}

# Format a token count compactly: 950 / 45k / 1.2M
fmt_tokens() {
	local n=$1
	if [ "$n" -ge 1000000 ]; then
		printf '%d.%dM' "$((n / 1000000))" "$(((n % 1000000) / 100000))"
	elif [ "$n" -ge 1000 ]; then
		printf '%dk' "$((n / 1000))"
	else
		printf '%d' "$n"
	fi
}
