local util = require("viewim.runners.util")

local M = {}

local function unix_socket_path(addr)
  if type(addr) ~= "string" then
    return nil
  end
  return addr:match("^unix:(.+)$")
end

local function socket_is_available(addr)
  local path = unix_socket_path(addr)
  if not path then
    return true
  end
  return vim.fn.getftype(path) == "socket"
end

local function detached_launch(path, listen_on, launch_type)
  local cmd = { "kitty", "@" }
  if listen_on and listen_on ~= "" and socket_is_available(listen_on) then
    vim.list_extend(cmd, { "--to", listen_on })
  end

  vim.list_extend(cmd, {
    "launch",
    "--type=" .. (launch_type or "os-window"),
    "--cwd=current",
    "--hold",
    "--",
    "kitty",
    "+kitten",
    "icat",
    path,
  })

  local stderr_buf = {}
  local job_id = vim.fn.jobstart(cmd, {
    detach = true,
    on_stderr = function(_, data)
      if type(data) == "table" then
        vim.list_extend(stderr_buf, data)
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        return
      end

      local msg = util.join_nonempty(stderr_buf)
      if msg == "" then
        msg = "kitty launch exited with code " .. code
      end

      vim.schedule(function()
        vim.notify("viewim: kitty error: " .. msg, vim.log.levels.ERROR)
      end)
    end,
  })

  if job_id <= 0 then
    return false, "viewim: failed to start kitty launch job"
  end

  return true
end

--- Launch kitty preview.
--- @param path string
--- @param opts table|nil
--- @return boolean,string|nil
function M.run(path, opts)
  if vim.fn.executable("kitty") ~= 1 then
    return false, "viewim: 'kitty' command not found in $PATH"
  end

  opts = opts or {}
  local listen_on = opts.listen_on or os.getenv("KITTY_LISTEN_ON")
  local launch_type = opts.launch_type or "os-window"
  local can_use_socket = listen_on and listen_on ~= "" and socket_is_available(listen_on)

  local cmd = { "kitty", "@" }
  if can_use_socket then
    vim.list_extend(cmd, { "--to", listen_on })
  elseif listen_on and listen_on ~= "" then
    vim.notify(
      "viewim: kitty socket not found, retrying without --to: " .. listen_on,
      vim.log.levels.WARN
    )
  end

  vim.list_extend(cmd, {
    "launch",
    "--type=" .. launch_type,
    "--cwd=current",
    "--hold",
    "--",
    "kitty",
    "+kitten",
    "icat",
    path,
  })

  local stderr_buf = {}
  local job_id = vim.fn.jobstart(cmd, {
    detach = true,
    on_stderr = function(_, data)
      if type(data) == "table" then
        vim.list_extend(stderr_buf, data)
      end
    end,
    on_exit = function(_, code)
      local stderr_msg = util.join_nonempty(stderr_buf)
      local stderr_lower = stderr_msg:lower()
      local tty_issue = stderr_lower:find("/dev/tty", 1, true)
        or stderr_lower:find("controlling terminal", 1, true)
      local socket_missing = stderr_lower:find("failed to connect", 1, true)
        and stderr_lower:find("no such file or directory", 1, true)

      if socket_missing then
        local env_listen = os.getenv("KITTY_LISTEN_ON")
        local retry_listen = nil
        if env_listen and env_listen ~= "" and env_listen ~= listen_on then
          retry_listen = env_listen
        end

        vim.schedule(function()
          local ok, err = detached_launch(path, retry_listen, launch_type)
          if not ok and err then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end)
        return
      end

      if tty_issue then
        vim.schedule(function()
          local ok, err = detached_launch(path, listen_on, launch_type)
          if not ok and err then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end)
        return
      end

      if code == 0 then
        return
      end

      local msg = stderr_msg ~= "" and stderr_msg or ("kitty launch exited with code " .. code)
      vim.schedule(function()
        vim.notify("viewim: kitty error: " .. msg, vim.log.levels.ERROR)
      end)
    end,
  })

  if job_id <= 0 then
    return false, "viewim: failed to start kitty launch job"
  end

  return true
end

return M
