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
local iterm2_runner = require("viewim.runners.iterm2")

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
  notify.error(err or "viewim: preview command failed")
end

local function merged_options(mode_opts)
  local options = config.options or {}
  local kitty_opts = vim.deepcopy(options.kitty or {})
  local wezterm_opts = vim.deepcopy(options.wezterm or {})
  local ghostty_opts = vim.deepcopy(options.ghostty or {})

  mode_opts = mode_opts or {}
  if mode_opts.large then
    kitty_opts.launch_type = "os-window"

    local placement = options.preview_placement or {}
    wezterm_opts.split_direction = placement.direction or wezterm_opts.split_direction
    wezterm_opts.split_percent = wezterm_opts.split_percent or 90

    if ghostty_opts.mode == "tmux" then
      ghostty_opts.tmux_split_direction = placement.direction or ghostty_opts.tmux_split_direction
      ghostty_opts.tmux_split_percent = ghostty_opts.tmux_split_percent or 90
    end
  end

  return kitty_opts, wezterm_opts, ghostty_opts
end

local function dispatch_preview(resolved, mode_opts)
  local term = detect.get_terminal()
  local kitty_opts, wezterm_opts, ghostty_opts = merged_options(mode_opts)

  if not mode_opts or not mode_opts.large then
    local attempted, ok, err = renderers.try_render(resolved, term, config.options and config.options.experimental)
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
        notify.warn("viewim: internal render unavailable (no controlling terminal), auto-disabled for this session")
      else
        notify.warn("viewim: internal render failed, falling back to launcher" .. (err and (": " .. err) or ""))
      end
    end
  end

  if term == "kitty" then
    run_or_notify(kitty_runner.run(resolved, kitty_opts))
  elseif term == "wezterm" then
    run_or_notify(wezterm_runner.run(resolved, wezterm_opts))
  elseif term == "ghostty" then
    run_or_notify(ghostty_runner.run(resolved, ghostty_opts))
  elseif term == "iterm2" then
    local iterm2_opts = config.options and config.options.iterm2 or {}
    if iterm2_opts.enabled ~= false then
      run_or_notify(iterm2_runner.run(resolved, iterm2_opts))
    else
      notify.warn("viewim: iTerm2 backend is disabled (set iterm2.enabled=true)")
    end
  else
    notify.error("viewim: unsupported terminal. Requires kitty, wezterm, ghostty, or iTerm2.")
  end
end

local function resolve_svg_converter(converter)
  if converter == "rsvg-convert" then
    return vim.fn.executable("rsvg-convert") == 1 and "rsvg-convert" or nil
  elseif converter == "magick" then
    return vim.fn.executable("magick") == 1 and "magick" or nil
  end
  -- auto
  if vim.fn.executable("rsvg-convert") == 1 then
    return "rsvg-convert"
  elseif vim.fn.executable("magick") == 1 then
    return "magick"
  end
  return nil
end

local function maybe_convert_svg(raw_path, callback)
  local svg_opts = config.options and config.options.svg or {}
  local ext = config.get_extension(raw_path)
  if ext ~= ".svg" or not svg_opts.enabled then
    return callback(raw_path, nil)
  end

  local converter = resolve_svg_converter(svg_opts.converter or "auto")
  if not converter then
    return callback(nil, "viewim: no SVG converter found (install rsvg-convert or ImageMagick)")
  end

  local tmp = vim.fn.tempname() .. ".png"
  local cmd = converter == "rsvg-convert" and { "rsvg-convert", raw_path, "-o", tmp } or { "magick", raw_path, tmp }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      vim.schedule(function()
        if code ~= 0 then
          vim.fn.delete(tmp)
          callback(nil, "viewim: SVG conversion failed (exit " .. code .. ")")
          return
        end
        callback(tmp, nil)
        vim.defer_fn(function()
          vim.fn.delete(tmp)
        end, 30000)
      end)
    end,
  })
end

local function preview_with_mode(raw_path, mode_opts)
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
          if level == vim.log.levels.WARN then
            notify.warn(v_err)
          else
            notify.error(v_err)
          end
          return
        end

        dispatch_preview(resolved, mode_opts)
      end)
    end)
    return
  end

  local scheme = url.get_scheme(raw_path)
  if scheme and scheme ~= "http" and scheme ~= "https" then
    notify.error("viewim: unsupported URL scheme: " .. scheme)
    return
  end

  -- SVG conversion must happen before validate_path (svg is not in supported_extensions)
  local svg_opts = config.options and config.options.svg or {}
  local ext = config.get_extension(raw_path)
  if ext == ".svg" and svg_opts.enabled then
    maybe_convert_svg(raw_path, function(converted, svg_err)
      if svg_err then
        notify.error(svg_err)
        return
      end
      local resolved, v_err, level = validate_path(converted)
      if not resolved then
        if level == vim.log.levels.WARN then
          notify.warn(v_err)
        else
          notify.error(v_err)
        end
        return
      end
      dispatch_preview(resolved, mode_opts)
    end)
    return
  end

  local resolved, err, level = validate_path(raw_path)
  if not resolved then
    if level == vim.log.levels.WARN then
      notify.warn(err)
    else
      notify.error(err)
    end
    return
  end

  dispatch_preview(resolved, mode_opts)
end

--- Preview an image file in the terminal.
--- @param raw_path string
function M.preview(raw_path)
  preview_with_mode(raw_path, nil)
end

--- Preview using a larger launcher mode (used by search alt action).
--- @param raw_path string
function M.preview_large(raw_path)
  preview_with_mode(raw_path, { large = true })
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
