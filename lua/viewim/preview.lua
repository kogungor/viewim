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
  local launcher = "kitty"
  if vim.fn.executable(launcher) ~= 1 then
    vim.notify("viewim: 'kitty' command not found in $PATH", vim.log.levels.ERROR)
    return
  end

  local listen_on = os.getenv("KITTY_LISTEN_ON")

  local cmd = { launcher, "@" }
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

  local out = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    local msg = (out or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" then
      msg = "command failed with exit code " .. vim.v.shell_error
    end
    vim.notify("viewim: kitty error: " .. msg, vim.log.levels.ERROR)
  end
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
