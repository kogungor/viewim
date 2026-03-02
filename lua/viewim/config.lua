local M = {}

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
}

M.options = {}

function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts)

  -- Build extension lookup table for fast checks
  M._ext_lookup = {}
  for _, ext in ipairs(M.options.supported_extensions) do
    M._ext_lookup[ext:lower()] = true
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
  local ext = M.get_extension(path)
  return ext ~= nil and (M._ext_lookup[ext] == true)
end

return M
