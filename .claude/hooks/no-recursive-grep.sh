#!/usr/bin/env bash
# PreToolUse(Bash) hook — nudge off recursive `grep -r` / `-R` and
# `find … -exec grep` toward the Grep tool (ripgrep-backed: faster, respects
# .gitignore, no permission prompt).
#
# Only plain recursive grep and find-exec-grep are blocked. `git grep`,
# non-recursive grep, and piped greps (e.g. `... | grep -n foo`) pass through.
# Personal hook, wired in ~/.claude/settings.json (PreToolUse, matcher "Bash").
# Disable via /hooks.

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"

[ -z "$cmd" ] && exit 0
case "$cmd" in *grep*) ;; *) exit 0 ;; esac   # fast path: no grep at all

# `git grep` is a deliberate, allowlisted tool — neutralize it before matching.
scrubbed="$(printf '%s' "$cmd" | sed -E 's/git[[:space:]]+grep/git_grep_/g')"

# grep token (with optional intervening short flags) followed by a flag containing
# r/R. Anchored to the grep token so a stray -r elsewhere in a pipe doesn't trip it.
pat='(^|[^[:alnum:]_])grep([[:space:]]+-[A-Za-z]+)*[[:space:]]+-[A-Za-z]*[rR][A-Za-z]*([[:space:]]|=|$)'

# `find … -exec grep`/`-execdir grep` — a compound that matches no allow-rule
# prefix, so it always prompts. The Grep tool does the same job natively.
pat_find='-exec(dir)?[[:space:]]+grep([[:space:]]|$)'

if printf '%s' "$scrubbed" | grep -Eq "$pat" || printf '%s' "$scrubbed" | grep -Eq "$pat_find"; then
  jq -n --arg r "Use the Grep tool for recursive search instead of 'grep -r'/'grep -R' or 'find … -exec grep' — it's ripgrep-backed (faster, respects .gitignore) and never prompts. For files containing a string, use Grep with output_mode 'files_with_matches'. A non-recursive 'grep' over specific files or a pipe is fine." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
fi

exit 0
