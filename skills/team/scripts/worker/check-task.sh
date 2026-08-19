#!/bin/sh
# check-task.sh — run THIS worker's hidden acceptance check and report the verdict.
# Worker. A coarse "am I done?" handshake (D22), NOT a test harness. The check is fully
# hidden from the file-blind worker (D21): its source is never shown AND its output is
# suppressed — only the verdict (PASS/FAIL) is printed, so a criteria-echoing check can't
# leak. (Amends D22's original "no suppression": the worker doesn't need the output — the
# task prose carries the acceptance criteria, and a supervised worker can ask the human.)
# A checkless task has nothing to run.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
state=$(sh "$dir/../internal/state-dir.sh") || exit 1
name=$(sh "$dir/../internal/whoami.sh") || exit 1
slot="$state/slots/$name"

[ -f "$slot/task" ] || { printf 'check-task: no active task.\n' >&2; exit 1; }

if [ ! -f "$slot/check.sh" ]; then
    printf 'no check for this task (checkless) — finish-task will record DONE.\n'
    exit 0
fi

if sh "$slot/check.sh" >/dev/null 2>&1; then
    printf 'PASS — the task looks done.\n'
    exit 0
else
    printf 'FAIL — something the task asked for is missing.\n'
    exit 1
fi
