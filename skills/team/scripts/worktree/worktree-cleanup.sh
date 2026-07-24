#!/bin/sh
# worktree-cleanup.sh — tear down a git worktree (made by the tmux-mining-team launcher,
# the user's bug-fix command, or a manual git worktree add).
# Generic and POSIX (/bin/sh): the repo path comes from $TEAM_REPO in ~/.claude/.env
# (loaded via internal/load-env.sh) — never hardcoded.
# Usage:  sh worktree-cleanup.sh <name> [branch]
#   <name>    the worktree under "$TEAM_REPO/.worktrees/<name>".
#   [branch]  branch to delete; defaults to <name>. Pass it when the worktree outlived
#             its original branch and now holds a follow-up branch.
# Order is load-bearing: virtualenvs (while the dir still exists) -> worktree -> branch.
# Run from OUTSIDE the target worktree (e.g. the main checkout). LLM-facing — named in
# references/tasks/worktree.md.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=/dev/null
. "$dir/../internal/load-env.sh"

name=${1:-}
[ -n "$name" ] || { printf 'worktree-cleanup.sh: usage: worktree-cleanup.sh <name> [branch]\n' >&2; exit 2; }
branch=${2:-$name}

repo=${TEAM_REPO:-}
[ -n "$repo" ] || { printf 'worktree-cleanup.sh: TEAM_REPO unset in %s\n' "$TEAM_ENV_FILE" >&2; exit 1; }
[ -d "$repo" ] || { printf 'worktree-cleanup.sh: TEAM_REPO is not a directory: %s\n' "$repo" >&2; exit 1; }

workdir="$repo/.worktrees/$name"

# 1. Remove language virtualenvs FIRST — while the worktree dir still exists, because a
#    venv's identity is derived from its directory path. Each ecosystem is an independent,
#    runtime-detected block; add a new ecosystem as a sibling block below, not by a rewrite.
if [ -d "$workdir" ]; then
    # poetry: a pyproject.toml (worktree root or one level down) declaring [tool.poetry].
    for pp in "$workdir"/pyproject.toml "$workdir"/*/pyproject.toml; do
        { [ -f "$pp" ] && grep -q '^\[tool\.poetry' "$pp"; } || continue
        pdir=$(dirname -- "$pp")
        if command -v poetry >/dev/null 2>&1; then
            printf 'worktree-cleanup.sh: poetry project at %s — removing virtualenvs\n' "$pdir" >&2
            ( cd -- "$pdir" && poetry env remove --all ) \
                || printf 'worktree-cleanup.sh: poetry env remove failed in %s (continuing)\n' "$pdir" >&2
        else
            printf 'worktree-cleanup.sh: poetry marker at %s but poetry not installed — skipping venv removal\n' "$pp" >&2
        fi
    done
fi

# 2. Remove the worktree (force: cleanup assumes possibly-uncommitted work).
git -C "$repo" worktree remove --force "$workdir" || exit 1

# 3. Delete the branch (safe -d: refuses if unmerged, which is the intended guard).
git -C "$repo" branch -d "$branch"
