local MiniTest = require("mini.test")
local path = require("viewim.path")

local T = MiniTest.new_set()

-- has_control_chars
T["has_control_chars"] = MiniTest.new_set()

T["has_control_chars"]["returns false for normal path"] = function()
  MiniTest.expect.equality(path.has_control_chars("/home/user/image.png"), false)
end

T["has_control_chars"]["returns false for empty string"] = function()
  MiniTest.expect.equality(path.has_control_chars(""), false)
end

T["has_control_chars"]["returns true for null byte"] = function()
  MiniTest.expect.equality(path.has_control_chars("file\0name.png"), true)
end

T["has_control_chars"]["returns true for newline"] = function()
  MiniTest.expect.equality(path.has_control_chars("file\nname.png"), true)
end

T["has_control_chars"]["returns true for tab"] = function()
  MiniTest.expect.equality(path.has_control_chars("file\tname.png"), true)
end

T["has_control_chars"]["returns true for carriage return"] = function()
  MiniTest.expect.equality(path.has_control_chars("file\rname.png"), true)
end

T["has_control_chars"]["returns true for DEL (127)"] = function()
  MiniTest.expect.equality(path.has_control_chars("file\127name.png"), true)
end

T["has_control_chars"]["returns false for non-string"] = function()
  MiniTest.expect.equality(path.has_control_chars(nil), false)
  MiniTest.expect.equality(path.has_control_chars(123), false)
end

T["has_control_chars"]["returns false for path with spaces"] = function()
  MiniTest.expect.equality(path.has_control_chars("/home/user/my image.png"), false)
end

T["has_control_chars"]["returns false for unicode path"] = function()
  MiniTest.expect.equality(path.has_control_chars("/home/user/görsel.png"), false)
end

-- resolve (requires filesystem; tests use temp files)
T["resolve"] = MiniTest.new_set()

T["resolve"]["returns absolute path unchanged"] = function()
  local tmp = vim.fn.tempname() .. ".png"
  vim.fn.writefile({}, tmp)
  local result = path.resolve(tmp)
  -- should be the same absolute path (normalized)
  MiniTest.expect.equality(result, vim.fn.fnamemodify(tmp, ":p"))
  vim.fn.delete(tmp)
end

T["resolve"]["expands ~ in path"] = function()
  local home = vim.fn.expand("~")
  local result = path.resolve("~/nonexistent_viewim_test.png")
  MiniTest.expect.equality(result:sub(1, #home), home)
end

return T
