local MiniTest = require("mini.test")

MiniTest.setup({
  execute = {
    reporter = MiniTest.gen_reporter.stdout({ group_depth = 2 }),
  },
  collect = {
    find_files = function()
      return vim.fn.globpath("test", "*_spec.lua", false, true)
    end,
  },
})

MiniTest.run()
