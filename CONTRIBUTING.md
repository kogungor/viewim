# Contributing to viewim

Thanks for contributing.

## Branch strategy

- `dev`: default integration branch for daily development.
- `main`: release/stable branch.
- `feature/*`: new features and enhancements.
- `fix/*`: regular bug fixes.
- `hotfix/*`: urgent fixes for released versions.

Examples:

- `feature/search-image-backend`
- `fix/markdown-reference-parse`
- `hotfix/kitty-socket-retry`

## Development flow

1. Start from latest `dev`.
2. Create a short-lived branch.
3. Make small, focused commits.
4. Open a pull request to `dev`.
5. Wait for CI and review before merge.

## Release flow

1. Land regular work into `dev`.
2. Open release PR from `dev` to `main`.
3. Tag release from `main` after merge.

## Commit messages

Keep messages clear and scoped. Prefer this style:

- `feat(search): add SearchImage backend`
- `fix(cursor): handle multiline img src`
- `docs(readme): clarify quick setup`

## Pull request checklist

- Feature or fix is scoped and tested.
- Documentation is updated if behavior changes.
- No unrelated refactors mixed in.
- Changelog entry added when user-visible.

## Local smoke checks

Run simple load checks:

```sh
nvim --headless -u NONE -i NONE \
  "+set rtp+=$PWD" \
  "+lua require('viewim').setup({})" \
  "+lua require('viewim.cursor')" \
  "+qa!"
```
