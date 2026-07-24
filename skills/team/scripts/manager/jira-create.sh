#!/bin/sh
# jira-create.sh — create a Jira issue, assign it to the authenticated user,
# and add it to the active sprint when there is one. Prints "KEY<tab>URL"
# (or just KEY when the browse URL cannot be derived).
#
# The issue type defaults to Task. Project, board and site are resolved by the
# jira CLI from its own config; the assignee is the authenticated user (jira me).
# No active sprint: the issue is still created, a note goes to stderr, and the
# sprint-add is skipped. jira and jq errors propagate (not masked). Uses the
# jira CLI per references/tasks/jira.md.
# Usage: jira-create.sh <summary> [body] [type]
set -u

summary=${1:?usage: jira-create.sh <summary> [body] [type]}
body=${2:-}
type=${3:-Task}

me=$(jira me) || exit

# Create the issue. --raw returns the Jira create response as JSON; the new
# issue's key is its top-level "key" field (verified: issue objects carry "key").
created=$(jira issue create -t"$type" -s"$summary" -b"$body" -a"$me" --no-input --raw) || exit
key=$(printf '%s' "$created" | jq -r '.key // empty')
if [ -z "$key" ]; then
    printf 'jira-create.sh: could not read issue key from create output\n' >&2
    exit 1
fi

# Add to the active sprint when there is one (first id, should a board report
# more than one). No active sprint: skip the add and note it on stderr.
sprint=$(jira sprint list --state active --plain --no-headers --columns ID) || exit
sprint=$(printf '%s\n' "$sprint" | head -n 1)
if [ -n "$sprint" ]; then
    jira sprint add "$sprint" "$key" >/dev/null || exit
else
    printf 'jira-create.sh: no active sprint — %s not added to any sprint\n' "$key" >&2
fi

# Browse URL: the jira CLI returns no URL on create, so read the site from its
# own config (the `server:` line), honoring JIRA_CONFIG_FILE. Print the key
# alone when the server cannot be read.
cfg=${JIRA_CONFIG_FILE:-$HOME/.config/.jira/.config.yml}
server=$(sed -n 's/^[[:space:]]*server:[[:space:]]*//p' "$cfg" 2>/dev/null | head -n 1)
if [ -n "$server" ]; then
    printf '%s\t%s/browse/%s\n' "$key" "$server" "$key"
else
    printf '%s\n' "$key"
fi
