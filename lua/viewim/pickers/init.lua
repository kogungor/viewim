local builtin = require("viewim.pickers.builtin")
local fzflua = require("viewim.pickers.fzflua")
local snacks = require("viewim.pickers.snacks")
local telescope = require("viewim.pickers.telescope")

local M = {}

local BACKENDS = {
  builtin = builtin,
  fzflua = fzflua,
  snacks = snacks,
  telescope = telescope,
}

local function backend_order(preferred)
  if preferred == "telescope" then
    return { "telescope", "snacks", "fzflua", "builtin" }
  end
  if preferred == "snacks" then
    return { "snacks", "telescope", "fzflua", "builtin" }
  end
  if preferred == "fzflua" then
    return { "fzflua", "builtin" }
  end
  if preferred == "builtin" then
    return { "builtin" }
  end

  -- auto
  return { "telescope", "snacks", "fzflua", "builtin" }
end

function M.resolve_backend(preferred)
  local order = backend_order(preferred)
  for _, name in ipairs(order) do
    local backend = BACKENDS[name]
    if backend and backend.is_available() then
      return name, backend
    end
  end
  return nil, nil
end

function M.open(items, opts)
  opts = opts or {}
  local name, backend = M.resolve_backend(opts.preferred_picker or "auto")
  if not backend then
    return false, "no picker backend available", nil
  end

  local ok, err = backend.open(items, opts)
  if not ok then
    return false, err or ("failed to open picker backend: " .. name), name
  end

  return true, nil, name
end

return M
