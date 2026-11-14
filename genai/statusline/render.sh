#!/bin/zsh
# Claude Code Enhanced Status Line
# Prompt | Model | Effort | Context % | Prompt Cache | 5h Rate | 7d Rate | Lines Changed

# How long a cache miss cause stays visible after it happens
MISS_CAUSE_WINDOW=300
# Recache size (tokens) worth a /compact. The docs give no threshold; the only figure is
# that an idle session past about 200K tokens on the one-hour cache is compacted for you,
# so this rule of thumb sits below it to also cover the sessions that never reach that.
# https://code.claude.com/docs/en/best-practices
RECACHE_THRESHOLD=100000
# Share of the TTL elapsed after which /compact is suggested (the ◕ pie stage).
# Every request renews the TTL, so getting this far means the session has gone idle,
# and it is the last chance to compact while the summary request can still read the cache.
# https://code.claude.com/docs/en/prompt-caching#compacting-the-conversation
COMPACT_HINT_PCT=75

RST='\033[0m'

# Resolve before sourcing .zshrc so nothing it loads can shadow $0
source "${0:A:h}/format.sh"

# Source .zshrc for prompt functions
source ~/dotfiles/common/.zshrc

# Build prompt string using print -P to expand zsh prompt escapes
_build_statusline_prompt() {
	local result=""
	for func in "${PROMPT_PARTS[@]}"; do
		local output=$($func)
		[ -n "$output" ] && result+="${result:+ }${output}"
	done
	# Keep -P and -n as separate flags: typos reads them bundled as a misspelling.
	print -P -n "$result"
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
  ((.prompt_cache.last_miss_cause.causes[0]? | strings) // ""),
  (.cost.total_lines_added | if type == "number" then floor | tostring else "" end),
  (.cost.total_lines_removed | if type == "number" then floor | tostring else "" end)
] | join("\u001f")' <<<"$input" 2>/dev/null)

# Use the ASCII Unit Separator (0x1f) so that empty fields (e.g. a missing
# resets_at) are preserved; a whitespace IFS like tab collapses them and shifts
# every subsequent value into the wrong variable.
IFS=$'\x1f' read -r model used_pct \
	five_hour_pct five_hour_reset seven_day_pct seven_day_reset effort \
	cache_observed cache_warm cache_ttl cache_expires cache_recache \
	cache_miss_at cache_miss_cause lines_added lines_removed <<<"$_data"

pct_int=${used_pct%%.*}
pct_int=${pct_int:-0}
current_time=$(date +%s)

# Append one metric block to global $out: " │ <icon><label> <color><pie> <value><RST>[ <reset>]"
# Color/pie are derived from $pct_for_color (integer 0-100);
# $value_text is the user-visible suffix (e.g. "42%").
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

# --- Build output ---
out=""

# Zsh prompt
prompt_str=$(_build_statusline_prompt)
[ -n "$prompt_str" ] && out+="${prompt_str} │ "

# Model and reasoning effort stay plain, except the choices that spend usage fastest
# (Fable, and effort high or above), which take the same yellow as the cache miss warning.
HEAVY='\033[33m'
[[ "${model:l}" == *fable* ]] && out+="🤖${HEAVY}${model}${RST}" || out+="🤖${model}"

# Reasoning effort (only when present; no pie)
case "$effort" in
"") ;;
high | xhigh | max) out+=" │ 🧠${HEAVY}${effort}${RST}" ;;
*) out+=" │ 🧠${effort}" ;;
esac

# Context usage
render_metric "📊" "ctx" "$pct_int" "${pct_int}%"

# Prompt cache (absent until the first response; skipped when caching is off)
# Color/pie track how much of the TTL has elapsed, like the other metrics.
# Laid out as "<pie> [<recache tokens>[→/compact]] <time left> [⚠<miss cause>]",
# so the time left stays uncolored like the reset time of the rate limits.
if [ "$cache_observed" = "true" ]; then
	cache_left=$((${cache_expires:-0} - current_time))
	cache_is_warm=false
	[ "$cache_warm" = "true" ] && [ -n "$cache_expires" ] && [ "$cache_left" -gt 0 ] && cache_is_warm=true
	if [ "$cache_is_warm" = "true" ]; then
		# An unknown TTL counts as just renewed, so it never suggests /compact by mistake
		case "$cache_ttl" in
		5m) ttl_sec=300 ;;
		1h) ttl_sec=3600 ;;
		*) ttl_sec=$cache_left ;;
		esac
		elapsed_pct=$(((ttl_sec - cache_left) * 100 / ttl_sec))
		[ "$elapsed_pct" -lt 0 ] && elapsed_pct=0
		# A warm cache is never used up, so red/● stay reserved for cold
		[ "$elapsed_pct" -gt 99 ] && elapsed_pct=99
		cache_time=$(fmt_reset "$cache_expires")
	else
		# Cold means the whole TTL has elapsed, so it renders as a spent (100%) metric
		elapsed_pct=100
		cache_time="-m"
	fi
	cache_color=$(color_for_pct "$elapsed_pct")
	out+=" │ 💾ttl ${cache_color}$(pie_char "$elapsed_pct")${RST}"
	# Below the threshold the recache size is not worth attention, so it stays uncolored
	# like the label; above it, it takes the pie's color to share its urgency.
	# /compact is suggested once the session has idled through COMPACT_HINT_PCT of the TTL,
	# while compacting is still cheap, and stays suggested after the cache goes cold, since
	# the history the next request re-reads then shrinks to the summary for every later turn.
	if [ -n "$cache_recache" ]; then
		if [ "$cache_recache" -lt "$RECACHE_THRESHOLD" ]; then
			out+=" $(fmt_tokens "$cache_recache")"
		else
			[ "$elapsed_pct" -ge "$COMPACT_HINT_PCT" ] && cache_next="→/compact" || cache_next=""
			out+=" ${cache_color}$(fmt_tokens "$cache_recache")${cache_next}${RST}"
		fi
	fi
	out+=" ${cache_time}"
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

# Lines Claude changed this session, colored like a git diff (only once something changed).
# There is no upper bound, so it gets no pie.
if [ $((${lines_added:-0} + ${lines_removed:-0})) -gt 0 ]; then
	out+=" │ ✏️diff \033[32m+${lines_added:-0}${RST}/\033[31m-${lines_removed:-0}${RST}"
fi

printf '%b' "$out"

exit 0
