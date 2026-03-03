local M = {}

local VALID_KITTY_LAUNCH_TYPES = {
  ["os-window"] = true,
  tab = true,
  window = true,
}

local VALID_WEZTERM_SPLIT_DIRECTIONS = {
  left = true,
  right = true,
  top = true,
  bottom = true,
}

local VALID_GHOSTTY_MODES = {
  external = true,
  tmux = true,
}

M.defaults = {
  enabled = true,
  quiet_warnings = false,
  keymap = "<leader>p",
  cursor_keymap = "<leader>wi",
  mouse_preview = {
    enabled = false,
    key = "<M-LeftMouse>",
  },
  explorer_auto_preview = {
    enabled = false,
    debounce_ms = 180,
    only_images = true,
  },
  experimental = {
    internal_render = false,
  },
  supported_extensions = {
    ".bmp",
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
    ".webp",
    ".avif",
  },
  integrations = {
    nvim_tree = {
      enabled = true,
      resolve_path = nil,
    },
    oil = {
      enabled = true,
      resolve_path = nil,
    },
    neo_tree = {
      enabled = true,
      resolve_path = nil,
    },
  },
  kitty = {
    listen_on = nil,
    launch_type = "os-window",
  },
  wezterm = {
    split_direction = "right",
    split_percent = nil,
  },
  ghostty = {
    mode = "external",
    opener = "auto",
    tmux_split_direction = "right",
    tmux_split_percent = nil,
    tmux_command = "kitten icat --hold",
  },
  remote = {
    enabled = true,
    timeout_ms = 10000,
    max_bytes = 10485760,
    cache_dir = vim.fs.normalize(vim.fn.stdpath("cache") .. "/viewim/remote"),
    require_https = false,
  },
}

M.options = {}
local quiet_warnings = false

local function warn(message)
  if quiet_warnings then
    return
  end
  vim.notify(message, vim.log.levels.WARN)
end

local function normalize_extensions(values)
  if type(values) ~= "table" then
    return vim.deepcopy(M.defaults.supported_extensions)
  end

  local normalized = {}
  for _, ext in ipairs(values) do
    if type(ext) == "string" then
      local candidate = ext:lower()
      if candidate:sub(1, 1) ~= "." then
        candidate = "." .. candidate
      end

      if candidate:match("^%.[a-z0-9]+$") then
        table.insert(normalized, candidate)
      else
        warn("viewim: ignoring invalid extension: " .. ext)
      end
    end
  end

  if #normalized == 0 then
    warn("viewim: no valid supported_extensions provided, using defaults")
    return vim.deepcopy(M.defaults.supported_extensions)
  end

  return normalized
end

local function normalize_kitty(opts)
  opts = opts or {}
  if not VALID_KITTY_LAUNCH_TYPES[opts.launch_type] then
    warn("viewim: invalid kitty.launch_type, using 'os-window'")
    opts.launch_type = "os-window"
  end
  return opts
end

local function normalize_integration(name, value)
  local defaults = vim.deepcopy(M.defaults.integrations[name] or { enabled = true, resolve_path = nil })

  if type(value) == "boolean" then
    defaults.enabled = value
    return defaults
  end

  if value == nil then
    return defaults
  end

  if type(value) ~= "table" then
    warn("viewim: invalid integrations." .. name .. ", using defaults")
    return defaults
  end

  local normalized = vim.tbl_deep_extend("force", defaults, value)
  if type(normalized.enabled) ~= "boolean" then
    normalized.enabled = true
  end

  if normalized.resolve_path ~= nil and type(normalized.resolve_path) ~= "function" then
    warn("viewim: integrations." .. name .. ".resolve_path must be a function")
    normalized.resolve_path = nil
  end

  return normalized
end

local function normalize_integrations(values)
  if type(values) ~= "table" then
    return vim.deepcopy(M.defaults.integrations)
  end

  return {
    nvim_tree = normalize_integration("nvim_tree", values.nvim_tree),
    oil = normalize_integration("oil", values.oil),
    neo_tree = normalize_integration("neo_tree", values.neo_tree),
  }
end

local function normalize_ghostty(opts)
  opts = opts or {}
  if not VALID_GHOSTTY_MODES[opts.mode] then
    warn("viewim: unsupported ghostty.mode, using 'external'")
    opts.mode = "external"
  end

  if not VALID_WEZTERM_SPLIT_DIRECTIONS[opts.tmux_split_direction] then
    opts.tmux_split_direction = "right"
  end

  if opts.tmux_split_percent ~= nil then
    local n = tonumber(opts.tmux_split_percent)
    if not n or n < 1 or n > 99 then
      warn("viewim: invalid ghostty.tmux_split_percent, ignoring")
      opts.tmux_split_percent = nil
    else
      opts.tmux_split_percent = math.floor(n)
    end
  end

  if type(opts.tmux_command) ~= "string" or opts.tmux_command == "" then
    opts.tmux_command = "kitten icat --hold"
  end

  return opts
end

local function normalize_wezterm(opts)
  opts = opts or {}

  if not VALID_WEZTERM_SPLIT_DIRECTIONS[opts.split_direction] then
    warn("viewim: invalid wezterm.split_direction, using 'right'")
    opts.split_direction = "right"
  end

  if opts.split_percent ~= nil then
    local n = tonumber(opts.split_percent)
    if not n or n < 1 or n > 99 then
      warn("viewim: invalid wezterm.split_percent, ignoring")
      opts.split_percent = nil
    else
      opts.split_percent = math.floor(n)
    end
  end

  return opts
end

local function normalize_remote(opts)
  opts = opts or {}

  if type(opts.enabled) ~= "boolean" then
    opts.enabled = true
  end

  if type(opts.require_https) ~= "boolean" then
    opts.require_https = false
  end

  if type(opts.timeout_ms) ~= "number" or opts.timeout_ms < 1000 then
    warn("viewim: invalid remote.timeout_ms, using 10000")
    opts.timeout_ms = 10000
  end

  if type(opts.max_bytes) ~= "number" or opts.max_bytes <= 0 then
    warn("viewim: invalid remote.max_bytes, using 10485760")
    opts.max_bytes = 10485760
  end

  if type(opts.cache_dir) ~= "string" or opts.cache_dir == "" then
    opts.cache_dir = vim.fs.normalize(vim.fn.stdpath("cache") .. "/viewim/remote")
  end

  return opts
end

local function normalize_enabled(value)
  if type(value) == "boolean" then
    return value
  end
  return true
end

local function normalize_cursor_keymap(value)
  if type(value) == "string" and value ~= "" then
    return value
  end
  return "<leader>wi"
end

local function normalize_quiet_warnings(value)
  if type(value) == "boolean" then
    return value
  end
  return false
end

local function normalize_mouse_preview(opts)
  opts = opts or {}

  if type(opts.enabled) ~= "boolean" then
    opts.enabled = false
  end

  if type(opts.key) ~= "string" or opts.key == "" then
    opts.key = "<M-LeftMouse>"
  end

  return opts
end

local function normalize_explorer_auto_preview(opts)
  opts = opts or {}

  if type(opts.enabled) ~= "boolean" then
    opts.enabled = false
  end

  if type(opts.only_images) ~= "boolean" then
    opts.only_images = true
  end

  if type(opts.debounce_ms) ~= "number" or opts.debounce_ms < 50 then
    opts.debounce_ms = 180
  end

  return opts
end

local function normalize_experimental(opts)
  opts = opts or {}
  if type(opts.internal_render) ~= "boolean" then
    opts.internal_render = false
  end
  return opts
end

function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts)

  M.options.enabled = normalize_enabled(M.options.enabled)
  M.options.quiet_warnings = normalize_quiet_warnings(M.options.quiet_warnings)
  quiet_warnings = M.options.quiet_warnings
  M.options.cursor_keymap = normalize_cursor_keymap(M.options.cursor_keymap)
  M.options.mouse_preview = normalize_mouse_preview(M.options.mouse_preview)
  M.options.explorer_auto_preview = normalize_explorer_auto_preview(M.options.explorer_auto_preview)
  M.options.experimental = normalize_experimental(M.options.experimental)
  M.options.integrations = normalize_integrations(M.options.integrations)
  M.options.supported_extensions = normalize_extensions(M.options.supported_extensions)
  M.options.kitty = normalize_kitty(M.options.kitty)
  M.options.wezterm = normalize_wezterm(M.options.wezterm)
  M.options.ghostty = normalize_ghostty(M.options.ghostty)
  M.options.remote = normalize_remote(M.options.remote)

  M._ext_lookup = {}
  for _, ext in ipairs(M.options.supported_extensions) do
    M._ext_lookup[ext:lower()] = true
  end
end

local function ensure_initialized()
  if not M._ext_lookup then
    M.setup({})
  end
end

--- Get the file extension from a path (lowercase).
--- @param path string
--- @return string|nil
function M.get_extension(path)
  local ext = path:match("^.+(%.[^./\\]+)$")
  return ext and ext:lower()
end

--- Check if a path points to a supported image file.
--- @param path string
--- @return boolean
function M.is_image(path)
  ensure_initialized()
  local ext = M.get_extension(path)
  return ext ~= nil and (M._ext_lookup[ext] == true)
end

return M
