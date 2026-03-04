# ViewIm Manual Testing Playground

This folder provides reproducible fixture content for trying `viewim` features.

## Quick start

1. Generate local image fixtures:

```sh
python3 test/scripts/generate_test_images.py
```

2. Open Neovim at repo root.
3. Run `:checkhealth viewim`.
4. Open files under `test/fixtures/` and run commands below.

## Core command checks

- `:ViewImage test/fixtures/images/pixel.png`
- `:ViewImage test/fixtures/images/pixel.gif`
- `:ViewImage test/fixtures/images/pixel.bmp`
- `:ViewImageAtCursor` inside markdown/html fixture files
- `:SearchImage pixel` (should list generated files)
- `:ViewImageDisable` -> preview commands should be blocked
- `:ViewImageEnable` -> previews should work again
- `:ViewImageStatus` -> verify terminal and state

## Cursor parsing checks

Use consolidated fixture files so you do not need to switch often:

- `test/fixtures/markdown/all_cases.md`
- `test/fixtures/html/all_cases.html`

Open a file, place cursor on/near each image syntax example section, and run `:ViewImageAtCursor`.

Expected coverage in markdown file:
- Inline markdown resolves.
- Reference markdown resolves.
- Multiline `<img>` resolves.
- Root-relative path mapping resolves from repo root cwd.
- Remote URL resolves through download path.
- Nearest-source fallback works when cursor is not exactly on path.

## Search checks

- Run `:SearchImage` (no query) and verify picker opens.
- Move selection and confirm selection-preview behavior.
- Press `<Space>` and verify alternate action behavior for your terminal backend.

## Remote URL checks

Use `:ViewImage` with a remote PNG URL, for example:

```vim
:ViewImage https://raw.githubusercontent.com/github/explore/main/topics/neovim/neovim.png
```

Expected:
- Download + preview succeeds when `remote.enabled=true` and `curl` exists.
- If `remote.require_https=true`, `http://` URLs are rejected.

## Explorer checks

Use your explorer plugin (`nvim-tree`, `oil`, `neo-tree`) on `test/fixtures/explorer/`.

- Trigger preview keymap on image entries.
- Test nested directories.
- Optionally test hidden files if your explorer shows them.

## Notes

- Generated local fixtures currently cover: `.png`, `.gif`, `.bmp`.
- `.webp` and `.avif` remain environment-dependent and are best tested with your own sample files.

## Tiny backend matrix checklist

Use this quick pass/fail matrix per environment.

Legend: `Y` = works, `P` = partial/limited, `N/A` = not applicable

| Feature | kitty | wezterm | ghostty external | ghostty tmux |
|---|---|---|---|---|
| `:ViewImage` local file | [ ] Y | [ ] Y | [ ] Y | [ ] Y |
| `:ViewImageAtCursor` markdown/html | [ ] Y | [ ] Y | [ ] Y | [ ] Y |
| `:SearchImage` picker open/select | [ ] Y | [ ] Y | [ ] Y | [ ] Y |
| Selection-change preview in picker* | [ ] Y/P | [ ] Y/P | [ ] Y/P | [ ] Y/P |
| `<Space>` alt action (`large_preview`) | [ ] Y | [ ] Y | [ ] P | [ ] Y |
| Remote URL preview (`curl`) | [ ] Y | [ ] Y | [ ] Y | [ ] Y |
| Explorer keymap preview | [ ] Y | [ ] Y | [ ] Y | [ ] Y |
| Explorer auto-preview (if enabled) | [ ] Y | [ ] Y | [ ] Y | [ ] Y |
| Runtime controls (enable/disable/status) | [ ] Y | [ ] Y | [ ] Y | [ ] Y |
| Experimental internal render | [ ] Y | [ ] N/A | [ ] N/A | [ ] N/A |

\* Depends on picker backend: telescope supports selection-change preview, snacks/builtin are more limited.
