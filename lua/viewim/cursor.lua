local notify = require("viewim.notify")

local M = {}

local function col_in_range(col, s, e)
  return col >= s and col <= e
end

local function normalize_markdown_target(raw)
  if type(raw) ~= "string" then
    return nil
  end

  local value = vim.trim(raw)
  if value == "" then
    return nil
  end

  if value:sub(1, 1) == "<" and value:sub(-1) == ">" then
    value = value:sub(2, -2)
  end

  if (value:sub(1, 1) == '"' and value:sub(-1) == '"')
    or (value:sub(1, 1) == "'" and value:sub(-1) == "'") then
    value = value:sub(2, -2)
  end

  local first = value:match("^([^%s]+)")
  local target = first or value

  if target:sub(1, 1) == "<" and target:sub(-1) == ">" then
    target = target:sub(2, -2)
  end

  if (target:sub(1, 1) == '"' and target:sub(-1) == '"')
    or (target:sub(1, 1) == "'" and target:sub(-1) == "'") then
    target = target:sub(2, -2)
  end

  return target
end

local function normalize_reference_id(raw)
  if type(raw) ~= "string" then
    return nil
  end

  local value = vim.trim(raw):lower()
  if value == "" then
    return nil
  end

  value = value:gsub("%s+", " ")
  return value
end

local function maybe_map_root_relative(path_value)
  if type(path_value) ~= "string" then
    return path_value
  end

  if path_value:sub(1, 1) ~= "/" then
    return path_value
  end

  if path_value:match("^https?://") then
    return path_value
  end

  if vim.fn.filereadable(path_value) == 1 then
    return path_value
  end

  local mapped = vim.fs.normalize(vim.fn.getcwd() .. path_value)
  if vim.fn.filereadable(mapped) == 1 then
    return mapped
  end

  return path_value
end

local function markdown_image_under_cursor(line, col)
  local search_from = 1
  while true do
    local s, e = line:find("%!%b[]%b()", search_from)
    if not s then
      return nil
    end

    if col_in_range(col, s, e) then
      local chunk = line:sub(s, e)
      local inside = chunk:match("%((.*)%)")
      return normalize_markdown_target(inside)
    end

    search_from = e + 1
  end
end

local function markdown_reference_id_under_cursor(line, col)
  local search_from = 1
  while true do
    local s, e = line:find("%!%b[]%b[]", search_from)
    if not s then
      return nil
    end

    if col_in_range(col, s, e) then
      local chunk = line:sub(s, e)
      local id = chunk:match("^%!%b[]%[([^%]]+)%]$")
      return normalize_reference_id(id)
    end

    search_from = e + 1
  end
end

local function resolve_markdown_reference(id, bufnr)
  local wanted = normalize_reference_id(id)
  if not wanted then
    return nil
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for _, line in ipairs(lines) do
    local ref_id, rhs = line:match("^%s*%[([^%]]+)%]%s*:%s*(.+)%s*$")
    if ref_id and rhs and normalize_reference_id(ref_id) == wanted then
      return normalize_markdown_target(rhs)
    end
  end

  return nil
end

local function html_img_src_under_cursor(line, col)
  local search_from = 1
  while true do
    local s, e = line:find("<[Ii][Mm][Gg]%s+.-/?>", search_from)
    if not s then
      return nil
    end

    if col_in_range(col, s, e) then
      local tag = line:sub(s, e)
      local src = tag:match('[Ss][Rr][Cc]%s*=%s*"([^"]+)"')
        or tag:match("[Ss][Rr][Cc]%s*=%s*'([^']+)'")
        or tag:match("[Ss][Rr][Cc]%s*=%s*([^%s>]+)")
      return src and vim.trim(src) or nil
    end

    search_from = e + 1
  end
end

--- Extract image source under cursor from markdown/html image syntax.
--- @return string|nil
--- @return string|nil
function M.get_image_source_under_cursor()
  local pos = vim.api.nvim_win_get_cursor(0)
  local bufnr = vim.api.nvim_get_current_buf()
  local col = pos[2] + 1
  local line = vim.api.nvim_get_current_line()

  local src = markdown_image_under_cursor(line, col)
  if not src then
    local ref_id = markdown_reference_id_under_cursor(line, col)
    if ref_id then
      src = resolve_markdown_reference(ref_id, bufnr)
      if not src then
        return nil, "viewim: markdown image reference not found: [" .. ref_id .. "]"
      end
    end
  end

  if not src then
    src = html_img_src_under_cursor(line, col)
  end

  if not src then
    return nil, "viewim: no markdown/html image source under cursor"
  end

  return maybe_map_root_relative(src), nil
end

function M.preview_at_cursor()
  local src, err = M.get_image_source_under_cursor()
  if not src then
    notify.warn(err or "viewim: no markdown/html image source under cursor")
    return false
  end

  require("viewim.preview").preview(src)
  return true
end

return M
