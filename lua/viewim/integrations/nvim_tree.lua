local preview = require("viewim.preview")

local M = {}

--- Get the file path under cursor in nvim-tree and preview it.
function M.preview()
  local ok, api = pcall(require, "nvim-tree.api")
  if not ok then
    vim.notify("viewim: nvim-tree is not loaded", vim.log.levels.WARN)
    return
  end

  local node = api.tree.get_node_under_cursor()

  if not node then
    vim.notify("viewim: no file under cursor", vim.log.levels.WARN)
    return
  end

  if node.type ~= "file" then
    vim.notify("viewim: not a file", vim.log.levels.WARN)
    return
  end

  preview.preview(node.absolute_path)
end

return M
