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

vim.api.nvim_create_user_command("ViewImageEnable", function()
  require("viewim").enable()
end, {
  nargs = 0,
  desc = "Enable viewim previews",
})

vim.api.nvim_create_user_command("ViewImageDisable", function()
  require("viewim").disable()
end, {
  nargs = 0,
  desc = "Disable viewim previews",
})

vim.api.nvim_create_user_command("ViewImageToggle", function()
  require("viewim").toggle()
end, {
  nargs = 0,
  desc = "Toggle viewim previews",
})

vim.api.nvim_create_user_command("ViewImageStatus", function()
  require("viewim").status()
end, {
  nargs = 0,
  desc = "Show viewim status",
})
