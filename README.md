# 🖼️ ViewIm: View Image

Preview images directly from Neovim file explorers in your terminal.

Works with **kitty**, **wezterm**, and **Ghostty**.

- kitty / wezterm: opens image previews in a separate terminal window/pane
- Ghostty: opens image previews in your OS native image viewer

## ✨ Features

- Preview images from **nvim-tree**, **oil.nvim**, and **neo-tree**
- Preview image files open in the **current buffer**
- Terminal auto-detection (kitty / wezterm / ghostty)
- Configurable keyboard and optional mouse preview keymaps
- `:ViewImage` command with optional path argument
- Remote image preview via `:ViewImage https://...`
- Runtime controls: `:ViewImageEnable`, `:ViewImageDisable`, `:ViewImageToggle`, `:ViewImageStatus`
- Per-integration path resolver hooks (`resolve_path`) with safe fallback
- Optional debounced auto-preview while moving cursor in explorer buffers
- WezTerm split placement presets (direction and size percent)
- Experimental internal rendering mode for kitty with fallback to launcher mode
- `:checkhealth viewim` to verify your setup
- Supported formats: `bmp`, `jpg`, `jpeg`, `png`, `gif`, `webp`, `avif`
- Safer execution path: argv-based process launching and control-character path rejection

## 🔐 Requirements

- Neovim >= 0.9
- One of:
  - [kitty](https://sw.kovidgoyal.net/kitty/) terminal (uses `kitten icat`)
  - [wezterm](https://wezfurlong.org/wezterm/) terminal (uses `wezterm imgcat`)
  - [Ghostty](https://ghostty.org/) terminal (opens images in your OS native viewer)
- At least one file explorer (optional):
  - [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua)
  - [oil.nvim](https://github.com/stevearc/oil.nvim)
  - [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim)
- [curl](https://curl.se/) (required only for remote URL previews)

### 🐱 Kitty Setup (Required for kitty users)

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

## 📦 Installation

### 💤 [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "kogungor/viewim",
  config = function()
    require("viewim").setup()
  end,
}
```

### 🎒 [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "kogungor/viewim",
  config = function()
    require("viewim").setup()
  end,
}
```

### 🛠️ Manual

Clone into your Neovim packages directory:

```sh
git clone https://github.com/kogungor/viewim.git \
  ~/.local/share/nvim/site/pack/plugins/start/viewim
```

Then add to your config:

```lua
require("viewim").setup()
```

## ⚙️ Configuration

`setup()` accepts an optional table. All values below are defaults:

```lua
require("viewim").setup({
  enabled = true,
  keymap = "<leader>p",
  mouse_preview = {
    enabled = false,
    key = "<M-LeftMouse>",
  },
  explorer_auto_preview = {
    enabled = false,
    debounce_ms = 180,
    only_images = true,
  },
  supported_extensions = {
    ".bmp", ".jpg", ".jpeg", ".png", ".gif", ".webp", ".avif",
  },
  integrations = {
    nvim_tree = { enabled = true, resolve_path = nil },
    oil = { enabled = true, resolve_path = nil },
    neo_tree = { enabled = true, resolve_path = nil },
  },
  kitty = {
    listen_on = nil,
    launch_type = "os-window",
  },
  wezterm = {
    split_direction = "right", -- left|right|top|bottom
    split_percent = nil, -- 1..99 or nil
  },
  ghostty = {
    mode = "external",
    opener = "auto",
  },
  remote = {
    enabled = true,
    timeout_ms = 10000,
    max_bytes = 10485760,
    cache_dir = vim.fn.stdpath("cache") .. "/viewim/remote",
    require_https = false,
  },
  experimental = {
    internal_render = false,
  },
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `enabled` | `bool` | `true` | Enable or disable viewim previews globally |
| `keymap` | `string` | `"<leader>p"` | Key to trigger image preview in file explorers |
| `mouse_preview.enabled` | `bool` | `false` | Enable mouse-triggered preview in explorer buffers |
| `mouse_preview.key` | `string` | `"<M-LeftMouse>"` | Mouse keymap used for preview when enabled |
| `explorer_auto_preview.enabled` | `bool` | `false` | Auto-preview on cursor movement in explorer buffers |
| `explorer_auto_preview.debounce_ms` | `number` | `180` | Debounce delay for auto-preview triggers |
| `explorer_auto_preview.only_images` | `bool` | `true` | Skip non-image entries when auto-previewing |
| `supported_extensions` | `table` | see above | List of image file extensions to recognize |
| `integrations.nvim_tree.enabled` | `bool` | `true` | Enable nvim-tree keymap |
| `integrations.oil.enabled` | `bool` | `true` | Enable oil.nvim keymap |
| `integrations.neo_tree.enabled` | `bool` | `true` | Enable neo-tree keymap |
| `integrations.<name>.resolve_path` | `function\|nil` | `nil` | Optional hook to rewrite selected path before preview |
| `kitty.listen_on` | `string\|nil` | `nil` | Kitty remote socket (fallback to `$KITTY_LISTEN_ON`) |
| `kitty.launch_type` | `string` | `"os-window"` | Kitty launch target (`os-window`, `tab`, `window`) |
| `wezterm.split_direction` | `string` | `"right"` | WezTerm split direction (`left`, `right`, `top`, `bottom`) |
| `wezterm.split_percent` | `number\|nil` | `nil` | Optional pane size percentage (`1..99`) |
| `ghostty.mode` | `string` | `"external"` | Ghostty preview mode (currently `external`) |
| `ghostty.opener` | `string` | `"auto"` | External opener command (`auto`, `open`, `xdg-open`, or custom) |
| `remote.enabled` | `bool` | `true` | Enable remote URL previews (`http://` / `https://`) |
| `remote.timeout_ms` | `number` | `10000` | Download timeout in milliseconds for remote previews |
| `remote.max_bytes` | `number` | `10485760` | Maximum remote download size in bytes |
| `remote.cache_dir` | `string` | `stdpath("cache") .. "/viewim/remote"` | Cache directory for downloaded remote images |
| `remote.require_https` | `bool` | `false` | If true, reject `http://` URLs and allow only `https://` |
| `experimental.internal_render` | `bool` | `false` | Try experimental internal rendering for kitty before launcher fallback |

Notes:
- `supported_extensions` entries are normalized to lowercase; both `"png"` and `".png"` are accepted.
- Invalid extension entries are ignored with a warning.
- Invalid `kitty.launch_type` falls back to `"os-window"` with a warning.
- Invalid `wezterm.split_direction` falls back to `"right"`.
- Invalid `wezterm.split_percent` is ignored.
- Unsupported `ghostty.mode` falls back to `"external"` with a warning.
- `.avif` is recognized by viewim, but actual rendering depends on terminal/image codec support.

Integration resolver hooks:

```lua
require("viewim").setup({
  integrations = {
    nvim_tree = {
      enabled = true,
      resolve_path = function(node_path, ctx)
        return node_path
      end,
    },
  },
})
```

- `resolve_path(node_path, ctx)` is optional and can rewrite the selected path before preview.
- If the hook errors or returns an invalid value, viewim falls back to the original path.
- Backward compatible shorthand still works: `integrations = { nvim_tree = true }`.

## 🚀 Usage

### 🌳 From a file explorer

1. Open nvim-tree, oil.nvim, or neo-tree
2. Navigate to an image file
3. Press `<leader>p` (or your configured keymap)
4. The image opens in a new terminal window/pane

If enabled, you can also preview via mouse keymap in explorer buffers:

```lua
require("viewim").setup({
  mouse_preview = {
    enabled = true,
    key = "<M-LeftMouse>",
  },
})
```

Optional auto-preview on cursor movement in explorer buffers:

```lua
require("viewim").setup({
  explorer_auto_preview = {
    enabled = true,
    debounce_ms = 200,
    only_images = true,
  },
})
```

Experimental internal render mode (kitty only, with fallback):

```lua
require("viewim").setup({
  experimental = {
    internal_render = true,
  },
})
```

If internal rendering is unavailable or fails, viewim falls back to normal launcher behavior.

### 📄 From any buffer

Run the command:

```
:ViewImage
```

If the current buffer is an image file, it previews it.

### 🔧 Runtime controls

- `:ViewImageEnable` - enable previews
- `:ViewImageDisable` - disable previews
- `:ViewImageToggle` - toggle enabled/disabled state
- `:ViewImageStatus` - show enabled state, detected terminal, and remote status
  (also shows experimental internal mode state)

You can also pass an explicit path:

```
:ViewImage /path/to/image.png
```

You can also preview a remote image URL:

```
:ViewImage https://example.com/image.png
```

Only `http://` and `https://` URLs are supported.

If a path contains control characters (for example newline or NUL bytes), viewim rejects it before command execution.

## 🩺 Health Check

Run `:checkhealth viewim` to verify:

- Terminal emulator detected
- CLI tools (`kitten` / `wezterm`) available in `$PATH`
- `curl` available in `$PATH` (for remote URL preview)
- Kitty remote socket available (for kitty)
- Native opener available (for ghostty)
- Optional integrations loadable
- `.avif` enabled status and compatibility warning
- experimental internal-render capability state

If `KITTY_LISTEN_ON` is empty, set `kitty.listen_on` in `setup()` as shown above.

## 🧠 How It Works

- **kitty** — runs `kitty @ launch --type=os-window --cwd=current --hold -- kitty +kitten icat <file>`
  to open the image in a new kitty OS window.
- **wezterm** — runs `wezterm cli split-pane -- wezterm imgcat <file>`
  to open the image in a new wezterm pane.
  `wezterm.split_direction` and `wezterm.split_percent` control pane placement.
- **ghostty** — opens the image with your OS native viewer:
  - macOS: `open <file>`
  - Linux: `xdg-open <file>`
  - Windows: `explorer.exe <file>`
- **remote URL** — downloads `http/https` images via `curl` into `remote.cache_dir`
  using timeout and max-size limits before dispatching to terminal runners.

## 🧩 Architecture

`viewim` is split into small modules by responsibility:

- `plugin/viewim.lua` — registers user commands (`:ViewImage`, `:ViewImageEnable`, `:ViewImageDisable`, `:ViewImageToggle`, `:ViewImageStatus`)
- `lua/viewim/init.lua` — public API (`setup`, `view`, runtime controls) and integration keymaps
- `lua/viewim/config.lua` — defaults, merge, and config normalization/validation
- `lua/viewim/path.lua` — path resolution and control-character checks
- `lua/viewim/url.lua` — URL parsing helpers (`scheme`, extension hints)
- `lua/viewim/download.lua` — remote downloader with `curl` and guardrails
- `lua/viewim/preview.lua` — orchestration (`enabled check -> local/remote resolve -> validate -> dispatch`)
- `lua/viewim/renderers/*.lua` — experimental internal renderers (kitty prototype)
- `lua/viewim/detect.lua` — terminal/platform/command detection helpers
- `lua/viewim/runners/{kitty,wezterm,ghostty}.lua` — terminal-specific command runners
- `lua/viewim/integrations/{nvim_tree,oil,neo_tree,buffer,resolve}.lua` — explorer adapters and resolver hook application
- `lua/viewim/health.lua` — `:checkhealth viewim` diagnostics

Runtime flow:

1. User runs `:ViewImage` or presses the integration keymap.
2. Integration resolves a candidate file path.
3. Optional integration `resolve_path` hook rewrites the path.
4. `preview.lua` checks global enabled state.
5. Local path is validated, or remote URL is downloaded then validated.
6. Terminal is detected.
7. Matching runner executes the preview command.

## 📜 License

MIT
