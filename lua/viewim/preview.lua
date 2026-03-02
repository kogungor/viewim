local config = require("viewim.config")
local detect = require("viewim.detect")

local M = {}

--- Preview an image file in the terminal.
--- @param path string absolute path to the image file
function M.preview(path)
  if not path or path == "" then
    vim.notify("viewim: no file path provided", vim.log.levels.WARN)
    return
  end

  -- Resolve to absolute path
  path = vim.fn.fnamemodify(path, ":p")

  if not config.is_image(path) then
    vim.notify("viewim: not a supported image: " .. path, vim.log.levels.WARN)
    return
  end

  if vim.fn.filereadable(path) ~= 1 then
    vim.notify("viewim: file not readable: " .. path, vim.log.levels.ERROR)
    return
  end

  local term = detect.get_terminal()

  if term == "kitty" then
    M._preview_kitty(path)
  elseif term == "wezterm" then
    M._preview_wezterm(path)
  else
    vim.notify(
      "viewim: unsupported terminal. Requires kitty or wezterm.",
      vim.log.levels.ERROR
    )
  end
end

--- Open image in a new kitty OS window using kitten icat.
--- @param path string
function M._preview_kitty(path)
  local launcher = vim.fn.executable("kitty") == 1 and "kitty" or "kitten"

  local cmd = {
    launcher, "@", "launch",
    "--type=window",
    "--",
    "kitten", "icat", "--hold", path,
  }

  vim.fn.jobstart(cmd, {
    detach = true,
    on_stderr = function(_, data)
      local msg = table.concat(data, "\n")
      if msg ~= "" then
        vim.schedule(function()
          vim.notify("viewim: kitty error: " .. msg, vim.log.levels.ERROR)
        end)
      end
    end,
  })
end

--- Open image in a new wezterm pane.
--- @param path string
function M._preview_wezterm(path)
  local cmd = {
    "wezterm", "cli", "split-pane",
    "--", "wezterm", "imgcat", path,
  }

  vim.fn.jobstart(cmd, {
    detach = true,
    on_stderr = function(_, data)
      local msg = table.concat(data, "\n")
      if msg ~= "" then
        vim.schedule(function()
          vim.notify("viewim: wezterm error: " .. msg, vim.log.levels.ERROR)
        end)
      end
    end,
  })
end

return M
