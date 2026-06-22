#!/bin/sh
# PreToolUse hook (Bash|PowerShell): before a `git push` runs, pull first so
# Claude never pushes against a stale local branch.

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

if ! printf '%s' "$cmd" | grep -Eqi '(^|[;&|]|[[:space:]])git[[:space:]]+push([[:space:]]|$)'; then
    exit 0
fi

before=$(git rev-parse HEAD 2>/dev/null)
pull_output=$(git pull 2>&1)
pull_status=$?

if [ "$pull_status" -ne 0 ]; then
    jq -n --arg reason "git pull failed before push (likely conflicts). Resolve manually, then push again.

$pull_output" \
        '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
    exit 0
fi

after=$(git rev-parse HEAD 2>/dev/null)

if [ "$before" != "$after" ]; then
    jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: "git pull brought in new commits before the push. The local branch was updated - re-run git push now that it is up to date."}}'
fi

exit 0
