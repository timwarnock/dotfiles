#!/bin/sh
# run-gatekeeper.sh <task-file> <verdict-file> [check-file] — emit the gatekeeper prompt on
# stdout. delegate-task pastes this whole prompt into a freshly /clear'd pane (via
# tmux-paste.sh) as one message, so the generic Claude there judges and reports; the prompt is
# the message body, never a command the pane runs. Selects the gate mode by check presence
# (D13). Internal; composed by delegate-task, not called by a role LLM.
set -u

[ "$#" -ge 2 ] || { printf 'usage: run-gatekeeper.sh <task-file> <verdict-file> [check-file]\n' >&2; exit 1; }

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
taskf=$1
vf=$2
checkf=${3:-}
report="$dir/gate-report.sh"

cat "$dir/task-gatekeeper.system.md"

if [ -n "$checkf" ] && [ -f "$checkf" ]; then
    printf '\nMODE: CODE — a check is provided; validate the TASK and the CHECK.\n'
    printf '\n===== TASK =====\n'
    cat "$taskf"
    printf '\n===== CHECK SCRIPT =====\n'
    cat "$checkf"
else
    printf '\nMODE: NON-PROD — no check; validate ONLY that the task edits no production code.\n'
    printf '\n===== TASK =====\n'
    cat "$taskf"
fi

printf '\n===== REPORT YOUR VERDICT =====\n'
printf 'You are the validator, not the worker: judging the TASK is all you do.\n'
printf 'Run EXACTLY one of these, once — it is your only and final step:\n'
printf '  sh %s %s PASS "one-line reason"\n' "$report" "$vf"
printf '  sh %s %s FAIL "one-line reason"\n' "$report" "$vf"
printf 'Then stop. The manager clears this pane and a fresh session does the work, not you.\n'
