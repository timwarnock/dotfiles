#!/bin/sh
# init-persona.sh — the single entry point the SKILL.md bootstrap runs to instantiate a
# team member. Given a persona <Name> it does the deterministic setup, then prints a short
# bootstrap that points the LLM at the two identity files to Read:
#   1. validate <Name> against references/personas/<Name>.md (case-sensitive, even on a
#      case-insensitive filesystem)
#   2. derive the role from the tmux pane index (0 = manager, else = worker; not in tmux = worker)
#   3. label THIS pane via label-pane.sh (skipped outside tmux)
#   4. print "You are <Name> ... Role: <role> ..." with ABSOLUTE paths to Read
# It prints PATHS, not file contents, so the bootstrap can never be truncated; the persona
# and role docs (and anything they reference) are read by the LLM via the Read tool.
# $TEAM_PANE overrides the pane index for non-tmux testing (cf. $TEAM_NAME in whoami.sh).
# Usage: init-persona.sh <Name>
set -u

[ "$#" -eq 1 ] || { printf 'usage: init-persona.sh <Name>\n' >&2; exit 1; }
name=$1

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$dir/../.." && pwd)
personas_dir="$root/references/personas"

# Case-sensitive match, independent of the filesystem's case folding.
persona_file=
for f in "$personas_dir"/*.md; do
    [ -e "$f" ] || continue
    if [ "$(basename "$f" .md)" = "$name" ]; then
        persona_file=$f
        break
    fi
done

if [ -z "$persona_file" ]; then
    printf 'init-persona.sh: no such persona: %s\n\nValid personas:\n' "$name" >&2
    sh "$dir/list-personas.sh" >&2
    exit 1
fi

# Derive the role from the pane index. $TEAM_PANE overrides for non-tmux testing.
if [ -n "${TEAM_PANE:-}" ]; then
    idx=$TEAM_PANE
elif [ -n "${TMUX:-}" ]; then
    idx=$(tmux display-message -t "$TMUX_PANE" -p '#{pane_index}')
else
    idx=
fi

if [ "$idx" = "0" ]; then
    role=manager
else
    role=worker
fi

role_file="$root/references/roles/$role.md"
[ -f "$role_file" ] || { printf 'init-persona.sh: missing role doc: %s\n' "$role_file" >&2; exit 1; }

# Label THIS pane (protocol state, read back by whoami.sh). Skipped outside tmux.
if [ -n "${TMUX:-}" ]; then
    sh "$dir/label-pane.sh" "$name" || exit "$?"
fi

printf 'You are %s — read %s\n' "$name" "$persona_file"
printf 'Role: %s — read %s\n' "$role" "$role_file"
printf 'Then follow that role doc to orient, and announce yourself in one line (e.g. "%s — %s.").\n' "$name" "$role"
