#!/bin/sh
# delegate-task.sh <Worker> <task-file> [check-file] — gate, then place. Manager.
# task-file (and, for production code, check-file) are /tmp scratch the manager authored
# with the Write tool. Check present = checked lane (gate validates task + check);
# absent = checkless lane (gate validates the task edits no production code, D13).
#
# Gate-gating (Rule 1, deterministic): the LLM gatekeeper judges production code, and
# production code requires a git repo. The git test is the exit status of
# `git rev-parse --is-inside-work-tree`, never an LLM:
#   in a work tree    -> run the gatekeeper (below);
#   not in a git repo -> no production code, so SKIP the gate and place directly.
#
# Fresh base (BEFORE the slow gate): the team-home branch is rebased onto a current
# origin/main before any task starts, so work begins on top of main — never on a stale
# branch left from the launcher. Run on the team home explicitly (derived from the resolved
# state path), not CWD, so it holds wherever the manager stands; skipped when the home is not
# a git repo (the ~/.claude case has no branch). A failed fetch or a rebase that won't apply
# aborts here, fast and before gatekeeping, with the scratch kept so the manager can retry
# (fetch) or realign with the user (rebase).
#
# Flow (pane-reuse gate, D12): clear the worker's pane -> have the generic Claude there
# judge via run-gatekeeper -> poll its verdict file, fail-closed. PASS -> promote scratch
# into the slot and re-instantiate the worker (it picks the task up via get-task). FAIL
# or timeout -> print the critique, keep the scratch, leave the worker idle, exit 1.
# The git-skip path goes straight to that same promote-and-re-instantiate placement.
#
# The gate blocks for up to ~5 min (300s); invoke with a Bash timeout above that.
set -u

[ "$#" -ge 2 ] || { printf 'usage: delegate-task.sh <Worker> <task-file> [check-file]\n' >&2; exit 1; }
[ -n "${TMUX:-}" ] || { printf 'delegate-task: not inside tmux (the gate needs a pane)\n' >&2; exit 1; }

worker=$1
taskf=$2
checkf=${3:-}

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
internal="$dir/../internal"
# Resolve the team state through the single chokepoint: state-dir.sh refuses (non-zero,
# with a directive on stderr) when this is not a team workspace, so the manager cannot
# silently create a workspace in the wrong place. The grid home's thoughts/.team is created
# lazily when the slot is placed below.
state=$(sh "$internal/state-dir.sh") || exit 1

# E4: refuse a busy worker.
[ -f "$state/slots/$worker/task" ] && {
    printf 'delegate-task: %s is busy (active task). cancel-task first.\n' "$worker" >&2
    exit 1
}
[ -f "$taskf" ] || { printf 'delegate-task: no task file: %s\n' "$taskf" >&2; exit 1; }
[ -n "$checkf" ] && [ ! -f "$checkf" ] && { printf 'delegate-task: no check file: %s\n' "$checkf" >&2; exit 1; }

# Resolve the team home and whether it is a real git repo. Both the fresh-base rebase below
# and the gatekeeper gate further down turn on this one question — production code lives only
# in a git repo, and ~/.claude is not one — so it is computed once and reused, keyed on the
# home (not CWD) so it holds wherever the manager stands.
home=${state%/thoughts/.team}
if git -C "$home" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    home_is_repo=yes
else
    home_is_repo=no
fi

# --- Fresh base (before the gate, so a stale/dirty branch stops us in seconds, not after the
# ~5-min gatekeeper). Rebase the team-home branch onto a current origin/main. Only in a repo
# (the ~/.claude case has no branch). ---
if [ "$home_is_repo" = yes ]; then
    git -C "$home" fetch origin >/dev/null 2>&1 || {
        printf 'delegate-task: git fetch failed in %s — cannot confirm a current origin/main. Not delegated; retry when origin is reachable.\n' "$home" >&2
        exit 1
    }
    git -C "$home" rebase origin/main >/dev/null 2>&1 || {
        git -C "$home" rebase --abort >/dev/null 2>&1
        printf 'delegate-task: the team-home branch (%s) will not rebase cleanly onto origin/main. Not delegated. Talk to the user and align on what to do before delegating again.\n' "$home" >&2
        exit 1
    }
fi

# --- Gate-gating (Rule 1, deterministic): production code requires a git repo, so outside
# a work tree there is nothing for the LLM gatekeeper to judge. Same home_is_repo test as the
# fresh-base step above — the deterministic exit status of git, never an LLM. ---
if [ "$home_is_repo" = yes ]; then
    # --- Gate (pane-reuse) ---
    vf=$(mktemp)
    : > "$vf"   # ensure empty; we poll for non-empty

    # Compose the gatekeeper prompt, then clear the worker's pane to a fresh generic Claude and
    # paste the prompt in as one message (D12). The prompt is the message body, not a command
    # the pane runs: nothing opaque is executed, so the safety classifier has no "run this
    # script and follow its output" shape to block on. The only command the validator runs is
    # the narrow gate-report.sh.
    gatef=$(mktemp)
    sh "$internal/run-gatekeeper.sh" "$taskf" "$vf" "$checkf" > "$gatef" \
        || { printf 'delegate-task: could not compose gatekeeper prompt\n' >&2; rm -f "$vf" "$gatef"; exit 1; }
    sh "$internal/clear-pane.sh" "$worker" \
        || { printf 'delegate-task: could not clear %s\n' "$worker" >&2; rm -f "$vf" "$gatef"; exit 1; }
    sh "$internal/tmux-paste.sh" "$worker" < "$gatef" \
        || { printf 'delegate-task: could not drive %s\n' "$worker" >&2; rm -f "$vf" "$gatef"; exit 1; }
    rm -f "$gatef"

    deadline=$(( $(date +%s) + 300 ))
    verdict=""
    reason=""
    while [ "$(date +%s)" -lt "$deadline" ]; do
        if [ -s "$vf" ]; then
            verdict=$(cut -d ' ' -f 1 < "$vf")
            reason=$(cut -d ' ' -f 2- < "$vf")
            break
        fi
        sleep 3
    done
    rm -f "$vf"

    if [ "$verdict" != "PASS" ]; then
        # FAIL, timeout, or unparseable -> fail-closed.
        [ -n "$verdict" ] && printf 'GATE FAIL: %s\n' "$reason" >&2 \
            || printf 'GATE FAIL: gatekeeper timed out (no verdict) — failing closed.\n' >&2
        printf 'Scratch kept: %s %s — edit and resubmit.\n' "$taskf" "$checkf" >&2
        sh "$internal/reinit-pane.sh" "$worker" "/team $worker" || true
        exit 1
    fi
    gate=PASS
else
    # No git repo -> no production code -> the gate is unnecessary; skip it deterministically.
    gate=SKIPPED
    printf 'delegate-task: no git repo -> no production code; gate skipped.\n'
fi

# --- Place: promote scratch into the slot, then re-instantiate the worker. PASS and the
# git-skip path share this block verbatim. ---
slot="$state/slots/$worker"
mkdir -p "$slot"
cp "$taskf" "$slot/task"
[ -n "$checkf" ] && cp "$checkf" "$slot/check.sh"
rm -f "$taskf"
[ -n "$checkf" ] && rm -f "$checkf"

sh "$internal/reinit-pane.sh" "$worker" "/team $worker" \
    || { printf 'delegate-task: placed task but could not re-instantiate %s\n' "$worker" >&2; exit 1; }

printf 'delegated to %s (gate %s): %s\n' "$worker" "$gate" "$(head -n 1 "$slot/task")"
