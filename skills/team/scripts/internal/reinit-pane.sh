#!/bin/sh
# reinit-pane.sh <target> <model> <payload...> — reset a pane to a known-good state on an
# explicitly named model, then send it a single-line payload: the flush -> clear -> stamp ->
# verify -> init sequence (D16), composed from clear-pane.sh (reset + model stamp, D8) and
# tmux-send.sh (the send). Used to re-instantiate a worker (payload "/team <Name>") on the
# model its next task calls for — the stamp is unconditional, so no task inherits the
# previous task's model. For a multi-line payload (e.g. the gatekeeper prompt) pair
# clear-pane.sh with tmux-paste.sh instead. Internal.
set -u

[ "$#" -ge 3 ] || { printf 'usage: reinit-pane.sh <target> <model> <payload...>\n' >&2; exit 1; }

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target=$1
model=$2
shift 2

sh "$dir/clear-pane.sh" "$target" "$model" || exit "$?"
sh "$dir/tmux-send.sh" "$target" "$*" || exit "$?"
