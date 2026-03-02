local M = {}

local VALID_KITTY_LAUNCH_TYPES = {
  ["os-window"] = true,
  tab = true,
  window = true,
}

M.defaults = {
  keymap = "<leader>p",
  supported_extensions = {
    ".bmp",
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
    ".webp",
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

local function normalize_ghostty(opts)
  opts = opts or {}
  if opts.mode ~= "external" then
    vim.notify("viewim: unsupported ghostty.mode, using 'external'", vim.log.levels.WARN)
    opts.mode = "external"
  end
  return opts
end

function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts)

  M.options.supported_extensions = normalize_extensions(M.options.supported_extensions)
  M.options.kitty = normalize_kitty(M.options.kitty)
  M.options.ghostty = normalize_ghostty(M.options.ghostty)

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
