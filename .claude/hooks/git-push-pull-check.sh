#!/bin/sh
# PreToolUse hook (Bash|PowerShell): before a `git push` runs, pull first so
# Claude's push always goes out against an up-to-date branch. Only blocks if
# the pull itself fails (e.g. merge conflicts); a clean pull/merge is allowed
# through so the push includes the newly merged commits.

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
    echo "git-push-pull-check: pulled new commits from origin before pushing." >&2
fi

exit 0
