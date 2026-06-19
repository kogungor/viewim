local M = {}

function M.is_available()
  local ok = pcall(require, "fzf-lua")
  return ok
end

function M.open(items, opts)
  opts = opts or {}
  local fzf = require("fzf-lua")

  local index = {}
  local entries = {}
  for _, item in ipairs(items) do
    local label = item.label or item.path or tostring(item)
    index[label] = item
    table.insert(entries, label)
  end

  local preview_seq = 0

  local function trigger_change(selected)
    if type(opts.on_change) ~= "function" then
      return
    end
    local item = selected and index[selected[1]]
    if not item then
      return
    end
    preview_seq = preview_seq + 1
    local seq = preview_seq
    vim.defer_fn(function()
      if seq == preview_seq then
        opts.on_change(item)
      end
    end, 50)
  end

  fzf.fzf_exec(entries, {
    prompt = opts.prompt or "SearchImage> ",
    fzf_opts = { ["--no-multi"] = true },
    actions = {
      ["default"] = function(selected)
        if not selected or not selected[1] then
          return
        end
        local item = index[selected[1]]
        if item and type(opts.on_select) == "function" then
          opts.on_select(item)
        end
      end,
      ["space"] = function(selected)
        if not selected or not selected[1] then
          return
        end
        local item = index[selected[1]]
        if item and type(opts.on_alt_select) == "function" then
          opts.on_alt_select(item)
        end
      end,
    },
    fn_transform = function(entry)
      return entry
    end,
    -- fzf-lua fires on_select for each focus change when preview is wired;
    -- use a debounced change callback instead
    preview = function(selected)
      trigger_change(selected)
    end,
  })

  return true
end

return M
