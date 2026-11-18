#!/bin/bash
# Feed fixed status line inputs to genai/statusline and check what it prints.
# render.sh runs under /bin/bash, which is bash 3.2 on macOS, so the cases run
# there too. The prompt in front depends on the user, directory and git state,
# so only the part from the model on is compared.
# Usage: bash .github/scripts/test-statusline.sh
set -u

root=$(git rev-parse --show-toplevel) || exit 1
STATUSLINE_DIR="${root}/genai/statusline"
WORK=$(mktemp -d)
FAILED=0
PASSED=0

pass() {
	PASSED=$((PASSED + 1))
}

fail() {
	FAILED=$((FAILED + 1))
	printf 'FAIL: %s\n  %s\n' "$1" "$2"
}

# expect_eq <name> <want> <got>
expect_eq() {
	if [[ "$3" == "$2" ]]; then
		pass
	else
		fail "$1" "want '${2}', got '${3}'"
	fi
}

# format.sh
# Sourced into a subshell for each call, so its functions do not leak into
# this script. FMT_TZ sets the time zone the call runs in.
fmt() {
	TZ=${FMT_TZ:-UTC} /bin/bash -c 'source "$1/format.sh"; shift; "$@"' _ "${STATUSLINE_DIR}" "$@"
}

for pair in 0:○ 24:○ 25:◔ 49:◔ 50:◑ 74:◑ 75:◕ 99:◕ 100:● 150:●; do
	got=$(fmt pie_char "${pair%%:*}")
	expect_eq "pie_char ${pair%%:*}" "${pair#*:}" "${got}"
done

for pair in 24:37 25:32 50:33 75:35 100:31; do
	got=$(fmt color_for_pct "${pair%%:*}")
	expect_eq "color_for_pct ${pair%%:*}" $'\033['"${pair#*:}m" "${got}"
done

for pair in 950:950 999:999 1000:1k 45000:45k 999999:999k 1000000:1.0M 1234567:1.2M; do
	got=$(fmt fmt_tokens "${pair%%:*}")
	expect_eq "fmt_tokens ${pair%%:*}" "${pair#*:}" "${got}"
done

# 2026-01-01T00:00:00Z
now=1767225600
got=$(fmt fmt_reset $((now + 59)) "${now}")
expect_eq "fmt_reset: under a minute left is 0m" 0m "${got}"
got=$(fmt fmt_reset $((now + 5400)) "${now}")
expect_eq "fmt_reset: hours and minutes" 1h30m "${got}"
got=$(fmt fmt_reset $((now + 95400)) "${now}")
expect_eq "fmt_reset: days and hours" 1d2h "${got}"
got=$(fmt fmt_reset "${now}" "${now}")
expect_eq "fmt_reset: a reset that has passed is now" now "${got}"
got=$(FMT_TZ=Asia/Tokyo fmt fmt_reset 2026-01-01T01:30:00.000Z "${now}")
expect_eq "fmt_reset: an ISO 8601 time is read as UTC in any time zone" 1h30m "${got}"
if fmt fmt_reset "" "${now}" >/dev/null; then
	fail "fmt_reset: an empty reset time fails" "got exit 0"
else
	pass
fi

# render.sh
# strip_colors <text>
# Prints text without its SGR color sequences.
strip_colors() {
	local s=$1 re=$'\033''\[[0-9;]*m'
	while [[ "${s}" =~ ${re} ]]; do
		s=${s/"${BASH_REMATCH[0]}"/}
	done
	printf '%s' "${s}"
}

# render <json>
# Runs render.sh on json, leaving its output from the model on in OUTPUT,
# with colors in RAW and without them in OUTPUT.
render() {
	RAW=$(printf '%s' "$1" | /bin/bash "${STATUSLINE_DIR}/render.sh" 2>/dev/null)
	RAW="🤖${RAW#*🤖}"
	OUTPUT=$(strip_colors "${RAW}")
}

# Reset and expiry times sit mid-minute, so the second or two the cases take
# to run cannot change the minutes they print.
now=$(date +%s)

render '{"model": {"display_name": "Opus 5.5"}, "context_window": {"used_percentage": 42.7}}'
expect_eq "render: model and context only" "🤖Opus 5.5 │ 📊ctx ◔ 42%" "${OUTPUT}"

input=$(jq -cn --argjson n "${now}" '{
	model: {display_name: "Claude Fable 5"}, effort: {level: "high"},
	context_window: {used_percentage: 80},
	rate_limits: {
		five_hour: {used_percentage: 30.2, resets_at: ($n + 5430)},
		seven_day: {used_percentage: 100, resets_at: ($n + 95430)}
	},
	cost: {total_lines_added: 12, total_lines_removed: 3}
}')
render "${input}"
expect_eq "render: rate limits, effort and lines changed" \
	"🤖Claude Fable 5 │ 🧠high │ 📊ctx ◕ 80% │ ⏱️5h ◔ 30% 1h30m │ 📅7d ● 100% 1d2h │ ✏️diff +12/-3" "${OUTPUT}"
if [[ "${RAW}" == "🤖"$'\033[33m'"Claude Fable 5"* ]]; then
	pass
else
	fail "render: a Fable model is shown in yellow" "got '${RAW}'"
fi

render '{"model": {"display_name": "FABLE"}, "effort": {"level": "low"}}'
if [[ "${RAW}" == "🤖"$'\033[33m'"FABLE"$'\033[0m'" │ 🧠low"* ]]; then
	pass
else
	fail "render: the Fable match ignores case and low effort stays plain" "got '${RAW}'"
fi

input=$(jq -cn --argjson n "${now}" '{
	model: {id: "claude-sonnet"},
	prompt_cache: {
		caching_observed: true, warm: true, ttl: "1h", expires_at: ($n + 1830),
		recache_tokens_if_cold: 150000,
		last_miss_at: ($n - 60), last_miss_cause: {causes: ["model_changed"]}
	}
}')
render "${input}"
expect_eq "render: a warm cache with a recent miss" \
	"🤖claude-sonnet │ 📊ctx ○ 0% │ 💾ttl ◔ 150k 30m ⚠model_changed" "${OUTPUT}"

input=$(jq -cn --argjson n "${now}" '{
	model: {display_name: "x"},
	prompt_cache: {caching_observed: true, warm: true, ttl: "5m", expires_at: ($n + 30), recache_tokens_if_cold: 1200000}
}')
render "${input}"
expect_eq "render: a cache near expiry suggests /compact" \
	"🤖x │ 📊ctx ○ 0% │ 💾ttl ◕ 1.2M→/compact 0m" "${OUTPUT}"

render '{"model": {"display_name": "x"}, "prompt_cache": {"caching_observed": true, "warm": false, "ttl": "5m", "recache_tokens_if_cold": 45000}}'
expect_eq "render: a cold cache is spent" "🤖x │ 📊ctx ○ 0% │ 💾ttl ● 45k -m" "${OUTPUT}"

render 'not json'
expect_eq "render: unreadable input still prints a line" "🤖 │ 📊ctx ○ 0%" "${OUTPUT}"

# bash evaluates the operands of [[ -lt ]] as arithmetic, which runs any
# command substitution inside an array index, so non-numbers must not reach it.
input=$(jq -cn --arg p "a[\$(touch ${WORK}/ran)]" '{
	model: {display_name: "x"}, context_window: {used_percentage: $p},
	rate_limits: {five_hour: {used_percentage: $p}}
}')
render "${input}"
if [[ ! -e "${WORK}/ran" && "${OUTPUT}" == "🤖x │ 📊ctx ○ 0%" ]]; then
	pass
else
	fail "render: a percentage that is not a number is not evaluated" "got '${OUTPUT}'"
fi

printf '%d passed, %d failed\n' "${PASSED}" "${FAILED}"
((FAILED == 0))
