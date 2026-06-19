local MiniTest = require("mini.test")

local T = MiniTest.new_set()

local function fresh_config()
  package.loaded["viewim.config"] = nil
  return require("viewim.config")
end

-- get_extension
T["get_extension"] = MiniTest.new_set()

T["get_extension"]["extracts lowercase extension"] = function()
  local config = fresh_config()
  MiniTest.expect.equality(config.get_extension("photo.PNG"), ".png")
  MiniTest.expect.equality(config.get_extension("image.jpg"), ".jpg")
  MiniTest.expect.equality(config.get_extension("animation.GIF"), ".gif")
end

T["get_extension"]["returns nil when no extension"] = function()
  local config = fresh_config()
  MiniTest.expect.equality(config.get_extension("filename"), nil)
  MiniTest.expect.equality(config.get_extension(""), nil)
end

T["get_extension"]["handles path with directory segments"] = function()
  local config = fresh_config()
  MiniTest.expect.equality(config.get_extension("/some/path/image.png"), ".png")
  MiniTest.expect.equality(config.get_extension("relative/dir/photo.jpg"), ".jpg")
end

-- is_image
T["is_image"] = MiniTest.new_set()

T["is_image"]["returns true for supported extensions"] = function()
  local config = fresh_config()
  config.setup({})
  MiniTest.expect.equality(config.is_image("photo.png"), true)
  MiniTest.expect.equality(config.is_image("image.jpg"), true)
  MiniTest.expect.equality(config.is_image("image.jpeg"), true)
  MiniTest.expect.equality(config.is_image("image.gif"), true)
  MiniTest.expect.equality(config.is_image("image.webp"), true)
  MiniTest.expect.equality(config.is_image("image.avif"), true)
  MiniTest.expect.equality(config.is_image("image.bmp"), true)
end

T["is_image"]["returns false for non-image extensions"] = function()
  local config = fresh_config()
  config.setup({})
  MiniTest.expect.equality(config.is_image("script.lua"), false)
  MiniTest.expect.equality(config.is_image("document.pdf"), false)
  MiniTest.expect.equality(config.is_image("data.json"), false)
  MiniTest.expect.equality(config.is_image("file"), false)
end

T["is_image"]["is case-insensitive"] = function()
  local config = fresh_config()
  config.setup({})
  MiniTest.expect.equality(config.is_image("image.PNG"), true)
  MiniTest.expect.equality(config.is_image("IMAGE.JPG"), true)
end

-- normalize_extensions
T["normalize_extensions"] = MiniTest.new_set()

T["normalize_extensions"]["accepts valid extensions"] = function()
  local config = fresh_config()
  config.setup({ supported_extensions = { ".png", ".jpg" } })
  MiniTest.expect.equality(config.options.supported_extensions, { ".png", ".jpg" })
end

T["normalize_extensions"]["adds leading dot if missing"] = function()
  local config = fresh_config()
  config.setup({ supported_extensions = { "png", "jpg" } })
  MiniTest.expect.equality(config.options.supported_extensions, { ".png", ".jpg" })
end

T["normalize_extensions"]["lowercases extensions"] = function()
  local config = fresh_config()
  config.setup({ supported_extensions = { ".PNG", ".JPG" } })
  MiniTest.expect.equality(config.options.supported_extensions, { ".png", ".jpg" })
end

T["normalize_extensions"]["falls back to defaults for non-table input"] = function()
  local config = fresh_config()
  config.setup({ supported_extensions = "not a table" })
  MiniTest.expect.equality(#config.options.supported_extensions, 7) -- 7 defaults
end

T["normalize_extensions"]["falls back to defaults when all invalid"] = function()
  local config = fresh_config()
  -- All symbols: fail the ^%.[a-z0-9]+$ pattern → all rejected → fall back to 7 defaults
  config.setup({ supported_extensions = { "!@#", "???", "!!!" } })
  MiniTest.expect.equality(#config.options.supported_extensions, 7)
end

-- normalize_kitty
T["normalize_kitty"] = MiniTest.new_set()

T["normalize_kitty"]["accepts valid launch types"] = function()
  local config = fresh_config()
  for _, lt in ipairs({ "os-window", "tab", "window" }) do
    config.setup({ kitty = { launch_type = lt } })
    MiniTest.expect.equality(config.options.kitty.launch_type, lt)
  end
end

T["normalize_kitty"]["falls back to os-window for invalid launch_type"] = function()
  local config = fresh_config()
  config.setup({ kitty = { launch_type = "invalid" } })
  MiniTest.expect.equality(config.options.kitty.launch_type, "os-window")
end

-- normalize_wezterm
T["normalize_wezterm"] = MiniTest.new_set()

T["normalize_wezterm"]["accepts valid split directions"] = function()
  local config = fresh_config()
  for _, dir in ipairs({ "left", "right", "top", "bottom" }) do
    config.setup({ wezterm = { split_direction = dir } })
    MiniTest.expect.equality(config.options.wezterm.split_direction, dir)
  end
end

T["normalize_wezterm"]["falls back to right for invalid split_direction"] = function()
  local config = fresh_config()
  config.setup({ wezterm = { split_direction = "diagonal" } })
  MiniTest.expect.equality(config.options.wezterm.split_direction, "right")
end

T["normalize_wezterm"]["accepts split_percent in 1-99 range"] = function()
  local config = fresh_config()
  config.setup({ wezterm = { split_percent = 40 } })
  MiniTest.expect.equality(config.options.wezterm.split_percent, 40)
end

T["normalize_wezterm"]["rejects split_percent out of range"] = function()
  local config = fresh_config()
  config.setup({ wezterm = { split_percent = 150 } })
  MiniTest.expect.equality(config.options.wezterm.split_percent, nil)

  config.setup({ wezterm = { split_percent = 0 } })
  MiniTest.expect.equality(config.options.wezterm.split_percent, nil)
end

-- normalize_remote
T["normalize_remote"] = MiniTest.new_set()

T["normalize_remote"]["uses defaults when options are invalid"] = function()
  local config = fresh_config()
  config.setup({ remote = { timeout_ms = 500 } }) -- below minimum 1000
  MiniTest.expect.equality(config.options.remote.timeout_ms, 10000)
end

T["normalize_remote"]["accepts valid timeout_ms"] = function()
  local config = fresh_config()
  config.setup({ remote = { timeout_ms = 5000 } })
  MiniTest.expect.equality(config.options.remote.timeout_ms, 5000)
end

T["normalize_remote"]["rejects non-positive max_bytes"] = function()
  local config = fresh_config()
  config.setup({ remote = { max_bytes = 0 } })
  MiniTest.expect.equality(config.options.remote.max_bytes, 10485760)
end

T["normalize_remote"]["defaults require_https to false"] = function()
  local config = fresh_config()
  config.setup({})
  MiniTest.expect.equality(config.options.remote.require_https, false)
end

-- normalize_search
T["normalize_search"] = MiniTest.new_set()

T["normalize_search"]["accepts valid preferred_picker"] = function()
  local config = fresh_config()
  for _, picker in ipairs({ "auto", "telescope", "snacks", "builtin" }) do
    config.setup({ search = { preferred_picker = picker } })
    MiniTest.expect.equality(config.options.search.preferred_picker, picker)
  end
end

T["normalize_search"]["falls back to auto for invalid preferred_picker"] = function()
  local config = fresh_config()
  config.setup({ search = { preferred_picker = "fzf" } })
  MiniTest.expect.equality(config.options.search.preferred_picker, "auto")
end

T["normalize_search"]["enforces minimum max_results of 10"] = function()
  local config = fresh_config()
  config.setup({ search = { max_results = 5 } })
  MiniTest.expect.equality(config.options.search.max_results, 500)
end

T["normalize_search"]["floors max_results to integer"] = function()
  local config = fresh_config()
  config.setup({ search = { max_results = 99.9 } })
  MiniTest.expect.equality(config.options.search.max_results, 99)
end

-- normalize_ghostty
T["normalize_ghostty"] = MiniTest.new_set()

T["normalize_ghostty"]["accepts valid modes"] = function()
  local config = fresh_config()
  config.setup({ ghostty = { mode = "external" } })
  MiniTest.expect.equality(config.options.ghostty.mode, "external")

  config.setup({ ghostty = { mode = "tmux" } })
  MiniTest.expect.equality(config.options.ghostty.mode, "tmux")
end

T["normalize_ghostty"]["falls back to external for invalid mode"] = function()
  local config = fresh_config()
  config.setup({ ghostty = { mode = "native" } })
  MiniTest.expect.equality(config.options.ghostty.mode, "external")
end

T["normalize_ghostty"]["keeps default tmux_command when invalid"] = function()
  local config = fresh_config()
  config.setup({ ghostty = { tmux_command = "" } })
  MiniTest.expect.equality(config.options.ghostty.tmux_command, "kitten icat --hold")
end

-- normalize_integrations
T["normalize_integrations"] = MiniTest.new_set()

T["normalize_integrations"]["accepts boolean shorthand to disable"] = function()
  local config = fresh_config()
  config.setup({ integrations = { nvim_tree = false } })
  MiniTest.expect.equality(config.options.integrations.nvim_tree.enabled, false)
end

T["normalize_integrations"]["accepts boolean shorthand to enable"] = function()
  local config = fresh_config()
  config.setup({ integrations = { oil = true } })
  MiniTest.expect.equality(config.options.integrations.oil.enabled, true)
end

T["normalize_integrations"]["accepts resolve_path as function"] = function()
  local config = fresh_config()
  local fn = function(p)
    return p
  end
  config.setup({ integrations = { nvim_tree = { resolve_path = fn } } })
  MiniTest.expect.equality(config.options.integrations.nvim_tree.resolve_path, fn)
end

T["normalize_integrations"]["rejects non-function resolve_path"] = function()
  local config = fresh_config()
  config.setup({ integrations = { nvim_tree = { resolve_path = "not a function" } } })
  MiniTest.expect.equality(config.options.integrations.nvim_tree.resolve_path, nil)
end

return T
