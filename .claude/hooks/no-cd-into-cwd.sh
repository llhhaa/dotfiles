#!/usr/bin/env bash
# PreToolUse(Bash) hook — block a `cd` into the directory the agent is already
# working in. The Bash tool persists its working directory between calls, so
# `cd <current-dir>` is a no-op (typically a needless `cd <repo-root>; ...` prefix).
#
# Only the redundant case is blocked: `cd` into a *different* directory, and any
# command without a `cd`, pass through untouched.
#
# Personal hook, wired in ~/.claude/settings.json (PreToolUse, matcher "Bash").
# Disable via the /hooks menu.

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"

[ -z "$cmd" ] && exit 0
case "$cmd" in *cd*) ;; *) exit 0 ;; esac   # fast path: no `cd` substring at all

# Agent's working directory: prefer the hook payload, fall back to the hook's own.
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"
cwd="${cwd:-$PWD}"
cwd_real="$(cd "$cwd" 2>/dev/null && pwd -P)"
[ -z "$cwd_real" ] && exit 0   # can't resolve cwd -> don't interfere

# Each `cd` segment: (start|separator) ws* cd ws+ <target>  (double/single-quoted or bare).
sq=\'
pat="(^|[;&|(])[[:space:]]*cd[[:space:]]+(\"[^\"]*\"|${sq}[^${sq}]*${sq}|[^[:space:];&|()]+)"
segs="$(printf '%s\n' "$cmd" | grep -oE "$pat")"
[ -z "$segs" ] && exit 0   # `cd` substring existed but not as a command

while IFS= read -r seg; do
  [ -z "$seg" ] && continue
  tgt="$(printf '%s' "$seg" | sed -E 's/^[;&|(]?[[:space:]]*cd[[:space:]]+//')"
  tgt="${tgt%\"}"; tgt="${tgt#\"}"   # strip one layer of surrounding quotes
  tgt="${tgt%\'}"; tgt="${tgt#\'}"

  hit=""
  case "$tgt" in
    '$PWD' | '${PWD}' | '$(pwd)' | '`pwd`') hit=1 ;;   # explicit "current dir" spellings
  esac
  if [ -z "$hit" ]; then
    # Resolve the target relative to cwd; redundant iff it lands back on cwd.
    resolved="$(cd "$cwd_real" 2>/dev/null && cd "$tgt" 2>/dev/null && pwd -P)"
    [ -n "$resolved" ] && [ "$resolved" = "$cwd_real" ] && hit=1
  fi

  if [ -n "$hit" ]; then
    jq -n --arg r "You're already working in $cwd_real — the Bash tool persists its working directory between calls, so 'cd $tgt' is a no-op. Drop it and run the command directly." \
      '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
    exit 0
  fi
done <<EOF
$segs
EOF

exit 0
