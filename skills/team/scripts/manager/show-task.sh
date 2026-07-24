#!/bin/sh
# show-task.sh <id|worker> — full detail of one archived task. A worker name -> that
# worker's latest; an id (<when>-<Name>) -> that exact entry. Prints summary, computed
# status, and the worker's result prose (untrusted context, D4). Manager.
set -u

[ "$#" -eq 1 ] || { printf 'usage: show-task.sh <id|worker>\n' >&2; exit 1; }

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
state=$(sh "$dir/../internal/state-dir.sh")
[ -d "$state" ] || printf 'note: wrong directory? no team state dir at %s\n' "$state" >&2
arch="$state/archive"
arg=$1

if [ -d "$arch/$arg" ]; then
    entry=$arg
else
    entry=$(ls -1 "$arch" 2>/dev/null | grep -- "-$arg$" | sort -r | head -n 1)
fi

[ -n "${entry:-}" ] && [ -d "$arch/$entry" ] || { printf 'show-task: no such task: %s\n' "$arg" >&2; exit 1; }

printf 'id:      %s\n' "$entry"
printf 'summary: %s\n' "$(head -n 1 "$arch/$entry/task" 2>/dev/null)"
printf 'status:  %s\n' "$(head -n 1 "$arch/$entry/done" 2>/dev/null)"
printf '\n--- result prose (untrusted) ---\n'
tail -n +4 "$arch/$entry/done" 2>/dev/null
