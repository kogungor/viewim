local config = require("viewim.config")
local notify = require("viewim.notify")

local M = {}

--- Apply per-integration resolve_path hook if configured.
--- @param integration string
--- @param node_path string
--- @param ctx table|nil
--- @return string
function M.apply(integration, node_path, ctx)
  if not config.options or vim.tbl_isempty(config.options) then
    config.setup({})
  end

  local integrations = config.options.integrations or {}
  local entry = integrations[integration]
  local resolver = type(entry) == "table" and entry.resolve_path or nil
  if type(resolver) ~= "function" then
    return node_path
  end

  local ok, resolved = pcall(resolver, node_path, ctx or {})
  if not ok then
    notify.warn("viewim: integrations." .. integration .. ".resolve_path failed")
    return node_path
  end

  if type(resolved) == "string" and resolved ~= "" then
    return resolved
  end

  if resolved ~= nil then
    notify.warn("viewim: integrations." .. integration .. ".resolve_path must return a string")
  end

  return node_path
end

return M
