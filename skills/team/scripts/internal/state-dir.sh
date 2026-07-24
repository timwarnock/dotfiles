#!/bin/sh
# state-dir.sh — resolve the team protocol state directory (the grid home's
# thoughts/.team) and print it. This is the SINGLE resolution chokepoint: every worker and
# manager script routes through it, so the protocol is airtight no matter which worktree an
# agent builds in. Internal; never called directly by an LLM.
#
# Resolution order:
#   1. $TEAM_STATE — explicit override, used outright (tests, and any first-class override).
#   2. toplevel = `git rev-parse --show-toplevel`; outside a git repo, toplevel = $PWD.
#      --show-toplevel lifts a deep subdir to the worktree root, so resolution is correct
#      from anywhere in a checkout without walking the path by hand.
#   3. A derived worktree records its grid home at <toplevel>/thoughts/TEAM_HOME — present
#      and non-empty -> use the home it records.
#   4. else <toplevel>/thoughts/ present -> this is the grid home -> <toplevel>/thoughts/.team
#      (.team is created lazily on the first delegation, so resolution keys on thoughts/).
#   5. else -> not a team workspace: print a clear directive to stderr and exit non-zero.
#
# Contract: on success prints the .team path and exits 0. On the wrong-place case it still
# prints a best-effort path to stdout (so a degrading caller has something), writes the
# directive to stderr, and exits 3 — so a hard-stop caller can `state=$(state-dir.sh) || exit`.
set -u

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# 1. Explicit override wins outright.
if [ -n "${TEAM_STATE:-}" ]; then
    printf '%s\n' "$TEAM_STATE"
    exit 0
fi

# 2. Worktree root via git; $PWD when not in a repo (the only basis without a toplevel).
toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || toplevel=$PWD

# 3. Derived worktree -> follow its recorded grid home.
pointer="$toplevel/thoughts/TEAM_HOME"
if [ -f "$pointer" ]; then
    home=""
    IFS= read -r home < "$pointer" || true
    if [ -n "$home" ]; then
        printf '%s\n' "$home"
        exit 0
    fi
fi

# 4. Grid home -> thoughts/ present (with or without .team yet).
if [ -d "$toplevel/thoughts" ]; then
    printf '%s/thoughts/.team\n' "$toplevel"
    exit 0
fi

# 5. Wrong place. Best-effort path on stdout; clear directive on stderr; exit non-zero.
printf '%s/thoughts/.team\n' "$toplevel"
# shellcheck source=/dev/null
. "$dir/load-env.sh"
if [ -n "${TEAM_REPO:-}" ]; then
    printf 'state-dir: not in a team workspace. Move to the worktree where the team was launched (under %s/.worktrees/) and run this again.\n' "$TEAM_REPO" >&2
else
    printf 'state-dir: not in a team workspace. Move to the worktree where the team was launched and run this again.\n' >&2
fi
exit 3
