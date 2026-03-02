local preview = require("viewim.preview")

local M = {}

--- Get the file path under cursor in neo-tree and preview it.
function M.preview()
  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if not ok then
    vim.notify("viewim: neo-tree is not loaded", vim.log.levels.WARN)
    return
  end

  local state = manager.get_state("filesystem")
  if not state then
    vim.notify("viewim: could not get neo-tree state", vim.log.levels.WARN)
    return
  end

  local tree = state.tree
  if not tree then
    vim.notify("viewim: no neo-tree tree available", vim.log.levels.WARN)
    return
  end

  local node = tree:get_node()
  if not node then
    vim.notify("viewim: no file under cursor", vim.log.levels.WARN)
    return
  end

  local node_type = node:get_type() or node.type
  if node_type ~= "file" then
    vim.notify("viewim: not a file", vim.log.levels.WARN)
    return
  end

  local path = node:get_id() or node.path
  if not path then
    vim.notify("viewim: could not determine file path", vim.log.levels.WARN)
    return
  end

  preview.preview(path)
end

return M
