#!/bin/sh
# list-personas.sh — list this skill's personas: name + one-line description (the first
# line of each references/personas/<Name>.md). Run by the SKILL.md dispatch (no-arg).
# Self-contained: reads team's own personas, no external skill.
set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
personas_dir="$script_dir/../../references/personas"

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
