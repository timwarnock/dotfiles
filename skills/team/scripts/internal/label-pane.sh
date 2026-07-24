#!/bin/sh
# label-pane.sh — set THIS pane's @persona label to "[ <Name> ]" (D15). The bootstrap
# (SKILL.md instantiate) runs it instead of raw `tmux`, because roster/finish read this
# label and it is therefore protocol state. Internal.
# Usage: label-pane.sh <Name>
set -u

[ -n "${TMUX:-}" ] || { printf 'label-pane.sh: not inside tmux\n' >&2; exit 1; }
[ "$#" -eq 1 ] || { printf 'usage: label-pane.sh <Name>\n' >&2; exit 1; }

tmux set-option -p -t "$TMUX_PANE" @persona "[ $1 ]"
