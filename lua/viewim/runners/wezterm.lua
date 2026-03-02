local util = require("viewim.runners.util")

local M = {}

--- Launch wezterm preview.
--- @param path string
--- @return boolean,string|nil
function M.run(path)
  if vim.fn.executable("wezterm") ~= 1 then
    return false, "viewim: 'wezterm' command not found in $PATH"
  end

  local cmd = {
    "wezterm", "cli", "split-pane",
    "--", "wezterm", "imgcat", path,
  }

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
