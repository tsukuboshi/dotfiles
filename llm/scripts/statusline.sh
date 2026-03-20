#!/bin/bash
# Claude Code Enhanced Status Line
# Model | Context % | 5h Rate | 7d Rate | Compression

CLAUDE_DIR="$HOME/.claude"
LAST_STATE_FILE="$CLAUDE_DIR/.sl_last_state.json"
COMPRESS_FILE="$CLAUDE_DIR/.sl_compress.json"

RST='\033[0m'

IFS= read -r -d '' input

if ! command -v jq &>/dev/null; then
	echo "jq required"
	exit 0
fi

# Extract all fields in single jq call
_data=$(jq -r '[
  (.model.display_name // .model.id // "Unknown"),
  (.context_window.context_window_size // 200000 | tostring),
  (.context_window.used_percentage // 0 | tostring),
  (.session_id // "unknown"),
  (.rate_limits.five_hour.used_percentage // -1 | tostring),
  (.rate_limits.five_hour.resets_at // ""),
  (.rate_limits.seven_day.used_percentage // -1 | tostring),
  (.rate_limits.seven_day.resets_at // "")
] | join("\t")' <<<"$input" 2>/dev/null)

IFS=$'\t' read -r model context_size used_pct session_id \
	five_hour_pct five_hour_reset seven_day_pct seven_day_reset <<<"$_data"

pct_int=${used_pct%%.*}
pct_int=${pct_int:-0}
current_used=$((pct_int * context_size / 100))
current_time=$(date +%s)

# ANSI true color gradient: green(0%) -> yellow(50%) -> red(100%)
color_for_pct() {
	local pct=$1 r g
	if [ "$pct" -le 50 ]; then
		r=$((pct * 255 / 50))
		g=255
	else
		r=255
		g=$(((100 - pct) * 255 / 50))
	fi
	printf '\033[38;2;%d;%d;0m' "$r" "$g"
}

# Fine-grained progress bar using block elements
fine_bar() {
	local pct=$1 width=${2:-8}
	local chars=('' '▏' '▎' '▍' '▌' '▋' '▊' '▉')
	local total_steps=$((width * 8))
	local filled_steps=$((pct * total_steps / 100))
	[ "$filled_steps" -gt "$total_steps" ] && filled_steps=$total_steps
	local full=$((filled_steps / 8))
	local partial=$((filled_steps % 8))
	local has_partial=0
	[ "$partial" -gt 0 ] && has_partial=1
	local empty=$((width - full - has_partial))
	local bar=""
	for ((i = 0; i < full; i++)); do bar+="█"; done
	if [ "$has_partial" -eq 1 ]; then
		bar+="${chars[$partial]}"
	fi
	for ((i = 0; i < empty; i++)); do bar+="░"; done
	printf '%s' "$bar"
}

# Format remaining time from ISO 8601 reset timestamp
fmt_reset() {
	local reset_at="$1"
	[ -z "$reset_at" ] && return 1
	local reset_ts
	# Strip fractional seconds and trailing Z for macOS date
	local clean="${reset_at%%.*}"
	clean="${clean%Z}"
	reset_ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$clean" +%s 2>/dev/null) ||
		reset_ts=$(date -d "$reset_at" +%s 2>/dev/null) ||
		return 1
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

# --- Session & compression tracking ---
compress_count=0

if [ -f "$LAST_STATE_FILE" ]; then
	_last=$(cat "$LAST_STATE_FILE" 2>/dev/null)
	last_sid=$(jq -r '.sid // ""' <<<"$_last" 2>/dev/null)
	last_tok=$(jq -r '.tok // 0' <<<"$_last" 2>/dev/null)

	if [ "$session_id" != "$last_sid" ]; then
		printf '{"sid":"%s","count":0}\n' "$session_id" >"$COMPRESS_FILE"
	elif [ "$current_used" -lt "${last_tok:-0}" ] 2>/dev/null; then
		drop=$((last_tok - current_used))
		threshold=$((last_tok / 5))
		if [ -f "$COMPRESS_FILE" ]; then
			_comp=$(cat "$COMPRESS_FILE" 2>/dev/null)
			c_sid=$(jq -r '.sid // ""' <<<"$_comp" 2>/dev/null)
			c_count=$(jq -r '.count // 0' <<<"$_comp" 2>/dev/null)
			[ "$session_id" = "$c_sid" ] && compress_count=$c_count
		fi
		if [ "$drop" -gt "$threshold" ] && [ "$drop" -gt 10000 ]; then
			compress_count=$((compress_count + 1))
		fi
		printf '{"sid":"%s","count":%d}\n' "$session_id" "$compress_count" >"$COMPRESS_FILE"
	fi
else
	printf '{"sid":"%s","count":0}\n' "$session_id" >"$COMPRESS_FILE"
fi

# Load compress count if not yet set
if [ "$compress_count" -eq 0 ] && [ -f "$COMPRESS_FILE" ]; then
	_comp=$(cat "$COMPRESS_FILE" 2>/dev/null)
	c_sid=$(jq -r '.sid // ""' <<<"$_comp" 2>/dev/null)
	c_count=$(jq -r '.count // 0' <<<"$_comp" 2>/dev/null)
	[ "$session_id" = "$c_sid" ] && compress_count=$c_count
fi

# Update last state
printf '{"sid":"%s","tok":%d}\n' "$session_id" "$current_used" >"$LAST_STATE_FILE"

# --- Build output ---
out=""

# Model
out+="🤖model:${model}"

# Context usage with colored bar
ctx_color=$(color_for_pct "$pct_int")
ctx_bar=$(fine_bar "$pct_int" 8)
out+=" │ 📊context:${ctx_color}${ctx_bar} ${pct_int}%${RST}"

# Compression bar (max 3)
cmp_level=$compress_count
[ "$cmp_level" -gt 3 ] && cmp_level=3
cmp_pct=$((cmp_level * 100 / 3))
cmp_color=$(color_for_pct "$cmp_pct")
cmp_bar=""
for ((i = 0; i < cmp_level; i++)); do cmp_bar+="█"; done
for ((i = cmp_level; i < 3; i++)); do cmp_bar+="░"; done
out+=" │ 🔄compress:${cmp_color}${cmp_bar} ${compress_count}x${RST}"

# 5h rate limit
if [ "${five_hour_pct%.*}" -ge 0 ] 2>/dev/null; then
	fh_int=${five_hour_pct%%.*}
	fh_color=$(color_for_pct "$fh_int")
	fh_bar=$(fine_bar "$fh_int" 5)
	fh_reset=$(fmt_reset "$five_hour_reset") && fh_reset=" ${fh_reset}" || fh_reset=""
	out+=" │ ⏱️5h-limit:${fh_color}${fh_bar} ${fh_int}%${RST}${fh_reset}"
fi

# 7d rate limit
if [ "${seven_day_pct%.*}" -ge 0 ] 2>/dev/null; then
	sd_int=${seven_day_pct%%.*}
	sd_color=$(color_for_pct "$sd_int")
	sd_bar=$(fine_bar "$sd_int" 5)
	sd_reset=$(fmt_reset "$seven_day_reset") && sd_reset=" ${sd_reset}" || sd_reset=""
	out+=" │ 📅7d-limit:${sd_color}${sd_bar} ${sd_int}%${RST}${sd_reset}"
fi

printf '%b' "$out"
