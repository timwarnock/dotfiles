# Procedure: Jira tickets

Use the `jira` CLI (`~/bin/jira`, v1.7.0). Do not use MCP tools for Jira.

Note: v1.7.0 does not support `ORDER BY` in JQL queries — omit it from `--jql` strings.

- User: `tim.warnock@nydig.com`
- Default project: `ME` (Mining Engineering)
- Board: `634` (Mining Engineering Sprint, scrum)

## Read: my active-sprint tickets

```sh
sh ~/.claude/skills/persona/scripts/jira-sprint-mine.sh
```

Prints `KEY  STATUS  SUMMARY` (tab-separated) for issues assigned to the
authenticated user in the active sprint. Prints `No active sprint.` and stops
when there is no active sprint — no fallback, no further querying.

## Create a ticket

1. Create the issue (assigned to the user, `--no-input` to skip prompts):
   ```sh
   jira issue create -tTask -s"Summary here" -b"Description here" \
       -a"tim.warnock@nydig.com" --no-input
   ```
2. Find the active sprint:
   ```sh
   jira sprint list --state active --plain --no-headers --columns ID
   ```
3. Add the new issue to the active sprint:
   ```sh
   jira sprint add <SPRINT_ID> <ISSUE-KEY>
   ```

## Conventions

- Assign to `tim.warnock@nydig.com` unless told otherwise.
- Add to the active sprint if one exists.
- Use `--no-input` to avoid interactive prompts.
- Use `-tTask` unless told otherwise (Bug, Story, …).
- Print the issue key and URL when done.
