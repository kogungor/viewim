# viewim

Preview images directly from Neovim file explorers in your terminal.

Works with **kitty** and **wezterm** — opens image previews in a separate terminal
window/pane without leaving your editor.

## Features

- Preview images from **nvim-tree**, **oil.nvim**, and **neo-tree**
- Preview image files open in the **current buffer**
- Terminal auto-detection (kitty / wezterm)
- Configurable keymap
- `:ViewImage` command with optional path argument
- `:checkhealth viewim` to verify your setup
- Supported formats: `bmp`, `jpg`, `jpeg`, `png`, `gif`, `webp`

## Requirements

- Neovim >= 0.9
- One of:
  - [kitty](https://sw.kovidgoyal.net/kitty/) terminal (uses `kitten icat`)
  - [wezterm](https://wezfurlong.org/wezterm/) terminal (uses `wezterm imgcat`)
- At least one file explorer (optional):
  - [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua)
  - [oil.nvim](https://github.com/stevearc/oil.nvim)
  - [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim)

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
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `keymap` | `string` | `"<leader>p"` | Key to trigger image preview in file explorers |
| `supported_extensions` | `table` | see above | List of image file extensions to recognize |
| `integrations.nvim_tree` | `bool` | `true` | Enable nvim-tree keymap |
| `integrations.oil` | `bool` | `true` | Enable oil.nvim keymap |
| `integrations.neo_tree` | `bool` | `true` | Enable neo-tree keymap |

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

## Health Check

Run `:checkhealth viewim` to verify:

- Terminal emulator detected
- CLI tools (`kitten` / `wezterm`) available in `$PATH`
- Optional integrations loadable

## How It Works

- **kitty** — runs `kitty @ launch --type=window --hold -- kitten icat <file>`
  to open the image in a new kitty OS window.
- **wezterm** — runs `wezterm cli split-pane -- wezterm imgcat <file>`
  to open the image in a new wezterm pane.

## License

MIT
