# Conventional Commits

Because I keep forgetting to use these, here is a sensible commit message convention I should be using. By using this convention, commit log messages will read like a changelog.

```
type(optional scope): present-tense description
```


## Common Types

- `feat`: new feature for the user, not a new feature for build script
- `fix`: bug fix for the user, not a fix to a build script
- `docs`: change to the documentation
- `style`: formatting, missing semi colons, etc; no production code change
- `refactor`: refactoring production code, eg. renaming a variable
- `test`: adding missing tests, refactoring tests; no production code change
- `chore`: update build scripts, etc; no production code change


## Examples

```
feat: add FOO search
fix(search): change case, Foo not FOO
test(search): add additional Foo tests
chore(search): add CI deployment targets
feat: add MAB search algorithm chooser
refactor: breaking change, remove MAB and set Foo as default
docs(search): add README for Foo search
```

## References

- https://www.conventionalcommits.org/
- https://seesparkbox.com/foundry/semantic_commit_messages
