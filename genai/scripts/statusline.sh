#!/bin/zsh
# Claude Code Enhanced Status Line
# Prompt | Model | Effort | Context % | Prompt Cache | 5h Rate | 7d Rate

# How long a cache miss cause stays visible after it happens
MISS_CAUSE_WINDOW=300
# Recache size (tokens) worth acting on: matches the threshold at which Claude Code
# offers "Resume from summary" for a session idle past the cache TTL
# https://code.claude.com/docs/en/sessions#resume-from-a-summary
RECACHE_THRESHOLD=100000

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
  (.context_window.used_percentage // 0 | tostring),
  (.rate_limits.five_hour.used_percentage // "" | tostring),
  (.rate_limits.five_hour.resets_at // "" | tostring),
  (.rate_limits.seven_day.used_percentage // "" | tostring),
  (.rate_limits.seven_day.resets_at // "" | tostring),
  (.effort.level // ""),
  # `//` treats false as missing, so booleans are stringified explicitly
  (.prompt_cache.caching_observed | if . == null then "" else tostring end),
  (.prompt_cache.warm | if . == null then "" else tostring end),
  (.prompt_cache.ttl // ""),
  # Numbers feed shell arithmetic, so anything but a number becomes empty
  (.prompt_cache.expires_at | if type == "number" then floor | tostring else "" end),
  (.prompt_cache.recache_tokens_if_cold | if type == "number" then floor | tostring else "" end),
  (.prompt_cache.last_miss_at | if type == "number" then floor | tostring else "" end),
  ((.prompt_cache.last_miss_cause.causes[0]? | strings) // "")
] | join("\u001f")' <<<"$input" 2>/dev/null)

# Use the ASCII Unit Separator (0x1f) so that empty fields (e.g. a missing
# resets_at) are preserved; a whitespace IFS like tab collapses them and shifts
# every subsequent value into the wrong variable.
IFS=$'\x1f' read -r model used_pct \
	five_hour_pct five_hour_reset seven_day_pct seven_day_reset effort \
	cache_observed cache_warm cache_ttl cache_expires cache_recache \
	cache_miss_at cache_miss_cause <<<"$_data"

pct_int=${used_pct%%.*}
pct_int=${pct_int:-0}
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

# Prompt cache (absent until the first response; skipped when caching is off)
# Color/pie track how much of the TTL has elapsed, like the other metrics.
if [ "$cache_observed" = "true" ]; then
	cache_left=$((${cache_expires:-0} - current_time))
	cache_is_warm=false
	[ "$cache_warm" = "true" ] && [ -n "$cache_expires" ] && [ "$cache_left" -gt 0 ] && cache_is_warm=true
	if [ "$cache_is_warm" = "true" ]; then
		[ "$cache_ttl" = "5m" ] && ttl_sec=300 || ttl_sec=3600
		elapsed_pct=$(((ttl_sec - cache_left) * 100 / ttl_sec))
		[ "$elapsed_pct" -lt 0 ] && elapsed_pct=0
		# Squeeze 0-99% into the four lower stages so red/● stay reserved for cold
		warm_stage_pct=$((elapsed_pct * 80 / 100))
		[ "$warm_stage_pct" -gt 79 ] && warm_stage_pct=79
		cache_color=$(color_for_pct "$warm_stage_pct")
		render_metric "💾" "cache" "$warm_stage_pct" "$(fmt_reset "$cache_expires")"
	else
		# Cold means the whole TTL has elapsed, so it renders as a spent (100%) metric
		cache_color=$(color_for_pct 100)
		render_metric "💾" "cache" 100 "-m"
	fi
	# Below the threshold the recache size is not worth attention, so it stays uncolored
	# like the label; above it, it takes the pie's color to share its urgency.
	if [ -n "$cache_recache" ]; then
		if [ "$cache_recache" -lt "$RECACHE_THRESHOLD" ]; then
			out+=" ↻$(fmt_tokens "$cache_recache")"
		else
			out+=" ${cache_color}↻$(fmt_tokens "$cache_recache")${RST}"
		fi
	fi
	if [ -n "$cache_miss_at" ] && [ -n "$cache_miss_cause" ] &&
		[ $((current_time - cache_miss_at)) -le "$MISS_CAUSE_WINDOW" ]; then
		out+=" \033[33m⚠${cache_miss_cause}${RST}"
	fi
fi

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
