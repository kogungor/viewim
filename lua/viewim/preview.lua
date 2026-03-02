local config = require("viewim.config")
local detect = require("viewim.detect")
local path = require("viewim.path")
local kitty_runner = require("viewim.runners.kitty")
local wezterm_runner = require("viewim.runners.wezterm")
local ghostty_runner = require("viewim.runners.ghostty")

local M = {}

local function validate_path(raw_path)
  if not raw_path or raw_path == "" then
    return nil, "viewim: no file path provided", vim.log.levels.WARN
  end

  if path.has_control_chars(raw_path) then
    return nil, "viewim: rejected path with control characters", vim.log.levels.ERROR
  end

  local resolved = path.resolve(raw_path)

  if path.has_control_chars(resolved) then
    return nil, "viewim: rejected path with control characters", vim.log.levels.ERROR
  end

  if not config.is_image(resolved) then
    return nil, "viewim: not a supported image: " .. resolved, vim.log.levels.WARN
  end

  if vim.fn.filereadable(resolved) ~= 1 then
    return nil, "viewim: file not readable: " .. resolved .. " (cwd: " .. vim.fn.getcwd() .. ")", vim.log.levels.ERROR
  end

  return resolved
end

local function run_or_notify(ok, err)
  if ok then
    return
  end
  vim.notify(err or "viewim: preview command failed", vim.log.levels.ERROR)
end

--- Preview an image file in the terminal.
--- @param raw_path string
function M.preview(raw_path)
  local resolved, err, level = validate_path(raw_path)
  if not resolved then
    vim.notify(err, level or vim.log.levels.ERROR)
    return
  end

  local term = detect.get_terminal()
  if term == "kitty" then
    run_or_notify(kitty_runner.run(resolved, config.options and config.options.kitty))
  elseif term == "wezterm" then
    run_or_notify(wezterm_runner.run(resolved))
  elseif term == "ghostty" then
    run_or_notify(ghostty_runner.run(resolved, config.options and config.options.ghostty))
  else
    vim.notify(
      "viewim: unsupported terminal. Requires kitty, wezterm, or ghostty.",
      vim.log.levels.ERROR
    )
  end
end

-- Backward-compatible internal entry points.
function M._preview_kitty(path_value)
  run_or_notify(kitty_runner.run(path_value, config.options and config.options.kitty))
end

function M._preview_wezterm(path_value)
  run_or_notify(wezterm_runner.run(path_value))
end

function M._preview_ghostty(path_value)
  run_or_notify(ghostty_runner.run(path_value, config.options and config.options.ghostty))
end

return M
