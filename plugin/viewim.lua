if vim.g.loaded_viewim then
  return
end
vim.g.loaded_viewim = true

vim.api.nvim_create_user_command("ViewImage", function(cmd_opts)
  local path = cmd_opts.args ~= "" and cmd_opts.args or nil
  require("viewim").view(path)
end, {
  nargs = "?",
  complete = "file",
  desc = "Preview an image file in the terminal",
})
