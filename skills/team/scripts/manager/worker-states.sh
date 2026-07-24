#!/bin/sh
# worker-states.sh — delegation-time lookup: every worker in THIS tmux window and its
# current state, so the manager can route a task to an idle worker or decide to cancel a
# busy one. Consulted when routing a task — NOT at boot (that is orient.sh) and NOT for
# history (that is list-tasks.sh). Live state only.
#
# Output: tab-separated  <pane-index>  <name>  <state>, one row per worker, where state
# is `idle` or `working: <task summary>` (the first line of the worker's active task).
# The manager (pane 0) is not a worker and is omitted. Manager.
set -u

[ -n "${TMUX:-}" ] || { printf 'worker-states: not inside tmux\n' >&2; exit 1; }

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
state=$(sh "$dir/../internal/state-dir.sh")

tmux list-panes -t "$TMUX_PANE" -F '#{pane_index} #{@persona}' | while IFS=' ' read -r idx persona; do
    name=${persona#"[ "}
    name=${name%" ]"}
    [ -n "$name" ] && [ "$name" != "$persona" ] || continue   # pane carries no @persona
    [ "$idx" = 0 ] && continue                                # pane 0 is the manager
    if [ -f "$state/slots/$name/task" ]; then
        printf '%s\t%s\tworking: %s\n' "$idx" "$name" "$(head -n 1 "$state/slots/$name/task")"
    else
        printf '%s\t%s\tidle\n' "$idx" "$name"
    fi
done
