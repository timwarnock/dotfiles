#!/bin/sh
# load-env.sh — single home for the team `.env` path. SOURCE this (do not run it):
#     . "$dir/../internal/load-env.sh"
# It loads ~/.claude/.env into the current shell so callers can read team config
# (e.g. TEAM_JIRA_BOARD). The file need not exist — when absent this is a no-op and
# callers simply see unset vars (degrade gracefully, never error). $TEAM_ENV_FILE
# overrides the path (used by tests). Internal; never called by an LLM.
TEAM_ENV_FILE="${TEAM_ENV_FILE:-$HOME/.claude/.env}"
# shellcheck source=/dev/null
[ -f "$TEAM_ENV_FILE" ] && . "$TEAM_ENV_FILE"
