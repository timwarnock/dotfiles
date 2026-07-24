#!/bin/sh
# tmux-send.sh <pane-index|name> <message...> — send a single-line message (typed keystrokes
# + Enter) to another pane in THIS tmux window. Target resolution is delegated to
# resolve-pane.sh, so it can never reach a pane in another window (E3/D20). Slash commands and
# other control input must be typed rather than pasted, so this stays keystroke-based; use
# tmux-paste.sh for a multi-line message body. Internal; called by other scripts.
set -u

[ -n "${TMUX:-}" ] || { printf 'tmux-send.sh: not inside tmux\n' >&2; exit 1; }
[ "$#" -ge 2 ] || { printf 'usage: tmux-send.sh <pane-index|name> <message...>\n' >&2; exit 1; }

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target=$1
shift

pane=$(sh "$dir/resolve-pane.sh" "$target") || exit 1

tmux send-keys -t "$pane" -l -- "$*"
tmux send-keys -t "$pane" Enter
