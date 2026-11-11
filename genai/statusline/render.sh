#!/bin/zsh
# Claude Code Enhanced Status Line
# Prompt | Model | Effort | Context % | Prompt Cache | Prompts Sent | Lines Changed | 5h Rate | 7d Rate

# How long a cache miss cause stays visible after it happens
MISS_CAUSE_WINDOW=300
# Recache size (tokens) worth acting on: matches the threshold at which Claude Code
# offers "Resume from summary" for a session idle past the cache TTL
# https://code.claude.com/docs/en/sessions#resume-from-a-summary
RECACHE_THRESHOLD=100000
# Prompts after which a session is long enough to consider /clear (pie fills here)
PROMPT_THRESHOLD=20

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
  (.transcript_path // ""),
  (.cost.total_lines_added | if type == "number" then floor | tostring else "" end),
  (.cost.total_lines_removed | if type == "number" then floor | tostring else "" end)
] | join("\u001f")' <<<"$input" 2>/dev/null)

# Use the ASCII Unit Separator (0x1f) so that empty fields (e.g. a missing
# resets_at) are preserved; a whitespace IFS like tab collapses them and shifts
# every subsequent value into the wrong variable.
IFS=$'\x1f' read -r model used_pct \
	five_hour_pct five_hour_reset seven_day_pct seven_day_reset effort \
	cache_observed cache_warm cache_ttl cache_expires cache_recache \
	cache_miss_at cache_miss_cause transcript_path lines_added lines_removed <<<"$_data"

# Count the prompts the user sent in the main conversation since the last /compact,
# like prompt-rail's rail. Tool results, meta entries, compact summaries, interrupts and
# shell / local command echoes are also "user" entries, so only typed prompts and skill
# invocations (<command-message>) count. /compact appends to the same transcript, so a
# compact_boundary entry restarts the count.
# grep drops assistant entries and tool results (the bulk of a transcript) before jq,
# and jq parses line by line so a line still being written is skipped, not fatal.
prompt_count=""
if [ -r "$transcript_path" ]; then
	prompt_count=$(grep -E '"type":"user"|"subtype":"compact_boundary"' "$transcript_path" |
		grep -v -F '"type":"tool_result"' |
		jq -R -n 'reduce (inputs | fromjson? | objects) as $e (0;
		  if $e.type == "system" and $e.subtype == "compact_boundary" then 0
		  elif $e.type == "user" and $e.isSidechain != true and $e.isMeta != true
		    and $e.isCompactSummary != true
		    and ($e.message.content
		      | if type == "string" then (startswith("<") | not) or startswith("<command-message>")
		        elif type == "array" then any(.[]; .type == "text" and (.text | startswith("[Request interrupted") | not))
		        else false end)
		  then . + 1
		  else . end)' 2>/dev/null)
fi

pct_int=${used_pct%%.*}
pct_int=${pct_int:-0}
current_time=$(date +%s)

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
if [ "$cache_observed" = "true" ]; then
	cache_left=$((${cache_expires:-0} - current_time))
	cache_is_warm=false
	[ "$cache_warm" = "true" ] && [ -n "$cache_expires" ] && [ "$cache_left" -gt 0 ] && cache_is_warm=true
	if [ "$cache_is_warm" = "true" ]; then
		[ "$cache_ttl" = "5m" ] && ttl_sec=300 || ttl_sec=3600
		elapsed_pct=$(((ttl_sec - cache_left) * 100 / ttl_sec))
		[ "$elapsed_pct" -lt 0 ] && elapsed_pct=0
		# A warm cache is never used up, so red/● stay reserved for cold
		[ "$elapsed_pct" -gt 99 ] && elapsed_pct=99
		cache_color=$(color_for_pct "$elapsed_pct")
		render_metric "💾" "ttl" "$elapsed_pct" "$(fmt_reset "$cache_expires")"
	else
		# Cold means the whole TTL has elapsed, so it renders as a spent (100%) metric
		cache_color=$(color_for_pct 100)
		render_metric "💾" "ttl" 100 "-m"
	fi
	# Below the threshold the recache size is not worth attention, so it stays uncolored
	# like the label; above it, it takes the pie's color to share its urgency.
	# Once cold, the next move follows prompt-cache-control: a recache worth acting on
	# calls for /compact, and a small one for /clear if the task is done.
	if [ -n "$cache_recache" ]; then
		[ "$cache_recache" -lt "$RECACHE_THRESHOLD" ] && cache_next="→/clear" || cache_next="→/compact"
		[ "$cache_is_warm" = "true" ] && cache_next=""
		if [ "$cache_recache" -lt "$RECACHE_THRESHOLD" ]; then
			out+=" ↻$(fmt_tokens "$cache_recache")${cache_next}"
		else
			out+=" ${cache_color}↻$(fmt_tokens "$cache_recache")${cache_next}${RST}"
		fi
	fi
	if [ -n "$cache_miss_at" ] && [ -n "$cache_miss_cause" ] &&
		[ $((current_time - cache_miss_at)) -le "$MISS_CAUSE_WINDOW" ]; then
		out+=" \033[33m⚠${cache_miss_cause}${RST}"
	fi
fi

# Prompts sent (only once the transcript has one); the pie fills at PROMPT_THRESHOLD,
# where the session has likely drifted across tasks and /clear is the next move.
if [ "${prompt_count:-0}" -gt 0 ]; then
	[ "$prompt_count" -ge "$PROMPT_THRESHOLD" ] && prompt_next="→/clear" || prompt_next=""
	render_metric "💬" "msg" "$((prompt_count * 100 / PROMPT_THRESHOLD))" "${prompt_count}x${prompt_next}"
fi

# Lines Claude changed this session, colored like a git diff (only once something changed).
# There is no upper bound, so it gets no pie.
if [ $((${lines_added:-0} + ${lines_removed:-0})) -gt 0 ]; then
	out+=" │ ✏️diff \033[32m+${lines_added:-0}${RST}/\033[31m-${lines_removed:-0}${RST}"
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
