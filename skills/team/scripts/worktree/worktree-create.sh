#!/bin/sh
# worktree-create.sh <name> [base-branch] — create a derived git worktree + branch for one
# task, seed it, and print its path. Sibling to worktree-cleanup.sh. The repo comes from
# $TEAM_REPO in ~/.claude/.env (loaded via internal/load-env.sh) — never hardcoded.
# Usage:  sh worktree-create.sh <name> [base-branch]
#   <name>        worktree + branch name under "$TEAM_REPO/.worktrees/<name>". For ticket
#                 work use <TICKET>-<aspect> (e.g. ME-4100-config); for a spike, a topic name.
#   [base-branch] branch to fork from; defaults to origin/main. Pass one only for the rare
#                 stacked case (branch off another in-flight branch).
# Run it from the grid home where the team was launched: it captures that home automatically
# and refuses to run anywhere else. The new worktree starts at the same commit as the base,
# on its own branch, ready for the task it is named in. STDOUT is the worktree path alone
# (everything else is stderr) so a caller can capture it. LLM-facing — named in
# references/tasks/worktree.md.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
internal="$dir/../internal"
# shellcheck source=/dev/null
. "$internal/load-env.sh"

name=${1:-}
[ -n "$name" ] || { printf 'worktree-create.sh: usage: worktree-create.sh <name> [base-branch]\n' >&2; exit 2; }
base=${2:-origin/main}

repo=${TEAM_REPO:-}
[ -n "$repo" ] || { printf 'worktree-create.sh: TEAM_REPO unset in %s\n' "$TEAM_ENV_FILE" >&2; exit 1; }
[ -d "$repo" ] || { printf 'worktree-create.sh: TEAM_REPO is not a directory: %s\n' "$repo" >&2; exit 1; }

# Capture the grid home from where this is run. state-dir.sh prints the home and exits
# non-zero with a directive when this is not a team workspace — that refusal IS the guard,
# so the home is recorded automatically and there is nothing to pass wrong.
home=$(sh "$internal/state-dir.sh") || exit 1

workdir="$repo/.worktrees/$name"
[ -e "$workdir" ] && { printf 'worktree-create.sh: already exists: %s\n' "$workdir" >&2; exit 1; }

# Bring the local repo up to date BEFORE branching: git-sync-latest.sh fetches (fail-closed),
# fast-forwards local main to origin/main, and rebases the current worktree's branch onto
# origin/main — so the new branch forks from current code, not a stale ref. sync already does
# the fetch this step used to do, so no separate fetch is needed here. Its progress and summary
# are sent to stderr (1>&2) so stdout stays the worktree path alone. If it exits non-zero
# (origin unreachable, or the current branch will not rebase cleanly) STOP — we do not build a
# new worktree on top of an unresolved state; the manager resolves it with the user first.
sh "$dir/git-sync-latest.sh" 1>&2 || exit 1

git -C "$repo" worktree add "$workdir" -b "$name" "$base" 1>&2 || exit 1

# The worktree gets its own thoughts/, recording the grid home it reports back to.
mkdir -p "$workdir/thoughts"
printf '%s\n' "$home" > "$workdir/thoughts/TEAM_HOME"

# Ticket-named worktree (<BOARD>-<digits>[-<aspect>]) -> seed the parent ticket's notes.
board=${TEAM_JIRA_BOARD:-}
ticket=""
if [ -n "$board" ]; then
    case "$name" in
    "$board"-[0-9]*)
        rest=${name#"$board"-}        # 4100-config
        num=${rest%%[!0-9]*}          # 4100
        [ -n "$num" ] && ticket="$board-$num"
        ;;
    esac
fi
if [ -n "$ticket" ]; then
    notes="$workdir/thoughts/notes-$ticket.md"
    if command -v jira >/dev/null 2>&1; then
        jira issue view "$ticket" --plain > "$notes" 2>/dev/null \
            || printf '# %s\n\nTicket context unavailable.\n' "$ticket" > "$notes"
    else
        printf '# %s\n\nTicket context unavailable (jira CLI not found).\n' "$ticket" > "$notes"
    fi
fi

printf '%s\n' "$workdir"
