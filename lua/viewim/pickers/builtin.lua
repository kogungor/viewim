local M = {}

function M.is_available()
  return true
end

function M.open(items, opts)
  opts = opts or {}

  vim.ui.select(items, {
    prompt = opts.prompt or "Select image>",
    format_item = function(item)
      return item.label or item.path or tostring(item)
    end,
  }, function(choice)
    if not choice then
      return
    end
    if type(opts.on_select) == "function" then
      opts.on_select(choice)
    end
  end)

  return true
end

return M
