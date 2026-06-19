# 🖼️ ViewIm: View Image

Fast image preview for Neovim with a launcher-first approach.

`ViewIm` is designed for people who want practical image preview workflows without running a full inline image rendering engine inside Neovim.

<!-- Demo GIF coming soon -->

## 🎯 Key Differentiation

| | ViewIm | image.nvim | snacks.image |
|---|---|---|---|
| Approach | Launcher-first (opens image in terminal pane/OS viewer) | Inline rendering via terminal protocols | Inline rendering via terminal protocols |
| Neovim footprint | Minimal (no persistent renderer process) | Heavier (persistent backend) | Heavier (persistent backend) |
| Backends | kitty, wezterm, ghostty, iTerm2 | kitty, wezterm, ueberzugpp | kitty, wezterm |
| SVG support | Yes (via rsvg-convert / magick) | No | No |
| Remote URLs | Yes (curl, cached) | No | No |
| Explorer integration | nvim-tree, oil, neo-tree | No | No |
| Markdown at-cursor | Yes | No | Partial |

ViewIm is not a replacement for image.nvim or snacks.image if you want images to appear inline in the document. It is the right tool if you want a fast, low-footprint preview workflow from your file explorer or cursor.

## 🧭 When To Use ViewIm

- You use `nvim-tree`, `oil`, or `neo-tree` and want quick preview.
- You want markdown/html image preview at cursor with a simple command/keymap.
- You want remote URL previews with guardrails.
- You prefer low dependency footprint and straightforward debugging.
- You are on iTerm2, Ghostty, Kitty, or WezTerm.

## ⚡ Features

- Explorer integrations (`nvim-tree`, `oil`, `neo-tree`) + buffer fallback.
- `:ViewImageAtCursor` for markdown/html image sources:
  - `![alt](path-or-url)` and `![](<path with spaces>)`
  - `![alt][id]` with `[id]: ...`
  - `<img src="...">` single-line and multi-line
- Nearest-source fallback near cursor (bounded local scan).
- Remote previews via `curl` (`timeout`, `max_bytes`, `cache_dir`, `require_https`).
- Cache cleanup via `:ViewimCleanCache` (age and size limits).
- SVG support via `rsvg-convert` or `magick`.
- Runtime controls: enable/disable/toggle/status.
- Optional explorer auto-preview and markdown auto-preview (both off by default).
- Placement controls (`wezterm` split options, ghostty tmux split options).
- Experimental internal render mode for kitty with safe fallback.
- Security-focused boundaries (control-char path rejection, URL scheme restrictions).

## 🔐 Requirements

- Neovim >= 0.9
- One terminal backend:
  - **kitty** — full pane control via kitten icat
  - **WezTerm** — imgcat via wezterm CLI
  - **Ghostty** — external OS viewer or tmux pane mode
  - **iTerm2** — imgcat via iTerm2 shell integration
- Optional:
  - `curl` for remote URL previews
  - `tmux` for `ghostty.mode = "tmux"`
  - `rsvg-convert` or `magick` (ImageMagick) for SVG support
  - `telescope.nvim`, `snacks.nvim`, or `fzf-lua` for enhanced image search picker

> **Ghostty note:** in `external` mode (the default), previews open in the system viewer (`open` / `xdg-open`). There is no split-pane. Use `ghostty.mode = "tmux"` for a side-by-side pane. The `<Space>` (`large_preview`) action behaves identically to normal preview in `external` mode.

> **iTerm2 note:** requires `imgcat` from iTerm2 shell integration. Install via *iTerm2 → Install Shell Integration* or run `~/.iterm2/install_shell_integration.bash`. Alternatively `brew install iterm2-imgcat` if available.

## 📦 Installation

### lazy.nvim (recommended)

```lua
{
  "kogungor/viewim",
  opts = {
    keymap = "<leader>p",
    cursor_keymap = "<leader>wi",
  },
}
```

Full setup with explicit config function:

```lua
{
  "kogungor/viewim",
  config = function()
    require("viewim").setup({
      keymap = "<leader>p",
      cursor_keymap = "<leader>wi",
    })
  end,
}
```

### packer.nvim

```lua
use {
  "kogungor/viewim",
  config = function()
    require("viewim").setup({
      keymap = "<leader>p",
      cursor_keymap = "<leader>wi",
    })
  end,
}
```

## ⚙️ Minimal Configuration

```lua
require("viewim").setup({
  quiet_warnings = false,
  keymap = "<leader>p",         -- explorer preview
  cursor_keymap = "<leader>wi", -- markdown/html at-cursor preview

  -- Override terminal auto-detection (useful in SSH, tmux, sudo contexts)
  -- force_terminal = "kitty",  -- "kitty"|"wezterm"|"ghostty"|"iterm2"

  preview_placement = {
    direction = "bottom",       -- right|left|top|bottom (global preference)
  },

  kitty = {
    listen_on = "unix:/tmp/kitty-viewim.sock",
    launch_type = "window",     -- os-window | tab | window
  },

  markdown_auto_preview = {
    enabled = false,
    debounce_ms = 220,
  },

  remote = {
    enabled = true,
    timeout_ms = 10000,
    max_bytes = 10485760,
    cache_dir = vim.fn.stdpath("cache") .. "/viewim/remote",
    require_https = false,
    max_age_days = 30,         -- 0 = disabled
    max_cache_bytes = 0,       -- 0 = disabled
  },

  svg = {
    enabled = true,
    converter = "auto",        -- "auto"|"rsvg-convert"|"magick"
  },

  search = {
    enabled = true,
    preferred_picker = "auto", -- auto|telescope|snacks|fzflua|builtin
    max_results = 500,
    include_hidden = false,
    selection_preview = true,
    selection_preview_debounce_ms = 120,
    space_action = "large_preview",
  },
})
```

## 🚀 Common Usage

- `:ViewImage` → preview from explorer/buffer context
- `:ViewImage /path/to/file.png` → preview explicit path
- `:ViewImage https://example.com/image.png` → preview remote URL
- `:ViewImageAtCursor` → preview markdown/html image source under cursor
- `:SearchImage [query]` → search project images and preview selected result
- `:ViewimCleanCache` → remove cached remote images by age/size
- `:ViewImageEnable`, `:ViewImageDisable`, `:ViewImageToggle`, `:ViewImageStatus`
- `:checkhealth viewim`

## 🐱 Kitty Setup

Enable remote control in `kitty.conf`:

```conf
allow_remote_control yes
listen_on unix:/tmp/kitty-viewim.sock
```

Then mirror in viewim:

```lua
require("viewim").setup({
  kitty = {
    listen_on = "unix:/tmp/kitty-viewim.sock",
    launch_type = "window", -- os-window | tab | window
  },
})
```

Restart kitty after changing `kitty.conf`. Run `:checkhealth viewim` to verify the socket is found.

## 🖥️ WezTerm Setup

No extra configuration required — WezTerm is detected automatically via `$WEZTERM_PANE`. Control the preview pane with:

```lua
require("viewim").setup({
  wezterm = {
    split_direction = "right", -- left|right|top|bottom
    split_percent = 50,        -- optional pane size 1..99
  },
})
```

## 👻 Ghostty Setup

Ghostty opens previews in external mode by default (`open` / `xdg-open`). For an in-terminal pane, use tmux mode:

```lua
require("viewim").setup({
  ghostty = {
    mode = "tmux",                   -- "external" (default) | "tmux"
    tmux_split_direction = "right",  -- left|right|top|bottom
    tmux_split_percent = 40,
    tmux_command = "kitten icat --hold",
  },
})
```

> **Security note:** `ghostty.tmux_command` is passed directly to `tmux new-window`. Do not set this to user-controlled input.

## 🍎 iTerm2 Setup

iTerm2 is detected automatically via `TERM_PROGRAM=iTerm.app`. Install shell integration to get `imgcat`:

```sh
curl -L https://iterm2.com/shell_integration/install_shell_integration.bash | bash
```

Then restart your shell. Verify with `:checkhealth viewim`.

To force iTerm2 even when the env var is absent:

```lua
require("viewim").setup({
  force_terminal = "iterm2",
})
```

## 🔍 Search Picker Backends

`:SearchImage` auto-selects the best available picker:

| Backend | `on_change` preview | `<Space>` action | Notes |
|---|---|---|---|
| telescope | ✓ | ✓ | Recommended — full feature set |
| snacks | ✓ (picker.pick API) | ✓ | Requires recent snacks.nvim |
| fzf-lua | ✓ | ✓ | Debounced preview via fzf preview hook |
| builtin | — | — | `vim.ui.select`, always available |

Force a specific backend:

```lua
search = { preferred_picker = "fzflua" }
```

## 📚 Full Docs

- Vim help: `:help viewim` (after helptags are generated by your plugin manager)
- Vimdoc file: `doc/viewim.txt`

## 📜 License

MIT
