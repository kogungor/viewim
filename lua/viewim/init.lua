local config = require("viewim.config")
local preview = require("viewim.preview")

local M = {}

--- Setup viewim with user options and register keymaps for integrations.
--- @param opts table|nil
function M.setup(opts)
  config.setup(opts)

  local key = config.options.keymap
  local integrations = config.options.integrations

  -- nvim-tree integration
  if integrations.nvim_tree then
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("viewim_nvim_tree", { clear = true }),
      pattern = "NvimTree",
      callback = function()
        vim.keymap.set("n", key, function()
          require("viewim.integrations.nvim_tree").preview()
        end, { buffer = true, silent = true, desc = "viewim: preview image" })
      end,
    })
  end

  -- oil.nvim integration
  if integrations.oil then
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("viewim_oil", { clear = true }),
      pattern = "oil",
      callback = function()
        vim.keymap.set("n", key, function()
          require("viewim.integrations.oil").preview()
        end, { buffer = true, silent = true, desc = "viewim: preview image" })
      end,
    })
  end

  -- neo-tree integration
  if integrations.neo_tree then
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("viewim_neo_tree", { clear = true }),
      pattern = "neo-tree",
      callback = function()
        vim.keymap.set("n", key, function()
          require("viewim.integrations.neo_tree").preview()
        end, { buffer = true, silent = true, desc = "viewim: preview image" })
      end,
    })
  end
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

  if ft == "NvimTree" then
    require("viewim.integrations.nvim_tree").preview()
  elseif ft == "oil" then
    require("viewim.integrations.oil").preview()
  elseif ft == "neo-tree" then
    require("viewim.integrations.neo_tree").preview()
  else
    -- Fall back to current buffer
    require("viewim.integrations.buffer").preview()
  end
end

return M
