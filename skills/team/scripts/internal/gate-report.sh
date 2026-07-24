#!/bin/sh
# gate-report.sh — the gatekeeper runs THIS to emit its verdict to a file. Scripts touch
# files; the LLM only runs this (D3). Internal.
# Usage: gate-report.sh <verdict-file> <PASS|FAIL> [reason...]
set -u

[ "$#" -ge 2 ] || { printf 'usage: gate-report.sh <verdict-file> <PASS|FAIL> [reason...]\n' >&2; exit 1; }

vf=$1
verdict=$2
shift 2
reason=$*

case "$verdict" in
    PASS|FAIL) : ;;
    *) reason="unparseable verdict '$verdict' -> FAIL (closed); $reason"; verdict=FAIL ;;
esac

printf '%s %s\n' "$verdict" "$reason" > "$vf"
