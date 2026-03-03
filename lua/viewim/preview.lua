local config = require("viewim.config")
local detect = require("viewim.detect")
local notify = require("viewim.notify")
local path = require("viewim.path")
local download = require("viewim.download")
local url = require("viewim.url")
local renderers = require("viewim.renderers")
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

local function dispatch_preview(resolved)
  local term = detect.get_terminal()

  local attempted, ok, err = renderers.try_render(
    resolved,
    term,
    config.options and config.options.experimental
  )
  if attempted and ok then
    return
  end
  if attempted and not ok then
    local exp = config.options and config.options.experimental or nil
    local reason = (err or ""):lower()
    local tty_failure = reason:find("/dev/tty", 1, true)
      or reason:find("controlling terminal", 1, true)
      or reason:find("not a tty", 1, true)

    if exp and exp.internal_render and tty_failure then
      exp.internal_render = false
      exp._auto_disabled_reason = err or "controlling terminal unavailable"
      notify.warn(
        "viewim: internal render unavailable (no controlling terminal), auto-disabled for this session"
      )
    else
      notify.warn(
        "viewim: internal render failed, falling back to launcher" .. (err and (": " .. err) or "")
      )
    end
  end

  if term == "kitty" then
    run_or_notify(kitty_runner.run(resolved, config.options and config.options.kitty))
  elseif term == "wezterm" then
    run_or_notify(wezterm_runner.run(resolved, config.options and config.options.wezterm))
  elseif term == "ghostty" then
    run_or_notify(ghostty_runner.run(resolved, config.options and config.options.ghostty))
  else
    notify.error(
      "viewim: unsupported terminal. Requires kitty, wezterm, or ghostty."
    )
  end
end

--- Preview an image file in the terminal.
--- @param raw_path string
function M.preview(raw_path)
  if not config.options or vim.tbl_isempty(config.options) then
    config.setup({})
  end

  if config.options.enabled == false then
    notify.warn("viewim: plugin is disabled (use :ViewImageEnable)")
    return
  end

  local is_remote = url.is_http_url(raw_path)
  if is_remote then
    local remote = config.options and config.options.remote or {}
    if not remote.enabled then
      notify.warn("viewim: remote preview is disabled (set remote.enabled=true)")
      return
    end

    if remote.require_https and url.get_scheme(raw_path) ~= "https" then
      notify.error("viewim: remote preview requires https URLs")
      return
    end

    if vim.fn.executable("curl") ~= 1 then
      notify.error("viewim: 'curl' command not found in $PATH")
      return
    end

    download.fetch(raw_path, remote, function(local_path, _, err)
      vim.schedule(function()
        if err then
          notify.error(err)
          return
        end

        local resolved, v_err, level = validate_path(local_path)
        if not resolved then
          vim.notify(v_err, level or vim.log.levels.ERROR)
          return
        end

        dispatch_preview(resolved)
      end)
    end)
    return
  end

  local scheme = url.get_scheme(raw_path)
  if scheme and scheme ~= "http" and scheme ~= "https" then
    notify.error("viewim: unsupported URL scheme: " .. scheme)
    return
  end

  local resolved, err, level = validate_path(raw_path)
  if not resolved then
    vim.notify(err, level or vim.log.levels.ERROR)
    return
  end

  dispatch_preview(resolved)
end

-- Backward-compatible internal entry points.
function M._preview_kitty(path_value)
  run_or_notify(kitty_runner.run(path_value, config.options and config.options.kitty))
end

function M._preview_wezterm(path_value)
  run_or_notify(wezterm_runner.run(path_value, config.options and config.options.wezterm))
end

function M._preview_ghostty(path_value)
  run_or_notify(ghostty_runner.run(path_value, config.options and config.options.ghostty))
end

return M
