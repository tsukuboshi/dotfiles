#!/bin/bash
# Claude Code Enhanced Status Line
# Model | Context | In/Out | Remaining | ETA | Compression | Burn Rate

CLAUDE_DIR="$HOME/.claude"
SESSION_FILE="$CLAUDE_DIR/.sl_session.json"
LAST_STATE_FILE="$CLAUDE_DIR/.sl_last_state.json"
COMPRESS_FILE="$CLAUDE_DIR/.sl_compress.json"

IFS= read -r -d '' input

# Extract JSON value by key (result in _v)
_jval() {
  local json="$1" key="$2"
  local rest="${json#*\"$key\"}"
  if [ "$rest" = "$json" ]; then
    _v="${3:-}"
    return
  fi
  rest="${rest#*:}"
  rest="${rest# }"; rest="${rest# }"; rest="${rest# }"
  if [ "${rest:0:1}" = '"' ]; then
    rest="${rest#\"}"
    _v="${rest%%\"*}"
  else
    _v="${rest%%[, \}]*}"
  fi
}

# Format number with k/M suffix (result in _f)
fmt() {
  local n=${1:-0}
  if [ "$n" -ge 1000000 ] 2>/dev/null; then
    local d=$((n / 1000000)) r=$(( (n % 1000000) / 100000 ))
    _f="${d}.${r}M"
  elif [ "$n" -ge 1000 ] 2>/dev/null; then
    local d=$((n / 1000)) r=$(( (n % 1000) / 100 ))
    _f="${d}.${r}k"
  else
    _f="$n"
  fi
}

# Extract data
_flat="${input//$'\n'/ }"
_flat="${_flat//$'\r'/ }"
_flat="${_flat//$'\t'/ }"

_jval "$_flat" "display_name" "Unknown"; model="$_v"
_jval "$_flat" "total_input_tokens" "0"; total_input="$_v"
_jval "$_flat" "total_output_tokens" "0"; total_output="$_v"
_jval "$_flat" "context_window_size" "200000"; context_size="$_v"
_jval "$_flat" "used_percentage" "0"; used_pct="$_v"
_jval "$_flat" "session_id" "unknown"; session_id="$_v"

pct_int=${used_pct%%.*}
pct_int=${pct_int:-0}
current_used=$(( pct_int * context_size / 100 ))
remaining_tokens=$((context_size - current_used))
[ "$remaining_tokens" -lt 0 ] && remaining_tokens=0
current_time=$(date +%s)

# Session & burn rate tracking
burn_rate_str="--"
eta_str="--"
br_val=0
compress_count=0

if [ -f "$LAST_STATE_FILE" ]; then
  read -r _last_state < "$LAST_STATE_FILE" 2>/dev/null
  _jval "$_last_state" "sid" ""; last_sid="$_v"
  _jval "$_last_state" "tok" "0"; last_tok="$_v"

  if [ "$session_id" != "$last_sid" ]; then
    printf '{"ts":%d,"tok":0}\n' "$current_time" > "$SESSION_FILE"
    printf '{"sid":"%s","count":0,"last_used":%d}\n' "$session_id" "$current_used" > "$COMPRESS_FILE"
  elif [ "$current_used" -lt "${last_tok:-0}" ] 2>/dev/null; then
    drop=$((last_tok - current_used))
    threshold=$((last_tok / 5))
    if [ -f "$COMPRESS_FILE" ]; then
      read -r _comp_state < "$COMPRESS_FILE" 2>/dev/null
      _jval "$_comp_state" "sid" ""; c_sid="$_v"
      _jval "$_comp_state" "count" "0"; c_count="$_v"
      [ "$session_id" = "$c_sid" ] && compress_count=$c_count
    fi
    if [ "$drop" -gt "$threshold" ] && [ "$drop" -gt 10000 ]; then
      compress_count=$((compress_count + 1))
    fi
    printf '{"sid":"%s","count":%d,"last_used":%d}\n' "$session_id" "$compress_count" "$current_used" > "$COMPRESS_FILE"
  fi
else
  printf '{"ts":%d,"tok":0}\n' "$current_time" > "$SESSION_FILE"
  printf '{"sid":"%s","count":0,"last_used":%d}\n' "$session_id" "$current_used" > "$COMPRESS_FILE"
fi

# Read current compress count if not yet loaded
if [ "$compress_count" -eq 0 ] && [ -f "$COMPRESS_FILE" ]; then
  read -r _comp_state < "$COMPRESS_FILE" 2>/dev/null
  _jval "$_comp_state" "sid" ""; c_sid="$_v"
  _jval "$_comp_state" "count" "0"; c_count="$_v"
  [ "$session_id" = "$c_sid" ] && compress_count=$c_count
fi

# Update last state
printf '{"sid":"%s","tok":%d,"ts":%d}\n' "$session_id" "$current_used" "$current_time" > "$LAST_STATE_FILE"

# Calculate burn rate & ETA
if [ -f "$SESSION_FILE" ]; then
  read -r _sess_state < "$SESSION_FILE" 2>/dev/null
  _jval "$_sess_state" "ts" "$current_time"; s_start="$_v"
  elapsed=$((current_time - s_start))
  if [ "$elapsed" -gt 10 ] && [ "$current_used" -gt 0 ]; then
    br_val=$(( (current_used * 60) / elapsed ))
    fmt "$br_val"; burn_rate_str="${_f}/min"

    if [ "$br_val" -gt 0 ] 2>/dev/null; then
      eta_sec=$(( (remaining_tokens * 60) / br_val ))
      if [ "$eta_sec" -ge 3600 ] 2>/dev/null; then
        eta_h=$((eta_sec / 3600))
        eta_r=$(( ((eta_sec % 3600) * 10 + 1800) / 3600 ))
        if [ "$eta_r" -ge 10 ]; then
          eta_h=$((eta_h + 1))
          eta_r=0
        fi
        eta_str="${eta_h}.${eta_r}h"
      elif [ "$eta_sec" -ge 60 ] 2>/dev/null; then
        eta_str="$((eta_sec / 60))min"
      else
        eta_str="${eta_sec}s"
      fi
    fi
  fi
fi

# Build progress bar
filled=$((pct_int / 10))
[ "$filled" -gt 10 ] && filled=10
empty=$((10 - filled))
bar=""
for ((i=0; i<filled; i++)); do bar+="█"; done
for ((i=0; i<empty; i++)); do bar+="░"; done

# Performance zone indicator
if [ "$pct_int" -ge 90 ]; then
  perf="🔴Critical"
elif [ "$pct_int" -ge 70 ]; then
  perf="🟠Warning"
elif [ "$pct_int" -ge 50 ]; then
  perf="🟡Caution"
else
  perf="🟢Good"
fi

# Pre-format values
fmt "$current_used"; f_used="$_f"
fmt "$context_size"; f_ctx="$_f"
fmt "$total_input"; f_in="$_f"
fmt "$total_output"; f_out="$_f"
fmt "$remaining_tokens"; f_rem="$_f"

# Output
printf "🤖%s │ 📊%s/%s %s %d%% %s │ 📖%s ✏️%s │ 💡残%s │ ⏳~%s │ 🔄%d回 │ 🔥%s" \
  "$model" \
  "$f_used" \
  "$f_ctx" \
  "$bar" \
  "$pct_int" \
  "$perf" \
  "$f_in" \
  "$f_out" \
  "$f_rem" \
  "$eta_str" \
  "$compress_count" \
  "$burn_rate_str"
