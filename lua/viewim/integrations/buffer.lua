local preview = require("viewim.preview")

local M = {}

--- Preview the image file open in the current buffer.
function M.preview()
  local path = vim.api.nvim_buf_get_name(0)

  if not path or path == "" then
    vim.notify("viewim: current buffer has no file", vim.log.levels.WARN)
    return
  end

  preview.preview(path)
end

return M
