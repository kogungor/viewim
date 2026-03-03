local M = {}

function M.is_available()
  local ok = pcall(require, "telescope")
  return ok
end

function M.open(items, opts)
  opts = opts or {}

  local has_telescope, _ = pcall(require, "telescope")
  if not has_telescope then
    return false, "telescope not available"
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = opts.prompt or "SearchImage",
    finder = finders.new_table({
      results = items,
      entry_maker = function(item)
        local text = item.label or item.path or tostring(item)
        return {
          value = item,
          display = text,
          ordinal = text,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection and selection.value and type(opts.on_select) == "function" then
          opts.on_select(selection.value)
        end
      end)

      map("i", "<Space>", function()
        local selection = action_state.get_selected_entry()
        if selection and selection.value and type(opts.on_alt_select) == "function" then
          opts.on_alt_select(selection.value)
        end
      end)

      map("n", "<Space>", function()
        local selection = action_state.get_selected_entry()
        if selection and selection.value and type(opts.on_alt_select) == "function" then
          opts.on_alt_select(selection.value)
        end
      end)

      return true
    end,
  }):find()

  return true
end

return M
