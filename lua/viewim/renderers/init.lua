local kitty_internal = require("viewim.renderers.kitty_internal")

local M = {}

--- Try experimental internal render for current terminal.
--- @param path string
--- @param term string|nil
--- @param opts table|nil
--- @return boolean attempted
--- @return boolean ok
--- @return string|nil err
function M.try_render(path, term, opts)
  opts = opts or {}
  if not opts.internal_render then
    return false, false, nil
  end

  if term ~= "kitty" then
    return false, false, nil
  end

  local supported, reason = kitty_internal.is_supported()
  if not supported then
    return true, false, reason
  end

  local ok, err = kitty_internal.render(path)
  return true, ok, err
end

--- Report capability for health checks.
--- @param term string|nil
--- @return boolean
--- @return string|nil
function M.is_supported(term)
  if term ~= "kitty" then
    return false, "supported currently only for kitty"
  end

  return kitty_internal.is_supported()
end

return M
