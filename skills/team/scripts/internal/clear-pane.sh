#!/bin/sh
# clear-pane.sh <pane-index|name> — clear another pane in THIS tmux window and let it settle,
# so the next message submits instead of hanging as a stray newline in a still-transitioning
# input (D8). The clear -> settle half of the pane primitive: reinit-pane.sh pairs it with
# tmux-send.sh (single-line re-instantiation), the gate pairs it with tmux-paste.sh (paste a
# whole prompt). Internal.
set -u

[ "$#" -ge 1 ] || { printf 'usage: clear-pane.sh <pane-index|name>\n' >&2; exit 1; }

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target=$1

sh "$dir/tmux-send.sh" "$target" "/clear" || exit "$?"

# Settle: let the pane finish processing /clear before the next send (D8). No deterministic
# readiness signal is exposed, so wait a fixed interval.
sleep 2
