local config = require("viewim.config")
local detect = require("viewim.detect")

local M = {}

local function is_abs_path(path)
  return path:sub(1, 1) == "/"
    or path:match("^%a:[/\\]") ~= nil
    or path:sub(1, 2) == "\\\\"
end

--- Resolve a path into an absolute local path.
--- For relative paths, prefer the current buffer's directory when possible.
--- @param path string
--- @return string
local function resolve_path(path)
  path = vim.fn.expand(path)

  if is_abs_path(path) then
    return vim.fn.fnamemodify(path, ":p")
  end

  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname ~= "" then
    local bufdir = vim.fn.fnamemodify(bufname, ":p:h")
    local from_buf = vim.fs.normalize(bufdir .. "/" .. path)
    if vim.fn.filereadable(from_buf) == 1 then
      return from_buf
    end
  end

  return vim.fn.fnamemodify(path, ":p")
end

local function join_nonempty(lines)
  if type(lines) ~= "table" then
    return ""
  end

  local acc = {}
  for _, line in ipairs(lines) do
    if line and line:match("%S") then
      table.insert(acc, line)
    end
  end
  return table.concat(acc, "\n")
end

local function unix_socket_path(addr)
  if type(addr) ~= "string" then
    return nil
  end
  return addr:match("^unix:(.+)$")
end

local function socket_is_available(addr)
  local path = unix_socket_path(addr)
  if not path then
    return true
  end
  return vim.fn.getftype(path) == "socket"
end

local function shell_launch_kitty(path, listen_on)
  local parts = { "kitty", "@" }
  if listen_on and listen_on ~= "" and socket_is_available(listen_on) then
    table.insert(parts, "--to")
    table.insert(parts, vim.fn.shellescape(listen_on))
  end

  vim.list_extend(parts, {
    "launch",
    "--type=os-window",
    "--cwd=current",
    "--hold",
    "--",
    "kitty",
    "+kitten",
    "icat",
    vim.fn.shellescape(path),
  })

  local cmdline = table.concat(parts, " ") .. " >/dev/null 2>&1 &"
  vim.cmd("silent !" .. cmdline)
  vim.cmd("redraw!")
end

local function build_external_open_cmd(path, opener)
  if opener and opener ~= "auto" then
    return { opener, path }
  end

  local platform = detect.get_platform()
  if platform == "macos" then
    return { "open", path }
  elseif platform == "linux" then
    return { "xdg-open", path }
  elseif platform == "windows" then
    return { "cmd.exe", "/c", "start", "", path }
  end

  return nil
end

--- Preview an image file in the terminal.
--- @param path string absolute path to the image file
function M.preview(path)
  if not path or path == "" then
    vim.notify("viewim: no file path provided", vim.log.levels.WARN)
    return
  end

  path = resolve_path(path)

  if not config.is_image(path) then
    vim.notify("viewim: not a supported image: " .. path, vim.log.levels.WARN)
    return
  end

  if vim.fn.filereadable(path) ~= 1 then
    vim.notify(
      "viewim: file not readable: " .. path .. " (cwd: " .. vim.fn.getcwd() .. ")",
      vim.log.levels.ERROR
    )
    return
  end

  local term = detect.get_terminal()

  if term == "kitty" then
    M._preview_kitty(path)
  elseif term == "wezterm" then
    M._preview_wezterm(path)
  elseif term == "ghostty" then
    M._preview_ghostty(path)
  else
    vim.notify(
      "viewim: unsupported terminal. Requires kitty, wezterm, or ghostty.",
      vim.log.levels.ERROR
    )
  end
end

--- Open image in a new kitty OS window using kitten icat.
--- @param path string
function M._preview_kitty(path)
  if vim.fn.executable("kitty") ~= 1 then
    vim.notify("viewim: 'kitty' command not found in $PATH", vim.log.levels.ERROR)
    return
  end

  local kitty_opts = (config.options and config.options.kitty) or {}
  local listen_on = kitty_opts.listen_on or os.getenv("KITTY_LISTEN_ON")
  local launch_type = kitty_opts.launch_type or "os-window"
  local can_use_socket = listen_on and listen_on ~= "" and socket_is_available(listen_on)

  local cmd = { "kitty", "@" }
  if can_use_socket then
    vim.list_extend(cmd, { "--to", listen_on })
  elseif listen_on and listen_on ~= "" then
    vim.notify(
      "viewim: kitty socket not found, retrying without --to: " .. listen_on,
      vim.log.levels.WARN
    )
  end

  vim.list_extend(cmd, {
    "launch",
    "--type=" .. launch_type,
    "--cwd=current",
    "--hold",
    "--",
    "kitty",
    "+kitten",
    "icat",
    path,
  })

  local stderr_buf = {}
  vim.fn.jobstart(cmd, {
    detach = true,
    on_stderr = function(_, data)
      if type(data) == "table" then
        vim.list_extend(stderr_buf, data)
      end
    end,
    on_exit = function(_, code)
      local stderr_msg = join_nonempty(stderr_buf)
      local stderr_lower = stderr_msg:lower()
      local tty_issue = stderr_lower:find("/dev/tty", 1, true)
        or stderr_lower:find("controlling terminal", 1, true)
      local socket_missing = stderr_lower:find("failed to connect", 1, true)
        and stderr_lower:find("no such file or directory", 1, true)

      if socket_missing then
        local env_listen = os.getenv("KITTY_LISTEN_ON")
        local retry_listen = nil
        if env_listen and env_listen ~= "" and env_listen ~= listen_on then
          retry_listen = env_listen
        end

        vim.schedule(function()
          shell_launch_kitty(path, retry_listen)
        end)
        return
      end

      if tty_issue then
        vim.schedule(function()
          shell_launch_kitty(path, listen_on)
        end)
        return
      end

      if code == 0 then
        return
      end

      local msg = stderr_msg ~= "" and stderr_msg or ("kitty launch exited with code " .. code)
      vim.schedule(function()
        vim.notify("viewim: kitty error: " .. msg, vim.log.levels.ERROR)
      end)
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

--- Open image via native external app (used for ghostty).
--- @param path string
function M._preview_ghostty(path)
  local ghostty_opts = (config.options and config.options.ghostty) or {}
  local mode = ghostty_opts.mode or "external"

  if mode ~= "external" then
    vim.notify("viewim: ghostty mode must be 'external'", vim.log.levels.ERROR)
    return
  end

  local opener = ghostty_opts.opener or "auto"
  local cmd = build_external_open_cmd(path, opener)
  if not cmd or #cmd == 0 then
    vim.notify("viewim: could not determine external opener for this platform", vim.log.levels.ERROR)
    return
  end

  if opener == "auto" then
    local native = cmd[1]
    if vim.fn.executable(native) ~= 1 then
      vim.notify("viewim: native opener not found: " .. native, vim.log.levels.ERROR)
      return
    end
  elseif vim.fn.executable(cmd[1]) ~= 1 then
    vim.notify("viewim: opener not found: " .. cmd[1], vim.log.levels.ERROR)
    return
  end

  vim.fn.jobstart(cmd, {
    detach = true,
    on_stderr = function(_, data)
      local msg = join_nonempty(data)
      if msg ~= "" then
        vim.schedule(function()
          vim.notify("viewim: ghostty opener error: " .. msg, vim.log.levels.ERROR)
        end)
      end
    end,
  })
end

return M
