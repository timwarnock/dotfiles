#!/bin/sh
# list-personas.sh — list available personas: name and one-line description.
# A persona is a file references/personas/<Name>.md whose first line is its
# description.
# Usage: list-personas.sh

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
personas_dir="$script_dir/../references/personas"

if [ ! -d "$personas_dir" ]; then
    printf 'list-personas.sh: no personas directory: %s\n' "$personas_dir" >&2
    exit 1
fi

found=0
for f in "$personas_dir"/*.md; do
    [ -e "$f" ] || continue
    found=1
    name=$(basename -- "$f" .md)
    IFS= read -r desc < "$f" || desc=''
    printf '%s\t%s\n' "$name" "$desc"
done

[ "$found" -eq 1 ] || printf 'list-personas.sh: no personas found in %s\n' "$personas_dir" >&2
