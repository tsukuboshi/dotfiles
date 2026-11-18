#!/bin/bash
# Run verify_page.sh against a stub Chrome that prints a fixed DOM and check
# the JSON it reports. The visualize-diff skill opens a page only after this
# script says every Mermaid figure was drawn, so a check that stops catching
# a figure left undrawn should fail here instead of in the user's browser.
# Usage: bash .github/scripts/test-verify-page.sh
set -u

root=$(git rev-parse --show-toplevel) || exit 1
SCRIPT="${root}/genai/skills/visualize-diff/scripts/verify_page.sh"
FAILED=0
PASSED=0

work=$(mktemp -d)
html="${work}/page.html"
shot="${work}/page-shot.png"
dom_file="${work}/dom.html"
log_file="${work}/chrome.log"
stub="${work}/chrome"
profile="${work}/tmp/visualize-diff-chrome-profile"
lock="${profile}.lock"
hash_html="${work}/fix#12 a.html"
mkdir "${work}/tmp"
trap 'rm -f "$html" "$shot" "$dom_file" "$log_file" "$stub" "$hash_html" "${hash_html%.html}-shot.png" "${lock}/pid"
	rmdir "$lock" "$profile" "${work}/tmp" "$work" 2>/dev/null' EXIT

# Prints STUB_DOM for --dump-dom and writes an empty PNG for --screenshot=,
# logging its arguments. It creates the profile directory as Chrome does.
# STUB_HANG keeps it running after its output, as headless Chrome sometimes
# does, and STUB_NO_SHOT skips the screenshot.
cat >"${stub}" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >>"$STUB_LOG"
for arg in "$@"; do
	case $arg in
	--user-data-dir=*) mkdir -p "${arg#--user-data-dir=}" ;;
	--dump-dom) cat "$STUB_DOM" ;;
	--screenshot=*) [[ -n "${STUB_NO_SHOT:-}" ]] || : >"${arg#--screenshot=}" ;;
	esac
done
if [[ -n "${STUB_HANG:-}" ]]; then
	sleep 31
fi
STUB
chmod +x "${stub}"
printf '<html></html>\n' >"${html}"

pass() {
	PASSED=$((PASSED + 1))
}

fail() {
	FAILED=$((FAILED + 1))
	printf 'FAIL: %s\n  %s\n' "$1" "$2"
}

# verify <dom> [script args...]
# Runs the script on the page with the stub printing dom, leaving its stdout
# in OUTPUT, its exit code in RC and the stub's arguments in the log file.
verify() {
	printf '%s' "$1" >"${dom_file}"
	shift
	: >"${log_file}"
	OUTPUT=$(TMPDIR="${work}/tmp" VISUALIZE_DIFF_CHROME="${stub}" STUB_DOM="${dom_file}" STUB_LOG="${log_file}" \
		bash "${SCRIPT}" "${html}" "$@" 2>&1)
	RC=$?
}

# expect <name> <jq filter> — checks that the script exited 0 and the filter
# holds on its JSON.
expect() {
	if ((RC == 0)) && jq -e "$2" <<<"${OUTPUT}" >/dev/null 2>&1; then
		pass
	else
		fail "$1" "want exit 0 and $2, got exit ${RC}: ${OUTPUT}"
	fi
}

DRAWN='<html><head><title>解説</title></head><body data-page-height="3000" data-mermaid-ready="1">
<pre class="mermaid"><svg id="fig-0"></svg></pre>
<pre class="mermaid"><svg id="fig-1"></svg></pre>
</body></html>'

verify "${DRAWN}"
expect "a page whose figures are all drawn is ok" \
	'.ok and .mermaidSources == 2 and .mermaidRendered == 2 and .mermaidReady and .warnings == []
	 and .title == "解説" and .pageHeight == 3000'
if [[ -f "${shot}" ]] && grep -q -- '--window-size=1250,3040 .*--screenshot=' "${log_file}"; then
	pass
else
	fail "the screenshot is taken next to the page at the page height plus 40" "$(<"${log_file}")"
fi

verify '<html><body data-page-height="3000" data-mermaid-ready="1">
<pre class="mermaid"><svg id="fig-0"></svg></pre>
<pre class="mermaid">
  flowchart LR
  A --> B
</pre>
</body></html>'
expect "a figure left as Mermaid source is reported" \
	'(.ok | not) and .mermaidSources == 2 and .mermaidRendered == 1
	 and (.warnings | any(test("描画されたのは 1 個")))'

verify '<html><body data-page-height="3000"><pre class="mermaid">flowchart LR</pre></body></html>'
expect "a page whose Mermaid never finished is reported" \
	'(.ok | not) and (.mermaidReady | not) and (.warnings | any(test("CDN")))'

verify '<html><body data-page-height="900"><p>図なし</p></body></html>'
expect "a page without figures needs no ready flag" \
	'.ok and .mermaidSources == 0 and .warnings == []'

verify '<html><body data-mermaid-ready="1"></body></html>'
expect "a page without its height is shot at a fallback height and reported" \
	'(.ok | not) and .pageHeight == 12000 and (.warnings | any(test("高さ")))'
if grep -q -- '--window-size=1250,12040 ' "${log_file}"; then
	pass
else
	fail "the fallback screenshot is 12000 plus 40 high" "$(<"${log_file}")"
fi

# expect_error <name> <want-message> <command...> — checks that the command
# exits 1 with a JSON error containing want-message.
expect_error() {
	local name=$1 want=$2
	shift 2
	OUTPUT=$("$@" 2>&1)
	RC=$?
	if ((RC == 1)) && jq -e --arg want "${want}" '(.ok | not) and (.error | contains($want))' <<<"${OUTPUT}" >/dev/null 2>&1; then
		pass
	else
		fail "${name}" "want exit 1 and an error with '${want}', got exit ${RC}: ${OUTPUT}"
	fi
}

expect_error "a missing page is refused" "ファイルが見つかりません" \
	env VISUALIZE_DIFF_CHROME="${stub}" bash "${SCRIPT}" "${work}/missing.html"
expect_error "a missing Chrome is refused" "Google Chrome が見つかりません" \
	env VISUALIZE_DIFF_CHROME="${work}/no-chrome" bash "${SCRIPT}" "${html}"
printf '%s' "${DRAWN}" >"${dom_file}"
: >"${shot}"
expect_error "a screenshot that was not taken is an error, even with an old one left" "スクリーンショット" \
	env VISUALIZE_DIFF_CHROME="${stub}" STUB_DOM="${dom_file}" STUB_LOG="${log_file}" STUB_NO_SHOT=1 bash "${SCRIPT}" "${html}"
OUTPUT=$(bash "${SCRIPT}" 2>&1)
RC=$?
if ((RC == 64)) && [[ "${OUTPUT}" == *"usage:"* ]]; then
	pass
else
	fail "no page prints the usage" "want exit 64 and the usage, got exit ${RC}: ${OUTPUT}"
fi

verify "${DRAWN}" --width 800 --wait 100
if ((RC == 0)) && grep -q -- '--window-size=800,1200 --virtual-time-budget=100 --dump-dom' "${log_file}" &&
	grep -q -- '--virtual-time-budget=100 --window-size=800,3040 ' "${log_file}"; then
	pass
else
	fail "--width and --wait reach both Chrome runs" "got exit ${RC}: $(<"${log_file}")"
fi

start=${SECONDS}
STUB_HANG=1 verify "${DRAWN}" --timeout 1
elapsed=$((SECONDS - start))
expect "a Chrome that keeps running after its output is stopped at --timeout" \
	'.ok and .mermaidRendered == 2'
if ((elapsed < 10)) && ! pgrep -fx 'sleep 31' >/dev/null; then
	pass
else
	fail "the stopped Chrome leaves no child behind" "took ${elapsed}s: $(pgrep -flx 'sleep 31' || true)"
fi

left=$(ls -A "${work}/tmp")
if [[ "${left}" == visualize-diff-chrome-profile ]]; then
	pass
else
	fail "the script leaves only the Chrome profile in TMPDIR" "${left}"
fi

# What the reviewer found the first version reported as ok.
verify '<html><body data-page-height="900" data-mermaid-ready="1">
<pre class="mermaid">---
title: x
---
flowchart LR</pre>
<div class="mermaid-box"><div class="mermaid">%%{init: {}}%%
flowchart LR</div></div>
</body></html>'
expect "a figure that starts with frontmatter or a directive, in any tag, is counted as undrawn" \
	'(.ok | not) and .mermaidSources == 2 and .mermaidRendered == 0'

verify '<html><head><title>解説</title></head><body data-page-height="900">
<pre class="code">data-mermaid-ready="1" data-page-height="5" class="mermaid"</pre>
<div class="mermaid"><svg id="fig-0"><title>図</title></svg></div>
</body></html>'
expect "only the body tag and the head title are read, not text on the page" \
	'(.ok | not) and (.mermaidReady | not) and .pageHeight == 900 and .title == "解説" and .mermaidSources == 1'

# Mermaid leaves the error SVG of a figure it could not parse at the end of
# the body, under the figure's id.
verify '<html><body data-page-height="900" data-mermaid-ready="1">
<pre class="mermaid"><svg id="fig-0"></svg></pre>
<pre class="mermaid">flowchart LR
A --> (((</pre>
<div id="dfig-1"><svg id="fig-1"></svg></div>
</body></html>'
expect "an error SVG outside its figure is not counted as drawn" \
	'(.ok | not) and .mermaidSources == 2 and .mermaidRendered == 1'

verify ''
if ((RC == 1)) && jq -e '.error | contains("DOM")' <<<"${OUTPUT}" >/dev/null 2>&1; then
	pass
else
	fail "an empty DOM is an error, not a page without figures" "got exit ${RC}: ${OUTPUT}"
fi

printf '<html></html>\n' >"${hash_html}"
printf '%s' "${DRAWN}" >"${dom_file}"
OUTPUT=$(TMPDIR="${work}/tmp" VISUALIZE_DIFF_CHROME="${stub}" STUB_DOM="${dom_file}" STUB_LOG="${log_file}" \
	bash "${SCRIPT}" "${hash_html}" 2>&1)
RC=$?
if ((RC == 0)) && grep -q 'fix%2312%20a\.html$' "${log_file}"; then
	pass
else
	fail "a # or a space in the file name is encoded in the URL" "got exit ${RC}: $(tail -1 "${log_file}" || true)"
fi

# A lock whose owner has exited is taken over; one held by a live process
# makes the run wait and give up instead of sharing the profile.
mkdir "${lock}"
sleep 60 &
holder=$!
printf '%s\n' "${holder}" >"${lock}/pid"
start=${SECONDS}
verify "${DRAWN}" --timeout 1
elapsed=$((SECONDS - start))
if ((RC == 1)) && jq -e '.error | contains("使用中")' <<<"${OUTPUT}" >/dev/null 2>&1 && ((elapsed < 15)); then
	pass
else
	fail "a profile in use by a live run is not shared" "took ${elapsed}s, got exit ${RC}: ${OUTPUT}"
fi
kill "${holder}"
wait "${holder}" 2>/dev/null
verify "${DRAWN}"
if ((RC == 0)) && [[ ! -e "${lock}" ]]; then
	pass
else
	fail "a lock left by an exited run is taken over and released" "got exit ${RC}: ${OUTPUT}"
fi

printf '%d passed, %d failed\n' "${PASSED}" "${FAILED}"
((FAILED == 0))
