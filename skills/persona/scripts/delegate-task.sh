#!/bin/sh

if [ "$#" -ne 1 ]; then
    printf 'Usage: delegate-task.sh <persona-name>\n' >&2
    exit 1
fi

name="$1"

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
send="$script_dir/tmux-send.sh"

rm -f "thoughts/$name.done"

sh "$send" "$name" "/clear" || exit "$?"
sh "$send" "$name" "/persona $name" || exit "$?"
