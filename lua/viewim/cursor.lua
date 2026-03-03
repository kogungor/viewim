local notify = require("viewim.notify")

local M = {}
local HTML_SCAN_RADIUS = 20
local NEAREST_SCAN_RADIUS = 8

local function col_in_range(col, s, e)
  return col >= s and col <= e
end

local function find_img_tag_start(line)
  local i = 1
  while true do
    local s = line:find("<", i, true)
    if not s then
      return nil
    end

    local head = line:sub(s, s + 3)
    if head:lower() == "<img" then
      local next_char = line:sub(s + 4, s + 4)
      if next_char == "" or next_char:match("[%s/>]") then
        return s
      end
    end

    i = s + 1
  end
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

local function first_markdown_image_in_line(line)
  local s, e = line:find("%!%b[]%b()")
  if not s then
    return nil
  end

  local chunk = line:sub(s, e)
  local inside = chunk:match("%((.*)%)")
  return normalize_markdown_target(inside)
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

local function first_markdown_reference_id_in_line(line)
  local s, e = line:find("%!%b[]%b[]")
  if not s then
    return nil
  end

  local chunk = line:sub(s, e)
  local id = chunk:match("^%!%b[]%[([^%]]+)%]$")
  return normalize_reference_id(id)
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
    local s, e = line:find("<[Ii][Mm][Gg][^>]*>", search_from)
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

local function first_html_img_src_in_line(line)
  local s, e = line:find("<[Ii][Mm][Gg][^>]*>")
  if not s then
    return nil
  end

  local tag = line:sub(s, e)
  local src = tag:match('[Ss][Rr][Cc]%s*=%s*"([^"]+)"')
    or tag:match("[Ss][Rr][Cc]%s*=%s*'([^']+)'")
    or tag:match("[Ss][Rr][Cc]%s*=%s*([^%s>]+)")
  return src and vim.trim(src) or nil
end

local function cursor_in_tag(cursor_row, cursor_col, tag)
  if cursor_row < tag.start_row or cursor_row > tag.end_row then
    return false
  end

  if tag.start_row == tag.end_row then
    return col_in_range(cursor_col, tag.start_col, tag.end_col)
  end

  if cursor_row == tag.start_row then
    return cursor_col >= tag.start_col
  end

  if cursor_row == tag.end_row then
    return cursor_col <= tag.end_col
  end

  return true
end

local function html_img_src_under_cursor_multiline(bufnr, cursor_row, cursor_col)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local from_row = math.max(1, cursor_row - HTML_SCAN_RADIUS)
  local to_row = math.min(line_count, cursor_row + HTML_SCAN_RADIUS)
  local lines = vim.api.nvim_buf_get_lines(bufnr, from_row - 1, to_row, false)

  local tags = {}
  local current = nil

  for i, line in ipairs(lines) do
    local row = from_row + i - 1

    if not current then
      local s = find_img_tag_start(line)
      if s then
        local e = line:find(">", s, true)
        if e then
          table.insert(tags, {
            text = line:sub(s, e),
            start_row = row,
            start_col = s,
            end_row = row,
            end_col = e,
          })
        else
          current = {
            text = line:sub(s),
            start_row = row,
            start_col = s,
          }
        end
      end
    else
      local e = line:find(">", 1, true)
      if e then
        current.text = current.text .. "\n" .. line:sub(1, e)
        current.end_row = row
        current.end_col = e
        table.insert(tags, current)
        current = nil
      else
        current.text = current.text .. "\n" .. line
      end
    end
  end

  for _, tag in ipairs(tags) do
    if cursor_in_tag(cursor_row, cursor_col, tag) then
      local src = tag.text:match('[Ss][Rr][Cc]%s*=%s*"([^"]+)"')
        or tag.text:match("[Ss][Rr][Cc]%s*=%s*'([^']+)'")
        or tag.text:match("[Ss][Rr][Cc]%s*=%s*([^%s>]+)")
      return src and vim.trim(src) or nil
    end
  end

  return nil
end

local function html_img_src_near_cursor_multiline(bufnr, cursor_row, cursor_col)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local from_row = math.max(1, cursor_row - HTML_SCAN_RADIUS)
  local to_row = math.min(line_count, cursor_row + HTML_SCAN_RADIUS)
  local lines = vim.api.nvim_buf_get_lines(bufnr, from_row - 1, to_row, false)

  local tags = {}
  local current = nil

  for i, line in ipairs(lines) do
    local row = from_row + i - 1

    if not current then
      local s = find_img_tag_start(line)
      if s then
        local e = line:find(">", s, true)
        if e then
          table.insert(tags, {
            text = line:sub(s, e),
            start_row = row,
            start_col = s,
            end_row = row,
            end_col = e,
          })
        else
          current = {
            text = line:sub(s),
            start_row = row,
            start_col = s,
          }
        end
      end
    else
      local e = line:find(">", 1, true)
      if e then
        current.text = current.text .. "\n" .. line:sub(1, e)
        current.end_row = row
        current.end_col = e
        table.insert(tags, current)
        current = nil
      else
        current.text = current.text .. "\n" .. line
      end
    end
  end

  local best_src = nil
  local best_dist = nil

  for _, tag in ipairs(tags) do
    local src = tag.text:match('[Ss][Rr][Cc]%s*=%s*"([^"]+)"')
      or tag.text:match("[Ss][Rr][Cc]%s*=%s*'([^']+)'")
      or tag.text:match("[Ss][Rr][Cc]%s*=%s*([^%s>]+)")

    if src and vim.trim(src) ~= "" then
      local row_dist = 0
      if cursor_row < tag.start_row then
        row_dist = tag.start_row - cursor_row
      elseif cursor_row > tag.end_row then
        row_dist = cursor_row - tag.end_row
      end

      local col_dist = 0
      if cursor_row == tag.start_row and cursor_col < tag.start_col then
        col_dist = tag.start_col - cursor_col
      elseif cursor_row == tag.end_row and cursor_col > tag.end_col then
        col_dist = cursor_col - tag.end_col
      end

      local dist = row_dist * 1000 + col_dist
      if not best_dist or dist < best_dist then
        best_dist = dist
        best_src = vim.trim(src)
      end
    end
  end

  return best_src, best_dist
end

local function nearest_source_around_cursor(bufnr, row)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local function source_from_line(line)
    local src = first_markdown_image_in_line(line)
    if src then
      return src
    end

    local ref_id = first_markdown_reference_id_in_line(line)
    if ref_id then
      local resolved = resolve_markdown_reference(ref_id, bufnr)
      if resolved then
        return resolved
      end
    end

    return first_html_img_src_in_line(line)
  end

  local current_line = lines[row]
  if current_line then
    local src = source_from_line(current_line)
    if src then
      return src, 0
    end
  end

  for offset = 1, NEAREST_SCAN_RADIUS do
    local up = row - offset
    if up >= 1 and up <= line_count then
      local src = source_from_line(lines[up])
      if src then
        return src, offset
      end
    end

    local down = row + offset
    if down >= 1 and down <= line_count then
      local src = source_from_line(lines[down])
      if src then
        return src, offset
      end
    end
  end

  return nil, nil
end

--- Extract image source under cursor from markdown/html image syntax.
--- @return string|nil
--- @return string|nil
function M.get_image_source_under_cursor()
  local pos = vim.api.nvim_win_get_cursor(0)
  local bufnr = vim.api.nvim_get_current_buf()
  local row = pos[1]
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
    if not src then
      src = html_img_src_under_cursor_multiline(bufnr, row, col)
    end
  end

  if not src then
    local html_src, html_dist = html_img_src_near_cursor_multiline(bufnr, row, col)
    local line_src, line_dist = nearest_source_around_cursor(bufnr, row)

    if html_src and line_src then
      if (line_dist or 0) <= (html_dist or 0) then
        src = line_src
      else
        src = html_src
      end
    else
      src = line_src or html_src
    end
  end

  if not src then
    return nil, "viewim: no markdown/html image source near cursor"
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
