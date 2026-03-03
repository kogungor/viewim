local M = {}

local function get_select_fn()
  local ok_snacks, snacks = pcall(require, "snacks")
  if ok_snacks and snacks and snacks.picker and type(snacks.picker.select) == "function" then
    return snacks.picker.select
  end

  local ok_picker, picker = pcall(require, "snacks.picker")
  if ok_picker and picker and type(picker.select) == "function" then
    return picker.select
  end

  return nil
end

function M.is_available()
  return get_select_fn() ~= nil
end

function M.open(items, opts)
  opts = opts or {}
  local select_fn = get_select_fn()
  if not select_fn then
    return false, "snacks picker not available"
  end

  select_fn(items, {
    prompt = opts.prompt or "SearchImage>",
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
