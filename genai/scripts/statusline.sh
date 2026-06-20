#!/bin/zsh
# Claude Code Enhanced Status Line
# Prompt | Model | Context % | 5h Rate | 7d Rate | Compression

CLAUDE_DIR="$HOME/.claude"
LAST_STATE_FILE="$CLAUDE_DIR/.sl_last_state.json"
COMPRESS_FILE="$CLAUDE_DIR/.sl_compress.json"

RST='\033[0m'

# Source .zshrc for prompt functions
source ~/dotfiles/common/.zshrc

# Build prompt string using print -P to expand zsh prompt escapes
_build_statusline_prompt() {
	local result=""
	for func in "${PROMPT_PARTS[@]}"; do
		local output=$($func)
		[ -n "$output" ] && result+="${result:+ }${output}"
	done
	print -Pn "$result"
}

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
  (.rate_limits.five_hour.used_percentage // "" | tostring),
  (.rate_limits.five_hour.resets_at // "" | tostring),
  (.rate_limits.seven_day.used_percentage // "" | tostring),
  (.rate_limits.seven_day.resets_at // "" | tostring),
  (.effort.level // "")
] | join("\u001f")' <<<"$input" 2>/dev/null)

# Use the ASCII Unit Separator (0x1f) so that empty fields (e.g. a missing
# resets_at) are preserved; a whitespace IFS like tab collapses them and shifts
# every subsequent value into the wrong variable.
IFS=$'\x1f' read -r model context_size used_pct session_id \
	five_hour_pct five_hour_reset seven_day_pct seven_day_reset effort <<<"$_data"

pct_int=${used_pct%%.*}
pct_int=${pct_int:-0}
current_used=$((pct_int * context_size / 100))
current_time=$(date +%s)

# ANSI color matching pie chart stages and zsh prompt palette
# ○(0-19%):white ◔(20-39%):green ◑(40-59%):yellow ◕(60-79%):magenta ●(80-100%):red
color_for_pct() {
	local pct=$1
	if [ "$pct" -lt 20 ]; then
		printf '\033[37m'
	elif [ "$pct" -lt 40 ]; then
		printf '\033[32m'
	elif [ "$pct" -lt 60 ]; then
		printf '\033[33m'
	elif [ "$pct" -lt 80 ]; then
		printf '\033[35m'
	else
		printf '\033[31m'
	fi
}

# Pie chart using circle characters: ○◔◑◕●
pie_char() {
	local pct=$1
	if [ "$pct" -lt 20 ]; then
		printf '○'
	elif [ "$pct" -lt 40 ]; then
		printf '◔'
	elif [ "$pct" -lt 60 ]; then
		printf '◑'
	elif [ "$pct" -lt 80 ]; then
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

# Append one metric block to global $out: " │ <icon><label> <color><pie> <value><RST>[ <reset>]"
# Color/pie are derived from $pct_for_color (integer 0-100);
# $value_text is the user-visible suffix (e.g. "42%" or "3x").
# Appends to $out directly to avoid one subshell per call on the statusline hot path.
render_metric() {
	local icon="$1" label="$2" pct_for_color="$3" value_text="$4" reset_iso="${5:-}"
	local color pie reset_suffix=""
	color=$(color_for_pct "$pct_for_color")
	pie=$(pie_char "$pct_for_color")
	if [ -n "$reset_iso" ]; then
		local r
		r=$(fmt_reset "$reset_iso") && reset_suffix=" $r"
	fi
	out+=" │ ${icon}${label} ${color}${pie} ${value_text}${RST}${reset_suffix}"
}

# Read {sid, count} from COMPRESS_FILE; returns stored count if session matches, else 0.
read_compress_count() {
	[ -f "$COMPRESS_FILE" ] || {
		printf 0
		return
	}
	local c_sid c_count
	IFS=$'\t' read -r c_sid c_count < <(
		jq -r '[(.sid // ""), (.count // 0 | tostring)] | @tsv' <"$COMPRESS_FILE" 2>/dev/null
	)
	if [ "$session_id" = "$c_sid" ]; then
		printf '%d' "${c_count:-0}"
	else
		printf 0
	fi
}

write_compress_count() {
	printf '{"sid":"%s","count":%d}\n' "$session_id" "$1" >"$COMPRESS_FILE"
}

# --- Session & compression tracking ---
compress_count=0

if [ -f "$LAST_STATE_FILE" ]; then
	IFS=$'\t' read -r last_sid last_tok < <(
		jq -r '[(.sid // ""), (.tok // 0 | tostring)] | @tsv' <"$LAST_STATE_FILE" 2>/dev/null
	)
	last_tok=${last_tok:-0}

	if [ "$session_id" != "$last_sid" ]; then
		write_compress_count 0
	elif [ "$current_used" -lt "$last_tok" ] 2>/dev/null; then
		drop=$((last_tok - current_used))
		threshold=$((last_tok / 5))
		compress_count=$(read_compress_count)
		if [ "$drop" -gt "$threshold" ] && [ "$drop" -gt 10000 ]; then
			compress_count=$((compress_count + 1))
		fi
		write_compress_count "$compress_count"
	fi
else
	write_compress_count 0
fi

# Load compress count if not yet set (covers the no-drop / new-session paths)
[ "$compress_count" -eq 0 ] && compress_count=$(read_compress_count)

# Update last state
printf '{"sid":"%s","tok":%d}\n' "$session_id" "$current_used" >"$LAST_STATE_FILE"

# --- Build output ---
out=""

# Zsh prompt
prompt_str=$(_build_statusline_prompt)
[ -n "$prompt_str" ] && out+="${prompt_str} │ "

# Model
out+="🤖${model}"

# Reasoning effort (only when present; plain text, no color/pie)
[ -n "$effort" ] && out+=" │ 🧠${effort}"

# Context usage
render_metric "📊" "ctx" "$pct_int" "${pct_int}%"

# Compression (max 4 levels visualised; pct synthesized from count)
cmp_level=$compress_count
[ "$cmp_level" -gt 4 ] && cmp_level=4
render_metric "🔄" "cmp" "$((cmp_level * 25))" "${compress_count}x"

# 5h rate limit (Pro/Max only; absent on Team/Enterprise)
if [ -n "$five_hour_pct" ]; then
	fh_int=${five_hour_pct%%.*}
	fh_int=${fh_int:-0}
	render_metric "⏱️" "5h" "$fh_int" "${fh_int}%" "$five_hour_reset"
fi

# 7d rate limit (Pro/Max only; absent on Team/Enterprise)
if [ -n "$seven_day_pct" ]; then
	sd_int=${seven_day_pct%%.*}
	sd_int=${sd_int:-0}
	render_metric "📅" "7d" "$sd_int" "${sd_int}%" "$seven_day_reset"
fi

printf '%b' "$out"

exit 0
