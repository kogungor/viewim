local preview = require("viewim.preview")
local resolve = require("viewim.integrations.resolve")

local M = {}

local function maybe_notify(silent, message)
  if not silent then
    vim.notify(message, vim.log.levels.WARN)
  end
end

--- Get the resolved candidate path under cursor in nvim-tree.
--- @param opts table|nil { silent = boolean }
--- @return string|nil
function M.get_candidate_path(opts)
  opts = opts or {}
  local silent = opts.silent == true

  local ok, api = pcall(require, "nvim-tree.api")
  if not ok then
    maybe_notify(silent, "viewim: nvim-tree is not loaded")
    return
  end

  local node = api.tree.get_node_under_cursor()

  if not node then
    maybe_notify(silent, "viewim: no file under cursor")
    return
  end

  if node.type ~= "file" then
    maybe_notify(silent, "viewim: not a file")
    return
  end

  return resolve.apply("nvim_tree", node.absolute_path, {
    filetype = vim.bo.filetype,
    node = node,
  })
end

--- Get the file path under cursor in nvim-tree and preview it.
function M.preview()
  local resolved = M.get_candidate_path()
  if not resolved then
    return
  end

  preview.preview(resolved)
end

return M
