# Procedure: Jira tickets

Use the `jira` CLI (v1.7.0, on the `PATH`). Do not use MCP tools for Jira.

Environment-specific values are not baked into this doc:

- The assignee is the authenticated user, from `jira me`.
- The `jira` CLI resolves its own project and board from its config.
- The project key lives in `.env` as `TEAM_JIRA_BOARD` (e.g. `ME`), used only to
  build the worktree ticket prefix.

`jira` v1.7.0 does not support `ORDER BY` in JQL — omit it from `--jql` strings.

## Read: my open tickets in the active sprint

```sh
sh ~/.claude/skills/team/scripts/manager/jira-sprint-tickets.sh
```

Prints `KEY  STATUS  SUMMARY` (tab-separated) for your open issues (status
category not Done) in the active sprint, or `No active sprint.` when there is
none — no fallback, no further querying.

## Read: worktree tickets

```sh
sh ~/.claude/skills/team/scripts/manager/get-worktrees.sh
```

Same columns for each worktree in flight under the repo's `.worktrees/` (repo
from `TEAM_REPO`), keyed by the `TEAM_JIRA_BOARD` prefix.

## Create a ticket

```sh
sh ~/.claude/skills/team/scripts/manager/jira-create.sh "<summary>" ["<body>"] ["<type>"]
```

Creates the issue assigned to `jira me`, adds it to the active sprint if one
exists, and prints `KEY<tab>URL`. The type defaults to `Task` — pass a third
argument for a `Bug`, `Story`, etc. With no active sprint the issue is still
created and a note goes to stderr.
