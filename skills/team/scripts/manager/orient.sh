#!/bin/sh
# orient.sh — the manager's boot script. Run once at startup. It detects the manager's
# MODE and whether work is ACTIVE, then emits prose + data into the manager's context:
# it tells the manager which mode it is in and what that means, so manager.md no longer
# carries the mode guidance.
#
# MODE (deterministic — a git test, never LLM judgment):
#   Implementation — inside a linked git worktree (a ticket worktree, or any throwaway).
#                    The manager already holds this work: read the worktree's notes and
#                    continue; do not pull the sprint.
#   Explore        — everything else: the main checkout of a repo, OR not in a repo at
#                    all. Survey the work in flight (sprint + worktrees) and help the
#                    user pick the next move.
#   The test: in a work tree AND `git rev-parse --git-dir` differs from `--git-common-dir`
#   -> linked worktree -> Implementation; otherwise Explore. In the main checkout both
#   resolve to the same .git; in a linked worktree git-dir is .git/worktrees/<id> while
#   the common dir is the main .git (git-worktree(1), gitrepository-layout(5)).
#
# ACTIVE work (fresh vs recovery): a worker slot holding a task (state/slots/<name>/task)
# means coordination was interrupted by a context refresh -> RECOVERY. No in-flight slot
# -> fresh. Archived results are history (list-tasks.sh), not recovery.
#
# Data emitted for the manager to render: in Explore mode the sprint rows
# (jira-sprint-tickets.sh) and worktree rows (get-worktrees.sh), both tab-separated
# KEY/STATUS/SUMMARY. The sprint renders as one `ticket / summary` table per distinct
# status (the status is the heading, To Do-category statuses before In-Progress-category);
# the worktrees render as one `ticket / status / summary` table. Degrades:
# outside a repo there is no sprint and no worktrees; with the jira CLI absent the sprint
# is skipped and worktrees fall back to bare paths.
#
# Reads git, the filesystem, and (in Explore) jira; needs no tmux. Manager-only.
set -u

nl='
'

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
state=$(sh "$dir/../internal/state-dir.sh")   # <root>/thoughts/.team
thoughts=$(dirname -- "$state")               # <root>/thoughts

# ── Mode detection (deterministic) ───────────────────────────────────────────
mode=Explore
topdir=
if topdir=$(git rev-parse --show-toplevel 2>/dev/null); then
    in_repo=1
    # Linked worktree iff git-dir and git-common-dir differ; identical in main checkout.
    if [ "$(git rev-parse --git-dir 2>/dev/null)" != "$(git rev-parse --git-common-dir 2>/dev/null)" ]; then
        mode=Implementation
    fi
else
    in_repo=0
fi

# ── Active-work scan (fresh vs recovery) ─────────────────────────────────────
# Read the slots directly (a different moment from delegation-time worker-states.sh,
# same underlying state). Buffer the in-flight rows now so recovery can lead the output.
inflight=
if [ -d "$state/slots" ]; then
    for d in "$state"/slots/*/; do
        [ -d "$d" ] || continue                 # no-match glob guard (no nullglob in sh)
        [ -f "$d/task" ] || continue
        name=${d%/}; name=${name##*/}
        row=$(printf '%s\t%s' "$name" "$(head -n 1 "$d/task")")
        inflight=${inflight:+$inflight$nl}$row
    done
fi

# Does this worktree carry ticket notes? (POSIX glob loop — no find -maxdepth.)
has_notes=0
for f in "$thoughts"/notes-*.md; do
    [ -e "$f" ] && { has_notes=1; break; }
done

# ── Header + mode line ───────────────────────────────────────────────────────
printf '# orient — manager boot\n\n'
printf 'mode: %s\n' "$mode"

# ── Recovery banner (leads, because alignment overrides) ─────────────────────
if [ -n "$inflight" ]; then
    printf '\n## RECOVERY — work is in flight\n'
    printf 'A worker slot still holds a task, so coordination was interrupted — your\n'
    printf 'context was very likely refreshed mid-task and you are NOT aligned with the\n'
    printf 'user on where things stand. Realign with the user before doing anything else.\n\n'
    printf 'In flight (worker<tab>task summary):\n'
    printf '%s\n' "$inflight"
fi

# ── Mode guidance prose ──────────────────────────────────────────────────────
if [ "$mode" = Implementation ]; then
    printf '\n## Implementation mode\n'
    printf 'You are inside a git worktree (%s) — you already hold this work.\n' "$topdir"
    if [ "$has_notes" = 1 ]; then
        printf 'Read its notes (notes-*.md, listed below) and continue. Do not pull the sprint.\n'
    else
        printf 'This worktree has no ticket notes (no notes-*.md) — treat it as a throwaway/\n'
        printf 'POC. Name the worktree path to the user; do not fabricate ticket context.\n'
    fi
else
    printf '\n## Explore mode\n'
    if [ "$in_repo" = 1 ]; then
        printf 'You are on the main checkout. Surface the work in flight and help the user\n'
        printf 'pick the next move — do not start from a blank slate. Below are the active\n'
        printf 'sprint tickets and the active worktrees. Render the sprint as one\n'
        printf '`ticket / summary` table per distinct status, with the status as the table\n'
        printf 'heading, ordering statuses in the To Do category before those in the In\n'
        printf 'Progress category (commonly "To Do" then "In Progress"). Render the\n'
        printf 'worktrees as one `ticket / status / summary` table. Never show bare keys or\n'
        printf 'paths. From there the user — never you — chooses: resume a worktree, start a\n'
        printf 'new ticket, or take a quick fix (see references/tasks/worktree.md).\n'
        printf 'Production code you delegate to a worker and never write yourself;\n'
        printf 'documentation, configuration, research and review are yours to do\n'
        printf 'directly or with subagents.\n'
    else
        printf 'You are not in a git repo — there is no sprint and no worktrees to\n'
        printf 'coordinate. Showing any working docs in thoughts/ below; nothing to\n'
        printf 'coordinate here yet.\n'
    fi
fi

# ── Context docs in thoughts/ ────────────────────────────────────────────────
printf '\n## context docs (%s)\n' "$thoughts"
if [ -d "$thoughts" ]; then
    found=0
    for f in "$thoughts"/notes-*.md; do
        [ -e "$f" ] || continue
        found=1; printf 'read first\t%s\n' "$(basename -- "$f")"
    done
    for f in "$thoughts"/plan-*.md; do
        [ -e "$f" ] || continue
        found=1; printf 'offer to read\t%s\n' "$(basename -- "$f")"
    done
    for f in "$thoughts"/hand-off-*.md; do
        [ -e "$f" ] || continue
        topic=$(basename -- "$f"); topic=${topic#hand-off-}; topic=${topic%.md}
        found=1; printf 'hand-off (%s), read only if asked\t%s\n' "$topic" "$(basename -- "$f")"
    done
    [ "$found" = 0 ] && printf 'none\n'
else
    printf 'none (no thoughts/ dir)\n'
    [ "$in_repo" = 1 ] && printf 'no thoughts/ — probably the wrong directory\n' >&2
fi

# ── Explore-mode data: sprint + worktrees (git repo only) ────────────────────
if [ "$mode" = Explore ] && [ "$in_repo" = 1 ]; then
    printf '\n## active sprint (render one ticket / summary table per status, To Do before In Progress)\n'
    if command -v jira >/dev/null 2>&1; then
        sh "$dir/jira-sprint-tickets.sh"
        printf '\n## worktrees (render as one ticket / status / summary table)\n'
        sh "$dir/get-worktrees.sh"
    else
        printf 'jira CLI not found — skipping sprint.\n'
        printf '\n## worktrees (paths only — jira CLI absent)\n'
        git worktree list
    fi
fi
