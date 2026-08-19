#!/bin/sh
# git-sync-latest.sh — bring the local repo up to date after merges. Sibling to
# worktree-create.sh / worktree-cleanup.sh. It takes NO arguments: the repo comes from
# $TEAM_REPO in ~/.claude/.env (loaded via internal/load-env.sh) and the grid home from
# internal/state-dir.sh — nothing is hardcoded, nothing is passed.
#
# What it does, in order:
#   1. fetch origin (fail-closed — nothing below is correct without a current origin/main)
#   2. remote prune origin (drop remote-tracking refs for branches deleted on the remote)
#   3. fast-forward the main checkout's local `main` to origin/main
#   4. rebase the current worktree's branch onto origin/main (only when standing in a
#      worktree, not the main checkout)
#
# Manager-owned git housekeeping: worktree-create.sh runs it before branching so work starts
# on top of a current main, worktree-cleanup.sh runs it after a merged branch is deleted so
# the merged code lands locally, and the manager can run it on demand after a PR merges.
# STDOUT is a one-line summary of what advanced; git progress and every warning go to stderr,
# so a caller can capture the summary alone. LLM-facing — named in references/tasks/worktree.md.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
internal="$dir/../internal"
# shellcheck source=/dev/null
. "$internal/load-env.sh"

repo=${TEAM_REPO:-}
[ -n "$repo" ] || { printf 'git-sync-latest.sh: TEAM_REPO unset in %s\n' "$TEAM_ENV_FILE" >&2; exit 1; }
[ -d "$repo" ] || { printf 'git-sync-latest.sh: TEAM_REPO is not a directory: %s\n' "$repo" >&2; exit 1; }

# 1. Fetch — FAIL-CLOSED. Without a successful fetch we cannot know what origin/main is, so
#    every step below would act on stale data. git's progress goes to stderr (1>&2).
git -C "$repo" fetch origin 1>&2 || {
    printf 'git-sync-latest.sh: git fetch failed — cannot confirm a current origin/main; retry when origin is reachable.\n' >&2
    exit 1
}

# 2. Prune remote-tracking refs left over from branches deleted on the remote (a merged PR's
#    branch is typically deleted there). NON-fatal: a stale ref lingering is harmless.
git -C "$repo" remote prune origin 1>&2 \
    || printf 'git-sync-latest.sh: git remote prune origin failed — continuing (stale remote-tracking refs may linger).\n' >&2

# 3. Advance the main checkout's local `main` to origin/main. Which git command depends on
#    whether `main` is the branch currently checked out in the repo: a checked-out branch is
#    advanced with a fast-forward merge, a non-checked-out ref with a ref-only fetch.
#    NON-fatal: if local main has diverged it will neither fast-forward nor update the ref, so
#    we warn and leave main for the user to resolve — we never force anything.
head_branch=$(git -C "$repo" symbolic-ref --short HEAD 2>/dev/null || true)
main_advanced=no
if [ "$head_branch" = main ]; then
    if git -C "$repo" merge --ff-only origin/main 1>&2; then
        main_advanced=yes
    else
        printf 'git-sync-latest.sh: local main will not fast-forward to origin/main (it has diverged) — resolve main by hand.\n' >&2
    fi
else
    if git -C "$repo" fetch origin main:main 1>&2; then
        main_advanced=yes
    else
        printf 'git-sync-latest.sh: local main will not fast-forward to origin/main (it has diverged) — resolve main by hand.\n' >&2
    fi
fi

# 4. Rebase the CURRENT worktree's branch onto origin/main — but only when we are standing in
#    a worktree rather than the main checkout. The grid home is resolved through the same
#    chokepoint delegate-task.sh uses. BEST-EFFORT: if state-dir.sh cannot resolve the home
#    (e.g. run outside a team workspace) we skip this step entirely — main was still refreshed
#    above. state-dir.sh's own directive is silenced here because skipping is expected, not an
#    error.
rebased_branch=""
if state=$(sh "$internal/state-dir.sh" 2>/dev/null); then
    home=${state%/thoughts/.team}
    # Compare git toplevels: only rebase when the home is a git work tree AND it is a
    # different checkout than the main repo (i.e. a real worktree). When the home IS the main
    # checkout (explore mode) the toplevels match and there is nothing extra to rebase.
    repo_top=$(git -C "$repo" rev-parse --show-toplevel)
    home_top=$(git -C "$home" rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$home_top" ] && [ "$home_top" != "$repo_top" ]; then
        rebased_branch=$(git -C "$home" symbolic-ref --short HEAD 2>/dev/null || true)
        # FAIL-CLOSED, exactly like delegate-task.sh's fresh-base rebase: a branch that will
        # not replay cleanly onto origin/main is a real conflict, not something to force past.
        git -C "$home" rebase origin/main 1>&2 || {
            git -C "$home" rebase --abort 1>&2
            printf 'git-sync-latest.sh: the current worktree branch will not rebase cleanly onto origin/main — resolve with the user before continuing.\n' >&2
            exit 1
        }
    fi
fi

# 5. One-line stdout summary so a human running this on demand sees the result at a glance.
if [ "$main_advanced" = yes ]; then
    summary='git-sync-latest: local main is up to date with origin/main'
else
    summary='git-sync-latest: local main left unchanged (resolve by hand — see warning above)'
fi
if [ -n "$rebased_branch" ]; then
    summary="$summary; rebased worktree branch $rebased_branch onto origin/main"
fi
printf '%s\n' "$summary"
