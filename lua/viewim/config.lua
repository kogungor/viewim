local M = {}

local VALID_KITTY_LAUNCH_TYPES = {
  ["os-window"] = true,
  tab = true,
  window = true,
}

M.defaults = {
  enabled = true,
  keymap = "<leader>p",
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
  ghostty = {
    mode = "external",
    opener = "auto",
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
        vim.notify("viewim: ignoring invalid extension: " .. ext, vim.log.levels.WARN)
      end
    end
  end

  if #normalized == 0 then
    vim.notify("viewim: no valid supported_extensions provided, using defaults", vim.log.levels.WARN)
    return vim.deepcopy(M.defaults.supported_extensions)
  end

  return normalized
end

local function normalize_kitty(opts)
  opts = opts or {}
  if not VALID_KITTY_LAUNCH_TYPES[opts.launch_type] then
    vim.notify("viewim: invalid kitty.launch_type, using 'os-window'", vim.log.levels.WARN)
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
    vim.notify("viewim: invalid integrations." .. name .. ", using defaults", vim.log.levels.WARN)
    return defaults
  end

  local normalized = vim.tbl_deep_extend("force", defaults, value)
  if type(normalized.enabled) ~= "boolean" then
    normalized.enabled = true
  end

  if normalized.resolve_path ~= nil and type(normalized.resolve_path) ~= "function" then
    vim.notify("viewim: integrations." .. name .. ".resolve_path must be a function", vim.log.levels.WARN)
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
  if opts.mode ~= "external" then
    vim.notify("viewim: unsupported ghostty.mode, using 'external'", vim.log.levels.WARN)
    opts.mode = "external"
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
    vim.notify("viewim: invalid remote.timeout_ms, using 10000", vim.log.levels.WARN)
    opts.timeout_ms = 10000
  end

  if type(opts.max_bytes) ~= "number" or opts.max_bytes <= 0 then
    vim.notify("viewim: invalid remote.max_bytes, using 10485760", vim.log.levels.WARN)
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

function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts)

  M.options.enabled = normalize_enabled(M.options.enabled)
  M.options.integrations = normalize_integrations(M.options.integrations)
  M.options.supported_extensions = normalize_extensions(M.options.supported_extensions)
  M.options.kitty = normalize_kitty(M.options.kitty)
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
