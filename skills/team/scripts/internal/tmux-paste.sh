#!/bin/sh
# tmux-paste.sh <pane-index|name> — deliver a message body (read from stdin) to another pane
# in THIS tmux window as ONE bracketed paste followed by Enter, so a multi-line payload lands
# as a single submission instead of one Enter per line. load-buffer reads stdin, so there is
# no argv/ARG_MAX ceiling on payload size; paste-buffer -p wraps it in bracketed-paste markers
# so the receiving TUI takes the whole block as one paste. Target resolution is delegated to
# resolve-pane.sh (E3/D20). Used to drop a whole prompt (e.g. the gatekeeper prompt) into a
# freshly cleared pane. Internal.
set -u

[ -n "${TMUX:-}" ] || { printf 'tmux-paste.sh: not inside tmux\n' >&2; exit 1; }
[ "$#" -ge 1 ] || { printf 'usage: tmux-paste.sh <pane-index|name> < body\n' >&2; exit 1; }

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
pane=$(sh "$dir/resolve-pane.sh" "$1") || exit 1

buf="teampaste$$"
tmux load-buffer -b "$buf" - || exit "$?"
tmux paste-buffer -p -d -t "$pane" -b "$buf" || exit "$?"
tmux send-keys -t "$pane" Enter
