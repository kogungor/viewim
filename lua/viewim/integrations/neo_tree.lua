local preview = require("viewim.preview")
local resolve = require("viewim.integrations.resolve")

local M = {}

local function maybe_notify(silent, message)
  if not silent then
    vim.notify(message, vim.log.levels.WARN)
  end
end

--- Get the resolved candidate path under cursor in neo-tree.
--- @param opts table|nil { silent = boolean }
--- @return string|nil
function M.get_candidate_path(opts)
  opts = opts or {}
  local silent = opts.silent == true

  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if not ok then
    maybe_notify(silent, "viewim: neo-tree is not loaded")
    return
  end

  local state = manager.get_state("filesystem")
  if not state then
    maybe_notify(silent, "viewim: could not get neo-tree state")
    return
  end

  local tree = state.tree
  if not tree then
    maybe_notify(silent, "viewim: no neo-tree tree available")
    return
  end

  local node = tree:get_node()
  if not node then
    maybe_notify(silent, "viewim: no file under cursor")
    return
  end

  local node_type = node:get_type() or node.type
  if node_type ~= "file" then
    maybe_notify(silent, "viewim: not a file")
    return
  end

  local path = node:get_id() or node.path
  if not path then
    maybe_notify(silent, "viewim: could not determine file path")
    return
  end

  return resolve.apply("neo_tree", path, {
    filetype = vim.bo.filetype,
    node = node,
    state = state,
  })
end

--- Get the file path under cursor in neo-tree and preview it.
function M.preview()
  local resolved = M.get_candidate_path()
  if not resolved then
    return
  end

  preview.preview(resolved)
end

return M
