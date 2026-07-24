#!/bin/sh
# test-delegate-task.sh — hermetic behavioral tests for delegate-task.sh.
# Runs delegate-task.sh against a fake tmux-send.sh in a temp directory and
# asserts the calls it makes: target, commands, ordering, arg validation,
# abort-on-failure. No tmux required. mktemp is not POSIX; the trailing-X
# template form used here works on macOS (BSD) and Linux (GNU). Each case runs
# delegate-task.sh with cwd in its sandbox: the script removes a cwd-relative
# thoughts/<name>.done, so it must never run against the real working tree.
# Usage: test-delegate-task.sh   (exit 0 = all passed)

set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
real="$script_dir/delegate-task.sh"
work=$(mktemp -d "${TMPDIR:-/tmp}/delegate-test.XXXXXX")
trap 'rm -rf "$work"' EXIT INT TERM

fails=0
n=0

# sandbox — fresh dir holding delegate-task.sh and a fake tmux-send.sh; echoes
# its path. The fake logs "target|message" per call to $DELEGATE_TEST_LOG and
# exits 1 on every call when $DELEGATE_TEST_FAIL is non-empty.
sandbox() {
    n=$((n + 1))
    d="$work/case$n"
    mkdir -p "$d"
    cp "$real" "$d/delegate-task.sh"
    cat > "$d/tmux-send.sh" <<'EOF'
#!/bin/sh
t="$1"; shift
printf '%s|%s\n' "$t" "$*" >> "$DELEGATE_TEST_LOG"
[ -n "${DELEGATE_TEST_FAIL:-}" ] && exit 1
exit 0
EOF
    printf '%s\n' "$d"
}

check() {  # check <desc> <expected> <actual>
    if [ "$2" = "$3" ]; then
        printf 'ok   - %s\n' "$1"
    else
        printf 'FAIL - %s\n        expected: [%s]\n        actual:   [%s]\n' "$1" "$2" "$3"
        fails=$((fails + 1))
    fi
}

# 1. Happy path: two sends — clear then re-instantiate — correct args, in order.
#    There is no poke; the worker reads its .task on orient (SKILL.md step 5).
d=$(sandbox)
log="$d/log"; : > "$log"
( cd "$d" && DELEGATE_TEST_LOG="$log" sh "$d/delegate-task.sh" Ed )
check "happy: exit 0" 0 "$?"
expected='Ed|/clear
Ed|/persona Ed'
check "happy: clear then persona — in order, verbatim" "$expected" "$(cat "$log")"

# 2. No arguments: usage on stderr, exit 1, no sends.
d=$(sandbox)
log="$d/log"; : > "$log"
err=$(cd "$d" && DELEGATE_TEST_LOG="$log" sh "$d/delegate-task.sh" 2>&1 1>/dev/null)
check "no args: exit 1" 1 "$?"
case "$err" in Usage:*) u=yes ;; *) u=no ;; esac
check "no args: usage on stderr" yes "$u"
check "no args: no sends" "" "$(cat "$log")"

# 3. Extra arguments: the script takes exactly one — the persona name. A stray
#    second argument (e.g. an old-style poke) is misuse: usage, exit 1, no sends.
d=$(sandbox)
log="$d/log"; : > "$log"
err=$(cd "$d" && DELEGATE_TEST_LOG="$log" sh "$d/delegate-task.sh" Ed "[Fred] stray poke" 2>&1 1>/dev/null)
check "extra args: exit 1" 1 "$?"
case "$err" in Usage:*) u=yes ;; *) u=no ;; esac
check "extra args: usage on stderr" yes "$u"
check "extra args: no sends" "" "$(cat "$log")"

# 4. Abort on failure: first send fails, the second is not attempted.
d=$(sandbox)
log="$d/log"; : > "$log"
( cd "$d" && DELEGATE_TEST_FAIL=1 DELEGATE_TEST_LOG="$log" sh "$d/delegate-task.sh" Ed ) >/dev/null 2>&1
check "abort: non-zero exit" 1 "$?"
check "abort: only the first send was attempted" 1 "$(grep -c . "$log")"

# 5. Re-instantiation clears a stale .done but keeps the incoming .task.
#    /persona orients on thoughts/<name>.{task,done}; a leftover .done from the
#    previous task would make the fresh worker read "done, awaiting review" and
#    idle on a live task. delegate-task.sh must remove the .done (cwd-relative —
#    the path /persona reads) and must NOT touch the new .task the manager wrote.
d=$(sandbox)
log="$d/log"; : > "$log"
mkdir -p "$d/thoughts"
: > "$d/thoughts/Ed.done"   # stale result from the previous task
: > "$d/thoughts/Ed.task"   # incoming task, written before delegating
( cd "$d" && DELEGATE_TEST_LOG="$log" sh "$d/delegate-task.sh" Ed )
if [ -e "$d/thoughts/Ed.done" ]; then ds=present; else ds=gone; fi
check "retask: stale .done removed" gone "$ds"
if [ -e "$d/thoughts/Ed.task" ]; then ts=present; else ts=gone; fi
check "retask: incoming .task preserved" present "$ts"
expected='Ed|/clear
Ed|/persona Ed'
check "retask: 2 sends still fire, in order" "$expected" "$(cat "$log")"

if [ "$fails" -eq 0 ]; then
    printf '\nall tests passed\n'
    exit 0
fi
printf '\n%d test(s) failed\n' "$fails" >&2
exit 1
