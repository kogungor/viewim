local config = require("viewim.config")

local M = {}

local function fuzzy_match(query, text)
  if query == "" then
    return true
  end

  local q = query:lower()
  local t = text:lower()
  local j = 1

  for i = 1, #t do
    if t:sub(i, i) == q:sub(j, j) then
      j = j + 1
      if j > #q then
        return true
      end
    end
  end

  return false
end

local function collect_by_extensions(root, extensions, include_hidden)
  local unique = {}
  local paths = {}

  for _, ext in ipairs(extensions) do
    local pattern = "**/*" .. ext
    local matches = vim.fn.globpath(root, pattern, false, true)
    for _, path in ipairs(matches) do
      local normalized = vim.fs.normalize(path)
      if not unique[normalized] then
        unique[normalized] = true
        table.insert(paths, normalized)
      end
    end

    if include_hidden then
      local hidden_pattern = "**/.*" .. ext
      local hidden = vim.fn.globpath(root, hidden_pattern, false, true)
      for _, path in ipairs(hidden) do
        local normalized = vim.fs.normalize(path)
        if not unique[normalized] then
          unique[normalized] = true
          table.insert(paths, normalized)
        end
      end
    end
  end

  return paths
end

--- Find image files in current project with optional fuzzy query.
--- @param query string|nil
--- @return table[]
function M.find(query)
  if not config.options or vim.tbl_isempty(config.options) then
    config.setup({})
  end

  local opts = config.options.search or {}
  local root = vim.fn.getcwd()
  local q = vim.trim(query or "")

  local raw_paths = collect_by_extensions(
    root,
    config.options.supported_extensions or {},
    opts.include_hidden == true
  )

  local items = {}
  for _, path in ipairs(raw_paths) do
    local relative = vim.fn.fnamemodify(path, ":.")
    local basename = vim.fn.fnamemodify(path, ":t")

    if q == "" or fuzzy_match(q, basename) or fuzzy_match(q, relative) then
      table.insert(items, {
        path = path,
        label = relative,
        name = basename,
      })
    end
  end

  table.sort(items, function(a, b)
    if a.name == b.name then
      return a.label < b.label
    end
    return a.name < b.name
  end)

  local max_results = opts.max_results or 500
  if #items > max_results then
    local limited = {}
    for i = 1, max_results do
      limited[i] = items[i]
    end
    items = limited
  end

  return items
end

return M
