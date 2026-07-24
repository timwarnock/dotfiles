#!/bin/sh
# list-tasks.sh [worker] — the archive ledger (forensics), newest first, optionally
# filtered to one worker. Manager.
# Output: tab-separated  <when>  <worker>  [STATUS]  <summary>
# Status encodes the lane: PASS/FAIL = checked, DONE = checkless, ABORTED = cancelled.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
state=$(sh "$dir/../internal/state-dir.sh")
[ -d "$state" ] || printf 'note: wrong directory? no team state dir at %s\n' "$state" >&2
arch="$state/archive"
filter=${1:-}

[ -d "$arch" ] || { printf 'no archived tasks.\n'; exit 0; }

ls -1 "$arch" 2>/dev/null | sort -r | while IFS= read -r d; do
    [ -d "$arch/$d" ] || continue
    ts=${d%%-*}
    name=${d#*-}
    [ -z "$filter" ] || [ "$name" = "$filter" ] || continue
    status=$(head -n 1 "$arch/$d/done" 2>/dev/null)
    summary=$(head -n 1 "$arch/$d/task" 2>/dev/null)
    printf '%s\t%s\t[%s]\t%s\n' "$ts" "$name" "${status:-?}" "$summary"
done
