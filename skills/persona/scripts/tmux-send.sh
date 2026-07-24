#!/bin/sh
# tmux-send.sh — send a message to another pane in the current tmux window.
# Target is a pane index (e.g. 0) or a persona name (e.g. Ed, matched against the bracketed @persona, "[ Ed ]").

if [ -z "$TMUX" ]; then
    printf 'tmux-send.sh: not inside tmux\n' >&2
    exit 1
fi

if [ "$#" -lt 2 ]; then
    printf 'Usage: tmux-send.sh <pane-index|persona-name> <message...>\n' >&2
    exit 1
fi

target="$1"
shift

case "$target" in
    *[!0-9]* | '')
        # Non-numeric: match the bracketed @persona name.
        pane=$(tmux list-panes -t "$TMUX_PANE" -F '#{pane_id} #{@persona}' \
            | grep -F "[ $target ]" | head -1 | cut -d ' ' -f1)
        ;;
    *)
        # Numeric: resolve the pane index to a stable pane id.
        pane=$(tmux list-panes -t "$TMUX_PANE" -F '#{pane_index} #{pane_id}' \
            | awk -v i="$target" '$1 == i { print $2; exit }')
        ;;
esac

if [ -z "$pane" ]; then
    printf 'tmux-send.sh: no pane for target: %s\n' "$target" >&2
    exit 1
fi

tmux send-keys -t "$pane" -l -- "$*"
tmux send-keys -t "$pane" Enter
