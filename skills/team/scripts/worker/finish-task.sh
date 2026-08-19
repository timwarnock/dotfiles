#!/bin/sh
# finish-task.sh — terminate THIS worker's task: compute the verdict, archive the slot,
# poke the manager. Worker. The worker is file-blind; it never writes or sees the
# archive. Prose comes on STDIN via a quoted heredoc (D10) so it is injection-safe:
#   sh finish-task.sh <<'TEAM_EOF'
#   ...your result prose...
#   TEAM_EOF
# Verdict is COMPUTED, never supplied (D3): a check present -> run it, exit 0 = PASS else
# FAIL; no check -> DONE (checkless, human-judged). Fail-closed if no active task (E2).
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
state=$(sh "$dir/../internal/state-dir.sh") || exit 1
name=$(sh "$dir/../internal/whoami.sh") || exit 1
slot="$state/slots/$name"

[ -f "$slot/task" ] || { printf 'finish-task: no active task. Nothing to finish.\n' >&2; exit 1; }

# Worker prose from stdin (may be empty).
prose=$(cat)

# Compute the verdict from the check's exit code — never from the prose (D3).
if [ -f "$slot/check.sh" ]; then
    if sh "$slot/check.sh" >/dev/null 2>&1; then status=PASS; else status=FAIL; fi
else
    status=DONE
fi

# Atomically claim the slot -> archive. The rename is the single atomic step (E2): a
# racing cancel-task loses because the source is already gone.
mkdir -p "$state/archive"
ts=$(date +%Y%m%dT%H%M%S)
target="$state/archive/$ts-$name"
while [ -e "$target" ]; do sleep 1; ts=$(date +%Y%m%dT%H%M%S); target="$state/archive/$ts-$name"; done
mv "$slot" "$target" 2>/dev/null \
    || { printf 'finish-task: no active task (already finished or cancelled).\n' >&2; exit 1; }

# Record the result: line 1 = computed status, blank, blank, then the prose (D4).
printf '%s\n\n\n%s\n' "$status" "$prose" > "$target/done"

# Poke the manager (pane 0): one script-stamped line, status + summary (D10/D19).
summary=$(head -n 1 "$target/task" 2>/dev/null)
if [ -n "${TMUX:-}" ]; then
    # Drop the @task marker and @branch pin: an idle worker falls back to a plain grey
    # cwd branch, so the status line makes active-vs-idle visually obvious.
    tmux set-option -pu -t "$TMUX_PANE" @task 2>/dev/null || true
    tmux set-option -pu -t "$TMUX_PANE" @branch 2>/dev/null || true
    sh "$dir/../internal/tmux-send.sh" 0 "[ $name ] $status — $summary" 2>/dev/null || true
fi

printf 'finished — %s (archived %s-%s)\n' "$status" "$ts" "$name"
