#!/bin/sh
# show-task.sh <id|worker> — detail of one task. A worker name whose slot holds a live
# in-flight task -> that live task (status IN FLIGHT); otherwise a worker name -> that
# worker's latest archived entry; an id (<when>-<Name>) -> that exact archived entry.
# Prints summary, computed status, and (archived only) the worker's result prose
# (untrusted context, D4). Manager.
set -u

[ "$#" -eq 1 ] || { printf 'usage: show-task.sh <id|worker>\n' >&2; exit 1; }

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
state=$(sh "$dir/../internal/state-dir.sh")
[ -d "$state" ] || printf 'note: wrong directory? no team state dir at %s\n' "$state" >&2
arch="$state/archive"
arg=$1
slot="$state/slots/$arg/task"

# A bare worker name whose slot holds a task -> that worker is working NOW. Show the live
# in-flight task, never stale archive. An explicit archive id, or a worker with no live
# slot, falls through to the archived entry below.
if [ ! -d "$arch/$arg" ] && [ -f "$slot" ]; then
    printf 'id:      %s (live slot)\n' "$arg"
    printf 'summary: %s\n' "$(head -n 1 "$slot" 2>/dev/null)"
    printf 'status:  IN FLIGHT (working now; not archived)\n'
    printf '\n--- task spec ---\n'
    tail -n +2 "$slot" 2>/dev/null
    printf '\n(archived history: list-tasks.sh %s)\n' "$arg"
    exit 0
fi

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
