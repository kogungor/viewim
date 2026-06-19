-- Neovim global (globals not read_globals — plugins write to vim.g, vim.b, etc.)
globals = { "vim" }

-- 212: unused argument (common in callbacks)
-- 631: line too long (stylua enforces formatting)
ignore = { "212", "631" }

max_line_length = false
