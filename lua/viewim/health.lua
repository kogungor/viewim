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
    vim.health.warn("No supported terminal detected (need kitty, wezterm, ghostty, or iTerm2)")
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
  elseif term == "iterm2" then
    local cfg = config.options
    local iterm2 = cfg.iterm2 or {}
    if iterm2.enabled == false then
      vim.health.warn("iTerm2 backend is disabled (iterm2.enabled = false)")
    else
      local imgcat_paths = {
        "imgcat",
        "/usr/local/bin/imgcat",
        vim.fn.expand("~") .. "/.iterm2/imgcat",
      }
      local found = nil
      for _, p in ipairs(imgcat_paths) do
        if vim.fn.executable(p) == 1 then
          found = p
          break
        end
      end
      if found then
        vim.health.ok("'imgcat' found: " .. found)
      else
        vim.health.error(
          "'imgcat' not found — install via iTerm2 shell integration: "
            .. "curl -L https://iterm2.com/shell_integration/install_shell_integration.bash | bash"
        )
      end
    end
  elseif term == "ghostty" then
    local cfg = config.options
    local ghostty = cfg.ghostty or {}
    local mode = ghostty.mode or "external"

    if mode == "tmux" then
      if detect.has_command("tmux") then
        vim.health.ok("'tmux' command found in $PATH")
      else
        vim.health.error("'tmux' command not found in $PATH")
      end

      if os.getenv("TMUX") then
        vim.health.ok("inside tmux session")
      else
        vim.health.warn("ghostty tmux mode requires running nvim inside tmux")
      end

      local tmux_command = ghostty.tmux_command or ""
      if tmux_command ~= "" then
        vim.health.ok("ghostty tmux command configured: " .. tmux_command)
      else
        vim.health.error("ghostty tmux command is empty")
      end
    else
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

  vim.health.start("viewim search")
  local search = cfg.search or {}
  if search.enabled == false then
    vim.health.info("search is disabled")
  else
    vim.health.ok("search is enabled")
    vim.health.info("search.preferred_picker = " .. tostring(search.preferred_picker or "auto"))

    local has_telescope = pcall(require, "telescope")
    local has_snacks = pcall(require, "snacks") or pcall(require, "snacks.picker")
    local has_fzflua = pcall(require, "fzf-lua")

    if has_telescope then
      vim.health.ok("telescope is available")
    else
      vim.health.info("telescope is not installed (optional)")
    end

    if has_snacks then
      vim.health.ok("snacks picker is available")
    else
      vim.health.info("snacks picker is not installed (optional)")
    end

    if has_fzflua then
      vim.health.ok("fzf-lua is available")
    else
      vim.health.info("fzf-lua is not installed (optional)")
    end

    local pickers = require("viewim.pickers")
    local backend_name = pickers.resolve_backend(search.preferred_picker or "auto")
    if backend_name then
      vim.health.ok("active search picker backend: " .. backend_name)
    else
      vim.health.error("no search picker backend available")
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
    vim.health.warn("AVIF rendering depends on terminal/image codec support and may fail on some systems")
  else
    vim.health.info("'.avif' is not enabled in supported_extensions")
  end

  local svg_opts = cfg.svg or {}
  if svg_opts.enabled == false then
    vim.health.info("SVG support is disabled (svg.enabled = false)")
  else
    local converter = svg_opts.converter or "auto"
    local has_rsvg = detect.has_command("rsvg-convert")
    local has_magick = detect.has_command("magick")

    if converter == "rsvg-convert" then
      if has_rsvg then
        vim.health.ok("SVG converter: rsvg-convert found")
      else
        vim.health.error("SVG converter 'rsvg-convert' not found (brew install librsvg / apt install librsvg2-bin)")
      end
    elseif converter == "magick" then
      if has_magick then
        vim.health.ok("SVG converter: magick (ImageMagick) found")
      else
        vim.health.error("SVG converter 'magick' not found (brew install imagemagick / apt install imagemagick)")
      end
    else
      -- auto
      if has_rsvg then
        vim.health.ok("SVG converter: rsvg-convert found (auto)")
      elseif has_magick then
        vim.health.ok("SVG converter: magick (ImageMagick) found (auto)")
      else
        vim.health.warn(
          "No SVG converter found — SVG preview will fail. "
            .. "Install rsvg-convert (librsvg) or magick (ImageMagick)"
        )
      end
    end
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
