#!/bin/sh
# get-task.sh — print THIS worker's current task, or "idle". Worker script.
# The worker is FILE-BLIND (D21): this prints ONLY the task prose; it never reveals the
# check or any protocol path. For a checkless task (no check) it appends the production
# guardrail (D13). Read-only w.r.t. the slot and idempotent (E1): safe to re-run on a reset;
# the slot is the single source of truth. On an active task it also sets the pane's @task
# marker (the status-line "running" indicator) and, when $slot/branch was recorded at
# delegation, pins @branch to it; both are cleared by finish-task / cancel-task, not here.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
state=$(sh "$dir/../internal/state-dir.sh") || exit 1
name=$(sh "$dir/../internal/whoami.sh") || exit 1
slot="$state/slots/$name"

if [ ! -f "$slot/task" ]; then
    printf 'idle — no task. Await instructions from the user.\n'
    exit 0
fi

cat "$slot/task"

# Mark the pane as running a task (drives the status line's active indicator), and pin
# @branch to the task's worktree branch when one was recorded at delegation. The worker
# builds in that worktree while its cwd stays the grid home. Idempotent; both are cleared
# by finish-task / cancel-task, not here.
if [ -n "${TMUX:-}" ]; then
    tmux set-option -p -t "$TMUX_PANE" @task 1 2>/dev/null || true
    [ -s "$slot/branch" ] && tmux set-option -p -t "$TMUX_PANE" @branch "$(cat "$slot/branch")" 2>/dev/null || true
fi

if [ ! -f "$slot/check.sh" ]; then
    cat <<'EOF'

--- CHECKLESS (non-production) TASK ---
Keep your edits within non-production code. If completing this requires editing
production code, stop and report that with finish-task.sh — it should have gone
through the gated (checked) path instead.
EOF
fi
