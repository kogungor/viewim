local M = {}

local function get_snacks()
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks and snacks.picker then
    return snacks
  end
  local ok2, sp = pcall(require, "snacks.picker")
  if ok2 and sp then
    return { picker = sp }
  end
  return nil
end

function M.is_available()
  return get_snacks() ~= nil
end

local function open_with_pick(snacks, items, opts)
  local index = {}
  local formatted = {}
  for i, item in ipairs(items) do
    local label = item.label or item.path or tostring(item)
    index[i] = item
    table.insert(formatted, { text = label, idx = i, file = item.path })
  end

  local preview_seq = 0

  snacks.picker.pick({
    title = opts.prompt or "SearchImage",
    items = formatted,
    format = function(item, _ctx)
      return { { item.text } }
    end,
    confirm = function(picker, item)
      picker:close()
      if item and type(opts.on_select) == "function" then
        opts.on_select(index[item.idx])
      end
    end,
    on_change = function(_picker, item)
      if not item then
        return
      end
      if type(opts.on_change) ~= "function" then
        return
      end
      preview_seq = preview_seq + 1
      local seq = preview_seq
      vim.defer_fn(function()
        if seq == preview_seq then
          opts.on_change(index[item.idx])
        end
      end, 50)
    end,
    actions = {
      viewim_space = function(picker, item)
        picker:close()
        if item and type(opts.on_alt_select) == "function" then
          opts.on_alt_select(index[item.idx])
        end
      end,
    },
    win = {
      input = {
        keys = {
          ["<Space>"] = { "viewim_space", mode = { "i", "n" } },
        },
      },
    },
  })

  return true
end

local function open_with_select(snacks, items, opts)
  snacks.picker.select(items, {
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

function M.open(items, opts)
  opts = opts or {}
  local snacks = get_snacks()
  if not snacks then
    return false, "snacks picker not available"
  end

  if type(snacks.picker.pick) == "function" then
    return open_with_pick(snacks, items, opts)
  end

  return open_with_select(snacks, items, opts)
end

return M
