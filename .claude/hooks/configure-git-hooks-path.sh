#!/bin/sh
# SessionStart hook: point git at the repo's tracked .githooks directory so
# the pre-push pull-check hook is active, without requiring a manual step.

current=$(git config --get core.hooksPath 2>/dev/null)

if [ -d .githooks ] && [ "$current" != ".githooks" ]; then
    git config core.hooksPath .githooks
    echo '{"systemMessage": "Configured git core.hooksPath=.githooks (enables the pull-before-push safety hook for this repo)."}'
fi
