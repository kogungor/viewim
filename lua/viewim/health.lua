local M = {}

function M.check()
  vim.health.start("viewim")
  local config = require("viewim.config")
  local renderers = require("viewim.renderers")
  if not config.options or vim.tbl_isempty(config.options) then
    config.setup({})
  end

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
    vim.health.warn("No supported terminal detected (need kitty, wezterm, or ghostty)")
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

    local cfg = config.options
    local listen_on = (cfg.kitty and cfg.kitty.listen_on) or os.getenv("KITTY_LISTEN_ON")
    if listen_on and listen_on ~= "" then
      local sock_path = listen_on:match("^unix:(.+)$")
      if sock_path then
        if vim.fn.getftype(sock_path) == "socket" then
          vim.health.ok("kitty remote socket available")
        else
          vim.health.warn("kitty listen_on set but socket is missing: " .. sock_path)
        end
      else
        vim.health.ok("kitty remote endpoint configured")
      end
    else
      vim.health.warn("KITTY_LISTEN_ON is empty (set kitty.listen_on or kitty listen_on config)")
    end
  elseif term == "wezterm" then
    if detect.has_command("wezterm") then
      vim.health.ok("'wezterm' command found in $PATH")
    else
      vim.health.error("'wezterm' command not found in $PATH")
    end
  elseif term == "ghostty" then
    local cfg = config.options
    local ghostty = cfg.ghostty or {}
    local opener = ghostty.opener or "auto"

    if opener == "auto" then
      local native = detect.get_native_opener()
      if native and detect.has_command(native) then
        vim.health.ok("native opener found: " .. native)
      elseif native then
        vim.health.error("native opener not found: " .. native)
      else
        vim.health.error("could not determine native opener for this platform")
      end
    elseif detect.has_command(opener) then
      vim.health.ok("ghostty opener found: " .. opener)
    else
      vim.health.error("ghostty opener not found: " .. opener)
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

  vim.health.start("viewim remote")
  local cfg = config.options
  local remote = cfg.remote or {}

  if remote.enabled == false then
    vim.health.info("remote preview is disabled")
  else
    if detect.has_command("curl") then
      vim.health.ok("'curl' command found in $PATH")
    else
      vim.health.error("'curl' command not found in $PATH (required for URL preview)")
    end

    if type(remote.cache_dir) == "string" and remote.cache_dir ~= "" then
      vim.health.ok("remote cache dir configured: " .. remote.cache_dir)
    else
      vim.health.error("remote cache dir is not configured")
    end
  end

  vim.health.start("viewim format support")
  local extensions = cfg.supported_extensions or {}
  local has_avif = false
  for _, ext in ipairs(extensions) do
    if ext == ".avif" then
      has_avif = true
      break
    end
  end

  if has_avif then
    vim.health.info("'.avif' is enabled in supported_extensions")
    vim.health.warn(
      "AVIF rendering depends on terminal/image codec support and may fail on some systems"
    )
  else
    vim.health.info("'.avif' is not enabled in supported_extensions")
  end

  vim.health.start("viewim experimental")
  local experimental = cfg.experimental or {}
  if experimental.internal_render then
    vim.health.info("experimental.internal_render is enabled")
    local supported, reason = renderers.is_supported(term)
    if supported then
      vim.health.ok("internal render capability detected")
    else
      vim.health.warn("internal render not available: " .. (reason or "unknown reason"))
    end
  else
    vim.health.info("experimental.internal_render is disabled")
    if type(experimental._auto_disabled_reason) == "string" and experimental._auto_disabled_reason ~= "" then
      vim.health.warn("internal render auto-disabled in this session: " .. experimental._auto_disabled_reason)
    end
  end
end

return M
