local preview = require("viewim.preview")
local resolve = require("viewim.integrations.resolve")
local notify = require("viewim.notify")

local M = {}

local function maybe_notify(silent, message)
  if not silent then
    notify.warn(message)
  end
end

--- Get the resolved candidate path under cursor in oil.nvim.
--- @param opts table|nil { silent = boolean }
--- @return string|nil
function M.get_candidate_path(opts)
  opts = opts or {}
  local silent = opts.silent == true

  local ok, oil = pcall(require, "oil")
  if not ok then
    maybe_notify(silent, "viewim: oil.nvim is not loaded")
    return
  end

  local entry = oil.get_cursor_entry()

  if not entry then
    maybe_notify(silent, "viewim: no entry under cursor")
    return
  end

  if entry.type ~= "file" then
    maybe_notify(silent, "viewim: not a file")
    return
  end

  local dir = oil.get_current_dir()
  if not dir then
    maybe_notify(silent, "viewim: could not determine directory")
    return
  end

  return resolve.apply("oil", dir .. entry.name, {
    filetype = vim.bo.filetype,
    entry = entry,
    dir = dir,
  })
end

--- Get the file path under cursor in oil.nvim and preview it.
function M.preview()
  local resolved = M.get_candidate_path()
  if not resolved then
    return
  end

  preview.preview(resolved)
end

return M
