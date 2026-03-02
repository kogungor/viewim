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

local function shell_launch_kitty(path, listen_on)
  local parts = { "kitty", "@" }
  if listen_on and listen_on ~= "" then
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
  if vim.fn.executable("kitty") ~= 1 then
    vim.notify("viewim: 'kitty' command not found in $PATH", vim.log.levels.ERROR)
    return
  end

  local listen_on = os.getenv("KITTY_LISTEN_ON")
  local cmd = { "kitty", "@" }
  if listen_on and listen_on ~= "" then
    vim.list_extend(cmd, { "--to", listen_on })
  end

  vim.list_extend(cmd, {
    "launch",
    "--type=os-window",
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

return M
