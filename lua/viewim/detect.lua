local M = {}

--- Detect the current terminal emulator.
--- @return string|nil terminal name ("kitty", "wezterm", "ghostty") or nil if unsupported
function M.get_terminal()
  if os.getenv("KITTY_PID") then
    return "kitty"
  elseif os.getenv("WEZTERM_PANE") then
    return "wezterm"
  elseif (os.getenv("TERM_PROGRAM") or ""):lower() == "ghostty" then
    return "ghostty"
  end
  return nil
end

--- Get platform name for opener selection.
--- @return string platform ("windows", "macos", "linux", "unknown")
function M.get_platform()
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    return "windows"
  elseif vim.fn.has("mac") == 1 then
    return "macos"
  elseif vim.fn.has("unix") == 1 then
    return "linux"
  end
  return "unknown"
end

--- Get native opener command for current platform.
--- @return string|nil
function M.get_native_opener()
  local platform = M.get_platform()
  if platform == "macos" then
    return "open"
  elseif platform == "linux" then
    return "xdg-open"
  elseif platform == "windows" then
    return "cmd.exe"
  end
  return nil
end

--- Check if a CLI tool exists in $PATH.
--- @param cmd string
--- @return boolean
function M.has_command(cmd)
  return vim.fn.executable(cmd) == 1
end

return M
