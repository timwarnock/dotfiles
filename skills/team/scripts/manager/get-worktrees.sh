#!/bin/sh
# get-worktrees.sh — active worktrees with their Jira status.
# Prints KEY, STATUS, SUMMARY (tab-separated) for each git worktree in flight
# under the repo's .worktrees/ — the worktree analog of jira-sprint-tickets.sh,
# sharing its columns so the two read as one table. The repo is TEAM_REPO
# (from .env), or the current directory when TEAM_REPO is unset.
#
# The ticket key is parsed from the worktree directory name using the
# TEAM_JIRA_BOARD prefix (e.g. ME matches ME-1234); the branch is ignored. When
# TEAM_JIRA_BOARD is unset no prefix is known, so every worktree is reported
# keyless. A worktree whose name yields no key gets a row with its basename in
# the KEY column and blank STATUS/SUMMARY — no deeper lookup. A parsed key Jira
# returns nothing for is shown the same way, key retained.
#
# No worktrees in flight: prints nothing, exits 0. git and jira errors
# propagate (not masked). Uses the jira CLI per references/tasks/jira.md.
# Usage: get-worktrees.sh

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$dir/../internal/load-env.sh"

repo=${TEAM_REPO:-$PWD}
tab=$(printf '\t')

# Ticket-key prefix from TEAM_JIRA_BOARD (e.g. ME matches ME-1234). A literal
# prefix keeps expr's greedy .* from eating into a multi-letter project key.
# Unset: no prefix is known, so keys are not parsed (every worktree is keyless).
prefix=${TEAM_JIRA_BOARD:-}

# Worktree paths under .worktrees/ (work in flight; main checkout excluded).
# --porcelain for stable parsing; git errors propagate.
raw=$(git -C "$repo" worktree list --porcelain) || exit
paths=$(printf '%s\n' "$raw" | sed -n 's/^worktree //p' | grep '/\.worktrees/')

# Collect the ticket keys, comma-joined for one batched JQL query.
list=
while IFS= read -r path; do
    [ -n "$path" ] || continue
    name=${path##*/}
    key=; [ -n "$prefix" ] && key=$(expr "$name" : ".*\($prefix-[0-9][0-9]*\)")
    [ -n "$key" ] && list=${list:+$list,}$key
done <<EOF
$paths
EOF

# One batched lookup (skipped when no keys — empty "key in ()" is invalid JQL).
rows=
if [ -n "$list" ]; then
    rows=$(jira issue list -q "key in ($list)" \
        --plain --no-headers --columns KEY,STATUS,SUMMARY) || exit
fi

# One row per worktree, in worktree order.
while IFS= read -r path; do
    [ -n "$path" ] || continue
    name=${path##*/}
    key=; [ -n "$prefix" ] && key=$(expr "$name" : ".*\($prefix-[0-9][0-9]*\)")
    if [ -z "$key" ]; then
        printf '%s\t\t\n' "$name"
    else
        row=$(printf '%s\n' "$rows" | grep "^$key$tab")
        if [ -n "$row" ]; then
            printf '%s\n' "$row"
        else
            printf '%s\t\t\n' "$key"
        fi
    fi
done <<EOF
$paths
EOF
