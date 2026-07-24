#!/bin/sh
# roster.sh — who is present in this tmux window.
#   roster.sh            every pane: "<index> <@persona, or - when unset>".
#   roster.sh available  the subset of those lines a task may go to — same
#                         "<index> <@persona>" format, filtered to workers (panes
#                         other than 0, which is the manager) that carry an
#                         @persona and are not mid-task. Mid-task = a started
#                         thoughts/<Name>.task with no .done yet; a finished worker
#                         (its .done is present) is available again, since
#                         delegate-task.sh clears the stale .done when it re-tasks.
#                         thoughts/ is cwd-relative, the path /persona and
#                         delegate-task.sh read. Focus/fit comes from
#                         list-personas.sh, not here.
# Usage: roster.sh [available]

if [ -z "$TMUX" ]; then
    printf 'roster.sh: not inside tmux\n' >&2
    exit 1
fi

case "${1:-}" in
    '')
        tmux list-panes -t "$TMUX_PANE" -F '#{pane_index} #{?#{@persona},#{@persona},-}'
        ;;
    available)
        tmux list-panes -t "$TMUX_PANE" -F '#{pane_index} #{@persona}' \
        | while IFS=' ' read -r idx persona; do
            [ "$idx" = 0 ] && continue                  # pane 0 is the manager
            name=${persona#"[ "}; name=${name%" ]"}     # require a real "[ Name ]"
            [ -n "$name" ] && [ "$name" != "$persona" ] || continue
            # busy only while mid-task: a started .task with no .done yet.
            [ -e "thoughts/$name.task" ] && [ ! -e "thoughts/$name.done" ] && continue
            printf '%s %s\n' "$idx" "$persona"
        done
        ;;
    *)
        printf 'roster.sh: unknown argument: %s\nUsage: roster.sh [available]\n' "$1" >&2
        exit 1
        ;;
esac
