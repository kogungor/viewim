local detect = require("viewim.detect")
local util = require("viewim.runners.util")

local M = {}

local function add_tmux_direction_flags(cmd, direction)
  if direction == "left" then
    vim.list_extend(cmd, { "-h", "-b" })
  elseif direction == "right" then
    table.insert(cmd, "-h")
  elseif direction == "top" then
    vim.list_extend(cmd, { "-v", "-b" })
  elseif direction == "bottom" then
    table.insert(cmd, "-v")
  end
end

local function build_external_open_cmd(path, opener)
  if opener and opener ~= "auto" then
    return { opener, path }
  end

  local platform = detect.get_platform()
  if platform == "macos" then
    return { "open", path }
  elseif platform == "linux" then
    return { "xdg-open", path }
  elseif platform == "windows" then
    return { "explorer.exe", path }
  end

  return nil
end

--- Launch ghostty external opener preview.
--- @param path string
--- @param opts table|nil
--- @return boolean,string|nil
function M.run(path, opts)
  opts = opts or {}
  local mode = opts.mode or "external"
  if mode ~= "external" and mode ~= "tmux" then
    return false, "viewim: ghostty mode must be 'external' or 'tmux'"
  end

  if mode == "tmux" then
    if vim.fn.executable("tmux") ~= 1 then
      return false, "viewim: 'tmux' command not found in $PATH"
    end

    if not os.getenv("TMUX") then
      return false, "viewim: ghostty tmux mode requires running inside a tmux session"
    end

    local tmux_command = opts.tmux_command or "kitten icat --hold"
    local tmux_cmd = { "tmux", "split-window" }
    add_tmux_direction_flags(tmux_cmd, opts.tmux_split_direction or "right")

    if opts.tmux_split_percent then
      vim.list_extend(tmux_cmd, { "-p", tostring(opts.tmux_split_percent) })
    end

    local shell_cmd = tmux_command .. " " .. vim.fn.shellescape(path)
    table.insert(tmux_cmd, shell_cmd)

    local tmux_job = vim.fn.jobstart(tmux_cmd, {
      detach = true,
      on_stderr = function(_, data)
        local msg = util.join_nonempty(data)
        if msg ~= "" then
          vim.schedule(function()
            vim.notify("viewim: ghostty tmux error: " .. msg, vim.log.levels.ERROR)
          end)
        end
      end,
    })

    if tmux_job <= 0 then
      return false, "viewim: failed to start tmux split for ghostty preview"
    end

    return true
  end

  local opener = opts.opener or "auto"
  local cmd = build_external_open_cmd(path, opener)
  if not cmd or #cmd == 0 then
    return false, "viewim: could not determine external opener for this platform"
  end

  if opener == "auto" then
    local native = cmd[1]
    if vim.fn.executable(native) ~= 1 then
      return false, "viewim: native opener not found: " .. native
    end
  elseif vim.fn.executable(cmd[1]) ~= 1 then
    return false, "viewim: opener not found: " .. cmd[1]
  end

  local job_id = vim.fn.jobstart(cmd, {
    detach = true,
    on_stderr = function(_, data)
      local msg = util.join_nonempty(data)
      if msg ~= "" then
        vim.schedule(function()
          vim.notify("viewim: ghostty opener error: " .. msg, vim.log.levels.ERROR)
        end)
      end
    end,
  })

  if job_id <= 0 then
    return false, "viewim: failed to start ghostty opener"
  end

  return true
end

return M
