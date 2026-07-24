#!/bin/sh
# resolve-pane.sh <pane-index|name> — print the pane id of a target in THIS tmux window.
# Window-scoped via `list-panes -t "$TMUX_PANE"` (E3/D20): a numeric target is a pane index,
# anything else is matched against the @persona "[ Name ]" label. Single source of truth for
# target resolution; tmux-send.sh and tmux-paste.sh both call it so neither can reach a pane
# in another window. Internal.
set -u

[ -n "${TMUX:-}" ] || { printf 'resolve-pane.sh: not inside tmux\n' >&2; exit 1; }
[ "$#" -ge 1 ] || { printf 'usage: resolve-pane.sh <pane-index|name>\n' >&2; exit 1; }

target=$1

case "$target" in
    *[!0-9]* | '')
        # Non-numeric: match the bracketed @persona label.
        pane=$(tmux list-panes -t "$TMUX_PANE" -F '#{pane_id} #{@persona}' \
            | grep -F "[ $target ]" | head -1 | cut -d ' ' -f1)
        ;;
    *)
        # Numeric: resolve the pane index to a stable pane id.
        pane=$(tmux list-panes -t "$TMUX_PANE" -F '#{pane_index} #{pane_id}' \
            | awk -v i="$target" '$1 == i { print $2; exit }')
        ;;
esac

[ -n "$pane" ] || { printf 'resolve-pane.sh: no pane for target: %s\n' "$target" >&2; exit 1; }
printf '%s\n' "$pane"
