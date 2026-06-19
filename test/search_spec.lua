local MiniTest = require("mini.test")
local search = require("viewim.search")
local config = require("viewim.config")

local T = MiniTest.new_set()

local orig_cwd = vim.fn.getcwd()

local function make_tmp_dir()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  return dir
end

-- find
T["find"] = MiniTest.new_set({
  hooks = {
    pre_case = function()
      config.setup({})
    end,
    post_case = function()
      vim.fn.chdir(orig_cwd)
    end,
  },
})

T["find"]["returns empty list when directory has no images"] = function()
  local dir = make_tmp_dir()
  vim.fn.writefile({}, dir .. "/readme.txt")
  vim.fn.chdir(dir)

  local results = search.find("")
  MiniTest.expect.equality(results, {})

  vim.fn.delete(dir, "rf")
end

T["find"]["finds png and jpg files"] = function()
  local dir = make_tmp_dir()
  vim.fn.writefile({}, dir .. "/photo.png")
  vim.fn.writefile({}, dir .. "/banner.jpg")
  vim.fn.writefile({}, dir .. "/readme.txt")
  vim.fn.chdir(dir)

  local results = search.find("")
  MiniTest.expect.equality(#results, 2)

  vim.fn.delete(dir, "rf")
end

T["find"]["result items have path, label and name fields"] = function()
  local dir = make_tmp_dir()
  vim.fn.writefile({}, dir .. "/photo.png")
  vim.fn.chdir(dir)

  local results = search.find("")
  MiniTest.expect.equality(#results, 1)
  MiniTest.expect.no_equality(results[1].path, nil)
  MiniTest.expect.no_equality(results[1].label, nil)
  MiniTest.expect.no_equality(results[1].name, nil)

  vim.fn.delete(dir, "rf")
end

T["find"]["filters by query (basename match)"] = function()
  local dir = make_tmp_dir()
  vim.fn.writefile({}, dir .. "/avatar.png")
  vim.fn.writefile({}, dir .. "/banner.png")
  vim.fn.writefile({}, dir .. "/logo.jpg")
  vim.fn.chdir(dir)

  local results = search.find("ava")
  MiniTest.expect.equality(#results, 1)
  MiniTest.expect.equality(results[1].name, "avatar.png")

  vim.fn.delete(dir, "rf")
end

T["find"]["empty query returns all images"] = function()
  local dir = make_tmp_dir()
  vim.fn.writefile({}, dir .. "/a.png")
  vim.fn.writefile({}, dir .. "/b.gif")
  vim.fn.writefile({}, dir .. "/c.webp")
  vim.fn.chdir(dir)

  local results = search.find("")
  MiniTest.expect.equality(#results, 3)

  vim.fn.delete(dir, "rf")
end

T["find"]["nil query behaves like empty query"] = function()
  local dir = make_tmp_dir()
  vim.fn.writefile({}, dir .. "/photo.png")
  vim.fn.chdir(dir)

  local results = search.find(nil)
  MiniTest.expect.equality(#results, 1)

  vim.fn.delete(dir, "rf")
end

T["find"]["respects max_results limit"] = function()
  local dir = make_tmp_dir()
  -- Create 15 images but limit to 10 (min valid value is 10)
  for i = 1, 15 do
    vim.fn.writefile({}, dir .. "/image" .. i .. ".png")
  end
  vim.fn.chdir(dir)
  config.setup({ search = { max_results = 10 } })

  local results = search.find("")
  MiniTest.expect.equality(#results, 10)

  vim.fn.delete(dir, "rf")
end

T["find"]["does not include non-image files"] = function()
  local dir = make_tmp_dir()
  vim.fn.writefile({}, dir .. "/image.png")
  vim.fn.writefile({}, dir .. "/document.pdf")
  vim.fn.writefile({}, dir .. "/script.lua")
  vim.fn.writefile({}, dir .. "/data.json")
  vim.fn.chdir(dir)

  local results = search.find("")
  MiniTest.expect.equality(#results, 1)

  vim.fn.delete(dir, "rf")
end

T["find"]["results are sorted by name"] = function()
  local dir = make_tmp_dir()
  vim.fn.writefile({}, dir .. "/zebra.png")
  vim.fn.writefile({}, dir .. "/apple.png")
  vim.fn.writefile({}, dir .. "/mango.jpg")
  vim.fn.chdir(dir)

  local results = search.find("")
  MiniTest.expect.equality(results[1].name, "apple.png")
  MiniTest.expect.equality(results[2].name, "mango.jpg")
  MiniTest.expect.equality(results[3].name, "zebra.png")

  vim.fn.delete(dir, "rf")
end

return T
