# Procedure: ticket-scoped worktree (create, lifecycle, cleanup)

Each Jira ticket gets its own git worktree under the mining repo, giving it an isolated working directory and its own `thoughts/`. 
This is what separates concurrent tickets — it is orthogonal to persona and role.

Repo: `$HOME/github/NYDIG/mining`. Worktree: `<repo>/.worktrees/<TICKET>`, branch `<TICKET>` off `origin/main`.

## Use `tmux-mining-personas` when starting a ticket

`tmux-mining-personas <TICKET> [max]` does the creation below and lays out the agent grid. 
Prefer it. The user runs it — agents never do.

```sh
tmux-mining-personas ME-3244      # worktree + 2x3 agent grid for the ticket
tmux-mining-personas ME-3244 max  # same, plus force /effort max on every persona pane
tmux-mining-personas              # no ticket: open the main checkout in explore mode (no worktree)
```

`max` (second positional) forces `/effort max` on every persona pane.
The no-ticket form opens the **main checkout** in *explore mode* (see `references/roles/manager.md`): mutable, but explore-mode edits must leave it clean.


## Quick fix: `bug-fix` (change first, ticket after)

For a small fix you can do so in explore mode (in main).
The user will run `bug-fix` with a one-line summary. And this will create a fresh `.worktrees/ME-XXXX` but without the separate 2x3 agent grid.


## Proof-of-concept (POC) worktree (explore mode, throwaway)

A throwaway worktree for POC work and head-to-head comparisons *before* there is a
ticket. Unlike ticket worktrees and `bug-fix` (user-run), **the manager may create
these directly**:

```sh
git worktree add .worktrees/<topic>-poc-<worker> -b <topic>-poc-<worker> origin/main
```

The worker builds *in* the worktree but reports through the **main checkout's
`thoughts/`** (`.done` by absolute path) — POC worktrees isolate code only; the
explore-mode manager coordinates. For a comparison: one per worker, identical spec
except the approach.
Throwaway by default — clean up per the procedure below (`--force` since uncommitted).


## Create manually (ticket ME-XXXX, outside tmux-mining-personas)

```sh
REPO="$HOME/github/NYDIG/mining"
TICKET="ME-XXXX"
WORKDIR="$REPO/.worktrees/$TICKET"

git -C "$REPO" fetch origin main
git -C "$REPO" worktree add "$WORKDIR" -b "$TICKET" origin/main
mkdir -p "$WORKDIR/thoughts"

# Seed ticket context for the manager's notes.
jira issue view "$TICKET" --plain > "$WORKDIR/thoughts/notes-${TICKET}.md" 2>/dev/null \
    || printf '# %s\n\nTicket context unavailable.\n' "$TICKET" \
        > "$WORKDIR/thoughts/notes-${TICKET}.md"
```

## Lifecycle

- A worktree may outlive its branch. If the branch is merged and the user reopens the worktree, ask what the new work is, then create a follow-up branch (e.g. `ME-3266-cfg`).
- A worktree matching `ME-????-*` belongs to the parent `ME-????` workstream. Resolve the parent path with `git worktree list`, then read/append to `<parent-path>/thoughts/notes-ME-????.md` — do not assume it exists in the current worktree.

## Cleanup (workstream done, branch merged)

Run from the main checkout (`$REPO`) — typically exploration mode (`tmux-mining-personas` with no ticket). Order matters: remove the poetry virtualenv **before** the worktree, because the venv hash requires the directory to still exist.

```sh
# 1. Remove poetry virtualenvs first (while the worktree still exists).
find .worktrees/<ticket> -maxdepth 2 -name 'pyproject.toml'
#    then, for each directory containing one:  (cd <dir> && poetry env remove --all)

# 2. Remove the worktree.
git worktree remove .worktrees/<ticket>

# 3. Delete the branch.
git branch -d <branch>
```

## Notes

- `notes-<TICKET>.md` is the manager's file; workers do not touch it.
- The worktree's `thoughts/` directory is per-ticket — that is the separation between concurrent tickets, so `/persona` needs no namespacing of its own.
