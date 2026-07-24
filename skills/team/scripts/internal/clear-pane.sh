#!/bin/sh
# clear-pane.sh <pane-index|name> <model> — reset another pane in THIS tmux window to a
# known-good state: flush the pane (interrupt a running turn, empty the input line),
# /clear the conversation, then stamp the model with /model <model> and VERIFY the stamp
# landed before returning. Every reset leaves the pane on an explicitly named model, so no
# task inherits the previous task's model. The clear -> stamp -> verify half of the pane
# primitive: reinit-pane.sh pairs it with tmux-send.sh (single-line re-instantiation), the
# gate pairs it with tmux-paste.sh (paste a whole prompt). Internal.
#
# Flush (field-found, in order): Ctrl-C interrupts a running turn (and discards stray text
# on an idle pane) — but interrupting RESTORES the interrupted prompt into the input box,
# so Ctrl-U then empties the input line (harmless when already empty). Never a second
# Ctrl-C (a quick double press exits claude) and never Enter (it would submit stray text
# as a real prompt, or confirm a stray dialog).
#
# The verify is load-bearing (field-found): /model opens an interactive "Switch model?"
# dialog when the conversation is prompt-cached for the current model. A cleared pane has
# no conversation, so its /model is instant — but if the /clear were ever swallowed, that
# dialog would eat every later keystroke, and an Enter would CONFIRM a wrong switch. So:
# count visible "Set model to" confirmations, send /model, poll for the count to rise,
# watching for the dialog. Dialog or no new confirmation in 15s -> send Escape (backs out
# of the dialog: "Kept model as X"), confirm the dialog is gone, report, exit 1 —
# fail-closed, nothing further sent.
set -u

[ "$#" -eq 2 ] || { printf 'usage: clear-pane.sh <pane-index|name> <model>\n' >&2; exit 1; }

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target=$1
model=$2

pane=$(sh "$dir/resolve-pane.sh" "$target") || exit 1

# Flush (see header), then let the pane settle before typing at it.
tmux send-keys -t "$pane" C-c
sleep 2
tmux send-keys -t "$pane" C-u
sleep 1

sh "$dir/tmux-send.sh" "$target" "/clear" || exit "$?"

# Settle: let the pane finish processing /clear before the stamp (D8).
sleep 2

# Stamp + verify. The count is a delta, not a bare grep: a failed /clear can leave OLD
# "Set model to" confirmations visible, so only a NEW one proves this stamp executed.
before=$(tmux capture-pane -p -t "$pane" | grep -c 'Set model to')
sh "$dir/tmux-send.sh" "$target" "/model $model" || exit "$?"

deadline=$(( $(date +%s) + 15 ))
while [ "$(date +%s)" -lt "$deadline" ]; do
    snap=$(tmux capture-pane -p -t "$pane")
    after=$(printf '%s\n' "$snap" | grep -c 'Set model to')
    if [ "$after" -gt "$before" ]; then
        # Stamped and confirmed; brief settle so the next send lands in a ready input.
        sleep 1
        exit 0
    fi
    # The dialog will never confirm on its own — bail out now rather than at the deadline.
    printf '%s\n' "$snap" | grep -q 'Switch model?' && break
    sleep 1
done

# Fail-closed: back out of the dialog if one is up, verify it is gone, report, stop.
tmux send-keys -t "$pane" Escape
sleep 1
if tmux capture-pane -p -t "$pane" | grep -q 'Switch model?'; then
    printf 'clear-pane: %s did not confirm "/model %s", and its "Switch model?" dialog is STILL OPEN after Escape — stopped, nothing further sent. Look at the pane before retrying.\n' "$target" "$model" >&2
else
    printf 'clear-pane: %s did not confirm "/model %s" — stopped, nothing further sent (any model dialog was backed out). Look at the pane before retrying.\n' "$target" "$model" >&2
fi
exit 1
