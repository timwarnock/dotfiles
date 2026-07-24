#!/bin/sh
# reinit-pane.sh <target> <payload...> — clear a pane and then send it a single-line payload:
# the clear -> settle -> init sequence (D16), composed from clear-pane.sh (clear + settle, D8)
# and tmux-send.sh (the send). Used to re-instantiate a worker (payload "/team <Name>"). For a
# multi-line payload (e.g. the gatekeeper prompt) pair clear-pane.sh with tmux-paste.sh
# instead. Internal.
set -u

[ "$#" -ge 2 ] || { printf 'usage: reinit-pane.sh <target> <payload...>\n' >&2; exit 1; }

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target=$1
shift

sh "$dir/clear-pane.sh" "$target" || exit "$?"
sh "$dir/tmux-send.sh" "$target" "$*" || exit "$?"
