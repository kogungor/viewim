local config = require("viewim.config")
local detect = require("viewim.detect")
local preview = require("viewim.preview")
local uv = vim.uv or vim.loop

local M = {}
local auto_preview_state = {}

local function ensure_config_initialized()
  if not config.options or vim.tbl_isempty(config.options) then
    config.setup({})
  end
end

local function map_preview_keys(bufnr, key, module_name)
  vim.keymap.set("n", key, function()
    require(module_name).preview()
  end, { buffer = bufnr, silent = true, desc = "viewim: preview image" })

  local mouse = config.options.mouse_preview or {}
  if mouse.enabled and type(mouse.key) == "string" and mouse.key ~= "" then
    vim.keymap.set("n", mouse.key, function()
      require(module_name).preview()
    end, { buffer = bufnr, silent = true, desc = "viewim: mouse preview image" })
  end
end

local function setup_auto_preview(bufnr, module_name)
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end

  local opts = config.options.explorer_auto_preview or {}
  if not opts.enabled then
    return
  end

  if vim.b[bufnr].viewim_auto_preview_attached then
    return
  end
  vim.b[bufnr].viewim_auto_preview_attached = true

  local state = auto_preview_state[bufnr]
  if not state then
    state = {
      timer = uv.new_timer(),
      pending_path = nil,
      last_path = nil,
    }
    auto_preview_state[bufnr] = state
  end

  local group = vim.api.nvim_create_augroup("viewim_auto_preview", { clear = false })
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    buffer = bufnr,
    callback = function()
      local integration = require(module_name)
      local get_path = integration.get_candidate_path
      if type(get_path) ~= "function" then
        return
      end

      local candidate = get_path({ silent = true })
      if not candidate or candidate == "" then
        return
      end

      local auto_opts = config.options.explorer_auto_preview or opts
      if auto_opts.only_images and not config.is_image(candidate) then
        return
      end

      state.pending_path = candidate
      state.timer:stop()
      state.timer:start(auto_opts.debounce_ms, 0, function()
        local path_value = state.pending_path
        if not path_value or path_value == state.last_path then
          return
        end

        state.last_path = path_value
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return
          end

          if vim.api.nvim_get_current_buf() ~= bufnr then
            return
          end

          preview.preview(path_value)
        end)
      end)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      local current = auto_preview_state[bufnr]
      if not current then
        return
      end

      current.timer:stop()
      current.timer:close()
      auto_preview_state[bufnr] = nil
    end,
  })
end

--- Setup viewim with user options and register keymaps for integrations.
--- @param opts table|nil
function M.setup(opts)
  config.setup(opts)

  local key = config.options.keymap
  local integrations = config.options.integrations

  -- nvim-tree integration
  if integrations.nvim_tree and integrations.nvim_tree.enabled then
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("viewim_nvim_tree", { clear = true }),
      pattern = "NvimTree",
      callback = function(args)
        map_preview_keys(args.buf, key, "viewim.integrations.nvim_tree")
        setup_auto_preview(args.buf, "viewim.integrations.nvim_tree")
      end,
    })
  end

  -- oil.nvim integration
  if integrations.oil and integrations.oil.enabled then
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("viewim_oil", { clear = true }),
      pattern = "oil",
      callback = function(args)
        map_preview_keys(args.buf, key, "viewim.integrations.oil")
        setup_auto_preview(args.buf, "viewim.integrations.oil")
      end,
    })
  end

  -- neo-tree integration
  if integrations.neo_tree and integrations.neo_tree.enabled then
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("viewim_neo_tree", { clear = true }),
      pattern = "neo-tree",
      callback = function(args)
        map_preview_keys(args.buf, key, "viewim.integrations.neo_tree")
        setup_auto_preview(args.buf, "viewim.integrations.neo_tree")
      end,
    })
  end
end

function M.is_enabled()
  ensure_config_initialized()
  return config.options.enabled == true
end

function M.enable()
  ensure_config_initialized()
  config.options.enabled = true
  vim.notify("viewim: enabled", vim.log.levels.INFO)
end

function M.disable()
  ensure_config_initialized()
  config.options.enabled = false
  vim.notify("viewim: disabled", vim.log.levels.INFO)
end

function M.toggle()
  ensure_config_initialized()
  config.options.enabled = not M.is_enabled()
  if config.options.enabled then
    vim.notify("viewim: enabled", vim.log.levels.INFO)
  else
    vim.notify("viewim: disabled", vim.log.levels.INFO)
  end
end

function M.status()
  ensure_config_initialized()
  local enabled = config.options.enabled and "enabled" or "disabled"
  local term = detect.get_terminal() or "unsupported"
  local remote = (config.options.remote and config.options.remote.enabled) and "on" or "off"
  vim.notify("viewim: " .. enabled .. " | terminal: " .. term .. " | remote: " .. remote, vim.log.levels.INFO)
end

--- Preview an image. Detects context automatically or accepts a path.
--- @param path string|nil optional file path; if nil, detects from context
function M.view(path)
  -- If a path was explicitly provided, use it directly
  if path and path ~= "" then
    preview.preview(path)
    return
  end

  -- Auto-detect context based on current filetype
  local ft = vim.bo.filetype
  local integrations = config.options.integrations or {}

  if ft == "NvimTree" and integrations.nvim_tree and integrations.nvim_tree.enabled then
    require("viewim.integrations.nvim_tree").preview()
  elseif ft == "oil" and integrations.oil and integrations.oil.enabled then
    require("viewim.integrations.oil").preview()
  elseif ft == "neo-tree" and integrations.neo_tree and integrations.neo_tree.enabled then
    require("viewim.integrations.neo_tree").preview()
  else
    -- Fall back to current buffer
    require("viewim.integrations.buffer").preview()
  end
end

return M
