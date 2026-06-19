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

- Feature or fix is scoped and focused.
- Tests are added or updated (see below).
- Documentation is updated if behavior changes.
- No unrelated refactors mixed in.
- Changelog entry added when user-visible.

## Local checks

### Run unit tests

```sh
# Clone mini.nvim once (test dependency)
git clone --depth 1 https://github.com/echasnovski/mini.nvim /tmp/mini.nvim

# Run all tests
nvim --headless --noplugin -u test/minimal_init.lua -S test/run.lua 2>&1
```

### Lint

```sh
luacheck lua/ plugin/ --codes
```

### Format check

```sh
stylua --check lua/ plugin/ test/
# To auto-format:
stylua lua/ plugin/ test/
```

## Writing tests

Tests live in `test/*_spec.lua` and use [mini.test](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-test.md).

**Coverage scope** — the following modules have unit tests and should stay covered:

| File | Spec |
|---|---|
| `lua/viewim/url.lua` | `test/url_spec.lua` |
| `lua/viewim/path.lua` | `test/path_spec.lua` |
| `lua/viewim/config.lua` | `test/config_spec.lua` |
| `lua/viewim/cursor.lua` | `test/cursor_spec.lua` |
| `lua/viewim/search.lua` | `test/search_spec.lua` |

**When to write a test:**

- **New public function or normalize_* rule** → add a case to the relevant spec.
- **Bug fix** → add a failing test first that reproduces the bug, then fix it. The test name should describe the expected (correct) behavior.
- **New backend or integration** → unit tests are not required for terminal runners or picker backends, but any pure-Lua helpers they introduce should be tested.

**Mini.test basics:**

```lua
local MiniTest = require("mini.test")
local T = MiniTest.new_set()

T["description of what it should do"] = function()
  MiniTest.expect.equality(actual, expected)   -- deep equality
  MiniTest.expect.no_equality(actual, other)   -- must differ
  MiniTest.expect.error(function() ... end)    -- must throw
  MiniTest.expect.no_error(function() ... end) -- must not throw
end

return T
```
