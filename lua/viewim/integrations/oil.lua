local preview = require("viewim.preview")

local M = {}

--- Get the file path under cursor in oil.nvim and preview it.
function M.preview()
  local ok, oil = pcall(require, "oil")
  if not ok then
    vim.notify("viewim: oil.nvim is not loaded", vim.log.levels.WARN)
    return
  end

  local entry = oil.get_cursor_entry()

  if not entry then
    vim.notify("viewim: no entry under cursor", vim.log.levels.WARN)
    return
  end

  if entry.type ~= "file" then
    vim.notify("viewim: not a file", vim.log.levels.WARN)
    return
  end

  local dir = oil.get_current_dir()
  if not dir then
    vim.notify("viewim: could not determine directory", vim.log.levels.WARN)
    return
  end

  preview.preview(dir .. entry.name)
end

return M
