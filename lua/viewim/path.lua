local M = {}

local function is_abs_path(path)
  return path:sub(1, 1) == "/"
    or path:match("^%a:[/\\]") ~= nil
    or path:sub(1, 2) == "\\\\"
end

--- Resolve a path into an absolute local path.
--- For relative paths, prefer the current buffer's directory when possible.
--- @param path string
--- @return string
function M.resolve(path)
  path = vim.fn.expand(path)

  if is_abs_path(path) then
    return vim.fn.fnamemodify(path, ":p")
  end

  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname ~= "" then
    local bufdir = vim.fn.fnamemodify(bufname, ":p:h")
    local from_buf = vim.fs.normalize(bufdir .. "/" .. path)
    if vim.fn.filereadable(from_buf) == 1 then
      return from_buf
    end
  end

  return vim.fn.fnamemodify(path, ":p")
end

--- Check whether a path contains control characters.
--- @param value string
--- @return boolean
function M.has_control_chars(value)
  if type(value) ~= "string" then
    return false
  end
  return value:find("[%z\1-\31\127]") ~= nil
end

return M
