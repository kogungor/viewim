# viewim

Preview images directly from Neovim file explorers in your terminal.

Works with **kitty**, **wezterm**, and **Ghostty**.

- kitty / wezterm: opens image previews in a separate terminal window/pane
- Ghostty: opens image previews in your OS native image viewer

## Features

- Preview images from **nvim-tree**, **oil.nvim**, and **neo-tree**
- Preview image files open in the **current buffer**
- Terminal auto-detection (kitty / wezterm / ghostty)
- Configurable keymap
- `:ViewImage` command with optional path argument
- `:checkhealth viewim` to verify your setup
- Supported formats: `bmp`, `jpg`, `jpeg`, `png`, `gif`, `webp`
- Safer execution path: argv-based process launching and control-character path rejection

## Requirements

- Neovim >= 0.9
- One of:
  - [kitty](https://sw.kovidgoyal.net/kitty/) terminal (uses `kitten icat`)
  - [wezterm](https://wezfurlong.org/wezterm/) terminal (uses `wezterm imgcat`)
  - [Ghostty](https://ghostty.org/) terminal (opens images in your OS native viewer)
- At least one file explorer (optional):
  - [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua)
  - [oil.nvim](https://github.com/stevearc/oil.nvim)
  - [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim)

### Kitty Setup (Required for kitty users)

If you use kitty, remote control must be enabled and reachable from Neovim.

Add this to your `kitty.conf` (usually `~/.config/kitty/kitty.conf`):

```conf
allow_remote_control yes
listen_on unix:/tmp/kitty-viewim.sock
```

Then configure viewim with the same socket:

```lua
require("viewim").setup({
  kitty = {
    listen_on = "unix:/tmp/kitty-viewim.sock",
    launch_type = "tab", -- recommended for first setup/debug
  },
})
```

Restart kitty after editing `kitty.conf`.

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "kogungor/viewim",
  config = function()
    require("viewim").setup()
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "kogungor/viewim",
  config = function()
    require("viewim").setup()
  end,
}
```

### Manual

Clone into your Neovim packages directory:

```sh
git clone https://github.com/kogungor/viewim.git \
  ~/.local/share/nvim/site/pack/plugins/start/viewim
```

Then add to your config:

```lua
require("viewim").setup()
```

## Configuration

`setup()` accepts an optional table. All values below are defaults:

```lua
require("viewim").setup({
  keymap = "<leader>p",
  supported_extensions = {
    ".bmp", ".jpg", ".jpeg", ".png", ".gif", ".webp",
  },
  integrations = {
    nvim_tree = true,
    oil = true,
    neo_tree = true,
  },
  kitty = {
    listen_on = nil,
    launch_type = "os-window",
  },
  ghostty = {
    mode = "external",
    opener = "auto",
  },
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `keymap` | `string` | `"<leader>p"` | Key to trigger image preview in file explorers |
| `supported_extensions` | `table` | see above | List of image file extensions to recognize |
| `integrations.nvim_tree` | `bool` | `true` | Enable nvim-tree keymap |
| `integrations.oil` | `bool` | `true` | Enable oil.nvim keymap |
| `integrations.neo_tree` | `bool` | `true` | Enable neo-tree keymap |
| `kitty.listen_on` | `string\|nil` | `nil` | Kitty remote socket (fallback to `$KITTY_LISTEN_ON`) |
| `kitty.launch_type` | `string` | `"os-window"` | Kitty launch target (`os-window`, `tab`, `window`) |
| `ghostty.mode` | `string` | `"external"` | Ghostty preview mode (currently `external`) |
| `ghostty.opener` | `string` | `"auto"` | External opener command (`auto`, `open`, `xdg-open`, or custom) |

Notes:
- `supported_extensions` entries are normalized to lowercase; both `"png"` and `".png"` are accepted.
- Invalid extension entries are ignored with a warning.
- Invalid `kitty.launch_type` falls back to `"os-window"` with a warning.
- Unsupported `ghostty.mode` falls back to `"external"` with a warning.

## Usage

### From a file explorer

1. Open nvim-tree, oil.nvim, or neo-tree
2. Navigate to an image file
3. Press `<leader>p` (or your configured keymap)
4. The image opens in a new terminal window/pane

### From any buffer

Run the command:

```
:ViewImage
```

If the current buffer is an image file, it previews it.

You can also pass an explicit path:

```
:ViewImage /path/to/image.png
```

If a path contains control characters (for example newline or NUL bytes), viewim rejects it before command execution.

## Health Check

Run `:checkhealth viewim` to verify:

- Terminal emulator detected
- CLI tools (`kitten` / `wezterm`) available in `$PATH`
- Kitty remote socket available (for kitty)
- Native opener available (for ghostty)
- Optional integrations loadable

If `KITTY_LISTEN_ON` is empty, set `kitty.listen_on` in `setup()` as shown above.

## How It Works

- **kitty** — runs `kitty @ launch --type=os-window --cwd=current --hold -- kitty +kitten icat <file>`
  to open the image in a new kitty OS window.
- **wezterm** — runs `wezterm cli split-pane -- wezterm imgcat <file>`
  to open the image in a new wezterm pane.
- **ghostty** — opens the image with your OS native viewer:
  - macOS: `open <file>`
  - Linux: `xdg-open <file>`
  - Windows: `explorer.exe <file>`

## Architecture

`viewim` is split into small modules by responsibility:

- `plugin/viewim.lua` — registers `:ViewImage`
- `lua/viewim/init.lua` — public API (`setup`, `view`) and integration keymaps
- `lua/viewim/config.lua` — defaults, merge, and config normalization/validation
- `lua/viewim/path.lua` — path resolution and control-character checks
- `lua/viewim/preview.lua` — orchestration (`validate -> detect terminal -> dispatch`)
- `lua/viewim/detect.lua` — terminal/platform/command detection helpers
- `lua/viewim/runners/{kitty,wezterm,ghostty}.lua` — terminal-specific command runners
- `lua/viewim/integrations/{nvim_tree,oil,neo_tree,buffer}.lua` — file explorer adapters
- `lua/viewim/health.lua` — `:checkhealth viewim` diagnostics

Runtime flow:

1. User runs `:ViewImage` or presses the integration keymap.
2. Integration resolves a candidate file path.
3. `preview.lua` validates/sanitizes the path.
4. Terminal is detected.
5. Matching runner executes the preview command.

## License

MIT
