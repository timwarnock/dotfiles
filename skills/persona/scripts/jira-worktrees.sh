#!/bin/sh
# jira-worktrees.sh — active worktrees with their Jira status.
# Prints KEY, STATUS, SUMMARY (tab-separated) for each git worktree in flight
# under the mining repo's .worktrees/ — the worktree analog of
# jira-sprint-mine.sh, sharing its columns so the two read as one table.
#
# The ticket key is parsed as ME-#### from the worktree directory name; the
# branch is ignored. A worktree whose name yields no ME-#### gets a row with
# its basename in the KEY column and blank STATUS/SUMMARY — no deeper lookup.
# A parsed key Jira returns nothing for is shown the same way, key retained.
#
# No worktrees in flight: prints nothing, exits 0. git and jira errors
# propagate (not masked). Uses the jira CLI per references/tasks/jira.md.
# Usage: jira-worktrees.sh

repo=$HOME/github/NYDIG/mining
tab=$(printf '\t')

# Worktree paths under .worktrees/ (work in flight; main checkout excluded).
# --porcelain for stable parsing; git errors propagate.
raw=$(git -C "$repo" worktree list --porcelain) || exit
paths=$(printf '%s\n' "$raw" | sed -n 's/^worktree //p' | grep '/\.worktrees/')

# Collect the ME-#### keys, comma-joined for one batched JQL query.
list=
while IFS= read -r path; do
    [ -n "$path" ] || continue
    name=${path##*/}
    key=$(expr "$name" : '.*\(ME-[0-9][0-9]*\)') || key=
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
    key=$(expr "$name" : '.*\(ME-[0-9][0-9]*\)') || key=
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
