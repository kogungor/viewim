local M = {}

local function quiet_warnings_enabled()
  local ok, config = pcall(require, "viewim.config")
  if not ok or not config.options then
    return false
  end
  return config.options.quiet_warnings == true
end

function M.warn(message)
  if quiet_warnings_enabled() then
    return
  end
  vim.notify(message, vim.log.levels.WARN)
end

function M.error(message)
  vim.notify(message, vim.log.levels.ERROR)
end

function M.info(message)
  vim.notify(message, vim.log.levels.INFO)
end

return M
