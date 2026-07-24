# Worktrees: when to isolate, how each one is created, and the calls that need a human

A worktree gives a unit of work its own checked-out directory and its own `thoughts/`, so
concurrent efforts stay isolated. A worktree lands at `$TEAM_REPO/.worktrees/<name>` on its
own branch `<name>` (`$TEAM_REPO` comes from `~/.claude/.env`).

## Per-task and throwaway worktrees — the manager creates these

When a ticket needs more than one PR, each task gets its own worktree and branch; a spike or
a head-to-head comparison gets one too. Create it with one script, run from the workspace
where the team is coordinating — it prints the new worktree's path:

```sh
sh ~/.claude/skills/team/scripts/worktree/worktree-create.sh <name> [base-branch]
```

- **Name it for the work.** Ticket work: `<TICKET>-<aspect>` (e.g. `ME-4100-config`). A
  spike or POC: a topic name (e.g. `latency-poc`).
- **Base branch is optional.** The branch forks from `origin/main` by default; pass a base
  branch to stack on another in-flight branch instead.
- **Point the task at the result.** The printed path is the worktree the worker builds in —
  name that path and its branch in the task, so the worker works there and commits on that
  branch.

For a head-to-head comparison, create one worktree per approach — same task spec, different
angle — and the workers build in parallel, each in its own.

## Ticket / tracked work — the launcher (user-run)

The primary path. The **user** runs `tmux-mining-team <TICKET>`; agents never do. When the
ticket has no worktree yet, the launcher creates one and seeds it, then lays out the 2×3
agent grid inside it. One worktree per ticket, named for it. With no ticket
(`tmux-mining-team`) it opens the **main checkout** in explore mode — no worktree, because
there is nothing to isolate.

## Quick fix — `bug-fix` (user-run, change first / ticket after)

The one scenario where work starts directly in the **main checkout** (explore mode) instead
of a fresh worktree: make a small change, then the **user** runs `bug-fix "<summary>"` to turn
it into a ticket and a PR. No agent grid.

**Only the user runs `bug-fix` — never an agent.** It creates a real ticket and pushes a
branch — outward-facing actions a human owns.

## Lifecycle

- **A worktree can outlive its branch.** If the branch merged and the user reopens the
  worktree for more work, **ask the user what the new work is** (one question), then create a
  fresh follow-up branch for it (e.g. `ME-3266-cfg`). When you later tear it down, pass that
  follow-up branch as the second argument to the cleanup script.
- **A `ME-????-*` worktree belongs to the parent `ME-????` workstream.** Its notes live with
  the parent, not in the current worktree: resolve the parent path with `git worktree list`,
  then read/append `<parent-path>/thoughts/notes-ME-????.md`, resolving that path rather than
  assuming the file is local.

## Cleanup (work done, branch merged)

Run `worktree-cleanup.sh` from **outside** the target worktree (e.g. the main checkout), or
you pull the directory out from under yourself. Order is load-bearing and the script enforces
it: any language virtualenv is removed first (while the directory still exists — a venv's
identity is tied to its path), then the worktree, then the branch (`git branch -d` refuses an
unmerged branch, the intended guard).

```sh
sh ~/.claude/skills/team/scripts/worktree/worktree-cleanup.sh <name> [branch]
```

A throwaway spike is torn down the same way. If its branch is unmerged the final
`git branch -d` refuses it — remove the branch by hand only when you mean to discard the work.

## Notes

- `notes-<TICKET>.md` is the manager's file; workers do not touch it.
- The worktree's `thoughts/` is per-worktree — that separation is what keeps concurrent work
  from colliding.
