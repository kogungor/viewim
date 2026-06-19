-- mini.nvim is cloned to /tmp/mini.nvim by CI (see .github/workflows/ci.yml)
vim.opt.rtp:prepend("/tmp/mini.nvim")
vim.opt.rtp:prepend(vim.fn.getcwd())

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.shadafile = "NONE"
