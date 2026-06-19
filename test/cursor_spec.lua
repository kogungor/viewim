local MiniTest = require("mini.test")
local cursor = require("viewim.cursor")

local T = MiniTest.new_set()

-- Helper: create a scratch buffer with given lines, position cursor, run fn, then clean up.
-- row is 1-indexed, col is 0-indexed (Neovim API convention).
local function with_buffer(lines, row, col, fn)
  local orig_bufnr = vim.api.nvim_get_current_buf()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, bufnr)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { row, col })

  local ok, err = pcall(fn)

  vim.api.nvim_win_set_buf(0, orig_bufnr)
  vim.api.nvim_buf_delete(bufnr, { force = true })

  if not ok then
    error(err, 2)
  end
end

-- Inline markdown image
T["inline markdown"] = MiniTest.new_set()

T["inline markdown"]["extracts http url from ![alt](url)"] = function()
  with_buffer({ "![alt text](https://example.com/photo.png)" }, 1, 0, function()
    local src, err = cursor.get_image_source_under_cursor()
    MiniTest.expect.equality(err, nil)
    MiniTest.expect.equality(src, "https://example.com/photo.png")
  end)
end

T["inline markdown"]["extracts url when cursor is mid-link"] = function()
  with_buffer({ "before ![alt](https://example.com/image.jpg) after" }, 1, 10, function()
    local src, err = cursor.get_image_source_under_cursor()
    MiniTest.expect.equality(err, nil)
    MiniTest.expect.equality(src, "https://example.com/image.jpg")
  end)
end

T["inline markdown"]["returns nil when cursor is outside any image syntax"] = function()
  with_buffer({ "just some plain text here" }, 1, 0, function()
    local src, err = cursor.get_image_source_under_cursor()
    MiniTest.expect.equality(src, nil)
    MiniTest.expect.no_equality(err, nil)
  end)
end

T["inline markdown"]["extracts local file path"] = function()
  local tmp = vim.fn.tempname() .. ".png"
  vim.fn.writefile({}, tmp)

  with_buffer({ "![alt](" .. tmp .. ")" }, 1, 0, function()
    local src, err = cursor.get_image_source_under_cursor()
    MiniTest.expect.equality(err, nil)
    MiniTest.expect.equality(src, vim.fs.normalize(tmp))
  end)

  vim.fn.delete(tmp)
end

-- Reference-style markdown
T["reference markdown"] = MiniTest.new_set()

T["reference markdown"]["resolves ![alt][ref] using [ref]: definition"] = function()
  with_buffer({
    "![logo][img-ref]",
    "",
    "[img-ref]: https://example.com/logo.png",
  }, 1, 0, function()
    local src, err = cursor.get_image_source_under_cursor()
    MiniTest.expect.equality(err, nil)
    MiniTest.expect.equality(src, "https://example.com/logo.png")
  end)
end

T["reference markdown"]["returns nil src when ref has no definition"] = function()
  with_buffer({ "![alt][missing-ref]" }, 1, 0, function()
    local src = cursor.get_image_source_under_cursor()
    MiniTest.expect.equality(src, nil)
  end)
end

T["reference markdown"]["ref lookup is case-insensitive"] = function()
  with_buffer({
    "![alt][MyRef]",
    "[myref]: https://example.com/image.png",
  }, 1, 0, function()
    local src, err = cursor.get_image_source_under_cursor()
    MiniTest.expect.equality(err, nil)
    MiniTest.expect.equality(src, "https://example.com/image.png")
  end)
end

-- HTML img tag (single line)
T["html img single-line"] = MiniTest.new_set()

T["html img single-line"]["extracts src from double-quoted attribute"] = function()
  with_buffer({ '<img src="https://example.com/banner.png">' }, 1, 0, function()
    local src, err = cursor.get_image_source_under_cursor()
    MiniTest.expect.equality(err, nil)
    MiniTest.expect.equality(src, "https://example.com/banner.png")
  end)
end

T["html img single-line"]["extracts src from single-quoted attribute"] = function()
  with_buffer({ "<img src='https://example.com/icon.gif'>", "" }, 1, 0, function()
    local src, err = cursor.get_image_source_under_cursor()
    MiniTest.expect.equality(err, nil)
    MiniTest.expect.equality(src, "https://example.com/icon.gif")
  end)
end

T["html img single-line"]["is case-insensitive for tag and attribute names"] = function()
  with_buffer({ '<IMG SRC="https://example.com/image.png">' }, 1, 0, function()
    local src, err = cursor.get_image_source_under_cursor()
    MiniTest.expect.equality(err, nil)
    MiniTest.expect.equality(src, "https://example.com/image.png")
  end)
end

-- HTML img tag (multi-line)
T["html img multi-line"] = MiniTest.new_set()

T["html img multi-line"]["extracts src from tag spanning multiple lines"] = function()
  with_buffer({
    "<img",
    '  src="https://example.com/wide.png"',
    "  alt='wide image'>",
  }, 1, 0, function()
    local src, err = cursor.get_image_source_under_cursor()
    MiniTest.expect.equality(err, nil)
    MiniTest.expect.equality(src, "https://example.com/wide.png")
  end)
end

-- Nearest-source fallback
T["nearest source fallback"] = MiniTest.new_set()

T["nearest source fallback"]["finds image on adjacent line when current line has none"] = function()
  with_buffer({
    "![alt](https://example.com/near.png)",
    "plain text here",
  }, 2, 0, function()
    local src, err = cursor.get_image_source_under_cursor()
    MiniTest.expect.equality(err, nil)
    MiniTest.expect.equality(src, "https://example.com/near.png")
  end)
end

T["nearest source fallback"]["returns error when no source within scan radius"] = function()
  local lines = {}
  for _ = 1, 30 do
    table.insert(lines, "plain text")
  end
  with_buffer(lines, 15, 0, function()
    local src, err = cursor.get_image_source_under_cursor()
    MiniTest.expect.equality(src, nil)
    MiniTest.expect.no_equality(err, nil)
  end)
end

-- NOTE: test for ![alt](<path with spaces>) is intentionally absent here.
-- This is a known bug tracked in Faz 1 (normalize_markdown_target strips
-- path at first whitespace after removing <> wrappers). The test will be
-- added in cursor_spec.lua once the Faz 1 fix is applied.

return T
