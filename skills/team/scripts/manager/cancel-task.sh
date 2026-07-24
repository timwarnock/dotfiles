#!/bin/sh
# cancel-task.sh <Worker> — abort a live task: archive it ABORTED, then re-instantiate
# the worker so it lands idle (D17). Fail-closed if there is no active task (E2). Manager.
set -u

[ "$#" -eq 1 ] || { printf 'usage: cancel-task.sh <Worker>\n' >&2; exit 1; }

worker=$1
dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
internal="$dir/../internal"
state=$(sh "$internal/state-dir.sh")
[ -d "$state" ] || printf 'note: wrong directory? no team state dir at %s\n' "$state" >&2
slot="$state/slots/$worker"

[ -f "$slot/task" ] || { printf 'cancel-task: %s has no active task.\n' "$worker" >&2; exit 1; }

# Atomically claim the slot -> archive (E2: the rename is the single atomic step; a
# racing finish-task loses because the source is already gone).
mkdir -p "$state/archive"
ts=$(date +%Y%m%dT%H%M%S)
target="$state/archive/$ts-$worker"
while [ -e "$target" ]; do sleep 1; ts=$(date +%Y%m%dT%H%M%S); target="$state/archive/$ts-$worker"; done
mv "$slot" "$target" 2>/dev/null \
    || { printf 'cancel-task: %s has no active task (already finished or cancelled).\n' "$worker" >&2; exit 1; }

printf 'ABORTED\n\n\ncancelled by manager.\n' > "$target/done"

# Re-instantiate the worker so it lands idle on its next get-task.
if [ -n "${TMUX:-}" ]; then
    sh "$internal/reinit-pane.sh" "$worker" "/team $worker" || true
fi

printf 'cancelled %s — ABORTED (archived %s-%s)\n' "$worker" "$ts" "$worker"
