local util = require("viewim.runners.util")

local M = {}

--- Launch wezterm preview.
--- @param path string
--- @param opts table|nil
--- @return boolean,string|nil
function M.run(path, opts)
  if vim.fn.executable("wezterm") ~= 1 then
    return false, "viewim: 'wezterm' command not found in $PATH"
  end

  opts = opts or {}
  local direction = opts.split_direction or "right"

  local cmd = { "wezterm", "cli", "split-pane" }
  if direction == "left" then
    table.insert(cmd, "--left")
  elseif direction == "right" then
    table.insert(cmd, "--right")
  elseif direction == "top" then
    table.insert(cmd, "--top")
  elseif direction == "bottom" then
    table.insert(cmd, "--bottom")
  end

  if opts.split_percent then
    vim.list_extend(cmd, { "--percent", tostring(opts.split_percent) })
  end

  vim.list_extend(cmd, { "--", "wezterm", "imgcat", path })

  local job_id = vim.fn.jobstart(cmd, {
    on_stderr = function(_, data)
      local msg = util.join_nonempty(data)
      if msg ~= "" then
        vim.schedule(function()
          vim.notify("viewim: wezterm error: " .. msg, vim.log.levels.ERROR)
        end)
      end
    end,
  })

  if job_id <= 0 then
    return false, "viewim: failed to start wezterm preview"
  end

  return true
end

return M
