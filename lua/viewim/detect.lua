local M = {}

--- Detect the current terminal emulator.
--- @return string|nil terminal name ("kitty", "wezterm") or nil if unsupported
function M.get_terminal()
  if os.getenv("KITTY_PID") then
    return "kitty"
  elseif os.getenv("WEZTERM_PANE") then
    return "wezterm"
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
