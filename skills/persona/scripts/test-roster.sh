#!/bin/sh
# test-roster.sh — behavioral tests for roster.sh. Mocks `tmux` with a PATH shim
# so no real tmux is needed. "available" cases run with cwd in a sandbox holding
# a fake thoughts/, the cwd-relative path roster.sh checks for .task/.done.
# mktemp's trailing-X template form works on macOS (BSD) and Linux (GNU).
# Usage: test-roster.sh   (exit 0 = all passed)

set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
real="$script_dir/roster.sh"
work=$(mktemp -d "${TMPDIR:-/tmp}/roster-test.XXXXXX")
trap 'rm -rf "$work"' EXIT INT TERM

fails=0
bindir="$work/bin"
mkdir -p "$bindir"

# Fake tmux: a fixed pane set, formatted for whichever -F roster.sh asks for.
#   0 Fred (manager) · 3 Joe · 4 Ed · 5 Kent (workers) · 6 no @persona.
# The all-mode format carries the #{?...} conditional and renders "-" when unset;
# the available-mode format renders the raw @persona (empty when unset).
cat > "$bindir/tmux" <<'EOF'
#!/bin/sh
cmd="$1"; shift
[ "$cmd" = list-panes ] || exit 0
fmt=
while [ "$#" -gt 0 ]; do case "$1" in -F) fmt="$2"; shift 2 ;; *) shift ;; esac; done
case "$fmt" in
    *'#{?'*)     printf '0 [ Fred ]\n3 [ Joe ]\n4 [ Ed ]\n5 [ Kent ]\n6 -\n' ;;
    *@persona*)  printf '0 [ Fred ]\n3 [ Joe ]\n4 [ Ed ]\n5 [ Kent ]\n6 \n' ;;
esac
EOF
chmod +x "$bindir/tmux"

check() {  # check <desc> <expected> <actual>
    if [ "$2" = "$3" ]; then printf 'ok   - %s\n' "$1"
    else printf 'FAIL - %s\n        expected: [%s]\n        actual:   [%s]\n' "$1" "$2" "$3"
        fails=$((fails + 1)); fi
}

# 1. No arg: every pane, verbatim, "-" for the persona-less pane.
out=$(PATH="$bindir:$PATH" TMUX=fake TMUX_PANE=%0 sh "$real")
check "all: exit 0" 0 "$?"
expected='0 [ Fred ]
3 [ Joe ]
4 [ Ed ]
5 [ Kent ]
6 -'
check "all: every pane verbatim" "$expected" "$out"

# 2. available: a worker is busy only while mid-task — a .task with no .done.
#    Joe is mid-task (.task, no .done) -> excluded. Kent finished (.task + .done)
#    -> available. Ed is idle (no files) -> available. Fred is pane 0 and pane 6
#    has no persona -> both excluded. Same "<index> <@persona>" lines, pane order.
box="$work/box1"; mkdir -p "$box/thoughts"
: > "$box/thoughts/Joe.task"                                  # mid-task
: > "$box/thoughts/Kent.task"; : > "$box/thoughts/Kent.done"  # finished
out=$(cd "$box" && PATH="$bindir:$PATH" TMUX=fake TMUX_PANE=%0 sh "$real" available)
check "available: exit 0" 0 "$?"
expected='4 [ Ed ]
5 [ Kent ]'
check "available: mid-task excluded; finished + idle kept; pane order" "$expected" "$out"

# 3. available: done-only is available too (finished, .task already retired), and
#    task-only is the one busy state. Joe has only a .done, Ed is mid-task, Kent
#    is idle -> Joe and Kent.
box="$work/box2"; mkdir -p "$box/thoughts"
: > "$box/thoughts/Joe.done"   # finished, .task already retired
: > "$box/thoughts/Ed.task"    # mid-task
out=$(cd "$box" && PATH="$bindir:$PATH" TMUX=fake TMUX_PANE=%0 sh "$real" available)
expected='3 [ Joe ]
5 [ Kent ]'
check "available: done-only available, task-only busy, pane order" "$expected" "$out"

# 4. Not inside tmux: exit 1, message on stderr, no listing.
err=$(PATH="$bindir:$PATH" TMUX= sh "$real" available 2>&1 1>/dev/null)
check "no tmux: exit 1" 1 "$?"
case "$err" in *'not inside tmux'*) v=yes ;; *) v=no ;; esac
check "no tmux: message on stderr" yes "$v"

# 5. Unknown argument: usage on stderr, exit 1.
err=$(PATH="$bindir:$PATH" TMUX=fake TMUX_PANE=%0 sh "$real" bogus 2>&1 1>/dev/null)
check "bad arg: exit 1" 1 "$?"
case "$err" in *Usage:*) v=yes ;; *) v=no ;; esac
check "bad arg: usage on stderr" yes "$v"

if [ "$fails" -eq 0 ]; then printf '\nall tests passed\n'; exit 0; fi
printf '\n%d test(s) failed\n' "$fails" >&2
exit 1
