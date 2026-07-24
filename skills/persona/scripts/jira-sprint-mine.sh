#!/bin/sh
# jira-sprint-mine.sh — the user's issues in the current active sprint.
# Prints KEY, STATUS, SUMMARY (tab-separated) for issues assigned to the
# authenticated Jira user in the active sprint. No active sprint: prints
# "No active sprint." and exits 0. jira CLI errors propagate (not masked
# as "no active sprint"). Uses the jira CLI per references/tasks/jira.md.
# Usage: jira-sprint-mine.sh

# Active sprint id (first line, should a board report more than one).
sprint=$(jira sprint list --state active --plain --no-headers --columns ID) || exit
sprint=$(printf '%s\n' "$sprint" | head -n 1)

if [ -z "$sprint" ]; then
    printf 'No active sprint.\n'
    exit 0
fi

# No ORDER BY in the JQL — v1.7.0 rejects it (see jira.md).
exec jira issue list \
    -q "sprint = $sprint AND assignee = currentUser()" \
    --plain --no-headers --columns KEY,STATUS,SUMMARY
