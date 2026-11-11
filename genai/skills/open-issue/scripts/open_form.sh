#!/bin/bash
# Check an issue or PR body, then open the GitHub page that creates it with
# the title and body filled in. The page opens only when every check passes,
# so a body with a secret, a leftover template comment, a missing section or
# a URL too long for GitHub never reaches the browser.
# Usage:
#   open_form.sh issue --repo-url URL --title TITLE --body-file PATH
#     [--template PATH] [--labels a,b] [--allow-missing HEADING]... [--dry-run]
#   open_form.sh pr --repo-url URL --base BRANCH --compare BRANCH --title TITLE
#     --body-file PATH [same options as issue]
# Exits 2 with the findings on stderr when a check fails. --dry-run prints
# the URL instead of opening it. The body file itself is not rewritten.
set -u

# GitHub answers "Whoa there! Your request URL is too long." above about 8KB.
MAX_URL_BYTES=8000
# The same rules as the Markdown rule file, without the project's config,
# since the body is not a file in the project.
RUMDL_ARGS=(--no-config --disable "MD034,MD013,MD025,MD041")

usage() {
	sed -n '6,12s/^# \{0,1\}//p' "$0" >&2
	exit 1
}

kind=${1:-}
[[ "$kind" == issue || "$kind" == pr ]] || usage
shift

repo_url="" title="" body_file="" template="" labels="" base="" compare=""
dry_run=false
allow_missing=()
while (($# > 0)); do
	case "$1" in
	--repo-url | --title | --body-file | --template | --labels | --base | --compare | --allow-missing)
		(($# >= 2)) || usage
		case "$1" in
		--repo-url) repo_url=$2 ;;
		--title) title=$2 ;;
		--body-file) body_file=$2 ;;
		--template) template=$2 ;;
		--labels) labels=$2 ;;
		--base) base=$2 ;;
		--compare) compare=$2 ;;
		--allow-missing) allow_missing+=("$2") ;;
		esac
		shift 2
		;;
	--dry-run)
		dry_run=true
		shift
		;;
	*) usage ;;
	esac
done
[[ -n "$repo_url" && -n "$title" && -f "$body_file" ]] || usage
[[ "$kind" == issue || (-n "$base" && -n "$compare") ]] || usage
[[ -z "$template" || -f "$template" ]] || usage
command -v jq >/dev/null 2>&1 || {
	echo "open_form: jq is required to encode the URL" >&2
	exit 1
}

findings=()
warnings=()

# Prints one line per section of a Markdown file: the heading, whether the
# section has content (1/0), and whether it says it may be deleted (1/0).
# Fenced code is skipped, and so is frontmatter when frontmatter=1, which
# only templates have: in a body, a leading --- is a horizontal rule. A
# section whose only content is deeper headings counts as having content.
sections() {
	awk -v OFS='\t' -v frontmatter="${2:-0}" '
		function flush() { if (h != "") print h, c, d }
		frontmatter && NR == 1 && /^---[ \t]*$/ { fm = 1; next }
		fm { if (/^---[ \t]*$/) fm = 0; next }
		/^[ \t]*(```|~~~)/ { fence = !fence; c = 1; next }
		!fence && /^#+[ \t]/ {
			match($0, /^#+/)
			level = RLENGTH
			if (h != "" && level > lv) c = 1
			flush()
			h = $0; sub(/^#+[ \t]+/, "", h); sub(/[ \t]+$/, "", h)
			lv = level; c = 0; d = 0
			next
		}
		/[^ \t]/ { c = 1 }
		/削除可/ { d = 1 }
		END { flush() }
	' "$1"
}

is_allowed_missing() {
	local heading
	for heading in "${allow_missing[@]+"${allow_missing[@]}"}"; do
		[[ "$1" == "$heading" ]] && return 0
	done
	return 1
}

# Leaves the unreserved characters as they are, so ASCII text does not take
# three times its length out of the URL limit.
urlencode() { jq -rn --arg s "$1" '$s | @uri'; }
# A branch name keeps its slashes, which GitHub reads as part of the name.
urlencode_branch() { urlencode "$1" | sed 's#%2F#/#g'; }

opener() {
	case "$(uname -s)" in
	Darwin) open "$1" ;;
	Linux)
		if grep -qi microsoft /proc/version 2>/dev/null; then
			explorer.exe "$1"
		elif command -v xdg-open >/dev/null 2>&1; then
			xdg-open "$1"
		else
			printf 'Open this URL: %s\n' "$1"
		fi
		;;
	*) printf 'Open this URL: %s\n' "$1" ;;
	esac
}

# check_tool <tool> <what it checks> <exit code on findings> <exit code>
# <output>: records the findings, or the tool failing, as a reason not to
# open the page. A tool that fails to run blocks the page too, since a check
# that did not run cannot vouch for the body.
check_tool() {
	local tool=$1 what=$2 found=$3 rc=$4 output=$5
	if ((rc == found)); then
		findings+=("${tool} found ${what}:"$'\n'"${output}")
	elif ((rc != 0)); then
		findings+=("${tool} failed to run (exit ${rc}):"$'\n'"${output}")
	fi
}

# The checks read a formatted copy, so the caller's file stays as written.
work_file=$(mktemp)
trap 'rm -f "$work_file"' EXIT
cp "$body_file" "$work_file"

# Fix what rumdl can fix by itself, such as a missing final newline, before
# anything reads the body.
if command -v rumdl >/dev/null 2>&1; then
	rumdl fmt "${RUMDL_ARGS[@]}" -- "$work_file" >/dev/null 2>&1
fi
body=$(<"$work_file")

# gitleaks exits 1 on its own errors too, so leaks get an exit code of their
# own. --redact keeps the secret itself out of the transcript.
if command -v gitleaks >/dev/null 2>&1; then
	output=$(printf '%s\n\n%s\n' "$title" "$body" |
		gitleaks stdin --no-banner --no-color --redact --log-level warn -v --exit-code 3 2>&1)
	check_tool gitleaks "secrets in the title or body" 3 $? "$output"
else
	warnings+=("gitleaks is not installed; the title and body were not scanned for secrets")
fi

# rumdl exits 1 on violations and 2 on its own errors.
if command -v rumdl >/dev/null 2>&1; then
	output=$(rumdl check "${RUMDL_ARGS[@]}" --stdin --stdin-filename body.md <"$work_file" 2>&1)
	check_tool rumdl "Markdown issues in the body" 1 $? "$output"
else
	warnings+=("rumdl is not installed; the body was not checked for Markdown issues")
fi

# typos exits 2 on findings, as in the pre-commit hook.
if command -v typos >/dev/null 2>&1; then
	output=$(printf '%s\n\n%s\n' "$title" "$body" | typos --format brief --color never - 2>&1)
	check_tool typos "misspellings in the title or body" 2 $? "$output"
else
	warnings+=("typos is not installed; the title and body were not checked for misspellings")
fi

# A comment inside fenced code is content, such as an example of a template.
output=$(awk '
	/^[ \t]*(```|~~~)/ { fence = !fence; next }
	!fence && /<!--/ { print }
' "$work_file")
[[ -n "$output" ]] && findings+=("the body still has template comments; replace them with content or delete them:"$'\n'"${output}")

body_sections=$(sections "$work_file")
while IFS=$'\t' read -r heading has_content _; do
	[[ -n "$heading" && "$has_content" == 0 ]] &&
		findings+=("section '${heading}' is empty; fill it or delete the heading")
done <<<"$body_sections"

if [[ -n "$template" ]]; then
	while IFS=$'\t' read -r heading _ deletable; do
		[[ -z "$heading" || "$deletable" == 1 ]] && continue
		is_allowed_missing "$heading" && continue
		cut -f1 <<<"$body_sections" | grep -qxF -- "$heading" ||
			findings+=("section '${heading}' of the template is missing from the body")
	done < <(sections "$template" 1)
fi

if [[ "$kind" == issue ]]; then
	url="${repo_url}/issues/new?"
else
	url="${repo_url}/compare/$(urlencode_branch "$base")...$(urlencode_branch "$compare")?quick_pull=1&"
fi
url+="title=$(urlencode "$title")&body=$(urlencode "$body")"
gh_user=$(git config github.user 2>/dev/null)
[[ -n "$gh_user" ]] && url+="&assignees=$(urlencode "$gh_user")"
[[ -n "$labels" ]] && url+="&labels=$(urlencode "$labels")"
# The URL is all ASCII once encoded, so its length in characters is its
# length in bytes.
((${#url} > MAX_URL_BYTES)) &&
	findings+=("the URL is ${#url} bytes, over the ${MAX_URL_BYTES} GitHub accepts; shorten the body")

((${#warnings[@]} > 0)) && printf 'open_form: warning: %s\n' "${warnings[@]}" >&2

if ((${#findings[@]} > 0)); then
	printf 'open_form: did not open the page; fix the body file and run the same command again\n' >&2
	printf -- '- %s\n' "${findings[@]}" >&2
	exit 2
fi

if $dry_run; then
	printf '%s\n' "$url"
else
	opener "$url"
fi
