#!/bin/sh
# whoami.sh — print THIS pane's persona name (the Name in @persona "[ Name ]"), so the
# worker scripts know whose slot to act on without the LLM passing (or knowing) it.
# Honors $TEAM_NAME as an override for non-tmux testing. Internal.
set -u

if [ -n "${TEAM_NAME:-}" ]; then
    printf '%s\n' "$TEAM_NAME"
    exit 0
fi

[ -n "${TMUX:-}" ] || { printf 'whoami.sh: not in tmux and TEAM_NAME unset\n' >&2; exit 1; }

p=$(tmux display-message -t "$TMUX_PANE" -p '#{@persona}')
name=${p#"[ "}
name=${name%" ]"}
[ -n "$name" ] && [ "$name" != "$p" ] || { printf 'whoami.sh: this pane has no @persona label\n' >&2; exit 1; }
printf '%s\n' "$name"
