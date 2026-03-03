# Contributing to viewim

Thanks for contributing.

## Branch strategy

- `main`: always stable and releasable.
- `feature/*`: new features and enhancements.
- `fix/*`: regular bug fixes.
- `hotfix/*`: urgent fixes for released versions.

Examples:

- `feature/search-image-backend`
- `fix/markdown-reference-parse`
- `hotfix/kitty-socket-retry`

## Development flow

1. Start from latest `main`.
2. Create a short-lived branch.
3. Make small, focused commits.
4. Open a pull request to `main`.
5. Wait for CI and review before merge.

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
