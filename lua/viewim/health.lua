local M = {}

function M.check()
  vim.health.start("viewim")

  -- Check Neovim version
  if vim.fn.has("nvim-0.9") == 1 then
    vim.health.ok("Neovim >= 0.9")
  else
    vim.health.error("Neovim >= 0.9 is required")
  end

  -- Detect terminal
  local detect = require("viewim.detect")
  local term = detect.get_terminal()

  if term then
    vim.health.ok("Terminal detected: " .. term)
  else
    vim.health.warn("No supported terminal detected (need kitty or wezterm)")
  end

  -- Check CLI tools
  if term == "kitty" then
    if detect.has_command("kitty") then
      vim.health.ok("'kitty' command found in $PATH")
    else
      vim.health.error("'kitty' command not found in $PATH (needed for launch)")
    end

    if detect.has_command("kitten") then
      vim.health.ok("'kitten' command found in $PATH")
    else
      vim.health.error("'kitten' command not found in $PATH (required for icat)")
    end
  elseif term == "wezterm" then
    if detect.has_command("wezterm") then
      vim.health.ok("'wezterm' command found in $PATH")
    else
      vim.health.error("'wezterm' command not found in $PATH")
    end
  end

  -- Check optional integrations
  vim.health.start("viewim integrations")

  local integrations = {
    { name = "nvim-tree", module = "nvim-tree.api" },
    { name = "oil.nvim", module = "oil" },
    { name = "neo-tree", module = "neo-tree.sources.manager" },
  }

  for _, int in ipairs(integrations) do
    local ok, _ = pcall(require, int.module)
    if ok then
      vim.health.ok(int.name .. " is available")
    else
      vim.health.info(int.name .. " is not installed (optional)")
    end
  end
end

return M
