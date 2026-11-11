#!/bin/bash
# Run open_form.sh with --dry-run on fixed bodies and check that it builds
# the URL for a body that passes and refuses one that fails a check.
# The open-issue and open-pr skills open the page only through this script,
# so a check that stops refusing a bad body should fail here instead of on
# GitHub.
# Usage: bash .github/scripts/test-open-form.sh
set -u

root=$(git rev-parse --show-toplevel) || exit 1
ISSUE_SCRIPT="${root}/genai/skills/open-issue/scripts/open_form.sh"
PR_SCRIPT="${root}/genai/skills/open-pr/scripts/open_form.sh"
ISSUE_TEMPLATE="${root}/.github/ISSUE_TEMPLATE/new_task.md"
PR_TEMPLATE="${root}/.github/pull_request_template.md"
REPO_URL="https://github.com/owner/repo"
FAILED=0
PASSED=0

body_file=$(mktemp)
trap 'rm -f "$body_file"' EXIT

pass() {
	PASSED=$((PASSED + 1))
}

fail() {
	FAILED=$((FAILED + 1))
	printf 'FAIL: %s\n  %s\n' "$1" "$2"
}

# run_form <body> <script args...>
# Writes the body to the body file and runs the script with --dry-run,
# leaving its stdout and stderr in OUTPUT and its exit code in RC.
run_form() {
	printf '%s' "$1" >"$body_file"
	shift
	OUTPUT=$(bash "$@" --body-file "$body_file" --dry-run 2>&1)
	RC=$?
}

# expect_open <name> <want-prefix> <body> <script args...>
# Checks that the script exits 0 and prints a URL starting with want-prefix.
expect_open() {
	local name=$1 want=$2
	shift 2
	run_form "$@"
	if ((RC == 0)) && [[ "$OUTPUT" == "$want"* ]]; then
		pass
	else
		fail "$name" "want exit 0 and a URL starting with ${want}, got exit ${RC}: ${OUTPUT}"
	fi
}

# expect_refuse <name> <want-message> <body> <script args...>
# Checks that the script exits 2 and its message contains want-message.
expect_refuse() {
	local name=$1 want=$2
	shift 2
	run_form "$@"
	if ((RC == 2)) && [[ "$OUTPUT" == *"$want"* ]]; then
		pass
	else
		fail "$name" "want exit 2 and '${want}', got exit ${RC}: ${OUTPUT}"
	fi
}

ISSUE_ARGS=("$ISSUE_SCRIPT" issue --repo-url "$REPO_URL" --title "Body を検査したい" --template "$ISSUE_TEMPLATE")
PR_ARGS=("$PR_SCRIPT" pr --repo-url "$REPO_URL" --base main --compare feat --title "feat: Body を検査する" --template "$PR_TEMPLATE")

ISSUE_BODY='## 背景

Body を検査せずに開いている。

## 完了条件

- 検査に通ったときだけ開く

## 補足情報

なし
'

PR_BODY='## 関連 Issue

Closes #1

## 概要

Body を検査してから開く。

## 実装方針

- 共通スクリプトにまとめる

## 動作確認

- テストが通る
'

# open
expect_open "issue: a body that follows the template opens" \
	"${REPO_URL}/issues/new?title=" "$ISSUE_BODY" "${ISSUE_ARGS[@]}"
run_form "$ISSUE_BODY" "${ISSUE_ARGS[@]}" --labels enhancement
if ((RC == 0)) && [[ "$OUTPUT" == *"&body=%23%23%20"* && "$OUTPUT" == *"&labels=enhancement" ]]; then
	pass
else
	fail "issue: the URL carries the encoded body and the labels" "got exit ${RC}: ${OUTPUT}"
fi
expect_open "pr: sections the template marks deletable may be left out" \
	"${REPO_URL}/compare/main...feat?quick_pull=1&title=" "$PR_BODY" "${PR_ARGS[@]}"
expect_open "pr: a # in a branch name is encoded and a / is kept" \
	"${REPO_URL}/compare/main...feat/fix%2312?quick_pull=1&title=" "$PR_BODY" "${PR_ARGS[@]}" --compare feat/fix#12
expect_open "issue: a heading passed with --allow-missing may be left out" \
	"${REPO_URL}/issues/new?title=" "${ISSUE_BODY%%## 補足情報*}" "${ISSUE_ARGS[@]}" --allow-missing 補足情報
# Built outside the ${//} below, where the bash 3.2 of macOS runs the
# backquotes of a $'...' replacement as a command substitution.
code_block=$'```html\n<!-- x -->\n```'
expect_open "issue: a template comment inside a code block is content" \
	"${REPO_URL}/issues/new?title=" "${ISSUE_BODY/なし/$code_block}" "${ISSUE_ARGS[@]}"
expect_open "issue: a body that opens with a horizontal rule keeps its headings" \
	"${REPO_URL}/issues/new?title=" "---"$'\n\n'"${ISSUE_BODY}" "${ISSUE_ARGS[@]}"
expect_open "issue: a section whose only content is a deeper heading after a tab is not empty" \
	"${REPO_URL}/issues/new?title=" "${ISSUE_BODY/なし/$'###\t詳細\n\nなし'}" "${ISSUE_ARGS[@]}"
english_body="${ISSUE_BODY}$(printf 'word %.0s' {1..600})"
expect_open "issue: ASCII text is not encoded, so 3000 English characters fit" \
	"${REPO_URL}/issues/new?title=" "$english_body" "${ISSUE_ARGS[@]}"

unformatted=$'## 背景\n\nなし\n## 完了条件\n\n- 開く\n\n## 補足情報\n\nなし'
run_form "$unformatted" "${ISSUE_ARGS[@]}"
if ((RC == 0)) && [[ "$(<"$body_file")" == "$unformatted" ]]; then
	pass
else
	fail "issue: the body file passed in is left as it was" "got exit ${RC}: $(<"$body_file")"
fi

# A PATH without the linters, so each check reports that it was skipped.
jq_dir=$(dirname "$(command -v jq)")
OUTPUT=$(printf '%s' "$ISSUE_BODY" >"$body_file" &&
	PATH="/usr/bin:/bin:${jq_dir}" bash "${ISSUE_ARGS[@]}" --body-file "$body_file" --dry-run 2>&1)
RC=$?
if ((RC == 0)) && [[ "$OUTPUT" == *"gitleaks is not installed"* ]]; then
	pass
else
	fail "issue: a missing linter is reported as skipped" "got exit ${RC}: ${OUTPUT}"
fi

# refuse
expect_refuse "issue: a template comment left in the body is refused" "<!--" \
	"${ISSUE_BODY/なし/<!-- 参考リンク -->}" "${ISSUE_ARGS[@]}"
expect_refuse "issue: a missing template heading is refused" "完了条件" \
	"${ISSUE_BODY/完了条件/完了}" "${ISSUE_ARGS[@]}"
expect_refuse "issue: an empty section is refused" "補足情報" \
	"${ISSUE_BODY%なし*}" "${ISSUE_ARGS[@]}"
long_body="${ISSUE_BODY}$(printf 'あ%.0s' {1..1000})"
expect_refuse "issue: a URL over 8000 bytes is refused" "8000" \
	"$long_body" "${ISSUE_ARGS[@]}"
# Assembled at run time so the commit hook does not flag this file itself.
token="ghp""_r7mqx2lk9vb4nc8zt1wy6hd3fj5ps0ga2k7q"
expect_refuse "issue: a secret in the body is refused" "gitleaks" \
	"${ISSUE_BODY/なし/${token}}" "${ISSUE_ARGS[@]}"
misspelling="te""h"
expect_refuse "issue: a misspelling is refused" "typos" \
	"${ISSUE_BODY/なし/see ${misspelling} docs}" "${ISSUE_ARGS[@]}"

printf '%d passed, %d failed\n' "$PASSED" "$FAILED"
((FAILED == 0))
