#!/bin/sh
# test-tmux-send.sh — behavioral tests for tmux-send.sh. Mocks `tmux` with a
# PATH shim and asserts the send contract: the target resolves (by pane index
# and by persona name) and the message is delivered as TWO writes — first the
# literal text via send-keys -l (NO trailing CR), then a separate interpreted
# Enter key. The split is deliberate: -l sends CR as a literal byte that never
# submits, so Enter must be a distinct send-keys call. No real tmux required.
# mktemp's trailing-X template form works on macOS (BSD) and Linux (GNU).
# Usage: test-tmux-send.sh   (exit 0 = all passed)

set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
real="$script_dir/tmux-send.sh"
work=$(mktemp -d "${TMPDIR:-/tmp}/tmux-send-test.XXXXXX")
trap 'rm -rf "$work"' EXIT INT TERM

fails=0
bindir="$work/bin"
mkdir -p "$bindir"

# Fake tmux: resolves panes for both -F formats tmux-send.sh uses; logs each
# send-keys invocation, one arg per [bracket], to $TMUX_SEND_LOG.
cat > "$bindir/tmux" <<'EOF'
#!/bin/sh
cmd="$1"; shift
case "$cmd" in
    list-panes)
        fmt=
        while [ "$#" -gt 0 ]; do
            case "$1" in -F) fmt="$2"; shift 2 ;; *) shift ;; esac
        done
        case "$fmt" in
            *@persona*)   printf '%%0 [ Fred ]\n%%5 [ Ed ]\n' ;;
            *pane_index*) printf '0 %%0\n5 %%5\n' ;;
        esac ;;
    send-keys)
        { printf 'SENDKEYS'; for a in "$@"; do printf ' [%s]' "$a"; done; printf '\n'; } \
            >> "$TMUX_SEND_LOG" ;;
esac
exit 0
EOF
chmod +x "$bindir/tmux"

check() {  # check <desc> <expected> <actual>
    if [ "$2" = "$3" ]; then printf 'ok   - %s\n' "$1"
    else printf 'FAIL - %s\n        expected: [%s]\n        actual:   [%s]\n' "$1" "$2" "$3"
        fails=$((fails + 1)); fi
}

# 1. Numeric target: two writes — literal message (no trailing CR), then Enter.
LOG="$work/log1"; : > "$LOG"
PATH="$bindir:$PATH" TMUX=fake TMUX_PANE=%5 TMUX_SEND_LOG="$LOG" sh "$real" 5 hello world
check "numeric: exit 0" 0 "$?"
check "numeric: exactly two send-keys calls (not one)" 2 "$(grep -c SENDKEYS "$LOG")"
seen=$(tr '\r' '#' < "$LOG")
case "$seen" in *'[-l]'*) v=yes ;; *) v=no ;; esac
check "numeric: literal (-l) flag present" yes "$v"
case "$(tr '\r' '#' < "$LOG" | sed -n '1p')" in *'[hello world]'*) v=yes ;; *) v=no ;; esac
check "numeric: first write is literal message, no trailing CR" yes "$v"
case "$(sed -n '2p' "$LOG")" in *'[Enter]'*) v=yes ;; *) v=no ;; esac
check "numeric: separate Enter sent as second write" yes "$v"

# 2. Persona-name target resolves and sends two writes: literal then Enter.
LOG="$work/log2"; : > "$LOG"
PATH="$bindir:$PATH" TMUX=fake TMUX_PANE=%5 TMUX_SEND_LOG="$LOG" sh "$real" Ed ping
check "name: exit 0" 0 "$?"
check "name: exactly two send-keys calls" 2 "$(grep -c SENDKEYS "$LOG")"
case "$(tr '\r' '#' < "$LOG" | sed -n '1p')" in *'[ping]'*) v=yes ;; *) v=no ;; esac
check "name: first write is literal message, no trailing CR" yes "$v"

# 3. Not inside tmux: exit 1, no send.
LOG="$work/log3"; : > "$LOG"
PATH="$bindir:$PATH" TMUX= TMUX_SEND_LOG="$LOG" sh "$real" 5 hi >/dev/null 2>&1
check "no tmux: exit 1" 1 "$?"
check "no tmux: no send" 0 "$(grep -c SENDKEYS "$LOG")"

# 4. Too few args: usage on stderr, exit 1.
LOG="$work/log4"; : > "$LOG"
err=$(PATH="$bindir:$PATH" TMUX=fake TMUX_PANE=%5 TMUX_SEND_LOG="$LOG" sh "$real" 5 2>&1 1>/dev/null)
check "few args: exit 1" 1 "$?"
case "$err" in Usage:*) v=yes ;; *) v=no ;; esac
check "few args: usage on stderr" yes "$v"

if [ "$fails" -eq 0 ]; then printf '\nall tests passed\n'; exit 0; fi
printf '\n%d test(s) failed\n' "$fails" >&2
exit 1
